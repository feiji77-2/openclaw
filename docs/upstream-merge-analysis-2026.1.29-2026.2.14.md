# 上游合并分析: v2026.1.29 → v2026.2.14

> 生成日期: 2026-02-15
> 上游项目: openclaw/openclaw
> 目标分支: openclaw-cn (中国本地化分支)
> 已合并 PR: #3304, #4407, #4456, #4521, #4533, #4578, #4593, #4651, #4873, #4880, #4909, #4957, #4984, #5055

## 概览统计

| 优先级 | 数量 | 说明 |
|--------|------|------|
| P0-SECURITY | 82 | 安全修复 (全部必须合并) |
| P1-CRITICAL-BUG | 27 | 核心/已用渠道的关键 bug |
| P2-CORE-FEATURE | 65 | 核心引擎功能改进 |
| P3-MODEL-SUPPORT | 19 | 新模型/提供商支持 |
| P4-CHANNEL-FIX | 50 | 已用渠道的 bug 修复 |
| P5-NICE-TO-HAVE | 30 | 锦上添花 |
| SKIP | 8 | 不适用 / 已合并 / 未使用渠道 |

---

## P0-SECURITY

> **所有安全修复必须合并**，无论是否涉及当前使用的渠道。标注了影响未使用渠道的项目以便评估优先顺序。

