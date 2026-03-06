---
summary: "网关调度器的定时任务 + 唤醒功能"
read_when:
  - 调度后台任务或唤醒
  - 配置应与心跳一起运行的自动化
  - 在心跳和定时任务之间选择用于计划任务
title: "定时任务"
---

# 定时任务（网关调度器）

> **定时任务 vs 心跳？** 请参阅 [定时任务 vs 心跳](/automation/cron-vs-heartbeat) 了解何时使用每种方式。

定时任务是网关内置的调度器。它持久化任务，在正确的时间唤醒代理，并可选择将输出发送回聊天。

如果您想要实现 _"每天早上运行这个"_ 或 _"20分钟后提醒代理"_，
定时任务就是这种机制。

## 简要说明

- 定时任务在 **网关内部** 运行（不在模型内部）。
- 任务持久化存储在 `~/.openclaw/cron/` 下，因此重启不会丢失计划。
- 两种执行方式：
  - **主会话**：排队系统事件，然后在下次心跳时运行。
  - **独立**：在 `cron:<jobId>` 中运行专用代理回合，支持发送（默认公告，完整输出或无；仍支持传统主摘要）。
- 唤醒是一等公民：任务可以请求 "立即唤醒" 或 "下次心跳"。

## 快速开始（可操作）

创建一次性提醒，验证其存在并立即运行：

```bash
openclaw-cn cron add \
  --name "提醒" \
  --at "2026-02-01T16:00:00Z" \
  --session main \
  --system-event "提醒：检查定时任务文档草稿" \
  --wake now \
  --delete-after-run

openclaw-cn cron list
openclaw-cn cron run <job-id> --force
openclaw-cn cron runs --id <job-id>
```

安排一个定期独立任务并发送输出：

```bash
openclaw-cn cron add \
  --name "晨间简报" \
  --cron "0 7 * * *" \
  --tz "America/Los_Angeles" \
  --session isolated \
  --message "总结夜间更新。" \
  --announce \
  --channel slack \
  --to "channel:C1234567890"
```

## 工具调用等效（网关定时任务工具）

