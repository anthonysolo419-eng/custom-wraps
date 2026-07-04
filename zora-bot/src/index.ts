import { config } from "./config.js";
import { Bot } from "./bot.js";

const bot = new Bot();

if (process.argv.includes("--scan-once")) {
  await bot.scanOnce();
  process.exit(0);
}

console.log(
  config.liveTrading
    ? "⚠️  LIVE TRADING ENABLED — real ETH will be spent on Base"
    : "📝 paper-trading mode (set LIVE_TRADING=true + PRIVATE_KEY to go live)"
);
console.log(`[bot] polling every ${config.pollSeconds}s — ctrl-c to stop`);

for (;;) {
  try {
    await bot.tick();
  } catch (error) {
    console.error("[bot] tick failed:", error);
  }
  await new Promise((resolve) => setTimeout(resolve, config.pollSeconds * 1000));
}
