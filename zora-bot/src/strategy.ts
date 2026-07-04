import { config } from "./config.js";
import type { CoinSnapshot, Position } from "./types.js";

export interface ExitSignal {
  position: Position;
  reason: "take-profit" | "stop-loss" | "max-hold";
  currentPriceUsd: number;
}

/**
 * Momentum entry: the coin is already moving (24h gain), has real two-sided
 * activity (volume, holders), and is small enough to still have room.
 * Returns a reason string when the coin is rejected, or null when it passes.
 */
export function rejectEntry(coin: CoinSnapshot): string | null {
  const { entry } = config;
  const previousCap = coin.marketCapUsd - coin.marketCapDelta24hUsd;
  const gainPct = previousCap > 0 ? (coin.marketCapDelta24hUsd / previousCap) * 100 : 0;

  if (gainPct < entry.min24hGainPct) return `24h gain ${gainPct.toFixed(1)}% below ${entry.min24hGainPct}%`;
  if (coin.volume24hUsd < entry.minVolume24hUsd) return `volume $${coin.volume24hUsd.toFixed(0)} below floor`;
  if (coin.marketCapUsd < entry.minMarketCapUsd) return `market cap $${coin.marketCapUsd.toFixed(0)} below floor`;
  if (coin.marketCapUsd > entry.maxMarketCapUsd) return `market cap $${coin.marketCapUsd.toFixed(0)} above ceiling`;
  if (coin.uniqueHolders < entry.minUniqueHolders) return `${coin.uniqueHolders} holders below ${entry.minUniqueHolders}`;
  return null;
}

export function checkExit(position: Position, currentPriceUsd: number): ExitSignal | null {
  const { exit } = config;
  const changePct = ((currentPriceUsd - position.entryPriceUsd) / position.entryPriceUsd) * 100;
  const heldMinutes = (Date.now() - Date.parse(position.openedAt)) / 60_000;

  let reason: ExitSignal["reason"] | null = null;
  if (changePct >= exit.takeProfitPct) reason = "take-profit";
  else if (changePct <= -exit.stopLossPct) reason = "stop-loss";
  else if (heldMinutes >= exit.maxHoldMinutes) reason = "max-hold";

  return reason ? { position, reason, currentPriceUsd } : null;
}