| # | PR/Issue | 版本 | 描述 | 备注 |
|---|----------|------|------|------|
| 1 | #5445 | v2026.2.1 | Agents: 添加系统提示安全防护 | 核心安全层，必须合并 |
| 2 | #5970 | v2026.2.1 | Gateway: TLS 监听器要求最低 TLS 1.3 | 网关安全强化 |
| 3 | — | v2026.2.1 | Plugins: 验证插件/hook 安装路径，拒绝路径遍历名称 | 防止路径遍历攻击 |
| 4 | #7641 | v2026.2.2 | Security: 添加健康检查技能和引导审计指导 | 安全审计基础 |
| 5 | #1 | v2026.2.2 | Security: gateway /approve 命令要求 operator.approvals | 网关权限控制 |
| 6 | — | v2026.2.2 | Security: Matrix allowlists 要求完整 MXIDs | 影响 Matrix 扩展 |
| 7 | — | v2026.2.2 | Security: 对 Slack slash 命令强制 access-group 门控 | Slack 为已用渠道 |
| 8 | — | v2026.2.2 | Security: 跳过设备身份前要求验证 shared-secret 认证 | 网关连接安全 |
| 9 | — | v2026.2.2 | Security: 技能安装器下载添加 SSRF 检查 | 防止 SSRF |
| 10 | — | v2026.2.2 | Security: 加固 Windows exec 白名单；阻止 cmd.exe 绕过 | Windows 安全（低优先级平台但仍需合并） |
| 11 | — | v2026.2.2 | voice-call: 加固入站白名单；拒绝匿名呼叫者；要求 Telnyx publicKey；token-gate Twilio 媒体流；限制 webhook body 大小 | 语音通话安全 |
| 12 | — | v2026.2.2 | Media understanding: 对提供商获取添加 SSRF 防护 | 核心媒体安全 |
| 13 | — | v2026.2.3 | Security: 将不可信渠道元数据排除出系统提示 (Slack/Discord) | Slack、Discord 为已用渠道 |
| 14 | #9182 | v2026.2.3 | Security: 对消息工具附件强制沙箱媒体路径 | 核心安全 |
| 15 | #8113 | v2026.2.3 | Security: gateway URL 覆盖要求显式凭据 | 网关安全 |
| 16 | #8768 | v2026.2.3 | Security: whatsapp_login 工具限制为 owner 发送者 | WhatsApp 为已用渠道 |
| 17 | — | v2026.2.3 | Voice call: 加固 webhook 验证 | 安全加固 |
| 18 | #8104 | v2026.2.3 | Voice call: 匿名入站呼叫者 ID 回归测试覆盖 | 安全测试 |
| 19 | #9518 | v2026.2.6 | Security: Gateway canvas host 和 A2UI 资产要求认证 | 网关安全 |
| 20 | #9806, #9858 | v2026.2.6 | Security: 添加技能/插件代码安全扫描器；config.get 脱敏凭据 | 核心安全特性 |
| 21 | — | v2026.2.12 | Gateway/OpenResponses: 用 SSRF 拒绝策略加固 URL 输入处理 | 核心 SSRF 防护 |
| 22 | #13719 | v2026.2.12 | Security: 修复未认证 Nostr 配置文件 API 远程配置篡改 | 影响未使用渠道但为远程配置篡改漏洞 |
| 23 | #14757 | v2026.2.12 | Security: 移除捆绑的 soul-evil hook | 恶意 hook 移除 |
| 24 | — | v2026.2.12 | Security/Audit: 添加 hook session-routing 加固检查 | 审计安全 |
| 25 | — | v2026.2.12 | Security/Sandbox: 限制镜像技能同步目标 | 沙箱安全 |
| 26 | — | v2026.2.12 | Security/Web tools: 默认将浏览器/web 内容视为不可信 | Web 工具安全 |
| 27 | — | v2026.2.12 | Security/Hooks: 用常量时间比较加固 webhook 和设备令牌验证 | 防止时序攻击 |
| 28 | — | v2026.2.12 | Security/Browser: loopback 浏览器控制 HTTP 路由要求认证 | 浏览器安全 |
| 29 | — | v2026.2.12 | Sessions/Gateway: 加固转录路径解析 | 路径安全 |
| 30 | #13787 | v2026.2.12 | BlueBubbles: 修复通过 loopback 代理信任的 webhook 认证绕过 | 未使用渠道，但为认证绕过漏洞 |
| 31 | #15390 | v2026.2.13 | Security/Gateway + ACP: 阻止高风险工具通过 HTTP /tools/invoke 调用 | 核心安全 |
| 32 | #14661 | v2026.2.13 | Security/Gateway: canvas IP 认证回退仅接受机器范围地址 | 网关安全 |
| 33 | #15604 | v2026.2.13 | Security/Link understanding: 阻止 loopback/内部主机模式 | SSRF 防护 |
| 34 | — | v2026.2.13 | Security/Browser: 约束 trace/download 输出路径 | 浏览器安全 |
| 35 | #10525 | v2026.2.13 | Security/Canvas: 通过 safe-open 路径提供 A2UI 资产 | Canvas 安全 |
| 36 | #10529 | v2026.2.13 | Security/WhatsApp: 对 creds.json 强制 0o600 权限 | WhatsApp 为已用渠道 |
| 37 | — | v2026.2.13 | Security/Gateway: 清理不可信 WebSocket header 值 | 网关安全 |
| 38 | — | v2026.2.13 | Security/Audit: 添加配置错误检查 | 审计增强 |
| 39 | #13474 | v2026.2.13 | Security/Audit: 区分外部 webhooks 和内部 hooks | 审计增强 |
| 40 | #13129 | v2026.2.13 | Security/Onboarding: 澄清多用户 DM 隔离补救 | 安全引导 |
| 41 | #4726 | v2026.2.13 | Agents/Nodes: 加固节点 exec approval 决策处理 | 执行安全 |
| 42 | — | v2026.2.14 | Memory/QMD/Security: 添加 rawKeyPrefix 支持用于范围规则 | QMD 安全，本地已有 QMD 需评估适配 |
| 43 | #12524 | v2026.2.14 | Security/Memory-LanceDB: 将召回记忆视为不可信上下文 | 内存安全 |
| 44 | #12552 | v2026.2.14 | Security/Memory-LanceDB: 要求显式 autoCapture 选入 | 内存安全 |
| 45 | #15541 | v2026.2.14 | Media/Security: 允许从 workspace/sandbox 根目录读取本地媒体 | 媒体安全 |
| 46 | #16739 | v2026.2.14 | Media/Security: 加固本地媒体白名单绕过 | 媒体安全 |
| 47 | — | v2026.2.14 | Discord/Security: 加固语音消息媒体加载 | Discord 为已用渠道 |
| 48 | #16322 | v2026.2.14 | Security/BlueBubbles: 要求显式 mediaLocalRoots | 未使用渠道，合并以保持安全一致性 |
| 49 | — | v2026.2.14 | Security/BlueBubbles: 拒绝歧义共享路径 webhook 路由 | 未使用渠道 |
| 50 | — | v2026.2.14 | Security/BlueBubbles: 加固反向代理后的 webhook 认证 | 未使用渠道 |
| 51 | #16285 | v2026.2.14 | Feishu/Security: 加固媒体 URL 请求防止 SSRF | 飞书为已用渠道，**高优先级** |
| 52 | — | v2026.2.14 | Security/Zalo: 拒绝歧义共享路径 webhook 路由 | Zalo 扩展安全 |
| 53 | — | v2026.2.14 | Security/Nostr: 要求 loopback 来源并阻止跨域 | 未使用渠道 |
| 54 | — | v2026.2.14 | Security/Signal: 加固 signal-cli 存档提取 | Signal 为已用渠道 |
| 55 | — | v2026.2.14 | Security/Hooks: 限制 hook transform 模块到 ~/.openclaw/hooks/transforms | Hook 安全 |
| 56 | — | v2026.2.14 | Security/Hooks: 忽略包目录外的 hook 包清单条目 | Hook 安全 |
| 57 | — | v2026.2.14 | Security/Archive: 强制存档提取条目/大小限制 | 核心安全 |
| 58 | — | v2026.2.14 | Security/Media: 拒绝过大的 base64 输入媒体 | 核心安全 |
| 59 | — | v2026.2.14 | Security/Media: 流式处理并限制 URL 输入媒体获取 | 核心安全 |
| 60 | — | v2026.2.14 | Security/Skills: 加固下载安装技能的存档提取 | 核心安全 |
| 61 | — | v2026.2.14 | Security/Slack: 计算 DM 斜杠命令的命令授权 | Slack 为已用渠道 |
| 62 | — | v2026.2.14 | Security/iMessage: 将 DM pairing-store 身份排除出群组白名单 | 未使用渠道 |
| 63 | — | v2026.2.14 | Security/Google Chat: 弃用 users/<email> 白名单 | 未使用渠道 |
| 64 | — | v2026.2.14 | Security/Google Chat: 拒绝歧义共享路径 webhook 路由 | 未使用渠道 |
| 65 | — | v2026.2.14 | Telegram/Security: 要求数字 Telegram 发送者 ID | Telegram 为已用渠道，**高优先级** |
| 66 | — | v2026.2.14 | Telegram/Security: webhookSecret 缺失时拒绝 webhook 启动 | Telegram，**高优先级** |
| 67 | — | v2026.2.14 | Security/Windows: 避免启动子进程时的 shell 调用 | Windows 安全 |
| 68 | #15924 | v2026.2.14 | Security/Agents (macOS): 防止 Claude CLI keychain 中的 shell 注入 | macOS 安全 |
| 69 | — | v2026.2.14 | macOS: 限制无密钥 openclaw://agent 深层链接 | macOS 安全 |
| 70 | — | v2026.2.14 | Scripts/Security: 验证 GitHub 登录 | 脚本安全 |
| 71 | — | v2026.2.14 | Security: 修复 Chutes 手动 OAuth 登录状态验证 | OAuth 安全 |
| 72 | — | v2026.2.14 | Security/Gateway: 加固工具提供的 gatewayUrl 覆盖 | 网关安全 |
| 73 | — | v2026.2.14 | Security/Gateway: 通过 node.invoke 阻止 system.execApprovals | 网关安全 |
| 74 | — | v2026.2.14 | Security/Gateway: 拒绝过大的 base64 聊天附件 | 网关安全 |
| 75 | — | v2026.2.14 | Security/Gateway: 停止在 skills.status 中返回原始解析配置值 | 信息泄露防护 |
| 76 | — | v2026.2.14 | Security/Net: 修复通过 IPv4-mapped IPv6 字面量的 SSRF 防护绕过 | **关键 SSRF 修复** |
| 77 | — | v2026.2.14 | Security/Browser: 加固浏览器控制文件上传/下载助手 | 浏览器安全 |
| 78 | — | v2026.2.14 | Security/Browser: 阻止跨域对 loopback 浏览器控制的变更请求 | 浏览器安全 |
| 79 | — | v2026.2.14 | Security/Node Host: 强制 system.run rawCommand/argv 一致性 | 执行安全 |
| 80 | — | v2026.2.14 | Security/Exec approvals: 防止 safeBins 白名单通过 shell 展开绕过 | 执行安全 |
| 81 | — | v2026.2.14 | Security/Exec: 加固 PATH 处理 | 执行安全 |
| 82 | — | v2026.2.14 | Security/Tlon: 加固 Urbit URL 获取防止 SSRF | 未使用渠道，但为 SSRF 修复 |
| 83 | — | v2026.2.14 | Security/Voice Call (Telnyx): 要求 webhook 签名验证 | 语音安全 |
| 84 | — | v2026.2.14 | Security/Voice Call: 要求有效 Twilio webhook 签名 | 语音安全 |
| 85 | — | v2026.2.14 | Security/Discovery: 停止将 Bonjour TXT 记录视为权威路由 | 发现服务安全 |
| 86 | — | v2026.2.14 | Security/Agents: 将 CLI 进程清理限定为自有子 PID | Agent 安全 |
| 87 | — | v2026.2.14 | Security/Agents: 对 apply_patch 强制 workspace 根目录路径边界 | Agent 安全 |
| 88 | — | v2026.2.14 | Security/Agents: 对 apply_patch 强制符号链接逃逸检查 | Agent 安全 |

