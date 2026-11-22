import { describe, expect, it } from "vitest";
import {
  DEEPSEEK_BASE_URL,
  DEEPSEEK_DEFAULT_MODEL,
  deepSeekModel,
  deepSeekModels,
  deepSeekSdkOptions,
  isDeepSeekEnabled,
} from "./deepseek.js";

const enabled = { BRIDGE_CLAUDE_BACKEND: "deepseek", DEEPSEEK_API_KEY: "test-deepseek-key" };

describe("DeepSeek backend", () => {
  it("requires explicit selection and leaves other SDK sessions unchanged", () => {
    expect(isDeepSeekEnabled({ DEEPSEEK_API_KEY: "unused" })).toBe(false);
    expect(deepSeekSdkOptions({ ANTHROPIC_API_KEY: "anthropic" })).toEqual({});
    expect(deepSeekModel("sonnet", {})).toBe("sonnet");
  });

  it("isolates credentials and backend flags without mutating the host environment", () => {
    const source = {
      ...enabled,
      ANTHROPIC_API_KEY: "other-key",
      CLAUDE_CODE_OAUTH_TOKEN: "oauth-token",
      CLAUDE_CODE_USE_BEDROCK: "1",
      CLAUDE_CODE_USE_VERTEX: "1",
      CLAUDE_CODE_USE_FOUNDRY: "1",
      PATH: "/test/bin",
    };
    const options = deepSeekSdkOptions(source);
    expect(options.env).toMatchObject({
      ANTHROPIC_BASE_URL: DEEPSEEK_BASE_URL,
      ANTHROPIC_AUTH_TOKEN: "test-deepseek-key",
      ANTHROPIC_API_KEY: "",
      CLAUDE_CODE_OAUTH_TOKEN: "",
      CLAUDE_CODE_USE_BEDROCK: "0",
      CLAUDE_CODE_USE_VERTEX: "0",
      CLAUDE_CODE_USE_FOUNDRY: "0",
      ANTHROPIC_MODEL: DEEPSEEK_DEFAULT_MODEL,
      ANTHROPIC_DEFAULT_OPUS_MODEL: DEEPSEEK_DEFAULT_MODEL,
      ANTHROPIC_DEFAULT_SONNET_MODEL: DEEPSEEK_DEFAULT_MODEL,
      ANTHROPIC_DEFAULT_HAIKU_MODEL: "deepseek-flash",
      CLAUDE_CODE_SUBAGENT_MODEL: "deepseek-flash",
      PATH: "/test/bin",
    });
    expect(source.ANTHROPIC_API_KEY).toBe("other-key");
    expect(source.CLAUDE_CODE_USE_BEDROCK).toBe("1");
  });

  it("rejects a missing or blank key even if other credentials exist", () => {
    for (const key of [undefined, "", "  "]) {
      expect(() => deepSeekSdkOptions({ ...enabled, DEEPSEEK_API_KEY: key, ANTHROPIC_API_KEY: "other" }))
        .toThrow("DeepSeek requires DEEPSEEK_API_KEY");
    }
  });

  it("maps old mobile Claude selections to the DeepSeek default", () => {
    for (const model of [undefined, "default", "sonnet", "opus[1m]", "claude-opus-4-7", "claude-sonnet-4-6"]) {
      expect(deepSeekModel(model, enabled)).toBe(DEEPSEEK_DEFAULT_MODEL);
    }
    expect(deepSeekModel("deepseek-v4-pro", enabled)).toBe("deepseek-v4-pro");
  });

  it("advertises a custom default first without duplicates or credential data", () => {
    const env = { ...enabled, DEEPSEEK_MODEL: "my-deepseek-model" };
    expect(deepSeekModel("sonnet", env)).toBe("my-deepseek-model");
    const models = deepSeekModels(env);
    expect(models[0].model).toBe("my-deepseek-model");
    expect(new Set(models.map((m) => m.model)).size).toBe(models.length);
    expect(JSON.stringify(models)).not.toContain(enabled.DEEPSEEK_API_KEY);
    expect(models.every((m) => m.effortLevels.length === 0)).toBe(true);
  });
});
