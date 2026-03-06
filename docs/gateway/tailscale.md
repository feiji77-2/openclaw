---
summary: "集成 Tailscale Serve/Funnel 用于网关仪表板"
read_when:
  - 将网关控制界面暴露到本地主机以外
  - 自动化尾网或公共仪表板访问
---
# Tailscale（网关仪表板）

openclaw-cn 可以为网关仪表板和 WebSocket 端口自动配置 Tailscale **Serve**（尾网）或 **Funnel**（公共）。
这使得网关绑定到回环，同时 Tailscale 提供 HTTPS、路由和（对于 Serve）身份头信息。

## 模式

- `serve`: 仅尾网 Serve，通过 `tailscale serve`。网关保持在 `127.0.0.1`。
- `funnel`: 通过 `tailscale funnel` 的公共 HTTPS。openclaw-cn 需要共享密码。
- `off`: 默认（无 Tailscale 自动化）。

## 认证

设置 `gateway.auth.mode` 来控制握手：

- `token`（当设置了 `OPENCLAW_GATEWAY_TOKEN` 时为默认）
- `password`（通过 `OPENCLAW_GATEWAY_PASSWORD` 或配置的共享密钥）

当 `tailscale.mode = "serve"` 且 `gateway.auth.allowTailscale` 为 `true` 时，
有效的 Serve 代理请求可以通过 Tailscale 身份头（`tailscale-user-login`）进行身份验证，
而无需提供令牌/密码。openclaw-cn 通过本地 Tailscale 守护程序（`tailscale whois`）
解析 `x-forwarded-for` 地址并在接受之前将其与头信息匹配来验证身份。
openclaw-cn 仅在从回环使用 Tailscale 的 `x-forwarded-for`、`x-forwarded-proto` 和 `x-forwarded-host`
头信息到达时将请求视为 Serve。
要要求显式凭据，请设置 `gateway.auth.allowTailscale: false` 或
强制 `gateway.auth.mode: "password"`。

## 配置示例

### 仅尾网（Serve）

```json5
{
  gateway: {
    bind: "loopback",
    tailscale: { mode: "serve" }
  }
}
```

打开：`https://<magicdns>/`（或您配置的 `gateway.controlUi.basePath`）

### 仅尾网（绑定到 Tailnet IP）

当您希望网关直接在 Tailnet IP 上监听时（无 Serve/Funnel）使用此方法。

```json5
{
  gateway: {
    bind: "tailnet",
    auth: { mode: "token", token: "your-token" }
  }
}
```

从另一个 Tailnet 设备连接：
- 控制界面：`http://<tailscale-ip>:18789/`
- WebSocket：`ws://<tailscale-ip>:18789`

注意：回环（`http://127.0.0.1:18789`）在此模式下**不**工作。

### 公共互联网（Funnel + 共享密码）

```json5
{
  gateway: {
    bind: "loopback",
    tailscale: { mode: "funnel" },
    auth: { mode: "password", password: "replace-me" }
  }
}
```

优先使用 `OPENCLAW_GATEWAY_PASSWORD` 而不是将密码提交到磁盘。

## CLI 示例

```bash
openclaw-cn gateway --tailscale serve
openclaw-cn gateway --tailscale funnel --auth password
```

## 注意事项

- Tailscale Serve/Funnel 需要安装并登录 `tailscale` CLI。
- `tailscale.mode: "funnel"` 拒绝启动，除非认证模式是 `password`，以避免公共暴露。
- 如果您希望 openclaw-cn 在关闭时撤消 `tailscale serve`
  或 `tailscale funnel` 配置，请设置 `gateway.tailscale.resetOnExit`。
- `gateway.bind: "tailnet"` 是直接 Tailnet 绑定（无 HTTPS，无 Serve/Funnel）。
- `gateway.bind: "auto"` 优先使用回环；如果需要仅 Tailnet，请使用 `tailnet`。
- Serve/Funnel 仅暴露 **网关控制界面 + WS**。节点通过
  相同的网关 WS 端点连接，因此 Serve 可用于节点访问。

## 浏览器控制服务器（远程网关 + 本地浏览器）

如果您在一台机器上运行网关但希望在另一台机器上驱动浏览器，请使用 **独立的浏览器控制服务器**
并通过 Tailscale **Serve**（仅尾网）发布：

```bash
# 在运行 Chrome 的机器上
openclaw-cn browser serve --bind 127.0.0.1 --port 18791 --token <token>
tailscale serve https / http://127.0.0.1:18791
```

然后将网关配置指向 HTTPS URL：

```json5
{
  browser: {
    enabled: true,
    controlUrl: "https://<magicdns>/"
  }
}
```

并使用相同的令牌从网关进行身份验证（优先使用环境变量）：

```bash
export OPENCLAW_BROWSER_CONTROL_TOKEN="<token>"
```

除非您明确希望公开暴露，否则避免为浏览器控制端点使用 Funnel。

## Tailscale 先决条件 + 限制

- Serve 要求为您的尾网启用 HTTPS；如果缺失，CLI 会提示。
- Serve 注入 Tailscale 身份头；Funnel 不注入。
- Funnel 要求 Tailscale v1.38.3+、MagicDNS、启用 HTTPS 和 funnel 节点属性。
- Funnel 仅支持 TLS 上的端口 `443`、`8443` 和 `10000`。
- macOS 上的 Funnel 需要开源 Tailscale 应用变体。

## 了解更多

- Tailscale Serve 概述：https://tailscale.com/kb/1312/serve
- `tailscale serve` 命令：https://tailscale.com/kb/1242/tailscale-serve
- Tailscale Funnel 概述：https://tailscale.com/kb/1223/tailscale-funnel
- `tailscale funnel` 命令：https://tailscale.com/kb/1311/tailscale-funnel