---

## P1-CRITICAL-BUG

| # | PR/Issue | 版本 | 描述 | 备注 |
|---|----------|------|------|------|
| 1 | #7014 | v2026.2.1 | Streaming: 在段落边界刷新块流 | 影响所有渠道的流式输出 |
| 2 | — | v2026.2.1 | Streaming: 稳定部分流过滤器 | 流式核心修复 |
| 3 | #7466 | v2026.2.2 | Telegram: 从 grammY long-poll 超时错误中恢复 | Telegram 关键稳定性 |
| 4 | #7473 | v2026.2.2 | Agents: 修复格式错误的工具调用和会话转录 | Agent 核心修复 |
| 5 | #7277 | v2026.2.2 | Agents: 调用 AbortSignal.any() 前验证 AbortSignal 实例 | 防止崩溃 |
| 6 | — | v2026.2.3 | Cron: 避免重复投递 | Cron 关键修复 |
| 7 | #9733, #9823, #9948, #9932 | v2026.2.6 | Cron: 修复调度和提醒投递回归 | 多个 Cron 回归 |
| 8 | #8928, #8391 | v2026.2.6 | Compaction/errors: 上下文溢出时允许多次压缩重试 | 影响长对话 |
| 9 | #1879 | v2026.2.9 | Model failover: 将 HTTP 400 错误视为可故障转移 | 模型可靠性 |
| 10 | #2078 | v2026.2.9 | Errors: 防止误判上下文溢出检测 | 防止假阳性错误 |
| 11 | #12283 | v2026.2.9 | Gateway: 消除压缩后失忆 | **重要** — 压缩后丢失上下文 |
| 12 | #11579 | v2026.2.9 | Agents: 从过大工具结果导致的上下文溢出中恢复 | Agent 稳定性 |
| 13 | #12124 | v2026.2.9 | Cron tool: LLM 省略 job 包装时恢复扁平参数 | Cron 稳定性 |
| 14 | #9295 | v2026.2.9 | Hooks: 修复自 2026.2.2 以来损坏的捆绑 hooks | **重要回归** |
| 15 | #14486 | v2026.2.12 | Gateway: 提高 WS payload/buffer 限制使 5MB 图片附件工作 | 影响图片发送 |
| 16 | #13931 | v2026.2.12 | Gateway: 重启前清空活跃轮次 | 防止数据丢失 |
| 17 | #13414 | v2026.2.12 | Gateway: 处理 stdout/stderr 上的异步 EPIPE | 防止崩溃 |
| 18 | #14068 | v2026.2.12 | Cron: 防止 cron 任务跳过执行 | Cron 关键修复 |
| 19 | #14233 | v2026.2.12 | Cron: onTimer 执行期间触发时重新武装计时器 | Cron 可靠性 |
| 20 | #14256 | v2026.2.12 | Cron: 防止重复触发 | Cron 可靠性 |
| 21 | #14385 | v2026.2.12 | Cron: 隔离调度器错误 | 防止调度器级联故障 |
| 22 | #13878 | v2026.2.12 | Cron: 防止一次性 at 任务重复触发 | Cron 可靠性 |
| 23 | #14901 | v2026.2.12 | Heartbeat: 防止调度器停滞 | 心跳核心修复 |
| 24 | #13565 | v2026.2.12 | Agents: 防止文件描述符泄漏 | **重要** — 内存/资源泄漏 |
| 25 | #13514 | v2026.2.12 | Agents: 防止缓存 TTL 导致的双重压缩 | Agent 稳定性 |
| 26 | #15636 | v2026.2.13 | Outbound: 添加带崩溃恢复的预写投递队列 | **关键** — 消息丢失防护 |
| 27 | #11052 | v2026.2.13 | macOS Voice Wake: 修复 CJK/Unicode 触发词裁剪崩溃 | **中文用户关键** — CJK 字符问题 |
| 28 | #15108 | v2026.2.13 | Heartbeat: 防止调度器静默死亡竞态 | 心跳稳定性 |
| 29 | #16156, #15750, #16694 | v2026.2.14 | Cron: 多个 bug 修复 | Cron 批量修复 |
| 30 | #16729 | v2026.2.14 | Gateway/Subagents: 保留排队的 announce 项目 | 防止消息丢失 |
| 31 | #16576 | v2026.2.14 | Gateway/Sessions: sessions.reset 前中止活跃嵌入运行 | 会话稳定性 |
| 32 | #16331 | v2026.2.14 | Agents: 在嵌入 session.compact() 周围添加安全超时 | 防止挂起 |
| 33 | #16131, #16539, #16457, #9855, #10210, #16717, #16191, #16222 | v2026.2.14 | Agents: 多个修复 | Agent 批量修复 |
| 34 | #6629 | v2026.2.14 | Auto-reply/Memory: 限制 ABORT_MEMORY 增长 | **内存泄漏修复** |
| 35 | #5140 | v2026.2.14 | Outbound/Memory: 限制目录缓存增长 | **内存泄漏修复** |

---

## P2-CORE-FEATURE

