---
summary: "CLI 引导向导：网关、工作区、频道和技能的引导式设置"
read_when:
  - 运行或配置引导向导
  - 设置新机器
title: "引导向导"
---

# 引导向导 (CLI)

引导向导是在 macOS、Linux 或 Windows（通过 WSL2；强烈推荐）上设置 OpenClaw 的**推荐**方式。
它在一个引导流程中配置本地网关或远程网关连接，以及频道、技能和工作区默认设置。

主要入口点：

```bash
openclaw-cn onboard
```

最快首次聊天：打开控制 UI（无需频道设置）。运行
`openclaw-cn dashboard` 并在浏览器中聊天。文档：[仪表板](/web/dashboard)。

后续重新配置：

```bash
openclaw-cn configure
```

推荐：设置 Brave Search API 密钥，这样代理就可以使用 `web_search`
（`web_fetch` 无需密钥即可工作）。最简单的方法：`openclaw-cn configure --section web`
这会存储 `tools.web.search.apiKey`。文档：[网络工具](/tools/web)。

## 快速开始 vs 高级模式

向导以**快速开始**（默认设置）vs**高级**（完全控制）开始。

**快速开始**保持默认设置：

- 本地网关（回环）
- 工作区默认设置（或现有工作区）
- 网关端口 **18789**
- 网关认证**令牌**（自动生成，即使是回环）
- Tailscale 暴露**关闭**
- Telegram + WhatsApp 私信默认为**白名单**（会提示您输入手机号码）

**高级**模式展示每个步骤（模式、工作区、网关、频道、守护进程、技能）。

## 向导的作用

**本地模式（默认）**引导您完成：

- 模型/认证（OpenAI Code (Codex) 订阅 OAuth、Anthropic API 密钥（推荐）或设置令牌（粘贴），以及 MiniMax/GLM/Moonshot/AI 网关选项）
- 工作区位置 + 启动文件
- 网关设置（端口/绑定/认证/tailscale）
- 提供商（Telegram、WhatsApp、Discord、Google Chat、Mattermost（插件）、Signal）
- 守护进程安装（LaunchAgent / systemd 用户单元）
- 健康检查
- 技能（推荐）

**远程模式**仅配置本地客户端连接到其他地方的网关。
它**不会**在远程主机上安装或更改任何内容。

要添加更多独立代理（独立工作区 + 会话 + 认证），请使用：

```bash
openclaw-cn agents add <name>
```

提示：`--json` **不**意味着非交互模式。脚本请使用 `--non-interactive`（和 `--workspace`）。

## 流程详情（本地）

1. **现有配置检测**
   - 如果 `~/.openclaw/openclaw.json` 存在，选择**保留 / 修改 / 重置**。
   - 重新运行向导**不会**清除任何内容，除非您明确选择**重置**
     （或传递 `--reset`）。
   - 如果配置无效或包含旧版密钥，向导会停止并要求
     您在继续之前运行 `openclaw-cn doctor`。
   - 重置使用 `trash`（从不使用 `rm`）并提供范围：
     - 仅配置
     - 配置 + 凭据 + 会话
     - 完全重置（也移除工作区）

2. **模型/认证**
   - **Anthropic API 密钥（推荐）**：如果存在则使用 `ANTHROPIC_API_KEY` 或提示输入密钥，然后保存供守护进程使用。
   - **Anthropic OAuth（Claude Code CLI）**：在 macOS 上，向导检查钥匙串项目 "Claude Code-credentials"（选择 "始终允许" 以便 launchd 启动不被阻止）；在 Linux/Windows 上，如果存在则重用 `~/.claude/.credentials.json`。
   - **Anthropic 令牌（粘贴设置令牌）**：在任何机器上运行 `claude setup-token`，然后粘贴令牌（可以命名；空白 = 默认）。
   - **OpenAI Code (Codex) 订阅（Codex CLI）**：如果 `~/.codex/auth.json` 存在，向导可以重用它。
   - **OpenAI Code (Codex) 订阅（OAuth）**：浏览器流程；粘贴 `code#state`。
     - 当模型未设置或为 `openai/*` 时，将 `agents.defaults.model` 设置为 `openai-codex/gpt-5.2`。
   - **OpenAI API 密钥**：如果存在则使用 `OPENAI_API_KEY` 或提示输入密钥，然后保存到 `~/.openclaw/.env` 以便 launchd 可以读取。
   - **OpenCode Zen（多模型代理）**：提示输入 `OPENCODE_API_KEY`（或 `OPENCODE_ZEN_API_KEY`，在 https://opencode.ai/auth 获取）。
   - **API 密钥**：为您存储密钥。
   - **Vercel AI 网关（多模型代理）**：提示输入 `AI_GATEWAY_API_KEY`。
   - 更多详情：[Vercel AI 网关](/providers/vercel-ai-gateway)
   - **Cloudflare AI 网关**：提示输入账户 ID、网关 ID 和 `CLOUDFLARE_AI_GATEWAY_API_KEY`。
   - 更多详情：[Cloudflare AI 网关](/providers/cloudflare-ai-gateway)
   - **MiniMax M2.1**：配置自动写入。
   - 更多详情：[MiniMax](/providers/minimax)
   - **Synthetic（Anthropic 兼容）**：提示输入 `SYNTHETIC_API_KEY`。
   - 更多详情：[Synthetic](/providers/synthetic)
   - **Moonshot（Kimi K2）**：配置自动写入。
   - **Kimi Coding**：配置自动写入。
   - 更多详情：[Moonshot AI（Kimi + Kimi Coding）](/providers/moonshot)
   - **跳过**：尚未配置认证。
   - 从检测到的选项中选择默认模型（或手动输入提供商/模型）。
   - 向导运行模型检查，如果配置的模型未知或缺少认证则发出警告。

