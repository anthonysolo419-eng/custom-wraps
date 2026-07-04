import { config } from "./config.js";
import {
  dailyLossLimitHit,
  inCooldown,
  loadState,
  recordClose,
  recordOpen,
  summarize,
} from "./portfolio.js";
import { checkExit, rejectEntry } from "./strategy.js";
import { createTrader, type Trader } from "./trader.js";
import type { BotState } from "./types.js";
import { fetchCandidates, fetchCoin } from "./zora.js";

export class Bot {
  private state: BotState = loadState();
  private trader: Trader = createTrader();

  async tick(): Promise<void> {
    await this.manageOpenPositions();
    await this.scanForEntries();
    console.log(`[bot] ${summarize(this.state)}`);
  }

  private async manageOpenPositions(): Promise<void> {
    for (const position of [...this.state.positions]) {
      try {
        const coin = await fetchCoin(position.coinAddress);
        if (!coin) {
          console.warn(`[bot] could not price ${position.symbol}, will retry next tick`);
          continue;
        }
        const signal = checkExit(position, coin.priceUsd);
        if (!signal) continue;
        const proceedsUsd = await this.trader.sell(position, coin.priceUsd);
        const trade = recordClose(this.state, position, proceedsUsd, signal.reason);
        console.log(
          `[bot] closed ${trade.symbol} (${trade.reason}) P&L $${trade.pnlUsd.toFixed(2)}`
        );
      } catch (error) {
        console.error(`[bot] error managing ${position.symbol}:`, error);
      }
    }
  }

  private async scanForEntries(): Promise<void> {
    if (this.state.positions.length >= config.risk.maxOpenPositions) return;
    if (dailyLossLimitHit(this.state)) {
      console.log("[bot] daily loss limit hit — no new entries today");
      return;
    }

    const candidates = await fetchCandidates();
    for (const coin of candidates) {
      if (this.state.positions.length >= config.risk.maxOpenPositions) break;
      const address = coin.address.toLowerCase();
      if (this.state.positions.some((p) => p.coinAddress.toLowerCase() === address)) continue;
      if (inCooldown(this.state, coin.address)) continue;
      if (rejectEntry(coin)) continue;

      try {
        const position = await this.trader.buy(coin);
        recordOpen(this.state, position);
        console.log(
          `[bot] opened ${position.mode} position in ${coin.symbol} @ $${coin.priceUsd.toPrecision(4)} ` +
            `(mcap $${Math.round(coin.marketCapUsd).toLocaleString()}, ` +
            `24h vol $${Math.round(coin.volume24hUsd).toLocaleString()}, ` +
            `${coin.uniqueHolders} holders)`
        );
      } catch (error) {
        console.error(`[bot] buy failed for ${coin.symbol}:`, error);
      }
    }
  }

  /** One-off scan that prints which coins currently pass/fail the entry filter. */
  async scanOnce(): Promise<void> {
    const candidates = await fetchCandidates();
    console.log(`fetched ${candidates.length} candidates from Zora explore feeds\n`);
    const passing = [];
    for (const coin of candidates) {
      const rejection = rejectEntry(coin);
      if (!rejection) passing.push(coin);
    }
    for (const coin of passing) {
      console.log(
        `PASS ${coin.symbol.padEnd(12)} $${coin.priceUsd.toPrecision(4).padEnd(12)} ` +
          `mcap $${Math.round(coin.marketCapUsd).toLocaleString().padEnd(12)} ` +
          `24h vol $${Math.round(coin.volume24hUsd).toLocaleString().padEnd(12)} ` +
          `${coin.uniqueHolders} holders  ${coin.address}`
      );
    }
    console.log(`\n${passing.length} of ${candidates.length} pass the current entry filters`);
  }
}
