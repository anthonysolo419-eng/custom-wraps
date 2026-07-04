import { tradeCoin } from "@zoralabs/coins-sdk";
import {
  createPublicClient,
  createWalletClient,
  erc20Abi,
  formatUnits,
  http,
  parseEther,
  type Address,
  type HttpTransport,
  type PublicClient,
  type WalletClient,
} from "viem";
import { privateKeyToAccount, type PrivateKeyAccount } from "viem/accounts";
import { base } from "viem/chains";
import { assertLiveConfig, config } from "./config.js";
import type { CoinSnapshot, Position } from "./types.js";

export interface Trader {
  readonly mode: "paper" | "live";
  buy(coin: CoinSnapshot): Promise<Position>;
  /** Returns proceeds in USD. */
  sell(position: Position, currentPriceUsd: number): Promise<number>;
}

/** Paper trader: no transactions, tracks a USD ledger against live prices. */
export class PaperTrader implements Trader {
  readonly mode = "paper" as const;

  async buy(coin: CoinSnapshot): Promise<Position> {
    const costUsd = config.risk.tradeSizeUsd;
    return {
      coinAddress: coin.address,
      symbol: coin.symbol,
      mode: this.mode,
      entryPriceUsd: coin.priceUsd,
      costUsd,
      tokenAmount: String(costUsd / coin.priceUsd),
      openedAt: new Date().toISOString(),
    };
  }

  async sell(position: Position, currentPriceUsd: number): Promise<number> {
    return Number(position.tokenAmount) * currentPriceUsd;
  }
}

/** Live trader: swaps real ETH on Base through Zora's router. */
export class LiveTrader implements Trader {
  readonly mode = "live" as const;
  private account: PrivateKeyAccount;
  private walletClient: WalletClient<HttpTransport, typeof base, PrivateKeyAccount>;
  private publicClient: PublicClient<HttpTransport, typeof base>;

  constructor() {
    assertLiveConfig();
    this.account = privateKeyToAccount(config.privateKey as `0x${string}`);
    const transport = http(config.rpcUrl);
    this.walletClient = createWalletClient({ account: this.account, chain: base, transport });
    this.publicClient = createPublicClient({ chain: base, transport });
    console.log(`[live] trading as ${this.account.address}`);
  }

  private balanceOf(token: Address): Promise<bigint> {
    return this.publicClient.readContract({
      address: token,
      abi: erc20Abi,
      functionName: "balanceOf",
      args: [this.account.address],
    });
  }

  async buy(coin: CoinSnapshot): Promise<Position> {
    const coinAddress = coin.address as Address;
    const before = await this.balanceOf(coinAddress);
    const receipt = await tradeCoin({
      tradeParameters: {
        sell: { type: "eth" },
        buy: { type: "erc20", address: coinAddress },
        amountIn: parseEther(String(config.risk.tradeSizeEth)),
        slippage: config.risk.slippage,
        sender: this.account.address,
      },
      walletClient: this.walletClient,
      account: this.account,
      publicClient: this.publicClient,
    });
    console.log(`[live] buy ${coin.symbol} tx ${receipt.transactionHash}`);
    const received = (await this.balanceOf(coinAddress)) - before;
    if (received <= 0n) throw new Error(`buy of ${coin.symbol} settled but no tokens received`);
    const costUsd = Number(formatUnits(received, 18)) * coin.priceUsd;
    return {
      coinAddress: coin.address,
      symbol: coin.symbol,
      mode: this.mode,
      entryPriceUsd: coin.priceUsd,
      costUsd,
      tokenAmount: received.toString(),
      openedAt: new Date().toISOString(),
    };
  }

  async sell(position: Position, currentPriceUsd: number): Promise<number> {
    const coinAddress = position.coinAddress as Address;
    // Sell the actual on-chain balance, capped at what this position bought,
    // so a manual top-up of the same coin isn't swept out from under you.
    const balance = await this.balanceOf(coinAddress);
    const amountIn = balance < BigInt(position.tokenAmount) ? balance : BigInt(position.tokenAmount);
    if (amountIn <= 0n) {
      console.warn(`[live] no ${position.symbol} balance left to sell`);
      return 0;
    }
    const receipt = await tradeCoin({
      tradeParameters: {
        sell: { type: "erc20", address: coinAddress },
        buy: { type: "eth" },
        amountIn,
        slippage: config.risk.slippage,
        sender: this.account.address,
      },
      walletClient: this.walletClient,
      account: this.account,
      publicClient: this.publicClient,
    });
    console.log(`[live] sell ${position.symbol} tx ${receipt.transactionHash}`);
    return Number(formatUnits(amountIn, 18)) * currentPriceUsd;
  }
}

export function createTrader(): Trader {
  return config.liveTrading ? new LiveTrader() : new PaperTrader();
}