- OAuth 凭据位于 `~/.openclaw/credentials/oauth.json`；认证配置文件位于 `~/.openclaw/agents/<agentId>/agent/auth-profiles.json`（API 密钥 + OAuth）。
- 更多详情：[/concepts/oauth](/concepts/oauth)

3. **工作区**
   - 默认 `~/.openclaw/workspace`（可配置）。
   - 为代理启动仪式生成所需的工作区文件。
   - 完整工作区布局 + 备份指南：[代理工作区](/concepts/agent-workspace)

4. **网关**
   - 端口、绑定、认证模式、tailscale 暴露。
   - 认证建议：即使是回环也要保持**令牌**，这样本地 WS 客户端必须进行认证。
   - 仅当您完全信任每个本地进程时才禁用认证。
   - 非回环绑定仍需要认证。

5. **频道**
   - [WhatsApp](/channels/whatsapp)：可选的二维码登录。
   - [Telegram](/channels/telegram)：机器人令牌。
   - [Discord](/channels/discord)：机器人令牌。
   - [Google Chat](/channels/googlechat)：服务账户 JSON + webhook 受众。
   - [Mattermost](/channels/mattermost)（插件）：机器人令牌 + 基础 URL。
   - [Signal](/channels/signal)：可选的 `signal-cli` 安装 + 账户配置。
   - [BlueBubbles](/channels/bluebubbles)：**推荐用于 iMessage**；服务器 URL + 密码 + webhook。
   - [iMessage](/channels/imessage)：旧版 `imsg` CLI 路径 + 数据库访问。
   - 私信安全：默认为配对。第一条私信发送代码；通过 `openclaw-cn pairing approve <channel> <code>` 批准或使用白名单。

6. **守护进程安装**
   - macOS：LaunchAgent
     - 需要已登录的用户会话；对于无头模式，使用自定义 LaunchDaemon（未提供）。
   - Linux（和通过 WSL2 的 Windows）：systemd 用户单元
     - 向导尝试通过 `loginctl enable-linger <user>` 启用 linger，这样网关在注销后仍保持运行。
     - 可能提示输入 sudo（写入 `/var/lib/systemd/linger`）；首先尝试不使用 sudo。
   - **运行时选择：** Node（推荐；WhatsApp/Telegram 必需）。**不推荐**使用 Bun。

7. **健康检查**
   - 启动网关（如果需要）并运行 `openclaw-cn health`。
   - 提示：`openclaw-cn status --deep` 将网关健康探针添加到状态输出中（需要可访问的网关）。

8. **技能（推荐）**
   - 读取可用技能并检查要求。
   - 让您选择节点管理器：**npm / pnpm**（不推荐 bun）。
   - 安装可选依赖项（某些在 macOS 上使用 Homebrew）。

9. **完成**
   - 总结 + 下一步，包括用于额外功能的 iOS/Android/macOS 应用。

- 如果未检测到 GUI，向导会打印 SSH 端口转发指令用于控制 UI，而不是打开浏览器。
- 如果缺少控制 UI 资产，向导会尝试构建它们；备用方案是 `pnpm ui:build`（自动安装 UI 依赖项）。

## 远程模式

远程模式配置本地客户端连接到其他地方的网关。

您将设置：

- 远程网关 URL (`ws://...`)
- 如果远程网关需要认证则设置令牌（推荐）

注意事项：

- 不执行远程安装或守护进程更改。
- 如果网关仅为回环，则使用 SSH 隧道或 tailnet。
- 发现提示：
  - macOS：Bonjour (`dns-sd`)
  - Linux：Avahi (`avahi-browse`)

## 添加另一个代理

使用 `openclaw-cn agents add <name>` 创建具有自己工作区、会话和认证配置文件的独立代理。不带 `--workspace` 运行会启动向导。

它设置的内容：

- `agents.list[].name`
- `agents.list[].workspace`
- `agents.list[].agentDir`

注意事项：

- 默认工作区遵循 `~/.openclaw/workspace-<agentId>`。
- 添加 `bindings` 来路由入站消息（向导可以做到这一点）。
- 非交互标志：`--model`、`--agent-dir`、`--bind`、`--non-interactive`。

## 非交互模式

使用 `--non-interactive` 来自动化或脚本化引导过程：