| # | PR/Issue | 版本 | 描述 | 备注 |
|---|----------|------|------|------|
| 1 | — | v2026.2.1 | Agents: 更新 pi-ai 到 0.50.9，重命名 cacheControlTtl → cacheRetention | API 变更 |
| 2 | — | v2026.2.1 | Agents: 扩展 CreateAgentSessionOptions，含 systemPrompt/skills/contextFiles | Agent 扩展性 |
| 3 | #3705 | v2026.2.1 | Gateway: 向 agent 和 chat.send 消息注入时间戳 | 消息追踪 |
| 4 | #5706 | v2026.2.1 | Auto-reply: /new 问候提示中避免引用 workspace 文件 | UX 改善 |
| 5 | — | v2026.2.1 | Tools: 对齐工具执行适配器/签名 | 工具核心 |
| 6 | — | v2026.2.1 | Tools: 将 `"*"` 工具白名单条目视为有效 | 工具核心 |
| 7 | #5332 | v2026.2.1 | Memory search: L2-normalize 本地嵌入向量 | 记忆搜索质量 |
| 8 | — | v2026.2.1 | Agents: 对齐嵌入运行器与 pi-coding-agent API 更新 | Agent 核心 |
| 9 | — | v2026.2.2 | Web UI: 添加 Agent 仪表板 (管理文件、工具、技能、模型、渠道、cron) | **重要功能** |
| 10 | #7372 | v2026.2.2 | Config: 允许设置默认子 agent 思考级别 | 配置增强 |
| 11 | #7475 | v2026.2.2 | Media understanding: 跳过文件文本提取中的二进制媒体 | 媒体处理 |
| 12 | #9001 | v2026.2.3 | Messages: 添加每渠道和每账户 responsePrefix 覆盖 | 消息定制 |
| 13 | — | v2026.2.3 | Cron: 添加 announce 投递模式用于隔离任务 | Cron 功能 |
| 14 | — | v2026.2.3 | Cron: 隔离任务默认 announce 投递；接受 ISO 8601 | Cron 改进 |
| 15 | — | v2026.2.3 | Cron: 硬迁移隔离任务到 announce/none 投递 | Cron 迁移 |
| 16 | — | v2026.2.3 | Cron: 成功后默认删除一次性任务 | Cron 改进 |
| 17 | — | v2026.2.3 | Cron: announce 投递期间抑制消息工具 | Cron 改进 |
| 18 | #8702 | v2026.2.3 | Heartbeat: 允许多账户渠道的显式 accountId 路由 | 多账户支持 |
| 19 | — | v2026.2.3 | Cron: 接受 epoch 时间戳和 0ms 持续时间 | Cron 改进 |
| 20 | — | v2026.2.3 | Cron: store 文件重建时重新加载 store 数据 | Cron 可靠性 |
| 21 | #8540 | v2026.2.3 | Cron: 直接投递 announce 运行 | Cron 改进 |
| 22 | #10072 | v2026.2.6 | Web UI: 添加 token 使用量仪表板 | **有用功能** — 成本追踪 |
| 23 | #10000 | v2026.2.6 | Sessions: 限制 sessions_history 负载 | 性能改进 |
| 24 | #10146 | v2026.2.6 | Update: 在更新流中加固 Control UI 资产处理 | 更新可靠性 |
| 25 | #9903 | v2026.2.6 | Exec approvals: 将裸字符串白名单条目强制转为对象 | 兼容性 |
| 26 | #11045 | v2026.2.9 | Gateway: 为 web UI 添加 agent 管理 RPC 方法 | Web UI 后端 |
| 27 | #1835 | v2026.2.9 | Agents: 在 agent 信封中包含运行时 shell | Agent 扩展 |
| 28 | #12091 | v2026.2.9 | Paths: 添加 OPENCLAW_HOME 用于覆盖主目录 | 部署灵活性 |
| 29 | #12419 | v2026.2.9 | Tools/web_search: 缓存键中包含提供商特定设置 | 搜索缓存 |
| 30 | #11523 | v2026.2.9 | Gateway: 修复多 agent sessions.usage 发现 | 多 agent 修复 |
| 31 | #11664 | v2026.2.9 | Subagents/compaction: 稳定 announce 时序 | 子 agent 稳定性 |
| 32 | #11641 | v2026.2.9 | Cron: 共享隔离 announce 流并加固调度 | Cron 稳定性 |
| 33 | #11448 | v2026.2.9 | Gateway/CLI: gateway.bind=lan 时使用 LAN IP | 网络配置 |
| 34 | #11372 | v2026.2.9 | Routing: 每条消息刷新绑定 | 路由可靠性 |
| 35 | #5516 | v2026.2.9 | Config: 将 maxTokens 限制到 contextWindow | 配置健壮性 |
| 36 | #12125 | v2026.2.9 | Paths: 结构化解析 OPENCLAW_HOME 派生路径 | 路径处理 |
| 37 | #4824 | v2026.2.9 | State dir: 尊重 OPENCLAW_STATE_DIR | 路径配置 |
| 38 | #14006 | v2026.2.12 | Config: 避免脱敏 maxTokens 类字段 | 配置修复 |
| 39 | — | v2026.2.12 | **BREAKING** Hooks: POST /hooks/agent 默认拒绝 sessionKey 覆盖 | **破坏性变更需验证** |
| 40 | #13813 | v2026.2.12 | Gateway: 安装期间自动生成 auth token | 安装改善 |
| 41 | #13809 | v2026.2.12 | Gateway: 防止 auth config 中未定义/缺失 token | 配置健壮性 |
| 42 | #14919 | v2026.2.12 | Gateway/Control UI: 解决全局安装的缺失仪表板资产 | 安装修复 |
| 43 | #13983 | v2026.2.12 | Cron: 隔离任务 auth 解析使用请求的 agentId | Cron 修复 |
| 44 | #14140 | v2026.2.12 | Cron: 传递 agentId 到 runHeartbeatOnce | Cron 修复 |
| 45 | #14983 | v2026.2.12 | Cron: 尊重存储的 session 模型覆盖 | Cron 修复 |
| 46 | #13317 | v2026.2.12 | Heartbeat: 过滤噪声系统事件 | 心跳改善 |
| 47 | #14399 | v2026.2.12 | Media: 剥离含本地路径的 MEDIA: 行 | 媒体处理 |
| 48 | #13342 | v2026.2.12 | Config/Cron: 从脱敏中排除 maxTokens | 配置修复 |
| 49 | #13460 | v2026.2.12 | Config: 在 watcher 中忽略 meta 字段变更 | 配置稳定性 |
| 50 | #13805 | v2026.2.12 | Agents: 上下文显示使用最后 API 调用的缓存 token | UX 改善 |
| 51 | #14979 | v2026.2.12 | Agents: 保持 followup-runner session totalTokens 对齐 | Token 计数准确性 |
| 52 | #14882 | v2026.2.12 | Hooks/Plugins: 接线 9 个先前未接线的插件生命周期 hooks | **插件系统完善** |
| 53 | #15012 | v2026.2.12 | Hooks/Tools: 分发 before_tool_call 和 after_tool_call hooks | **插件系统完善** |
| 54 | #14976 | v2026.2.13 | Auto-reply/Threading: 自动注入隐式回复线程 | 回复改善 |
| 55 | #14948 | v2026.2.13 | Outbound/Threading: 从消息发送工具传递 replyTo 和 threadId | 线程支持 |
| 56 | #11916 | v2026.2.13 | Auto-reply/Media: 允许纯图片入站消息 | 媒体处理 |
| 57 | #12237 | v2026.2.13 | Media: 将 text/* MIME 类型分类为文档 | 媒体分类 |
| 58 | #15195 | v2026.2.13 | Gateway/Restart: SIGUSR1 后清除陈旧命令队列状态 | 网关稳定性 |
| 59 | #14527 | v2026.2.13 | Heartbeat: 允许显式唤醒和 hook 唤醒原因 | 心跳功能 |
| 60 | #15847 | v2026.2.13 | Auto-reply/Heartbeat: 剥离句末 HEARTBEAT_OK 令牌 | 输出清理 |
| 61 | #11766 | v2026.2.13 | Agents/Heartbeat: 停止自动创建 HEARTBEAT.md | 行为修正 |
| 62 | #15141 | v2026.2.13 | Sessions/Agents: 解析转录路径时传递 agentId | 多 agent |
| 63 | #15103 | v2026.2.13 | Sessions/Agents: 通过 status 和 usage 路径传递 agentId | 多 agent |
| 64 | #14869 | v2026.2.13 | Sessions: /new 和 /reset 时存档先前转录文件 | 会话管理 |
| 65 | #15114 | v2026.2.13 | Status/Sessions: 停止钳制派生 totalTokens | 准确计数 |
| 66 | #12906 | v2026.2.13 | CLI: 延迟加载 outbound provider dependencies | 启动性能 |
| 67 | #15274 | v2026.2.13 | Routing: 强制严格绑定范围匹配 | 路由可靠性 |
| 68 | #13811 | v2026.2.13 | Exec/Allowlist: 允许多行 heredoc 内容 | 执行改善 |
| 69 | #11560 | v2026.2.13 | Config: 写入配置时保留 ${VAR} 环境变量引用 | 配置正确性 |
| 70 | — | v2026.2.13 | Config: 记录覆盖审计条目 | 审计 |
| 71 | #13185 | v2026.2.13 | Gateway/Tools Invoke: 清理执行失败 | 网关改善 |
| 72 | #15848 | v2026.2.13 | Gateway/Hooks: 保留 hook request-body 超时的 408 | Hook 改善 |
| 73 | #15635 | v2026.2.13 | Plugins/Hooks: before_tool_call hook 精确触发一次 | Hook 修复 |
| 74 | #15279 | v2026.2.13 | Agents/Transcript policy: 清理 OpenAI/Codex tool-call ids | Agent 兼容性 |
| 75 | #11770 | v2026.2.13 | Agents/Image tool: 限制图像分析完成 maxTokens | 成本控制 |
| 76 | #15833 | v2026.2.13 | Agents/Compaction: 集中 exec 默认解析 | Agent 改善 |
| 77 | #11450 | v2026.2.13 | Gateway/Agents: 停止注入幻影主 agent | 多 agent 修复 |
| 78 | #15138 | v2026.2.13 | Sandbox: 传递配置的 sandbox.docker.env 变量 | 沙箱改善 |
| 79 | #15368 | v2026.2.13 | Cron: 隔离 announce 投递中尊重 deleteAfterRun | Cron 修复 |
| 80 | #15376 | v2026.2.13 | Web tools/web_fetch: 优先 text/markdown 响应 | 工具改善 |
| 81 | #8930 | v2026.2.13 | Agents: 添加预提示上下文诊断 | 调试功能 |
| 82 | #16288 | v2026.2.14 | Sessions/Agents: 加固转录路径解析 | 会话安全/稳定 |
| 83 | #6036 | v2026.2.14 | Gateway/Memory: 清理 agentRunSeq 追踪 | 内存管理 |
| 84 | #6760 | v2026.2.14 | Skills/Memory: 从远程技能缓存中移除断连节点 | 缓存管理 |
| 85 | #16379 | v2026.2.14 | Sandbox/Tools: 使沙箱文件工具感知 bind-mount | 沙箱改善 |
| 86 | #11721 | v2026.2.14 | Memory/Builtin: 内置记忆修复 | 记忆修复 |

