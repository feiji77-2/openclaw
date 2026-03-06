---
summary: "OpenClaw 的代理工具界面（浏览器、画布、节点、消息、定时任务）替代旧版 `openclaw-*` 技能"
read_when:
  - 添加或修改代理工具
  - 淘汰或更改 `openclaw-*` 技能
title: "工具"
---

# 工具 (OpenClaw)

OpenClaw 为浏览器、画布、节点和定时任务暴露**一流的代理工具**。
这些工具替代了旧的 `openclaw-*` 技能：工具具有类型检查，无需 shell 调用，
代理应该直接依赖它们。

## 禁用工具

您可以通过 `openclaw.json` 中的 `tools.allow` / `tools.deny` 全局允许/拒绝工具
（拒绝优先）。这可以防止不允许的工具被发送给模型提供商。

```json5
{
  tools: { deny: ["browser"] },
}
```

注意事项：

- 匹配不区分大小写。
- 支持 `*` 通配符（`"*"` 表示所有工具）。
- 如果 `tools.allow` 仅引用未知或未加载的插件工具名称，OpenClaw 会记录警告并忽略允许列表，以便核心工具保持可用。

## 工具配置文件（基础允许列表）

`tools.profile` 在 `tools.allow`/`tools.deny` 之前设置**基础工具允许列表**。
每代理覆盖：`agents.list[].tools.profile`。

配置文件：

- `minimal`：仅 `session_status`
- `coding`：`group:fs`、`group:runtime`、`group:sessions`、`group:memory`、`image`
- `messaging`：`group:messaging`、`sessions_list`、`sessions_history`、`sessions_send`、`session_status`
- `full`：无限制（与未设置相同）

示例（默认仅消息，也允许 Slack + Discord 工具）：

```json5
{
  tools: {
    profile: "messaging",
    allow: ["slack", "discord"],
  },
}
```

示例（编码配置文件，但在各处拒绝 exec/process）：

```json5
{
  tools: {
    profile: "coding",
    deny: ["group:runtime"],
  },
}
```

示例（全局编码配置文件，仅消息支持代理）：

```json5
{
  tools: { profile: "coding" },
  agents: {
    list: [
      {
        id: "support",
        tools: { profile: "messaging", allow: ["slack"] },
      },
    ],
  },
}
```

## 提供商特定的工具策略

使用 `tools.byProvider` 来**进一步限制**特定提供商的工具
（或单个 `provider/model`），而无需更改全局默认设置。
每代理覆盖：`agents.list[].tools.byProvider`。

这在基础工具配置文件**之后**和允许/拒绝列表**之前**应用，
因此它只能缩小工具集。
提供商键接受 `provider`（例如 `google-antigravity`）或
`provider/model`（例如 `openai/gpt-5.2`）。

示例（保持全局编码配置文件，但为 Google Antigravity 使用最小工具）：

```json5
{
  tools: {
    profile: "coding",
    byProvider: {
      "google-antigravity": { profile: "minimal" },
    },
  },
}
```

示例（针对不稳定端点的提供商/模型特定允许列表）：

```json5
{
  tools: {
    allow: ["group:fs", "group:runtime", "sessions_list"],
    byProvider: {
      "openai/gpt-5.2": { allow: ["group:fs", "sessions_list"] },
    },
  },
}
```

示例（针对单个提供商的代理特定覆盖）：

```json5
{
  agents: {
    list: [
      {
        id: "support",
        tools: {
          byProvider: {
            "google-antigravity": { allow: ["message", "sessions_list"] },
          },
        },
      },
    ],
  },
}
```

## 工具组（快捷方式）

工具策略（全局、代理、沙盒）支持展开为多个工具的 `group:*` 条目。
在 `tools.allow` / `tools.deny` 中使用这些。

可用组：

- `group:runtime`：`exec`、`bash`、`process`
- `group:fs`：`read`、`write`、`edit`、`apply_patch`
- `group:sessions`：`sessions_list`、`sessions_history`、`sessions_send`、`sessions_spawn`、`session_status`
- `group:memory`：`memory_search`、`memory_get`
- `group:web`：`web_search`、`web_fetch`
- `group:ui`：`browser`、`canvas`
- `group:automation`：`cron`、`gateway`
- `group:messaging`：`message`
- `group:nodes`：`nodes`
- `group:openclaw`：所有内置 OpenClaw 工具（不包括提供商插件）

示例（仅允许文件工具 + 浏览器）：

```json5
{
  tools: {
    allow: ["group:fs", "browser"],
  },
}
```

## 插件 + 工具

插件可以注册核心工具集之外的**附加工具**（和 CLI 命令）。
请参见 [插件](/tools/plugin) 了解安装 + 配置，以及 [技能](/tools/skills) 了解
如何将工具使用指导注入提示中。一些插件随工具一起提供自己的技能
（例如，语音通话插件）。

