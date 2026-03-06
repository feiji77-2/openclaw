---
summary: "用于唤醒和独立代理运行的 Webhook 入口"
read_when:
  - 添加或更改 webhook 端点
  - 将外部系统连接到 OpenClaw
title: "Webhooks"
---

# Webhooks

网关可以暴露一个小的 HTTP webhook 端点用于外部触发器。

## 启用

```json5
{
  hooks: {
    enabled: true,
    token: "shared-secret",
    path: "/hooks",
    // 可选：将显式的 `agentId` 路由限制在此允许列表中。
    // 省略或包含 "*" 以允许任何代理。
    // 设置 [] 以拒绝所有显式的 `agentId` 路由。
    allowedAgentIds: ["hooks", "main"],
  },
}
```

注意事项：

- 当 `hooks.enabled=true` 时，`hooks.token` 是必需的。
- `hooks.path` 默认为 `/hooks`。

## 认证

每个请求都必须包含钩子令牌。推荐使用头部：

- `Authorization: Bearer <token>`（推荐）
- `x-openclaw-token: <token>`
- 查询字符串令牌被拒绝（`?token=...` 返回 `400`）。

## 端点

### `POST /hooks/wake`

有效载荷：

```json
{ "text": "系统行", "mode": "now" }
```

- `text` **必需**（字符串）：事件的描述（例如，"收到新邮件"）。
- `mode` 可选（`now` | `next-heartbeat`）：是否触发立即心跳（默认 `now`）或等待下一次周期性检查。

效果：

- 为**主**会话排队系统事件
- 如果 `mode=now`，触发立即心跳

### `POST /hooks/agent`

有效载荷：

```json
{
  "message": "运行这个",
  "name": "邮件",
  "agentId": "hooks",
  "sessionKey": "hook:email:msg-123",
  "wakeMode": "now",
  "deliver": true,
  "channel": "last",
  "to": "+15551234567",
  "model": "openai/gpt-5.2-mini",
  "thinking": "low",
  "timeoutSeconds": 120
}
```

- `message` **必需**（字符串）：代理要处理的提示或消息。
- `name` 可选（字符串）：钩子的人类可读名称（例如，"GitHub"），用作会话摘要中的前缀。
- `agentId` 可选（字符串）：将此钩子路由到特定代理。未知 ID 回退到默认代理。设置时，钩子使用解析代理的工作区和配置运行。
- `sessionKey` 可选（字符串）：用于识别代理会话的键。默认情况下，除非 `hooks.allowRequestSessionKey=true`，否则此字段被拒绝。
- `wakeMode` 可选（`now` | `next-heartbeat`）：是否触发立即心跳（默认 `now`）或等待下一次周期性检查。
- `deliver` 可选（布尔值）：如果为 `true`，代理的响应将发送到消息通道。默认为 `true`。仅心跳确认的响应会自动跳过。
- `channel` 可选（字符串）：交付的消息通道。其中之一：`last`、`whatsapp`、`telegram`、`discord`、`slack`、`mattermost`（插件）、`signal`、`imessage`、`msteams`。默认为 `last`。
- `to` 可选（字符串）：通道的接收者标识符（例如，WhatsApp/Signal 的电话号码，Telegram 的聊天 ID，Discord/Slack/Mattermost（插件）的频道 ID，MS Teams 的对话 ID）。默认为住会话中的最后一个接收者。
- `model` 可选（字符串）：模型覆盖（例如，`anthropic/claude-3-5-sonnet` 或别名）。如果受限制，必须在允许的模型列表中。
- `thinking` 可选（字符串）：思维级别覆盖（例如，`low`、`medium`、`high`）。
- `timeoutSeconds` 可选（数字）：代理运行的最大持续时间（秒）。

效果：

- 运行**独立**代理回合（自己的会话键）
- 始终在**主**会话中发布摘要
- 如果 `wakeMode=now`，触发立即心跳

## 会话键策略（破坏性更改）

`/hooks/agent` 有效载荷 `sessionKey` 覆盖默认被禁用。

- 推荐：设置固定的 `hooks.defaultSessionKey` 并保持请求覆盖关闭。
- 可选：仅在需要时允许请求覆盖，并限制前缀。

推荐配置：

```json5
{
  hooks: {
    enabled: true,
    token: "${OPENCLAW_HOOKS_TOKEN}",
    defaultSessionKey: "hook:ingress",
    allowRequestSessionKey: false,
    allowedSessionKeyPrefixes: ["hook:"],
  },
}
```

兼容性配置（旧版行为）：

```json5
{
  hooks: {
    enabled: true,
    token: "${OPENCLAW_HOOKS_TOKEN}",
    allowRequestSessionKey: true,
    allowedSessionKeyPrefixes: ["hook:"], // 强烈推荐
  },
}
```