---

## P3-MODEL-SUPPORT

| # | PR/Issue | 版本 | 描述 | 备注 |
|---|----------|------|------|------|
| 1 | — | v2026.2.1 | Auth: 更新 MiniMax OAuth 提示 + portal auth 备注 | MiniMax 中国用户常用 |
| 2 | #7914 | v2026.2.3 | Onboarding: 添加 Cloudflare AI Gateway 提供商设置 | 提供商选项 |
| 3 | #7180 | v2026.2.3 | Onboarding: 添加 Moonshot (.cn) auth 选择，保留中国 base URL | **中国用户高度相关** — Moonshot/月之暗面 |
| 4 | #9853, #10720, #9995 | v2026.2.6 | Models: 支持 Anthropic Opus 4.6 和 OpenAI Codex gpt-5.3-codex | **重要** — 最新模型支持 |
| 5 | #9885 | v2026.2.6 | Providers: 添加 xAI (Grok) 支持 | 新提供商 |
| 6 | #7078 | v2026.2.6 | Memory: 原生 Voyage AI 支持 | 嵌入提供商 |
| 7 | — | v2026.2.6 | Agents: 升级 pi-mono 到 0.52.7；Opus 4.6 前向兼容 | 模型兼容性 |
| 8 | #12419 | v2026.2.9 | Tools: 添加 Grok (xAI) 作为 web_search 提供商 | 搜索提供商 |
| 9 | #12795 | v2026.2.9 | Tools/web_search: 规范化直接 Perplexity 模型 ID | 搜索模型 |
| 10 | #11646 | v2026.2.9 | Thinking: 为 github-copilot 模型允许 xhigh | 模型选项 |
| 11 | #10818 | v2026.2.9 | Memory: 设置 Voyage embeddings input_type | 嵌入修复 |
| 12 | #13456 | v2026.2.12 | Onboarding/Providers: 添加 Z.AI 端点特定 auth 选择 | **中国用户相关** — 智谱 AI |
| 13 | #14865 | v2026.2.12 | Onboarding/Providers: 更新 MiniMax API 默认模型 | MiniMax 中国用户常用 |
| 14 | #14131 | v2026.2.12 | Ollama: 使用配置的 baseUrl 进行模型发现 | Ollama 本地部署 |
| 15 | #14218 | v2026.2.12 | Antigravity: 添加 opus 4.6 前向兼容 | 模型兼容 |
| 16 | #15867 | v2026.2.13 | Agents: 为 hf:zai-org/GLM-5 添加合成目录支持 | **中国用户高度相关** — 智谱 GLM-5 |
| 17 | #13472 | v2026.2.13 | Onboarding/Providers: 添加 Hugging Face Inference 提供商支持 | 新提供商 |
| 18 | #15275 | v2026.2.13 | Providers/MiniMax: 将隐式 provider 从 openai-completions 切换到 anthropic-messages | MiniMax **中国用户相关** |
| 19 | #14990, #15174 | v2026.2.13 | OpenAI Codex/Spark: 实现 gpt-5.3-codex-spark 支持 | 新模型 |
| 20 | #15406 | v2026.2.13 | Auth/OpenAI Codex: 共享 OAuth 登录处理 | 认证改善 |
| 21 | #12577 | v2026.2.13 | Onboarding/Providers: 添加 vLLM 作为 onboarding 提供商 | 本地部署相关 |
| 22 | #11853 | v2026.2.13 | Ollama/Agents: 使用解析的 model/provider base URLs 进行原生流式 | Ollama 修复 |
| 23 | #15429 | v2026.2.13 | Memory: 默认本地嵌入模型切换到 QAT 变体 | 嵌入模型更新 |

