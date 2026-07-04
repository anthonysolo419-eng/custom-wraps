# Zora Trading Bot

A momentum trading bot for [Zora](https://zora.co) coins (creator & content coins on Base), built on the official [`@zoralabs/coins-sdk`](https://docs.zora.co/coins/sdk/getting-started).

## ⚠️ Read this first

**No bot guarantees profit.** Zora coins are extremely volatile, thinly traded, and most of them go to zero. Momentum strategies like this one lose money in choppy or falling markets, and you also pay gas, swap fees, and slippage on every round trip. Treat this as a tool for experimenting with small amounts you can fully afford to lose — not an income source.

That's why the bot **defaults to paper trading**: it watches real market data and tracks hypothetical P&L in `state.json` without spending anything. Run it in paper mode for at least a couple of weeks and only consider going live if the paper results are consistently positive after assuming ~1–2% cost per round trip.

## What it does

Every `POLL_SECONDS` the bot:

1. **Manages open positions** — reprices each one via the Zora API and exits on take-profit (+30%), stop-loss (−15%), or a max-hold timeout (4h). All thresholds configurable.
2. **Scans for entries** — pulls the *top gainers* and *top 24h volume* explore feeds and buys coins that pass all filters:
   - 24h market-cap gain ≥ `MIN_24H_GAIN_PCT` (momentum)
   - 24h volume ≥ `MIN_VOLUME_24H_USD` (real activity)
   - market cap between `MIN_MARKET_CAP_USD` and `MAX_MARKET_CAP_USD` (not dust, not already peaked)
   - unique holders ≥ `MIN_UNIQUE_HOLDERS` (filters single-wallet pumps)

Risk limits: max `MAX_OPEN_POSITIONS` concurrent positions, fixed per-trade size, a daily realized-loss circuit breaker, and a re-entry cooldown per coin so it doesn't churn the same token.

State (open positions, trade history, daily P&L) persists to `state.json`, so restarts are safe.

## Setup

```bash
cd zora-bot
npm install
cp .env.example .env   # then edit .env
```

Get a free API key at [zora.co/settings/developer](https://zora.co/settings/developer) and put it in `ZORA_API_KEY` (optional but recommended — avoids rate limiting).

## Usage

```bash
# One-off scan: shows which coins currently pass your entry filters
npm run scan

# Run the bot (paper trading by default)
npm start
```

## Going live (optional, at your own risk)

1. Create a **fresh burner wallet** — never your main wallet — and fund it on **Base** with a small amount of ETH (enough for a few trades plus gas).
2. In `.env` set:
   ```
   LIVE_TRADING=true
   PRIVATE_KEY=0x...        # the burner wallet's key
   ```
3. Start with tiny sizes (`TRADE_SIZE_ETH=0.002`) and watch the first few round trips closely.

Live trades are routed through Zora's swap router via the SDK's `tradeCoin` (ETH → coin to enter, coin → ETH to exit, with your configured slippage tolerance).

**Key safety notes**
- The `.env` file is git-ignored. Never commit or share the private key.
- The daily loss limit only gates *new* entries; open positions still exit per their own rules.
- If you run this on Claude Code on the web or another sandbox, the environment's network policy must allow `api-sdk.zora.engineering` (Zora API) and your RPC host, or every request will fail.

## Other ways people make money on Zora (no bot needed)

Worth knowing before you sink time into trading automation — on Zora the most reliable earnings usually come from *creating*, not trading:

- **Post content**: every Zora post is automatically a tradeable coin, and creators earn a share of trading fees plus 10M of each coin's 1B supply.
- **Creator coins**: your profile has its own coin; fees accrue to you as it trades.
- **Referrals**: apps/interfaces that route trades earn protocol fee shares.

A "make money on Zora" bot could just as well be a bot that *posts* good content on a schedule — happy to build that variant too.

## Project layout

```
src/
  index.ts      entry point / main loop
  bot.ts        orchestrates scan → filter → trade → manage
  strategy.ts   entry filters and exit rules
  trader.ts     PaperTrader (USD ledger) and LiveTrader (real swaps via tradeCoin)
  zora.ts       market data via the Coins SDK explore/coin queries
  portfolio.ts  position tracking, P&L, persistence (state.json)
  config.ts     all tunables, read from .env
  types.ts      shared types
```
