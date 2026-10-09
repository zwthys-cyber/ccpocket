import { beforeEach, describe, expect, it, vi } from "vitest";
import { consumeCodexReset, fetchAllUsage, fetchCodexUsage, isGlobalCodexRateLimit, mapCodexRateLimits } from "./usage.js";

const fiveHourWindow = {
  usedPercent: 35,
  windowDurationMins: 300,
  resetsAt: 1_800_000_000,
};

const sevenDayWindow = {
  usedPercent: 80,
  windowDurationMins: 10_080,
  resetsAt: 1_800_500_000,
};

describe("mapCodexRateLimits", () => {
  it("maps the usual primary and secondary windows by duration", () => {
    const result = mapCodexRateLimits({
      primary: fiveHourWindow,
      secondary: sevenDayWindow,
    });

    expect(result).toEqual({
      fiveHour: {
        utilization: 35,
        resetsAt: new Date(1_800_000_000 * 1000).toISOString(),
      },
      sevenDay: {
        utilization: 80,
        resetsAt: new Date(1_800_500_000 * 1000).toISOString(),
      },
    });
  });

  it("maps a weekly-only primary window to sevenDay", () => {
    const result = mapCodexRateLimits({
      primary: sevenDayWindow,
      secondary: null,
    });

    expect(result.fiveHour).toBeNull();
    expect(result.sevenDay?.utilization).toBe(80);
  });

  it("does not depend on the upstream window order", () => {
    const result = mapCodexRateLimits({
      primary: sevenDayWindow,
      secondary: fiveHourWindow,
    });

    expect(result.fiveHour?.utilization).toBe(35);
    expect(result.sevenDay?.utilization).toBe(80);
  });
});

describe("isGlobalCodexRateLimit", () => {
  it("accepts the account-wide Codex limit", () => {
    expect(isGlobalCodexRateLimit({ limitId: "codex" })).toBe(true);
  });

  it("accepts legacy rate limits without an identifier", () => {
    expect(isGlobalCodexRateLimit({})).toBe(true);
  });

  it("rejects model-specific Codex limits", () => {
    expect(isGlobalCodexRateLimit({ limitId: "codex_bengalfox" })).toBe(
      false,
    );
  });
});

const { initializeMock, readMock, stopMock, consumeMock } = vi.hoisted(() => ({
  initializeMock: vi.fn(),
  readMock: vi.fn(),
  stopMock: vi.fn(),
  consumeMock: vi.fn(),
}));

vi.mock("./codex-process.js", () => ({
  CodexProcess: class {
    initializeOnly = initializeMock;
    readRateLimits = readMock;
    stop = stopMock;
    consumeRateLimitReset = consumeMock;
  },
}));