---

## P4-CHANNEL-FIX

> 仅列出 **已使用渠道** (Telegram, Discord, WhatsApp, Slack, Signal, Feishu, Web UI, TUI) 的修复。

| # | PR/Issue | 版本 | 描述 | 渠道 | 备注 |
|---|----------|------|------|------|------|
| 1 | #6127 | v2026.2.1 | 使用共享 pairing store | Telegram | — |
| 2 | — | v2026.2.1 | 精细化聊天布局 + 延长会话活跃时长 | Web UI | — |
| 3 | #6914 | v2026.2.1 | 为文件获取添加下载超时 | Telegram | — |
| 4 | #6833 | v2026.2.1 | 对 DM vs 论坛发送强制线程规范 | Telegram | — |
| 5 | #6639 | v2026.2.1 | 加固媒体获取限制和文件 URL 验证 | Slack | — |
| 6 | #5838 | v2026.2.1 | 为白名单解析 PluralKit 代理发送者 | Discord | — |
| 7 | #3892 | v2026.2.1 | 为路由继承线程父绑定 | Discord | — |
| 8 | #7226 | v2026.2.2 | 流式传输期间尊重用户滚动位置 | Web UI | — |
| 9 | — | v2026.2.2 | 阻止 TUI 活跃时的 onboarding 输出 | TUI | — |
| 10 | — | v2026.2.2 | 正确解析 Control UI 资产路径 | Web UI | — |
| 11 | — | v2026.2.2 | 外部编辑后刷新 agent 文件 | Web UI | — |
| 12 | #8432 | v2026.2.3 | 处理非流式最终消息，刷新历史 | TUI/Gateway | — |
| 13 | #8193 | v2026.2.3 | 内联模型选择中尊重 session 模型覆盖 | Telegram | — |
| 14 | — | v2026.2.3 | 修复 agent 模型选择保存 | Web UI | — |
| 15 | #7178 | v2026.2.3 | 设置 basePath 时解析 header logo 路径 | Web UI | — |
| 16 | #8392 | v2026.2.3 | 包含 forward_from_chat 元数据 | Telegram | 转发消息支持 |
| 17 | #7235 | v2026.2.6 | 在消息工具 + 子 agent announce 中自动注入 DM topic threadId | Telegram | — |
| 18 | #9971 | v2026.2.6 | 为 /new 和 /reset 添加 mention stripPatterns | Slack | — |
| 19 | #11341 | v2026.2.9 | 在聊天历史中显示压缩分隔符 | Web UI | UX 改善 |
| 20 | #12156 | v2026.2.9 | 加固引用解析；保留引用上下文 | Telegram | — |
| 21 | #11620 | v2026.2.9 | 陈旧 topic thread ID 时恢复主动发送 | Telegram | — |
| 22 | #11543 | v2026.2.9 | 用 `<tg-spoiler>` 渲染 markdown spoilers | Telegram | — |
| 23 | #12356 | v2026.2.9 | 将命令注册截断到 100 条 | Telegram | — |
| 24 | #12779 | v2026.2.9 | DM allowFrom 匹配发送者 user id | Telegram | — |
| 25 | #10062 | v2026.2.9 | 支持论坛/媒体线程创建起始消息 | Discord | — |
| 26 | #14608 | v2026.2.12 | 将 blockquotes 渲染为原生 `<blockquote>` 标签 | Telegram | 格式改善 |
| 27 | #14285 | v2026.2.12 | 转换 Markdown 粗体/删除线到 WhatsApp 格式 | WhatsApp | 格式改善 |
| 28 | #14408 | v2026.2.12 | 允许纯媒体发送，规范化前导空负载 | WhatsApp | — |
| 29 | #14444 | v2026.2.12 | 语音消息的默认 MIME 类型 | WhatsApp | — |
| 30 | #14397 | v2026.2.12 | 模型选择器中处理无文本消息 | Telegram | — |
| 31 | #14340 | v2026.2.12 | 将 REACTION_INVALID 显示为非致命警告 | Telegram | — |
| 32 | #14364 | v2026.2.12 | 默认 replyToMode 从 "off" 改为 "all" | Slack | 行为变更 |
| 33 | #14142 | v2026.2.12 | 渠道消息以 bot mention 开头时检测控制命令 | Slack | — |
| 34 | #15063 | v2026.2.12 | 强制 E.164 验证 | Signal | — |
| 35 | #10418 | v2026.2.12 | 处理 DM 反应 | Discord | — |
| 36 | #11062 | v2026.2.12 | 在线程中尊重 replyToMode | Discord | — |
| 37 | #2013 | v2026.2.12 | 渲染 mention 占位符 | Signal | — |
| 38 | #9507 | v2026.2.12 | 纯媒体消息省略空内容字段 | Discord | — |
| 39 | #10345 | v2026.2.12 | 直接将 Buffer 传递给 SDK upload API | Feishu | 需与本地飞书自定义对比 |
| 40 | #11088 | v2026.2.12 | 仅在 bot 被 mention 时触发 mention 门控群组处理 | Feishu | 需与本地飞书自定义对比 |
| 41 | #11233 | v2026.2.12 | probe status 使用解析的账户上下文 | Feishu | 需与本地飞书自定义对比 |
| 42 | #13994 | v2026.2.12 | 保留顶级转换块顺序 | Feishu DocX | 飞书文档处理 |
| 43 | #14423 | v2026.2.12 | 移除 workspace:* 依赖 | Feishu 插件打包 | **重要** — 与本地依赖替换相关 |
| 44 | #5542 | v2026.2.12 | 允许 channel-edit 归档/锁定线程 | Discord | — |
| 45 | #7253 | v2026.2.13 | 发送带波形预览的语音消息 | Discord | — |
| 46 | #10855 | v2026.2.13 | 添加可配置的 presence 状态/活动 | Discord | — |
| 47 | #15775 | v2026.2.13 | 添加线程所有权出站门控 | Slack/Plugins | — |
| 48 | #8302 | v2026.2.13 | 将 autoThread 回复路由到现有线程 | Discord | — |
| 49 | #15437 | v2026.2.13 | 向 DOMPurify 允许标签添加 img | Web UI | — |
| 50 | #15438 | v2026.2.13 | 将 MP3 和 M4A 视为语音兼容 | Telegram/Matrix | — |
| 51 | #15594 | v2026.2.13 | 保留出站文档文件名 | WhatsApp | — |
| 52 | #15844 | v2026.2.13 | 将 bot 菜单注册限制为 100 命令 | Telegram | — |
| 53 | #15599 | v2026.2.13 | 将技能命令限定到解析的 agent | Telegram | — |
| 54 | #12326 | v2026.2.13 | 避免数字 guild 白名单条目的错误路由 | Discord | — |
| 55 | #11547 | v2026.2.13 | 保留字面量 \n 序列 | Inbound/Web UI | — |
| 56 | #15452 | v2026.2.13 | 保留更丰富的流式 assistant 文本 | TUI/Streaming | TUI 流式改善 |
| 57 | #15443 | v2026.2.13 | 在非 x64 Linux 上通过 Homebrew 自动安装 signal-cli | Signal/Install | — |
| 58 | #11224 | v2026.2.13 | 应用渠道/群组 historyLimit | Discord/Agents | — |
| 59 | #13578 | v2026.2.13 | WhatsApp/Twitch/Google Chat 回退采用 fail closed | Outbound | WhatsApp 相关 |
| 60 | #5258 | v2026.2.14 | 限制 thread-starter 缓存增长 | Slack/Memory | 内存管理 |
| 61 | #10704, #6958, #13007, #5355, #16750 | v2026.2.14 | 多个稳定性/渲染修复 | TUI | TUI 批量修复 |
| 62 | — | v2026.2.14 | 传递显式 reset 原因 | TUI/Hooks | — |
| 63 | #16714 | v2026.2.14 | 各种修复 | Discord | — |
| 64 | #16763 | v2026.2.14 | 设置 webhook 回调超时处理 | Telegram | — |
| 65 | #16748 | v2026.2.14 | 保留大小写敏感的 group: 目标 ID | Signal | — |

