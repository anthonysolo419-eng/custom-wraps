import {
  getCoin,
  getCoinsTopGainers,
  getCoinsTopVolume24h,
  setApiKey,
} from "@zoralabs/coins-sdk";
import { base } from "viem/chains";
import { config } from "./config.js";
import type { CoinSnapshot } from "./types.js";

if (config.zoraApiKey) setApiKey(config.zoraApiKey);

/** Shape shared by explore-feed nodes and getCoin's zora20Token. */
interface RawCoin {
  address?: string;
  chainId?: number;
  name?: string;
  symbol?: string;
  marketCap?: string;
  marketCapDelta24h?: string;
  volume24h?: string;
  totalSupply?: string;
  uniqueHolders?: number;
  createdAt?: string;
  platformBlocked?: boolean;
  tokenPrice?: { priceInUsdc?: string | null };
}

function toSnapshot(raw: RawCoin): CoinSnapshot | null {
  if (!raw.address || raw.platformBlocked) return null;
  const marketCapUsd = Number(raw.marketCap ?? "0");
  const totalSupply = Number(raw.totalSupply ?? "0");
  // Prefer the indexer's USD price; fall back to marketCap / supply.
  let priceUsd = Number(raw.tokenPrice?.priceInUsdc ?? "0");
  if (!priceUsd && marketCapUsd > 0 && totalSupply > 0) {
    priceUsd = marketCapUsd / totalSupply;
  }
  if (!priceUsd) return null;
  return {
    address: raw.address,
    chainId: raw.chainId ?? base.id,
    name: raw.name ?? "",
    symbol: raw.symbol ?? "",
    priceUsd,
    marketCapUsd,
    marketCapDelta24hUsd: Number(raw.marketCapDelta24h ?? "0"),
    volume24hUsd: Number(raw.volume24h ?? "0"),
    uniqueHolders: raw.uniqueHolders ?? 0,
    createdAt: raw.createdAt,
  };
}

/** Candidate coins from the top-gainers and top-volume feeds, deduped by address. */
export async function fetchCandidates(count = 50): Promise<CoinSnapshot[]> {
  const [gainers, volume] = await Promise.all([
    getCoinsTopGainers({ count }),
    getCoinsTopVolume24h({ count }),
  ]);
  const byAddress = new Map<string, CoinSnapshot>();
  for (const response of [gainers, volume]) {
    const edges = response.data?.exploreList?.edges ?? [];
    for (const edge of edges) {
      const snap = toSnapshot(edge.node as RawCoin);
      if (snap && snap.chainId === base.id) byAddress.set(snap.address.toLowerCase(), snap);
    }
  }
  return [...byAddress.values()];
}

/** Refresh a single coin (used to mark open positions to market). */
export async function fetchCoin(address: string): Promise<CoinSnapshot | null> {
  const response = await getCoin({ address, chain: base.id });
  const token = response.data?.zora20Token;
  return token ? toSnapshot(token as RawCoin) : null;
}