describe("fetchCodexUsage", () => {
  beforeEach(() => {
    vi.resetAllMocks();
    initializeMock.mockResolvedValue(undefined);
    readMock.mockResolvedValue({ rateLimits: { primary: sevenDayWindow } });
  });

  it("preserves the authoritative reset count when detail rows are absent", async () => {
    readMock.mockResolvedValue({
      rateLimits: { primary: sevenDayWindow },
      rateLimitResetCredits: { availableCount: 3, credits: null },
    });
    expect((await fetchCodexUsage()).resetCredits).toEqual({ availableCount: 3, credits: null });
  });

  it("distinguishes unsupported reset information from zero available credits", async () => {
    expect((await fetchCodexUsage()).resetCredits).toBeNull();
    readMock.mockResolvedValue({
      rateLimits: { primary: sevenDayWindow },
      rateLimitResetCredits: { availableCount: 0, credits: [] },
    });
    expect((await fetchCodexUsage()).resetCredits).toEqual({ availableCount: 0, credits: [] });
  });

  it("reads fresh account limits on each refresh without a session", async () => {
    expect((await fetchAllUsage())[0].sevenDay?.utilization).toBe(80);
    readMock.mockResolvedValue({
      rateLimits: { primary: { ...sevenDayWindow, usedPercent: 100 } },
    });
    expect((await fetchAllUsage())[0].sevenDay?.utilization).toBe(100);
    expect(readMock).toHaveBeenCalledTimes(2);
    expect(stopMock).toHaveBeenCalledTimes(2);
    expect(initializeMock).toHaveBeenCalledWith(expect.any(String), 10_000);
  });

  it("prefers the account-wide bucket over the legacy view", async () => {
    readMock.mockResolvedValue({
      rateLimits: { limitId: "codex_other", primary: fiveHourWindow },
      rateLimitsByLimitId: {
        codex: { limitId: "codex", primary: sevenDayWindow },
      },
    });
    expect((await fetchCodexUsage()).sevenDay?.utilization).toBe(80);
  });

  it("shares concurrent requests without caching later reads", async () => {
    const first = fetchCodexUsage();
    const second = fetchCodexUsage();
    expect(first).toBe(second);
    await Promise.all([first, second]);
    expect(readMock).toHaveBeenCalledTimes(1);
    await fetchCodexUsage();
    expect(readMock).toHaveBeenCalledTimes(2);
  });

  it("clears old quota on RPC failure and allows retry", async () => {
    await fetchCodexUsage();
    readMock.mockRejectedValueOnce(new Error("Unauthorized"));
    expect(await fetchCodexUsage()).toEqual({
      provider: "codex", fiveHour: null, sevenDay: null,
      error: "Failed to fetch Codex usage: Unauthorized",
    });
    expect(stopMock).toHaveBeenCalledTimes(2);
    expect((await fetchCodexUsage()).sevenDay?.utilization).toBe(80);
  });

  it("stops the connection when initialization fails", async () => {
    initializeMock.mockRejectedValue(new Error("initialize timed out"));
    expect((await fetchCodexUsage()).error).toContain("initialize timed out");
    expect(readMock).not.toHaveBeenCalled();
    expect(stopMock).toHaveBeenCalledOnce();
  });

  it.each([
    { rateLimits: { limitId: "codex_other", primary: sevenDayWindow } },
    { rateLimits: { primary: null, secondary: null } },
    { rateLimits: { primary: { ...sevenDayWindow, resetsAt: null } } },
    { rateLimits: { primary: { ...sevenDayWindow, usedPercent: NaN } } },
    { rateLimits: { primary: { ...sevenDayWindow, windowDurationMins: 60 } } },
  ])("returns an error when no supported account quota is available: %j", async (response) => {
    readMock.mockResolvedValue(response);
    expect(await fetchCodexUsage()).toMatchObject({
      fiveHour: null, sevenDay: null, error: expect.any(String),
    });
    expect(stopMock).toHaveBeenCalledOnce();
  });
});

describe("consumeCodexReset", () => {
  beforeEach(() => {
    vi.resetAllMocks();
    initializeMock.mockResolvedValue(undefined);
    consumeMock.mockResolvedValue("reset");
  });

  it("shares concurrent redemptions of the same logical attempt", async () => {
    const first = consumeCodexReset("attempt-1", "credit-1");
    const second = consumeCodexReset("attempt-1", "credit-1");
    expect(first).toBe(second);
    expect(await first).toBe("reset");
    expect(consumeMock).toHaveBeenCalledExactlyOnceWith("attempt-1", "credit-1", 10_000);
    expect(stopMock).toHaveBeenCalledOnce();
  });

  it("cleans up a failed operation and reuses the caller's key on retry", async () => {
    consumeMock.mockRejectedValueOnce(new Error("Timeout"));
    await expect(consumeCodexReset("attempt-2")).rejects.toThrow("Timeout");
    expect(await consumeCodexReset("attempt-2")).toBe("reset");
    expect(consumeMock).toHaveBeenCalledTimes(2);
    expect(stopMock).toHaveBeenCalledTimes(2);
  });
});