```bash
openclaw-cn onboard --non-interactive \
  --mode local \
  --auth-choice apiKey \
  --anthropic-api-key "$ANTHROPIC_API_KEY" \
  --gateway-port 18789 \
  --gateway-bind loopback \
  --install-daemon \
  --daemon-runtime node \
  --skip-skills
```

添加 `--json` 以获得机器可读的摘要。

Gemini 示例：

```bash
openclaw-cn onboard --non-interactive \
  --mode local \
  --auth-choice gemini-api-key \
  --gemini-api-key "$GEMINI_API_KEY" \
  --gateway-port 18789 \
  --gateway-bind loopback
```

Z.AI 示例：

```bash
openclaw-cn onboard --non-interactive \
  --mode local \
  --auth-choice zai-api-key \
  --zai-api-key "$ZAI_API_KEY" \
  --gateway-port 18789 \
  --gateway-bind loopback
```

Vercel AI 网关示例：

```bash
openclaw-cn onboard --non-interactive \
  --mode local \
  --auth-choice ai-gateway-api-key \
  --ai-gateway-api-key "$AI_GATEWAY_API_KEY" \
  --gateway-port 18789 \
  --gateway-bind loopback
```

Cloudflare AI 网关示例：

```bash
openclaw-cn onboard --non-interactive \
  --mode local \
  --auth-choice cloudflare-ai-gateway-api-key \
  --cloudflare-ai-gateway-account-id "your-account-id" \
  --cloudflare-ai-gateway-gateway-id "your-gateway-id" \
  --cloudflare-ai-gateway-api-key "$CLOUDFLARE_AI_GATEWAY_API_KEY" \
  --gateway-port 18789 \
  --gateway-bind loopback
```

Moonshot 示例：

```bash
openclaw-cn onboard --non-interactive \
  --mode local \
  --auth-choice moonshot-api-key \
  --moonshot-api-key "$MOONSHOT_API_KEY" \
  --gateway-port 18789 \
  --gateway-bind loopback
```

Synthetic 示例：

```bash
openclaw-cn onboard --non-interactive \
  --mode local \
  --auth-choice synthetic-api-key \
  --synthetic-api-key "$SYNTHETIC_API_KEY" \
  --gateway-port 18789 \
  --gateway-bind loopback
```

OpenCode Zen 示例：

```bash
openclaw-cn onboard --non-interactive \
  --mode local \
  --auth-choice opencode-zen \
  --opencode-zen-api-key "$OPENCODE_API_KEY" \
  --gateway-port 18789 \
  --gateway-bind loopback
```

添加代理（非交互）示例：

```bash
openclaw-cn agents add work \
  --workspace ~/.openclaw/workspace-work \
  --model openai/gpt-5.2 \
  --bind whatsapp:biz \
  --non-interactive \
  --json
```

## 网关向导 RPC

网关通过 RPC 暴露向导流程（`wizard.start`、`wizard.next`、`wizard.cancel`、`wizard.status`）。
客户端（macOS 应用、控制 UI）可以在不重新实现引导逻辑的情况下渲染步骤。

## Signal 设置（signal-cli）

向导可以从 GitHub 发布版本安装 `signal-cli`：

- 下载适当的发布资产。
- 将其存储在 `~/.openclaw/tools/signal-cli/<version>/` 下。
- 将 `channels.signal.cliPath` 写入您的配置。

注意事项：

- JVM 构建需要 **Java 21**。
- 可用时使用原生构建。
- Windows 使用 WSL2；signal-cli 安装遵循 WSL 内的 Linux 流程。

## 向导写入的内容

`~/.openclaw/openclaw.json` 中的典型字段：

- `agents.defaults.workspace`
- `agents.defaults.model` / `models.providers`（如果选择了 Minimax）
- `gateway.*`（模式、绑定、认证、tailscale）
- `channels.telegram.botToken`、`channels.discord.token`、`channels.signal.*`、`channels.imessage.*`
- 频道白名单（Slack/Discord/Matrix/Microsoft Teams），当您在提示中选择加入时（名称尽可能解析为 ID）。
- `skills.install.nodeManager`
- `wizard.lastRunAt`
- `wizard.lastRunVersion`
- `wizard.lastRunCommit`
- `wizard.lastRunCommand`
- `wizard.lastRunMode`

`openclaw-cn agents add` 写入 `agents.list[]` 和可选的 `bindings`。

WhatsApp 凭据位于 `~/.openclaw/credentials/whatsapp/<accountId>/` 下。
会话存储在 `~/.openclaw/agents/<agentId>/sessions/` 下。

某些频道以插件形式提供。当您在引导过程中选择其中一个时，向导
会在配置之前提示安装它（npm 或本地路径）。

## 相关文档

- macOS 应用引导：[引导](/start/onboarding)
- 配置参考：[网关配置](/gateway/configuration)
- 提供商：[WhatsApp](/channels/whatsapp)、[Telegram](/channels/telegram)、[Discord](/channels/discord)、[Google Chat](/channels/googlechat)、[Signal](/channels/signal)、[BlueBubbles](/channels/bluebubbles)（iMessage）、[iMessage](/channels/imessage)（旧版）
- 技能：[技能](/tools/skills)、[技能配置](/tools/skills-config)
