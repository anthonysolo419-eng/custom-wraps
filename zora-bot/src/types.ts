export interface CoinSnapshot {
  address: string;
  chainId: number;
  name: string;
  symbol: string;
  priceUsd: number;
  marketCapUsd: number;
  marketCapDelta24hUsd: number;
  volume24hUsd: number;
  uniqueHolders: number;
  createdAt?: string;
}

export interface Position {
  coinAddress: string;
  symbol: string;
  /** "paper" positions track USD only; "live" positions hold real tokens */
  mode: "paper" | "live";
  entryPriceUsd: number;
  /** USD spent at entry (paper: TRADE_SIZE_USD; live: ETH spent × ETH price at entry) */
  costUsd: number;
  /** Token quantity. Paper: costUsd / entryPriceUsd. Live: on-chain balance in wei. */
  tokenAmount: string;
  openedAt: string;
}

export interface ClosedTrade {
  coinAddress: string;
  symbol: string;
  mode: "paper" | "live";
  costUsd: number;
  proceedsUsd: number;
  pnlUsd: number;
  reason: "take-profit" | "stop-loss" | "max-hold" | "manual";
  openedAt: string;
  closedAt: string;
}

export interface BotState {
  positions: Position[];
  history: ClosedTrade[];
  /** coin address -> ISO time of last exit, for re-entry cooldown */
  cooldowns: Record<string, string>;
  /** YYYY-MM-DD -> realized P&L in USD */
  dailyPnlUsd: Record<string, number>;
}
