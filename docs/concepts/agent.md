---
summary: "代理运行时（嵌入式 p-mono）、工作区契约和会话引导"
read_when:
  - 更改代理运行时、工作区引导或会话行为
---
# 代理运行时 🤖

OpenClaw 运行一个源自 **p-mono** 的单一嵌入式代理运行时。

## 工作区（必需）

OpenClaw 使用单个代理工作区目录（`agents.defaults.workspace`）作为代理的 **唯一** 工作目录（`cwd`）用于工具和上下文。

推荐：使用 `openclaw-cn setup` 创建 `~/.openclaw-cn/openclaw-cn.json`（如果缺失）并初始化工作区文件。

完整工作区布局 + 备份指南：[代理工作区](/concepts/agent-workspace)

如果启用了 `agents.defaults.sandbox`，非主会话可以通过
`agents.defaults.sandbox.workspaceRoot` 下的每个会话工作区覆盖此设置（参见
[网关配置](/gateway/configuration)）。

## 引导文件（注入）

在 `agents.defaults.workspace` 内部，OpenClaw 期望这些用户可编辑的文件：
- `AGENTS.md` — 操作说明 + "记忆"
- `SOUL.md` — 人格、边界、语调
- `TOOLS.md` — 用户维护的工具笔记（例如 `imsg`、`sag`、约定）
- `BOOTSTRAP.md` — 一次性首次运行仪式（完成后删除）
- `IDENTITY.md` — 代理名称/氛围/表情符号
- `USER.md` — 用户资料 + 首选地址

在新会话的第一回合，OpenClaw 将这些文件的内容直接注入到代理上下文中。

空白文件会被跳过。大文件会被修剪和截断并带有标记，以便提示保持精简（阅读文件获取完整内容）。

如果文件缺失，OpenClaw 会注入一行 "missing file" 标记（并且 `openclaw-cn setup` 会创建一个安全的默认模板）。

`BOOTSTRAP.md` 仅为 **全新工作区** 创建（不存在其他引导文件）。如果您在完成仪式后删除它，不应在后续重启时重新创建。

要完全禁用引导文件创建（对于预植入的工作区），请设置：

```json5
{ agent: { skipBootstrap: true } }
```

## 内置工具

核心工具（读取/执行/编辑/写入及相关系统工具）始终可用，
受工具策略约束。`apply_patch` 是可选的，由
`tools.exec.applyPatch` 控制。`TOOLS.md` **不** 控制哪些工具存在；它是
关于 *您* 希望如何使用它们的指导。

## 技能

OpenClaw 从三个位置加载技能（工作区在名称冲突时获胜）：
- 捆绑（随安装包提供）
- 管理/本地：`~/.openclaw/skills`
- 工作区：`<workspace>/skills`

技能可以通过配置/环境控制（参见 [网关配置](/gateway/configuration) 中的 `skills`）。

## p-mono 集成

OpenClaw 重用 p-mono 代码库的部分内容（模型/工具），但 **会话管理、发现和工具连接归 OpenClaw 所有**。

- 没有 p-coding 代理运行时。
- 不参考 `~/.pi/agent` 或 `<workspace>/.pi` 设置。

## 会话

会话转录存储为 JSONL 格式：
- `~/.openclaw/agents/<agentId>/sessions/<SessionId>.jsonl`

会话 ID 是稳定的，由 OpenClaw 选择。
不读取旧版 Pi/Tau 会话文件夹。

## 流式传输时的引导

当队列模式为 `steer` 时，入站消息被注入到当前运行中。
队列在 **每次工具调用后** 检查；如果存在排队消息，
则跳过来自当前助手消息的剩余工具调用（工具错误结果为 "由于排队用户消息而跳过"），然后在下一次助手响应前注入排队的用户消息。

当队列模式为 `followup` 或 `collect` 时，入站消息被保留直到
当前回合结束，然后新的代理回合以排队的有效载荷开始。参见
[队列](/concepts/queue) 了解模式 + 防抖/上限行为。

块流式传输在助手块完成后立即发送；默认 **关闭**（`agents.defaults.blockStreamingDefault: "off"`）。
通过 `agents.defaults.blockStreamingBreak` 调整边界（`text_end` vs `message_end`；默认为 text_end）。
使用 `agents.defaults.blockStreamingChunk` 控制软块分块（默认
800-1200 个字符；优先段落分隔，然后是换行；句子最后）。
使用 `agents.defaults.blockStreamingCoalesce` 合并流式块以减少
单行垃圾信息（发送前基于空闲的合并）。非 Telegram 频道需要
显式 `*.blockStreaming: true` 来启用块回复。
详细的工具摘要在工具启动时发出（无防抖）；控制 UI
在可用时通过代理事件流式传输工具输出。
更多详情：[流式传输 + 分块](/concepts/streaming)。

## 模型引用

配置中的模型引用（例如 `agents.defaults.model` 和 `agents.defaults.models`）通过在 **第一个** `/` 处分割来解析。

- 配置模型时使用 `provider/model`。
- 如果模型 ID 本身包含 `/`（OpenRouter 风格），包含提供商前缀（例如：`openrouter/moonshotai/kimi-k2`）。
- 如果省略提供商，OpenClaw 将输入视为别名或 **默认提供商** 的模型（仅在模型 ID 中没有 `/` 时有效）。

## 配置（最小）

至少设置：
- `agents.defaults.workspace`
- `channels.whatsapp.allowFrom`（强烈推荐）

---

*下一步：[群聊](/concepts/group-messages)* 🦞