可选插件工具：

- [Lobster](/tools/lobster)：具有可恢复审批的类型化工作流运行时（需要网关主机上的 Lobster CLI）。
- [LLM 任务](/tools/llm-task)：仅 JSON 的 LLM 步骤，用于结构化工作流输出（可选模式验证）。

## 工具清单

### `apply_patch`

在一個或多個文件中應用結構化補丁。用於多塊編輯。
實驗性：通過 `tools.exec.applyPatch.enabled` 啟用（僅限 OpenAI 模型）。
`tools.exec.applyPatch.workspaceOnly` 默認為 `true`（工作區內）。僅當您有意讓 `apply_patch` 在工作區目錄外寫入/刪除時才設為 `false`。

### `exec`

在工作區中運行 shell 命令。

核心參數：

- `command`（必需）
- `yieldMs`（超時後自動後台運行，默認 10000）
- `background`（立即後台運行）
- `timeout`（秒；超過時殺死進程，默認 1800）
- `elevated`（布爾值；如果啟用/允許提升模式則在主機上運行；僅當代理被沙盒化時才改變行為）
- `host`（`sandbox | gateway | node`）
- `security`（`deny | allowlist | full`）
- `ask`（`off | on-miss | always`）
- `node`（`host=node` 的節點 ID/名稱）
- 需要真實 TTY？設置 `pty: true`。

注意事項：

- 後台運行時返回 `status: "running"` 和 `sessionId`。
- 使用 `process` 來輪詢/記錄/寫入/殺死/清除後台會話。
- 如果 `process` 被禁止，`exec` 同步運行並忽略 `yieldMs`/`background`。
- `elevated` 受 `tools.elevated` 和任何 `agents.list[].tools.elevated` 覆蓋保護（兩者都必須允許），並且是 `host=gateway` + `security=full` 的別名。
- `elevated` 僅當代理被沙盒化時才改變行為（否則無操作）。
- `host=node` 可以針對 macOS 伴侶應用或無頭節點主機（`openclaw-cn node run`）。
- 網關/節點審批和允許列表：[執行審批](/tools/exec-approvals)。

### `process`

管理後台執行會話。

核心操作：

- `list`、`poll`、`log`、`write`、`kill`、`clear`、`remove`

注意事項：

- `poll` 完成時返回新輸出和退出狀態。
- `log` 支持基於行的 `offset`/`limit`（省略 `offset` 以獲取最後 N 行）。
- `process` 按代理範圍劃分；其他代理的會話不可見。

### `web_search`

使用 Brave Search API 搜索網絡。

核心參數：

- `query`（必需）
- `count`（1–10；默認來自 `tools.web.search.maxResults`）

注意事項：

- 需要 Brave API 密鑰（推薦：`openclaw-cn configure --section web`，或設置 `BRAVE_API_KEY`）。
- 通過 `tools.web.search.enabled` 啟用。
- 響應被緩存（默認 15 分鐘）。
- 請參見 [網絡工具](/tools/web) 進行設置。

### `web_fetch`

從 URL 獲取並提取可讀內容（HTML → markdown/text）。

核心參數：

- `url`（必需）
- `extractMode`（`markdown` | `text`）
- `maxChars`（截斷長頁面）

注意事項：

- 通過 `tools.web.fetch.enabled` 啟用。
- `maxChars` 受 `tools.web.fetch.maxCharsCap` 限制（默認 50000）。
- 響應被緩存（默認 15 分鐘）。
- 對於 JS 密集型網站，優先使用瀏覽器工具。
- 請參見 [網絡工具](/tools/web) 進行設置。
- 請參見 [Firecrawl](/tools/firecrawl) 了解可選的反機器人備用方案。

### `browser`

控制專門的 OpenClaw 管理瀏覽器。

核心操作：

- `status`、`start`、`stop`、`tabs`、`open`、`focus`、`close`
- `snapshot`（aria/ai）
- `screenshot`（返回圖像塊 + `MEDIA:<path>`）
- `act`（UI 操作：click/type/press/hover/drag/select/fill/resize/wait/evaluate）
- `navigate`、`console`、`pdf`、`upload`、`dialog`

配置文件管理：

- `profiles` — 列出所有帶狀態的瀏覽器配置文件
- `create-profile` — 創建帶自動分配端口的新配置文件（或 `cdpUrl`）
- `delete-profile` — 停止瀏覽器，刪除用戶數據，從配置中移除（僅本地）
- `reset-profile` — 殺死配置文件端口上的孤兒進程（僅本地）

常用參數：

- `profile`（可選；默認為 `browser.defaultProfile`）
- `target`（`sandbox` | `host` | `node`）
- `node`（可選；選擇特定節點 ID/名稱）
  注意事項：