有关标准 JSON 格式和示例，请参见 [工具调用的 JSON 模式](/automation/cron-jobs#json-schema-for-tool-calls)。

## 定时任务存储位置

定时任务默认持久化存储在网关主机的 `~/.openclaw/cron/jobs.json` 文件中。
网关将文件加载到内存中并在更改时写回，因此只有在网关停止时手动编辑才是安全的。
建议使用 `openclaw-cn cron add/edit` 或定时任务工具调用 API 进行更改。

## 新手友好概述

将定时任务视为：**何时**运行 + **做什么**。

1. **选择计划**
   - 一次性提醒 → `schedule.kind = "at"` (CLI: `--at`)
   - 重复任务 → `schedule.kind = "every"` 或 `schedule.kind = "cron"`
   - 如果您的 ISO 时间戳省略了时区，则被视为 **UTC**。

2. **选择运行位置**
   - `sessionTarget: "main"` → 在下次心跳时使用主上下文运行。
   - `sessionTarget: "isolated"` → 在 `cron:<jobId>` 中运行专用代理回合。

3. **选择有效载荷**
   - 主会话 → `payload.kind = "systemEvent"`
   - 独立会话 → `payload.kind = "agentTurn"`

可选：一次性任务（`schedule.kind = "at"`）默认成功后删除。
设置 `deleteAfterRun: false` 来保留它们（成功后将被禁用）。

## 概念

### 任务

定时任务是一个存储记录，包含：

- 一个 **计划**（何时运行），
- 一个 **有效载荷**（做什么），
- 可选的 **发送模式**（公告、完整输出或无）。
- 可选的 **代理绑定**（`agentId`）：在特定代理下运行任务；如果
  缺失或未知，网关将回退到默认代理。

任务通过稳定的 `jobId` 标识（CLI/网关 API 使用）。
在代理工具调用中，`jobId` 是标准的；为了兼容性接受传统的 `id`。
一次性任务默认成功后自动删除；设置 `deleteAfterRun: false` 来保留它们。

### 计划

定时任务支持三种计划类型：

- `at`：一次性时间戳。优先使用 ISO 8601 通过 `schedule.at`；也接受 `atMs`（纪元毫秒）。
- `every`：固定间隔（毫秒）。
- `cron`：5字段的 cron 表达式，带可选的 IANA 时区。

Cron 表达式使用 `croner`。如果省略时区，则使用网关主机的本地时区。

### 主会话 vs 独立执行

#### 主会话任务（系统事件）

主任务排队一个系统事件并可选择唤醒心跳运行器。
它们必须使用 `payload.kind = "systemEvent"`。

- `wakeMode: "next-heartbeat"`（默认）：事件等待下一个计划的心跳。
- `wakeMode: "now"`：事件触发立即心跳运行。

当您需要正常的
心跳提示 + 主会话上下文时，这是最佳选择。
请参见 [心跳](/gateway/heartbeat)。

#### 独立任务（专用定时任务会话）

独立任务在会话 `cron:<jobId>` 中运行专用代理回合。

关键行为：

- 提示前缀为 `[cron:<jobId> <任务名称>]` 以确保可追溯性。
- 每次运行启动一个 **新的会话 ID**（没有先前对话的延续）。
- 默认行为：如果省略 `delivery`，独立任务立即发布公告摘要（`delivery.mode = "announce"`），除非提供了传统的隔离设置或传统的有效载荷发送字段。
- 传统行为：具有传统隔离设置、传统有效载荷发送字段或没有 `delivery` 的旧存储任务会在主会话中发布摘要（前缀 `Cron`，可配置）。
- `delivery.mode`（仅限独立）选择替代传统摘要的行为：
  - `announce`：子代理风格的摘要立即发送到聊天。
  - `deliver`：完整的代理输出立即发送到聊天。
  - `none`：仅内部使用（无主摘要，无发送）。
- `wakeMode: "now"` 仅在使用传统主摘要路径时触发立即心跳。

对嘈杂、频繁或 "后台杂务" 类型的任务使用独立任务，这些任务不应干扰您的主聊天历史。

### 有效载荷形状（运行什么）

支持两种有效载荷类型：

- `systemEvent`：仅限主会话，通过心跳提示路由。
- `agentTurn`：仅限独立会话，运行专用代理回合。

常见的 `agentTurn` 字段：

- `message`：必需的文本提示。
- `model` / `thinking`：可选覆盖（见下文）。
- `timeoutSeconds`：可选超时覆盖。

发送配置（仅限独立任务）：

- `delivery.mode`：`none` | `announce` | `deliver`。
- `delivery.channel`：`last` 或特定通道。
- `delivery.to`：通道特定目标（电话/聊天/通道 ID）。
- `delivery.bestEffort`：如果发送失败则避免任务失败（发送模式）。

如果独立任务省略 `delivery`，OpenClaw 默认为 `announce`，除非存在传统隔离设置。

传统发送字段（当省略 `delivery` 时仍被接受）：

- `payload.deliver`：`true` 将输出发送到通道目标。
- `payload.channel`：`last` 或特定通道。
- `payload.to`：通道特定目标（电话/聊天/通道 ID）。
- `payload.bestEffortDeliver`：如果发送失败则避免任务失败。

隔离选项（仅适用于 `session=isolated`）：

- `postToMainPrefix`（CLI：`--post-prefix`）：主会话中系统事件的前缀。
- `postToMainMode`：`summary`（默认）或 `full`。
- `postToMainMaxChars`：当 `postToMainMode=full` 时的最大字符数（默认 8000）。

注意：设置隔离发送到主会话选项会选择传统主摘要路径（无 `delivery` 字段）。如果设置了 `delivery`，则跳过传统摘要。

### 模型和思考级别覆盖

独立任务（`agentTurn`）可以覆盖模型和思考级别：

- `model`：提供者/模型字符串（例如，`anthropic/claude-sonnet-4-20250514`）或别名（例如，`opus`）
- `thinking`：思考级别（`off`、`minimal`、`low`、`medium`、`high`、`xhigh`；仅限 GPT-5.2 + Codex 模型）

注意：您也可以在主会话任务上设置 `model`，但这会改变共享的主会话模型。
我们建议仅对独立任务进行模型覆盖，以避免意外的上下文转换。

解析优先级：

1. 任务有效载荷覆盖（最高）
2. 钩子特定默认值（例如，`hooks.gmail.model`）
3. 代理配置默认值

### 发送（通道 + 目标）

独立任务可以通过顶层 `delivery` 配置将输出发送到通道：

- `delivery.mode`：`announce`（子代理风格摘要）或 `deliver`（完整输出）。
- `delivery.channel`：`whatsapp` / `telegram` / `discord` / `slack` / `mattermost`（插件）/ `signal` / `imessage` / `last`。
- `delivery.to`：通道特定的接收者目标。

发送配置仅对独立任务有效（`sessionTarget: "isolated"`）。

如果省略 `delivery.channel` 或 `delivery.to`，定时任务可以回退到主会话的
"最后路线"（代理上次回复的地方）。

传统行为（没有 `delivery` 字段的传统隔离设置或旧任务）：

- 如果设置了 `payload.to`，即使省略了 `payload.deliver`，定时任务也会自动发送代理的最终输出。
- 当您想要最后路线发送而无需显式 `to` 时，使用 `payload.deliver: true`。
- 即使存在 `to`，也要使用 `payload.deliver: false` 来保持输出内部使用。

如果设置了 `delivery`，它会覆盖传统的有效载荷发送字段并跳过传统的主会话摘要。

目标格式提醒：

- Slack/Discord/Mattermost（插件）目标应使用显式前缀（例如 `channel:<id>`、`user:<id>`）以避免歧义。
- Telegram 主题应使用 `:topic:` 形式（见下文）。

#### Telegram 发送目标（主题 / 论坛帖子）

Telegram 通过 `message_thread_id` 支持论坛主题。对于定时任务发送，您可以将
主题/帖子编码到 `to` 字段中：

- `-1001234567890`（仅聊天 ID）
- `-1001234567890:topic:123`（首选：显式主题标记）
- `-1001234567890:123`（简写：数字后缀）

也接受带有前缀的目标，如 `telegram:...` / `telegram:group:...`：

- `telegram:group:-1001234567890:topic:123`

## 工具调用的 JSON 模式

直接调用网关 `cron.*` 工具时使用这些格式（代理工具调用或 RPC）。
CLI 标志接受人类可读的持续时间如 `20m`，但工具调用应使用 ISO 8601 字符串
作为 `schedule.at`（首选）或使用纪元毫秒作为 `atMs` 和 `everyMs`。

### cron.add 参数

一次性、主会话任务（系统事件）：

```json
{
  "name": "提醒",
  "schedule": { "kind": "at", "at": "2026-02-01T16:00:00Z" },
  "sessionTarget": "main",
  "wakeMode": "now",
  "payload": { "kind": "systemEvent", "text": "提醒文本" },
  "deleteAfterRun": true
}
```

定期、独立任务并发送输出：

```json
{
  "name": "晨间简报",
  "schedule": { "kind": "cron", "expr": "0 7 * * *", "tz": "America/Los_Angeles" },
  "sessionTarget": "isolated",
  "wakeMode": "next-heartbeat",
  "payload": {
    "kind": "agentTurn",
    "message": "总结夜间更新。"
  },
  "delivery": {
    "mode": "announce",
    "channel": "slack",
    "to": "channel:C1234567890",
    "bestEffort": true
  }
}
```

注意事项：

- `schedule.kind`：`at`（`at` 或 `atMs`）、`every`（`everyMs`）或 `cron`（`expr`，可选 `tz`）。
- `schedule.at` 接受 ISO 8601（时区可选；省略时视为 UTC）。
- `atMs` 和 `everyMs` 是纪元毫秒。
- `sessionTarget` 必须是 `"main"` 或 `"isolated"` 并且必须匹配 `payload.kind`。
- 可选字段：`agentId`、`description`、`enabled`、`deleteAfterRun`（`at` 的默认值为 true），
  `delivery`、`isolation`。
- 省略时 `wakeMode` 默认为 `"next-heartbeat"`。

### cron.update 参数

```json
{
  "jobId": "job-123",
  "patch": {
    "enabled": false,
    "schedule": { "kind": "every", "everyMs": 3600000 }
  }
}
```

注意事项：

- `jobId` 是标准的；为了兼容性接受 `id`。
- 在补丁中使用 `agentId: null` 来清除代理绑定。

### cron.run 和 cron.remove 参数

```json
{ "jobId": "job-123", "mode": "force" }
```

```json
{ "jobId": "job-123" }
```

## 存储和历史

- 任务存储：`~/.openclaw/cron/jobs.json`（网关管理的 JSON）。
- 运行历史：`~/.openclaw/cron/runs/<jobId>.jsonl`（JSONL，自动修剪）。
- 覆盖存储路径：配置中的 `cron.store`。

## 配置

```json5
{
  cron: {
    enabled: true, // 默认 true
    store: "~/.openclaw/cron/jobs.json",
    maxConcurrentRuns: 1, // 默认 1
  },
}
```

完全禁用定时任务：

- `cron.enabled: false`（配置）
- `OPENCLAW_SKIP_CRON=1`（环境变量）

## CLI 快速开始

一次性提醒（UTC ISO，成功后自动删除）：

```bash
openclaw-cn cron add \
  --name "发送提醒" \
  --at "2026-01-12T18:00:00Z" \
  --session main \
  --system-event "提醒：提交费用报告。" \
  --wake now \
  --delete-after-run
```

一次性提醒（主会话，立即唤醒）：

```bash
openclaw-cn cron add \
  --name "日历检查" \
  --at "20m" \
  --session main \
  --system-event "下次心跳：检查日历。" \
  --wake now
```

定期独立任务（向 WhatsApp 公告）：

```bash
openclaw-cn cron add \
  --name "晨间状态" \
  --cron "0 7 * * *" \
  --tz "America/Los_Angeles" \
  --session isolated \
  --message "总结今天的收件箱 + 日历。" \
  --announce \
  --channel whatsapp \
  --to "+15551234567"
```

定期独立任务（发送到 Telegram 主题）：

```bash
openclaw-cn cron add \
  --name "夜间总结（主题）" \
  --cron "0 22 * * *" \
  --tz "America/Los_Angeles" \
  --session isolated \
  --message "总结今天；发送到夜间主题。" \
  --deliver \
  --channel telegram \
  --to "-1001234567890:topic:123"
```

带模型和思考级别覆盖的独立任务：

```bash
openclaw-cn cron add \
  --name "深度分析" \
  --cron "0 6 * * 1" \
  --tz "America/Los_Angeles" \
  --session isolated \
  --message "每周项目进展深度分析。" \
  --model "opus" \
  --thinking high \
  --deliver \
  --channel whatsapp \
  --to "+15551234567"
```

代理选择（多代理设置）：

```bash
# 将任务固定到代理 "ops"（如果该代理缺失则回退到默认）
openclaw-cn cron add --name "运维扫描" --cron "0 6 * * *" --session isolated --message "检查运维队列" --agent ops

# 切换或清除现有任务上的代理
openclaw-cn cron edit <jobId> --agent ops
openclaw-cn cron edit <jobId> --clear-agent
```

手动运行（调试）：

```bash
openclaw-cn cron run <jobId> --force
```

编辑现有任务（修补字段）：

```bash
openclaw-cn cron edit <jobId> \
  --message "更新的提示" \
  --model "opus" \
  --thinking low
```

运行历史：

```bash
openclaw-cn cron runs --id <jobId> --limit 50
```

不创建任务的立即系统事件：

```bash
openclaw-cn system event --mode now --text "下次心跳：检查电池。"
```

## 网关 API 接口

- `cron.list`、`cron.status`、`cron.add`、`cron.update`、`cron.remove`
- `cron.run`（强制或到期）、`cron.runs`
  对于不创建任务的立即系统事件，请使用 [`openclaw-cn system event`](/cli/system)。

## 故障排除

### "什么都不运行"

- 检查定时任务是否启用：`cron.enabled` 和 `OPENCLAW_SKIP_CRON`。
- 检查网关是否连续运行（定时任务在网关进程内运行）。
- 对于 `cron` 计划：确认时区（`--tz`）与主机时区。

### Telegram 发送到错误的地方

- 对于论坛主题，使用 `-100…:topic:<id>` 使其明确且无歧义。
- 如果您在日志或存储的 "最后路线" 目标中看到 `telegram:...` 前缀，这很正常；
  定时任务发送接受它们并仍然能正确解析主题 ID。
