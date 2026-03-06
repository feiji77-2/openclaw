---
summary: "WhatsApp 群组消息处理的行为和配置（mentionPatterns 在各平台间共享）"
read_when:
  - 更改群组消息规则或提及
---
# 群组消息（WhatsApp 网页频道）

目标：让 Clawd 坐在 WhatsApp 群组中，仅在被 ping 时唤醒，并将该线程与个人 DM 会话分开。

注意：`agents.list[].groupChat.mentionPatterns` 现在也被 Telegram/Discord/Slack/iMessage 使用；本文档专注于 WhatsApp 特定行为。对于多代理设置，为每个代理设置 `agents.list[].groupChat.mentionPatterns`（或使用 `messages.groupChat.mentionPatterns` 作为全局回退）。

## 已实现功能（2025-12-03）
- 激活模式：`mention`（默认）或 `always`。`mention` 需要 ping（通过 `mentionedJids` 的真实 WhatsApp @提及、正则表达式模式，或文本中任何位置的机器人 E.164）。`always` 在每条消息时唤醒代理，但它应该只在能够增加有意义价值时回复；否则返回静默令牌 `NO_REPLY`。可以在配置中设置默认值（`channels.whatsapp.groups`），并通过 `/activation` 为每个群组覆盖。当设置 `channels.whatsapp.groups` 时，它也充当群组允许列表（包含 `"*"` 以允许所有）。
- 群组策略：`channels.whatsapp.groupPolicy` 控制是否接受群组消息（`open|disabled|allowlist`）。`allowlist` 使用 `channels.whatsapp.groupAllowFrom`（回退：明确的 `channels.whatsapp.allowFrom`）。默认为 `allowlist`（阻止直到您添加发送者）。
- 每群组会话：会话键看起来像 `agent:<agentId>:whatsapp:group:<jid>`，因此 `/verbose on` 或 `/think high` 等命令（作为独立消息发送）作用域限定在该群组；个人 DM 状态不受影响。群组线程跳过心跳。
- 上下文注入：**仅待处理** 的群组消息（默认 50 条）*未* 触发运行的前缀为 `[自您上次回复以来的聊天消息 - 供上下文]`，触发行在 `[当前消息 - 回复此消息]` 下。已在会话中的消息不会重新注入。
- 发送者显示：每个群组批次现在以 `[from: 发送者姓名 (+E164)]` 结尾，因此 Pi 知道谁在说话。
- 临时/一次性查看：我们在提取文本/提及之前解开它们，因此其中的 ping 仍会触发。
- 群组系统提示：在群组会话的第一回合（以及每当 `/activation` 更改模式时），我们将简短说明注入系统提示，如 `您正在 WhatsApp 群组 "<subject>" 中回复。群组成员：Alice (+44...)、Bob (+43...)、… 激活：仅触发 … 回复消息上下文中注明的特定发送者。` 如果元数据不可用，我们仍告诉代理这是群组聊天。

## 配置示例（WhatsApp）
向 `~/.openclaw-cn/openclaw-cn.json` 添加 `groupChat` 块，以便显示名称 ping 即使 WhatsApp 在文本主体中剥离视觉 `@` 也能工作：

```json5
{
  channels: {
    whatsapp: {
      groups: {
        "*": { requireMention: true }
      }
    }
  },
  agents: {
    list: [
      {
        id: "main",
        groupChat: {
          historyLimit: 50,
          mentionPatterns: [
            "@?clawdbot",
            "\\+?15555550123"
          ]
        }
      }
    ]
  }
}
```

注意事项：
- 正则表达式不区分大小写；它们涵盖显示名称 ping 如 `@clawdbot` 和带或不带 `+`/空格的原始号码。
- 当有人点击联系人时，WhatsApp 仍通过 `mentionedJids` 发送规范提及，因此很少需要号码回退，但这是一个有用的保障。

### 激活命令（仅所有者）

使用群组聊天命令：
- `/activation mention`
- `/activation always`

只有所有者号码（来自 `channels.whatsapp.allowFrom`，或未设置时代理自己的 E.164）可以更改此设置。在群组中发送 `/status` 作为独立消息以查看当前激活模式。

## 如何使用
1) 将您的 WhatsApp 账户（运行 Clawdbot 的那个）添加到群组。
2) 说 `@clawdbot …`（或包含号码）。除非您设置 `groupPolicy: "open"`，否则只有允许列表中的发送者可以触发它。
3) 代理提示将包含最近的群组上下文加上尾随的 `[from: …]` 标记，因此它可以回应正确的人。
4) 会话级别指令（`/verbose on`、`/think high`、`/new` 或 `/reset`、`/compact`）仅适用于该群组的会话；将它们作为独立消息发送以便注册。您的个人 DM 会话保持独立。

## 测试 / 验证
- 手动冒烟测试：
  - 在群组中发送 `@clawd` ping 并确认引用发送者姓名的回复。
  - 发送第二次 ping 并验证历史块在下一回合包含然后清除。
- 检查网关日志（使用 `--verbose` 运行）查看显示 `from: <groupJid>` 和 `[from: …]` 后缀的 `inbound web message` 条目。

## 已知注意事项
- 故意跳过群组的心跳以避免嘈杂的广播。
- 回声抑制使用组合批次字符串；如果您在没有提及的情况下发送两次相同文本，只有第一次会得到回复。
- 会话存储条目将在会话存储中显示为 `agent:<agentId>:whatsapp:group:<jid>`（默认 `~/.openclaw/agents/<agentId>/sessions/sessions.json`）；缺少条目仅意味着群组尚未触发运行。
- 群组中的输入指示符遵循 `agents.defaults.typingMode`（默认：未提及时为 `message`）。