### `POST /hooks/<name>`（映射）

自定义钩子名称通过 `hooks.mappings` 解析（参见配置）。映射可以
将任意有效载荷转换为 `wake` 或 `agent` 操作，带有可选模板或
代码转换。

映射选项（摘要）：

- `hooks.presets: ["gmail"]` 启用内置的 Gmail 映射。
- `hooks.mappings` 让您在配置中定义 `match`、`action` 和模板。
- `hooks.transformsDir` + `transform.module` 加载用于自定义逻辑的 JS/TS 模块。
  - `hooks.transformsDir`（如果设置）必须保持在您的 OpenClaw 配置目录下的转换根目录内（通常为 `~/.openclaw/hooks/transforms`）。
  - `transform.module` 必须在有效的转换目录内解析（遍历/逃逸路径被拒绝）。
- 使用 `match.source` 保持通用的摄取端点（有效载荷驱动的路由）。
- TS 转换需要 TS 加载器（例如 `bun` 或 `tsx`）或运行时预编译的 `.js`。
- 在映射上设置 `deliver: true` + `channel`/`to` 以将回复路由到聊天界面
  （`channel` 默认为 `last` 并回退到 WhatsApp）。
- `agentId` 将钩子路由到特定代理；未知 ID 回退到默认代理。
- `hooks.allowedAgentIds` 限制显式的 `agentId` 路由。省略它（或包含 `*`）以允许任何代理。设置 `[]` 以拒绝显式的 `agentId` 路由。
- `hooks.defaultSessionKey` 为钩子代理运行设置默认会话，当未提供显式键时。
- `hooks.allowRequestSessionKey` 控制 `/hooks/agent` 有效载荷是否可以设置 `sessionKey`（默认：`false`）。
- `hooks.allowedSessionKeyPrefixes` 可选地限制来自请求有效载荷和映射的显式 `sessionKey` 值。
- `allowUnsafeExternalContent: true` 为该钩子禁用外部内容安全包装器
  （危险；仅用于受信任的内部来源）。
- `openclaw-cn webhooks gmail setup` 为 `openclaw-cn webhooks gmail run` 编写 `hooks.gmail` 配置。
  请参见 [Gmail Pub/Sub](/automation/gmail-pubsub) 了解完整的 Gmail 监视流程。

## 响应

- `/hooks/wake` 返回 `200`
- `/hooks/agent` 返回 `202`（异步运行已启动）
- 认证失败返回 `401`
- 同一客户端重复认证失败后返回 `429`（检查 `Retry-After`）
- 无效有效载荷返回 `400`
- 超大有效载荷返回 `413`

## 示例

```bash
curl -X POST http://127.0.0.1:18789/hooks/wake \
  -H 'Authorization: Bearer SECRET' \
  -H 'Content-Type: application/json' \
  -d '{"text":"收到新邮件","mode":"now"}'
```

```bash
curl -X POST http://127.0.0.1:18789/hooks/agent \
  -H 'x-openclaw-token: SECRET' \
  -H 'Content-Type: application/json' \
  -d '{"message":"总结收件箱","name":"邮件","wakeMode":"next-heartbeat"}'
```

### 使用不同的模型

在代理有效载荷（或映射）中添加 `model` 以覆盖该次运行的模型：

```bash
curl -X POST http://127.0.0.1:18789/hooks/agent \
  -H 'x-openclaw-token: SECRET' \
  -H 'Content-Type: application/json' \
  -d '{"message":"总结收件箱","name":"邮件","model":"openai/gpt-5.2-mini"}'
```

如果您强制执行 `agents.defaults.models`，请确保覆盖模型包含在其中。

```bash
curl -X POST http://127.0.0.1:18789/hooks/gmail \
  -H 'Authorization: Bearer SECRET' \
  -H 'Content-Type: application/json' \
  -d '{"source":"gmail","messages":[{"from":"Ada","subject":"你好","snippet":"嗨"}]}'
```

## 安全

- 将钩子端点保持在回环、尾网或受信任的反向代理后面。
- 使用专用的钩子令牌；不要重用网关认证令牌。
- 重复的认证失败按客户端地址进行速率限制，以减缓暴力破解尝试。
- 如果您使用多代理路由，请设置 `hooks.allowedAgentIds` 以限制显式的 `agentId` 选择。
- 保持 `hooks.allowRequestSessionKey=false`，除非您需要调用者选择的会话。
- 如果您启用请求 `sessionKey`，请限制 `hooks.allowedSessionKeyPrefixes`（例如，`["hook:"]`）。
- 避免在 webhook 日志中包含敏感的原始有效载荷。
- 钩子有效载荷默认被视为不受信任，并用安全边界包装。
  如果您必须为特定钩子禁用此功能，请在该钩子的映射中设置 `allowUnsafeExternalContent: true`
  （危险）。