---

## P5-NICE-TO-HAVE

| # | PR/Issue | 版本 | 描述 | 备注 |
|---|----------|------|------|------|
| 1 | #3050 等 21 个 | v2026.2.1 | 文档更新 (批量) | 可选同步 |
| 2 | — | v2026.2.1 | Agents: OpenRouter 归属头应用于嵌入运行器 | OpenRouter 用户 |
| 3 | — | v2026.2.1 | Agents: 添加 OpenRouter 应用归属头 | OpenRouter 用户 |
| 4 | #5723, #5807 | v2026.2.1 | CI: 添加合规和别名一致性检查 | CI 改善 |
| 5 | #4502 | v2026.2.1 | Skills: 更新 session-logs 路径 (.clawdbot → .openclaw) | 品牌重命名路径，fork 有自己路径 |
| 6 | #5815 | v2026.2.1 | Process: 解决 Windows spawn() 失败 | Windows 非主要平台 |
| 7 | #8202 等 | v2026.2.2 | Docs: zh-CN 翻译种子 + 优化 | fork 有自己翻译 |
| 8 | — | v2026.2.2 | Onboarding: 保持 TUI 流独占 | 引导改善 |
| 9 | — | v2026.2.2 | CLI/Zsh completion: 在 state dir 缓存脚本 | CLI 改善 |
| 10 | #6619 | v2026.2.2 | Tests: 桩 SSRF DNS pinning | 测试改善 |
| 11 | #9206, #9180, #9077 | v2026.2.3 | Telegram: 从 bot 文件移除 @ts-nocheck | 代码质量 |
| 12 | #7737 | v2026.2.3 | Docs: 澄清 TUI 的 tmux send-keys | 文档 |
| 13 | #8994 | v2026.2.3 | Docs: zh-CN 镜像着陆页改版 | fork 有自己翻译 |
| 14 | — | v2026.2.3 | Web UI: 为新消息指示器应用按钮样式 | UX 细节 |
| 15 | #8484 | v2026.2.3 | Onboarding: 从非交互 API key flags 推断 auth 选择 | 引导改善 |
| 16 | — | v2026.2.3 | Shell completion: 自动检测和迁移慢动态模式 | CLI 改善 |
| 17 | — | v2026.2.3 | macOS: 修复 cron 负载摘要渲染 | macOS 细节 |
| 18 | #8068 | v2026.2.6 | CLI: 按字母排序命令 | CLI UX |
| 19 | #8914 | v2026.2.6 | Chrome extension: 修复捆绑路径解析 | Chrome 扩展 |
| 20 | #11756 | v2026.2.9 | iOS: alpha 节点应用 + setup-code 引导 | iOS alpha |
| 21 | #11755 | v2026.2.9 | Plugins: 设备配对 + 手机控制插件 | 新插件 |
| 22 | — | v2026.2.9 | Onboarding: QuickStart 自动安装 shell 补全 | 引导改善 |
| 23 | — | v2026.2.9 | Auth: 剥离粘贴 API key 中的嵌入换行 | UX 修复 |
| 24 | — | v2026.2.9 | Web UI: 平滑滚动聊天刷新 | UX 细节 |
| 25 | #11937 | v2026.2.9 | Exec approvals: 用等宽字体渲染转发命令 | UX 细节 |
| 26 | #10982 | v2026.2.9 | Media understanding: 识别 .caf 音频附件 | 媒体格式 |
| 27 | #13818 | v2026.2.12 | CLI: 添加 openclaw logs --local-time | CLI 功能 |
| 28 | #14771 | v2026.2.12 | Logging/CLI: 使用本地时区时间戳 | 日志 UX |
| 29 | — | v2026.2.12 | Logging/Browser: 临时路径回退到 os.tmpdir | 日志修复 |
| 30 | #14156 | v2026.2.12 | CLI/Wizard: 取消向导时以 code 1 退出 | CLI 修复 |
| 31 | #14343 | v2026.2.12 | Daemon: 重启 LaunchAgent 时抑制 EPIPE 错误 | macOS 细节 |
| 32 | #14029 | v2026.2.12 | Voice Call: 通过 Parameter 传递 Twilio stream auth token | 语音通话 |
| 33 | — | v2026.2.13 | Skills: 移除重复的 local-places Google Places 技能 | 清理 |
| 34 | — | v2026.2.13 | Onboarding/CLI: 恢复终端状态不恢复暂停的 stdin | 引导修复 |
| 35 | #15481 | v2026.2.13 | CLI/Completion: 路由 plugin-load 日志到 stderr | CLI 修复 |
| 36 | #5042 | v2026.2.13 | Config: 保持旧音频转写迁移严格 | 兼容性 |
| 37 | #14998 | v2026.2.13 | Config: 在配置文件中接受 $schema key | 配置格式 |
| 38 | — | v2026.2.13 | Process/Exec: Windows 上 .exe 避免 shell 执行 | Windows |
| 39 | #15892 | v2026.2.13 | Voice Call: 路由 webhook 运行时事件处理 | 语音通话 |
| 40 | #15737 | v2026.2.13 | Cron: 添加 announce 模式隔离任务的回归覆盖 | 测试 |
| 41 | #15157 | v2026.2.13 | Docs/Mermaid: 移除硬编码 Mermaid init 主题块 | 文档 |
| 42 | #16395 | v2026.2.14 | Models/CLI: 守护 models status 字符串修剪 | CLI 修复 |
| 43 | #11325 | v2026.2.14 | Skills: 仅刷新时监视 SKILL.md | 性能 |
| 44 | #5136 | v2026.2.14 | Diagnostics/Memory: 修剪陈旧诊断会话状态 | 诊断 |

