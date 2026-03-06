import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import type { Tab } from "./navigation";
import { applySettingsFromUrl, setTabFromRoute } from "./app-settings";

const SETTINGS_STORAGE_KEY = "clawdbot.control.settings.v1";

type SettingsHost = Parameters<typeof setTabFromRoute>[0] & {
  logsPollInterval: number | null;
  debugPollInterval: number | null;
};

const createHost = (tab: Tab): SettingsHost => ({
  settings: {
    gatewayUrl: "",
    token: "",
    sessionKey: "main",
    lastActiveSessionKey: "main",
    theme: "system",
    chatFocusMode: false,
    chatShowThinking: true,
    splitRatio: 0.6,
    navCollapsed: false,
    navGroupsCollapsed: {},
  },
  theme: "system",
  themeResolved: "dark",
  applySessionKey: "main",
  sessionKey: "main",
  tab,
  connected: false,
  chatHasAutoScrolled: false,
  logsAtBottom: false,
  eventLog: [],
  eventLogBuffer: [],
  basePath: "",
  themeMedia: null,
  themeMediaHandler: null,
  logsPollInterval: null,
  debugPollInterval: null,
});

describe("setTabFromRoute", () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("starts and stops log polling based on the tab", () => {
    const host = createHost("chat");

    setTabFromRoute(host, "logs");
    expect(host.logsPollInterval).not.toBeNull();
    expect(host.debugPollInterval).toBeNull();

    setTabFromRoute(host, "chat");
    expect(host.logsPollInterval).toBeNull();
  });

  it("starts and stops debug polling based on the tab", () => {
    const host = createHost("chat");

    setTabFromRoute(host, "debug");
    expect(host.debugPollInterval).not.toBeNull();
    expect(host.logsPollInterval).toBeNull();

    setTabFromRoute(host, "chat");
    expect(host.debugPollInterval).toBeNull();
  });
});

describe("applySettingsFromUrl", () => {
  beforeEach(() => {
    localStorage.clear();
    window.history.replaceState({}, "", "http://localhost/chat");
  });

  it("resets settings and does not reapply stale session from URL", () => {
    localStorage.setItem(
      SETTINGS_STORAGE_KEY,
      JSON.stringify({
        gatewayUrl: "ws://localhost",
        token: "stale-token",
        sessionKey: "legacy-session",
        lastActiveSessionKey: "legacy-session",
        theme: "dark",
        chatFocusMode: true,
        chatShowThinking: false,
        sendOnEnter: true,
        splitRatio: 0.55,
        navCollapsed: true,
        navGroupsCollapsed: { admin: true },
      }),
    );
    const host = createHost("chat");
    host.settings = {
      ...host.settings,
      token: "stale-token",
      sessionKey: "legacy-session",
      lastActiveSessionKey: "legacy-session",
      theme: "dark",
    };
    host.password = "secret";
    host.theme = "dark";
    host.sessionKey = "legacy-session";
    host.applySessionKey = "legacy-session";

    window.history.replaceState({}, "", "http://localhost/chat?reset=1&session=legacy-session");
    applySettingsFromUrl(host);

    expect(host.settings.sessionKey).toBe("main");
    expect(host.settings.lastActiveSessionKey).toBe("main");
    expect(host.sessionKey).toBe("main");
    expect(host.applySessionKey).toBe("main");
    expect(host.theme).toBe("system");
    expect(host.password).toBe("");
    expect(new URL(window.location.href).search).toBe("");
  });
});
