import { render } from "lit";
import { describe, expect, it, vi } from "vitest";

import type { SessionsListResult } from "../types";
import { renderChat, type ChatProps } from "./chat";

function createSessions(): SessionsListResult {
  return {
    ts: 0,
    path: "",
    count: 0,
    defaults: { model: null, contextTokens: null },
    sessions: [],
  };
}

function createProps(overrides: Partial<ChatProps> = {}): ChatProps {
  return {
    sessionKey: "main",
    onSessionKeyChange: () => undefined,
    thinkingLevel: null,
    showThinking: false,
    loading: false,
    sending: false,
    canAbort: false,
    compactionStatus: null,
    messages: [],
    toolMessages: [],
    stream: null,
    streamStartedAt: null,
    assistantAvatarUrl: null,
    draft: "",
    queue: [],
    connected: true,
    canSend: true,
    disabledReason: null,
    error: null,
    sessions: createSessions(),
    focusMode: false,
    assistantName: "Clawdbot",
    assistantAvatar: null,
    onRefresh: () => undefined,
    onToggleFocusMode: () => undefined,
    onDraftChange: () => undefined,
    onSend: () => undefined,
    onQueueRemove: () => undefined,
    onNewSession: () => undefined,
    ...overrides,
  };
}

describe("chat view", () => {
  it("shows a stop button when aborting is available", () => {
    const container = document.createElement("div");
    const onAbort = vi.fn();
    render(
      renderChat(
        createProps({
          canAbort: true,
          onAbort,
        }),
      ),
      container,
    );

    const actionButton = container.querySelector(
      ".chat-compose__actions .btn",
    ) as HTMLButtonElement | null;
    expect(actionButton).not.toBeNull();
    actionButton?.dispatchEvent(new MouseEvent("click", { bubbles: true }));
    expect(onAbort).toHaveBeenCalledTimes(1);
  });

  it("shows a new session button when aborting is unavailable", () => {
    const container = document.createElement("div");
    const onNewSession = vi.fn();
    render(
      renderChat(
        createProps({
          canAbort: false,
          onNewSession,
        }),
      ),
      container,
    );

    const actionButton = container.querySelector(
      ".chat-compose__actions .btn",
    ) as HTMLButtonElement | null;
    expect(actionButton).not.toBeNull();
    actionButton?.dispatchEvent(new MouseEvent("click", { bubbles: true }));
    expect(onNewSession).toHaveBeenCalledTimes(1);
  });

  it("renders new messages button when showNewMessages is true", () => {
    const container = document.createElement("div");
    render(
      renderChat(
        createProps({
          showNewMessages: true,
          onScrollToBottom: () => undefined,
        }),
      ),
      container,
    );

    const newMessagesButton = container.querySelector(".chat-new-messages");
    expect(newMessagesButton).not.toBeNull();
  });

  it("calls onScrollToBottom when new messages button is clicked", () => {
    const container = document.createElement("div");
    const onScrollToBottom = vi.fn();
    render(
      renderChat(
        createProps({
          showNewMessages: true,
          onScrollToBottom,
        }),
      ),
      container,
    );

    const newMessagesButton = container.querySelector(".chat-new-messages");
    expect(newMessagesButton).not.toBeNull();
    newMessagesButton?.dispatchEvent(new MouseEvent("click", { bubbles: true }));
    expect(onScrollToBottom).toHaveBeenCalledTimes(1);
  });

  it("does not render new messages button when showNewMessages is false or undefined", () => {
    const hiddenContainer = document.createElement("div");
    render(
      renderChat(
        createProps({
          showNewMessages: false,
          onScrollToBottom: () => undefined,
        }),
      ),
      hiddenContainer,
    );
    expect(hiddenContainer.querySelector(".chat-new-messages")).toBeNull();

    const defaultContainer = document.createElement("div");
    render(renderChat(createProps()), defaultContainer);
    expect(defaultContainer.querySelector(".chat-new-messages")).toBeNull();
  });
});
