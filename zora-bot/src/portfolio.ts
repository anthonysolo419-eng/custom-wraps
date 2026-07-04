import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { config } from "./config.js";
import type { BotState, ClosedTrade, Position } from "./types.js";

const STATE_FILE = new URL("../state.json", import.meta.url).pathname;

export function loadState(): BotState {
  if (!existsSync(STATE_FILE)) {
    return { positions: [], history: [], cooldowns: {}, dailyPnlUsd: {} };
  }
  return JSON.parse(readFileSync(STATE_FILE, "utf8")) as BotState;
}

export function saveState(state: BotState): void {
  writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
}

function today(): string {
  return new Date().toISOString().slice(0, 10);
}

export function recordOpen(state: BotState, position: Position): void {
  state.positions.push(position);
  saveState(state);
}

export function recordClose(
  state: BotState,
  position: Position,
  proceedsUsd: number,
  reason: ClosedTrade["reason"]
): ClosedTrade {
  const trade: ClosedTrade = {
    coinAddress: position.coinAddress,
    symbol: position.symbol,
    mode: position.mode,
    costUsd: position.costUsd,
    proceedsUsd,
    pnlUsd: proceedsUsd - position.costUsd,
    reason,
    openedAt: position.openedAt,
    closedAt: new Date().toISOString(),
  };
  state.positions = state.positions.filter((p) => p.coinAddress !== position.coinAddress);
  state.history.push(trade);
  state.cooldowns[position.coinAddress.toLowerCase()] = trade.closedAt;
  state.dailyPnlUsd[today()] = (state.dailyPnlUsd[today()] ?? 0) + trade.pnlUsd;
  saveState(state);
  return trade;
}

export function inCooldown(state: BotState, coinAddress: string): boolean {
  const closedAt = state.cooldowns[coinAddress.toLowerCase()];
  if (!closedAt) return false;
  const minutes = (Date.now() - Date.parse(closedAt)) / 60_000;
  return minutes < config.risk.reentryCooldownMinutes;
}

export function dailyLossLimitHit(state: BotState): boolean {
  return (state.dailyPnlUsd[today()] ?? 0) <= -config.risk.dailyLossLimitUsd;
}

export function summarize(state: BotState): string {
  const realized = state.history.reduce((sum, t) => sum + t.pnlUsd, 0);
  const wins = state.history.filter((t) => t.pnlUsd > 0).length;
  return (
    `open positions: ${state.positions.length} | closed trades: ${state.history.length} ` +
    `(${wins} wins) | realized P&L: $${realized.toFixed(2)} | today: $${(
      state.dailyPnlUsd[today()] ?? 0
    ).toFixed(2)}`
  );
}