- 需要 `browser.enabled=true`（默認為 `true`；設為 `false` 以禁用）。
- 所有操作都接受可選的 `profile` 參數以支持多實例。
- 當省略 `profile` 時，使用 `browser.defaultProfile`（默認為 "chrome"）。
- 配置文件名稱：僅限小寫字母數字 + 連字符（最多 64 個字符）。
- 端口範圍：18800-18899（最多約 100 個配置文件）。
- 遠程配置文件僅支持附加（無啟動/停止/重置）。
- 如果連接了支持瀏覽器的節點，工具可能會自動路由到它（除非您固定 `target`）。
- 安裝 Playwright 時，`snapshot` 默認為 `ai`；對無障礙樹使用 `aria`。
- `snapshot` 還支持角色快照選項（`interactive`、`compact`、`depth`、`selector`），返回類似 `e12` 的引用。
- `act` 需要來自 `snapshot` 的 `ref`（AI 快照中的數字 `12`，或角色快照中的 `e12`）；對於罕見的 CSS 選擇器需求使用 `evaluate`。
- 默認情況下避免 `act` → `wait`；僅在特殊情況下使用（沒有可靠的 UI 狀態可等待）。
- `upload` 可以選擇性地傳遞 `ref` 以便在準備後自動點擊。
- `upload` 還支持 `inputRef`（aria 引用）或 `element`（CSS 選擇器）直接設置 `<input type="file">`。

### `canvas`

驅動節點畫布（呈現、評估、快照、A2UI）。

核心操作：

- `present`、`hide`、`navigate`、`eval`
- `snapshot`（返回圖像塊 + `MEDIA:<path>`）
- `a2ui_push`、`a2ui_reset`

注意事項：

- 底層使用網關 `node.invoke`。
- 如果未提供 `node`，工具會選擇默認值（單個連接節點或本地 mac 節點）。
- A2UI 僅限 v0.8（無 `createSurface`）；CLI 拒絕帶行錯誤的 v0.9 JSONL。
- 快速測試：`openclaw-cn nodes canvas a2ui push --node <id> --text "來自 A2UI 的問候"`。

### `nodes`

發現和定位配對節點；發送通知；捕獲相機/屏幕。

核心操作：

- `status`、`describe`
- `pending`、`approve`、`reject`（配對）
- `notify`（macOS `system.notify`）
- `run`（macOS `system.run`）
- `camera_snap`、`camera_clip`、`screen_record`
- `location_get`

注意事項：

- 相機/屏幕命令要求節點應用處於前臺。
- 圖像返回圖像塊 + `MEDIA:<path>`。
- 視頻返回 `FILE:<path>`（mp4）。
- 位置返回 JSON 載荷（緯度/經度/精度/時間戳）。
- `run` 參數：`command` argv 數組；可選 `cwd`、`env`（`KEY=VAL`）、`commandTimeoutMs`、`invokeTimeoutMs`、`needsScreenRecording`。

示例（`run`）：

```json
{
  "action": "run",
  "node": "office-mac",
  "command": ["echo", "你好"],
  "env": ["FOO=bar"],
  "commandTimeoutMs": 12000,
  "invokeTimeoutMs": 45000,
  "needsScreenRecording": false
}
```

### `image`

使用配置的圖像模型分析圖像。

核心參數：

- `image`（必需路徑或 URL）
- `prompt`（可選；默認為 "描述圖像。"）
- `model`（可選覆蓋）
- `maxBytesMb`（可選大小上限）

注意事項：

- 僅當配置了 `agents.defaults.imageModel`（主要或備用）時可用，或者當可以從您的默認模型 + 配置的認證推斷出隱式圖像模型時可用（盡力配對）。
- 直接使用圖像模型（獨立於主要聊天模型）。

### `message`

跨 Discord/Google Chat/Slack/Telegram/WhatsApp/Signal/iMessage/MS Teams 發送消息和頻道操作。

核心操作：

- `send`（文本 + 可選媒體；MS Teams 還支持 `card` 用於自適應卡）
- `poll`（WhatsApp/Discord/MS Teams 投票）
- `react` / `reactions` / `read` / `edit` / `delete`
- `pin` / `unpin` / `list-pins`
- `permissions`
- `thread-create` / `thread-list` / `thread-reply`
- `search`
- `sticker`
- `member-info` / `role-info`
- `emoji-list` / `emoji-upload` / `sticker-upload`
- `role-add` / `role-remove`
- `channel-info` / `channel-list`
- `voice-status`
- `event-list` / `event-create`
- `timeout` / `kick` / `ban`

注意事項：

- `send` 通過網關路由 WhatsApp；其他頻道直連。
- `poll` 對 WhatsApp 和 MS Teams 使用網關；Discord 投票直連。
- 當消息工具調用綁定到活動聊天會話時，發送被限制到該會話的目標以避免跨上下文洩漏。

