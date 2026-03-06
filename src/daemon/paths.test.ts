import path from "node:path";

import { describe, expect, it } from "vitest";

import { resolveGatewayStateDir } from "./paths.js";

describe("resolveGatewayStateDir", () => {
  it("uses the default state dir when no overrides are set", () => {
    const env = { HOME: "/Users/test" };
    expect(resolveGatewayStateDir(env)).toBe(path.join("/Users/test", ".openclaw"));
  });

  it("appends the profile suffix when set", () => {
    const env = { HOME: "/Users/test", OPENCLAW_PROFILE: "rescue" };
    expect(resolveGatewayStateDir(env)).toBe(path.join("/Users/test", ".openclaw-rescue"));
  });

  it("treats default profiles as the base state dir", () => {
    const env = { HOME: "/Users/test", OPENCLAW_PROFILE: "Default" };
    expect(resolveGatewayStateDir(env)).toBe(path.join("/Users/test", ".openclaw"));
  });

  it("uses OPENCLAW_STATE_DIR when provided", () => {
    const env = { HOME: "/Users/test", OPENCLAW_STATE_DIR: "/var/lib/clawdbot" };
    expect(resolveGatewayStateDir(env)).toBe(path.resolve("/var/lib/clawdbot"));
  });

  it("expands ~ in OPENCLAW_STATE_DIR", () => {
    const env = { HOME: "/Users/test", OPENCLAW_STATE_DIR: "~/openclawot-state" };
    expect(resolveGatewayStateDir(env)).toBe(path.resolve("/Users/test/clawdbot-state"));
  });

  it("preserves Windows absolute paths without HOME", () => {
    const env = { OPENCLAW_STATE_DIR: "C:\\State\\clawdbot" };
    expect(resolveGatewayStateDir(env)).toBe("C:\\State\\clawdbot");
  });
});
