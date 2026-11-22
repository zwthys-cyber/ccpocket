/** DeepSeek's official Anthropic-compatible backend for Claude SDK sessions. */
export const DEEPSEEK_BASE_URL = "https://api.deepseek.com/anthropic";
export const DEEPSEEK_DEFAULT_MODEL = "deepseek-flash[1m]";

export function isDeepSeekEnabled(env: NodeJS.ProcessEnv = process.env): boolean {
  return env.BRIDGE_CLAUDE_BACKEND?.trim().toLowerCase() === "deepseek";
}

export function deepSeekModel(
  model?: string,
  env: NodeJS.ProcessEnv = process.env,
): string | undefined {
  if (!isDeepSeekEnabled(env)) return model;
  // Older mobile clients send a Claude model by default. Use the configured
  // DeepSeek default instead of relying on the API's implicit price-tier mapping.
  if (!model || /^(?:default|sonnet|opus|haiku|claude-.*)(?:\[1m\])?$/.test(model)) {
    return env.DEEPSEEK_MODEL?.trim() || DEEPSEEK_DEFAULT_MODEL;
  }
  return model;
}

export function deepSeekModels(env: NodeJS.ProcessEnv = process.env) {
  const models = [...new Set([
    deepSeekModel(undefined, env)!,
    DEEPSEEK_DEFAULT_MODEL,
    "deepseek-flash",
    "deepseek-v4-pro",
  ])];
  return models.map((model) => ({ model, displayName: `DeepSeek · ${model}`, effortLevels: [] }));
}

export function deepSeekSdkOptions(env: NodeJS.ProcessEnv = process.env) {
  if (!isDeepSeekEnabled(env)) return {};
  const key = env.DEEPSEEK_API_KEY?.trim();
  if (!key) throw new Error("DeepSeek requires DEEPSEEK_API_KEY on the Bridge host");
  return {
    env: {
      ...env,
      ANTHROPIC_BASE_URL: DEEPSEEK_BASE_URL,
      ANTHROPIC_AUTH_TOKEN: key,
      // Prevent an inherited Anthropic key or OAuth session from taking priority.
      ANTHROPIC_API_KEY: "",
      CLAUDE_CODE_OAUTH_TOKEN: "",
      CLAUDE_CODE_USE_BEDROCK: "0",
      CLAUDE_CODE_USE_VERTEX: "0",
      CLAUDE_CODE_USE_FOUNDRY: "0",
      ANTHROPIC_MODEL: deepSeekModel(undefined, env),
      ANTHROPIC_DEFAULT_OPUS_MODEL: deepSeekModel(undefined, env),
      ANTHROPIC_DEFAULT_SONNET_MODEL: deepSeekModel(undefined, env),
      ANTHROPIC_DEFAULT_HAIKU_MODEL: "deepseek-flash",
      CLAUDE_CODE_SUBAGENT_MODEL: "deepseek-flash",
    },
  };
}