### `cron`

管理網關定時任務和喚醒。

核心操作：

- `status`、`list`
- `add`、`update`、`remove`、`run`、`runs`
- `wake`（排隊系統事件 + 可選立即心跳）

注意事項：

- `add` 期望完整的定時任務對象（與 `cron.add` RPC 相同模式）。
- `update` 使用 `{ jobId, patch }`（為了兼容性接受 `id`）。

### `gateway`

重新啟動或應用更新到正在運行的網關進程（原地）。

核心操作：

- `restart`（授權 + 發送 `SIGUSR1` 進行進程內重啟；`openclaw-cn gateway` 原地重啟）
- `config.get` / `config.schema`
- `config.apply`（驗證 + 寫入配置 + 重啟 + 喚醒）
- `config.patch`（合併部分更新 + 重啟 + 喚醒）
- `update.run`（運行更新 + 重啟 + 喚醒）

注意事項：

- 使用 `delayMs`（默認為 2000）以避免中斷正在進行的回復。
- `restart` 默認禁用；通過 `commands.restart: true` 啟用。

### `sessions_list` / `sessions_history` / `sessions_send` / `sessions_spawn` / `session_status`

列出會話、檢查轉錄歷史記錄或發送到另一個會話。

核心參數：

- `sessions_list`：`kinds?`、`limit?`、`activeMinutes?`、`messageLimit?`（0 = 無）
- `sessions_history`：`sessionKey`（或 `sessionId`）、`limit?`、`includeTools?`
- `sessions_send`：`sessionKey`（或 `sessionId`）、`message`、`timeoutSeconds?`（0 = 發射後不管）
- `sessions_spawn`：`task`、`label?`、`agentId?`、`model?`、`runTimeoutSeconds?`、`cleanup?`
- `session_status`：`sessionKey?`（默認當前；接受 `sessionId`）、`model?`（`default` 清除覆蓋）

注意事項：

- `main` 是規範的直接聊天鍵；全局/未知的被隱藏。
- `messageLimit > 0` 獲取每個會話的最後 N 條消息（過濾工具消息）。
- `sessions_send` 當 `timeoutSeconds > 0` 時等待最終完成。
- 交付/公告在完成後發生且盡力而為；`status: "ok"` 確認代理運行完成，而不是公告已交付。
- `sessions_spawn` 啟動子代理運行並向請求者聊天發布公告回復。
- `sessions_spawn` 是非阻塞的，立即返回 `status: "accepted"`。
- `sessions_send` 運行回復乒乓（回復 `REPLY_SKIP` 停止；通過 `session.agentToAgent.maxPingPongTurns` 最大回合數，0–5）。
- 乒乓之後，目標代理運行**公告步驟**；回復 `ANNOUNCE_SKIP` 以抑制公告。

### `agents_list`

列出當前會話可能通過 `sessions_spawn` 定向的代理 ID。

注意事項：

- 結果受限於每代理允許列表（`agents.list[].subagents.allowAgents`）。
- 當配置了 `["*"]` 時，工具包含所有配置的代理並標記 `allowAny: true`。

## 參數（通用）

網關支持的工具（`canvas`、`nodes`、`cron`）：

- `gatewayUrl`（默認 `ws://127.0.0.1:18789`）
- `gatewayToken`（如果啟用了認證）
- `timeoutMs`

注意：當設置 `gatewayUrl` 時，顯式包含 `gatewayToken`。工具不會繼承配置
或環境憑據進行覆蓋，缺少顯式憑據是錯誤。

瀏覽器工具：

- `profile`（可選；默認為 `browser.defaultProfile`）
- `target`（`sandbox` | `host` | `node`）
- `node`（可選；固定特定節點 ID/名稱）

## 推薦的代理流程

瀏覽器自動化：

1. `browser` → `status` / `start`
2. `snapshot`（ai 或 aria）
3. `act`（click/type/press）
4. 如需視覺確認則 `screenshot`

畫布渲染：

1. `canvas` → `present`
2. `a2ui_push`（可選）
3. `snapshot`

節點定向：

1. `nodes` → `status`
2. 對所選節點 `describe`
3. `notify` / `run` / `camera_snap` / `screen_record`

## 安全

- 避免直接 `system.run`；僅在明確用戶同意下使用 `nodes` → `run`。
- 尊重用戶對相機/屏幕捕獲的同意。
- 在調用媒體命令前使用 `status/describe` 確保權限。

## 工具如何呈現給代理

工具通過兩個並行通道暴露：

1. **系統提示文本**：人類可讀的列表 + 指導。
2. **工具模式**：發送到模型 API 的結構化函數定義。

這意味著代理既能看到「存在哪些工具」也能看到「如何調用它們」。如果工具
不出現在系統提示或模式中，模型無法調用它。