---

## SKIP

> 不适用的项目：已合并 PR、未使用渠道专属修复（不含安全）、已本地实现的功能。

| # | PR/Issue | 版本 | 描述 | 跳过原因 |
|---|----------|------|------|----------|
| 1 | #5926 | v2026.2.1 | Tlon: 为 SSE 客户端 fetch 添加超时 | 未使用渠道 (Tlon) |
| 2 | #3160 | v2026.2.2 | Memory: 实现 opt-in QMD 后端 | 已本地实现 QMD |
| 3 | — | v2026.2.2 | Docs: 完成 QMD 内存文档重命名 | 已本地实现 QMD |
| 4 | #7313 | v2026.2.2 | Feishu: 添加 Feishu/Lark 插件支持 + 文档 | 已深度自定义飞书插件，需评估上游差异 |
| 5 | #11093 | v2026.2.9 | Channels: 全面 BlueBubbles 和渠道清理 | BlueBubbles 未使用（通用清理部分可能需要） |
| 6 | #15436 | v2026.2.13 | MS Teams: 保留解析的 mention 实体 | 未使用渠道 (MS Teams) |
| 7 | #14962 | v2026.2.13 | Mattermost: 重试 websocket 监控连接 | 未使用渠道 (Mattermost) |
| 8 | #10863, #16740, #12919, #11302 | v2026.2.14 | Memory/QMD: 多个 QMD 修复 | 已本地实现 QMD — 需对比评估是否有价值的修复 |

---

## 合并策略建议

### 第一批 (立即合并 — 安全)
**P0-SECURITY** 全部 88 项。建议使用 `git cherry-pick` 逐个合并，因为安全修复通常为小范围补丁。优先处理：
- **#76** SSRF IPv4-mapped IPv6 绕过修复 — 通用网络层漏洞
- **#51** 飞书 SSRF 加固 — 飞书为核心渠道
- **#65-66** Telegram 安全修复 — Telegram 为核心渠道
- **#36** WhatsApp creds.json 权限修复

### 第二批 (关键 bug)
**P1-CRITICAL-BUG** 全部 35 项。按影响范围排序：
- **#11, #26** 压缩后失忆 + 崩溃恢复投递队列 — 消息丢失防护
- **#24, #25** Agent 文件描述符泄漏 + 双重压缩 — 资源泄漏
- **#27** CJK/Unicode 触发词裁剪崩溃 — **中国用户直接受影响**
- **#34, #35** 内存增长限制 — 长期运行稳定性

### 第三批 (核心功能)
**P2-CORE-FEATURE** 选择性合并。高优先级：
- **#9** Web UI Agent 仪表板
- **#22** Token 使用量仪表板 — 成本追踪
- **#39** BREAKING: hooks sessionKey 变更 — 需兼容性检查
- **#52, #53** 插件生命周期 hooks 接线 — 飞书插件可能受益

### 第四批 (模型支持)
**P3-MODEL-SUPPORT** 高优先级子集：
- **#3** Moonshot (.cn) — 月之暗面，中国用户必须
- **#4** Opus 4.6 + gpt-5.3-codex — 最新模型
- **#12** Z.AI — 智谱 AI，中国用户重要
- **#16** GLM-5 — 智谱 GLM-5，中国用户重要
- **#18** MiniMax provider 切换 — 中国用户常用

### 注意事项

1. **飞书冲突**: #10345, #11088, #11233, #13994, #14423 需要与本地深度自定义逐一对比，可能需要手动合并。
2. **QMD 冲突**: 已本地实现 QMD，上游 QMD 修复 (#10863, #16740, #12919, #11302) 需评估是否包含本地实现中缺少的修复。
3. **路径/品牌名**: 上游使用 `.openclaw`，fork 使用 `.clawdbot-cn`，涉及路径的 PR 需要调整。
4. **依赖替换**: #14423 (Feishu 移除 workspace:* 依赖) 与本地 GitHub deps → npm 替换策略一致，应优先合并。
5. **破坏性变更**: v2026.2.12 的 hooks sessionKey 变更需要验证不影响现有集成。
