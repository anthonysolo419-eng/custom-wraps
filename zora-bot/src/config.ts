import "dotenv/config";

function num(name: string, fallback: number): number {
  const raw = process.env[name];
  if (raw === undefined || raw === "") return fallback;
  const value = Number(raw);
  if (!Number.isFinite(value)) throw new Error(`${name} must be a number, got "${raw}"`);
  return value;
}

export const config = {
  zoraApiKey: process.env.ZORA_API_KEY || "",
  liveTrading: process.env.LIVE_TRADING === "true",
  privateKey: process.env.PRIVATE_KEY || "",
  rpcUrl: process.env.RPC_URL || "https://mainnet.base.org",

  pollSeconds: num("POLL_SECONDS", 60),

  entry: {
    min24hGainPct: num("MIN_24H_GAIN_PCT", 20),
    minVolume24hUsd: num("MIN_VOLUME_24H_USD", 5000),
    minMarketCapUsd: num("MIN_MARKET_CAP_USD", 10000),
    maxMarketCapUsd: num("MAX_MARKET_CAP_USD", 2_000_000),
    minUniqueHolders: num("MIN_UNIQUE_HOLDERS", 25),
  },

  exit: {
    takeProfitPct: num("TAKE_PROFIT_PCT", 30),
    stopLossPct: num("STOP_LOSS_PCT", 15),
    maxHoldMinutes: num("MAX_HOLD_MINUTES", 240),
  },

  risk: {
    tradeSizeEth: num("TRADE_SIZE_ETH", 0.005),
    tradeSizeUsd: num("TRADE_SIZE_USD", 15),
    maxOpenPositions: num("MAX_OPEN_POSITIONS", 3),
    dailyLossLimitUsd: num("DAILY_LOSS_LIMIT_USD", 50),
    reentryCooldownMinutes: num("REENTRY_COOLDOWN_MINUTES", 360),
    slippage: num("SLIPPAGE", 0.05),
  },
};

export function assertLiveConfig(): void {
  if (!config.privateKey.startsWith("0x") || config.privateKey.length !== 66) {
    throw new Error(
      "LIVE_TRADING=true requires PRIVATE_KEY to be a 0x-prefixed 32-byte hex key. " +
        "Use a dedicated burner wallet funded only with what you can afford to lose."
    );
  }
}
