---
summary: "解决 Web UI 配对要求问题 (disconnected 1008: pairing required)"
read_when:
  - 在容器化部署中遇到 pairing required 错误时
  - Docker/Kubernetes 中 Web 界面无法连接时
---

# 解决 Web UI 配对要求问题

当您在 **容器化部署**（Docker、Kubernetes 等）中访问 Web 界面时，可能会遇到错误：

```
disconnected (1008): pairing required
```

这个错误通常 **不会** 出现在本地直接运行的部署中，因为本地连接被自动识别为可信。

## 问题描述

### 症状

- Web UI 立即断开连接，显示错误消息
- 浏览器控制台显示 WebSocket 关闭代码 `1008` 和原因 `pairing required`
- 但其他渠道（Feishu、Telegram、Discord 等）能正常工作
- 网关日志显示类似：`[ws] closed before connect ... reason=pairing required`

### 示例日志

```
openclaw-cn-gateway-1 | 2026-02-01T06:35:03.089Z [ws] closed before connect conn=823f4c49-... 
remote=192.168.65.1 origin=http://localhost:18789 reason=pairing required
```

## 根本原因

Web UI 连接的认证路径取决于连接如何到达网关：

| 部署方式 | WebSocket 源 | 识别方式 | 需要配对？ |
|---------|-----------|--------|----------|
| **本地直接运行** | localhost/127.0.0.1 | 真正的本地连接 | ❌ 不需要 |
| **Docker（同主机）** | 127.0.0.1（经容器栈） | 网络连接 | ✅ 需要配置 |
| **远程服务器** | LAN/Internet IP | 网络连接 | ✅ 需要配置 |
| **Kubernetes** | Pod 内部 DNS | 网络连接 | ✅ 需要配置 |

在容器化部署中，即使浏览器访问 `http://127.0.0.1:18789/`，WebSocket 连接也经过容器网络栈处理，因此被视为网络连接而触发严格的设备配对检查。

## 解决方案

### 方案 1：启用 Web UI 不安全认证（推荐）

这是最简单、最推荐的解决方案。它告诉网关允许基于令牌的 Web UI 认证，无需设备配对。

**本地部署：**
```bash
openclaw-cn config set gateway.controlUi.allowInsecureAuth true
openclaw-cn gateway restart
```

**Docker 部署：**
```bash
docker compose run --rm openclaw-cn-cli config set gateway.controlUi.allowInsecureAuth true
docker compose restart openclaw-cn-gateway
```

**手动编辑配置文件：**

编辑 `~/.openclaw/openclaw.json`，在 `gateway` 部分添加：

```json
{
  "gateway": {
    "port": 18789,
    "mode": "local",
    "bind": "loopback",
    "auth": {
      "mode": "token",
      "token": "your-token-here"
    },
    "controlUi": {
      "allowInsecureAuth": true
    }
  }
}
```

然后重启网关。

### 方案 2：使用 HTTPS + 设备认证

如果您在远程服务器上运行网关，最安全的方法是使用 HTTPS 和设备认证。

```bash
# 设置 Tailscale Serve（推荐用于远程）
openclaw-cn configure gateway.tailscale.serve

# 或配置反向代理使用 HTTPS
openclaw-cn config set gateway.controlUi.basePath https://your-domain.com
```

然后通过 HTTPS 访问 Web UI，浏览器将能够生成设备身份进行加密配对。

参见 [Tailscale](/gateway/tailscale) 和 [控制 UI](/web/control-ui)。

## 验证配置

确认配置已正确应用：

```bash
# 方法 1：检查配置值
openclaw-cn config get gateway.controlUi.allowInsecureAuth

# 方法 2：查看整个配置
openclaw-cn config get gateway.controlUi

# 方法 3：检查配置文件
cat ~/.openclaw/openclaw.json | grep -A 3 controlUi
```

应该看到 `allowInsecureAuth` 设置为 `true`。

### 网关重启检查

重启后，检查网关日志确认配置已加载：

```bash
# 本地
openclaw-cn logs --follow | grep -i "controlUi\|allow"

# Docker
docker compose logs -f openclaw-cn-gateway | grep -i "control"
```

然后尝试重新打开 Web UI（刷新浏览器）。

## 安全考量

### 为什么这是安全的？

1. **网络隔离**
   - `gateway.bind=loopback` 限制网关仅在本地监听
   - 容器内部部署不会暴露给外部网络
   - 仅具有网络访问权限的用户可以尝试连接

2. **令牌认证**
   - 即使启用 `allowInsecureAuth`，所有 Web UI 连接仍需有效令牌
   - 令牌由 `docker-setup.sh` 自动生成，不在日志中暴露
   - 无效或缺失令牌的请求被拒绝

3. **应用于 Web UI 仅**
   - `allowInsecureAuth` 仅影响 Web UI（Control UI）连接
   - 不影响其他渠道或 API 的认证
   - 设备配对仍对其他连接类型应用

### 何时不应使用

- ❌ **公网服务器**：如果网关直接暴露到互联网，不要启用此选项。改用 HTTPS + 设备认证。
- ❌ **共享主机**：如果多个用户可以访问本机，应使用设备认证进行更强的隔离。

## 常见场景

### 场景 1：Docker Compose 本地开发

```bash
# 一次性修复
docker compose run --rm openclaw-cn-cli config set gateway.controlUi.allowInsecureAuth true
docker compose restart openclaw-cn-gateway

# 然后在浏览器中打开
open http://127.0.0.1:18789/?token=$(cat ~/.openclaw/openclaw.json | jq -r '.gateway.auth.token')
```

### 场景 2：Kubernetes 部署

```bash
# 在 Pod 中执行
kubectl exec -it <pod> -- /bin/sh -c \
  'openclaw-cn config set gateway.controlUi.allowInsecureAuth true'

# 端口转发到本地
kubectl port-forward svc/openclaw-gateway 18789:18789

# 打开 Web UI
open http://127.0.0.1:18789/?token=...
```

### 场景 3：远程 VPS 部署

```bash
# SSH 到服务器
ssh user@vps-host

# 设置配置
openclaw-cn config set gateway.controlUi.allowInsecureAuth true
openclaw-cn gateway restart

# 从本地机器通过 SSH 隧道访问
ssh -L 18789:localhost:18789 user@vps-host

# 打开浏览器
open http://127.0.0.1:18789/?token=...
```

## 故障排除

### 仍然显示 "pairing required"

1. **确认网关已重启**
   ```bash
   openclaw-cn gateway status
   ```
   查看是否显示最近启动时间。

2. **检查配置文件**
   ```bash
   cat ~/.openclaw/openclaw.json | jq '.gateway.controlUi'
   ```
   应该看到 `{ "allowInsecureAuth": true }`

3. **查看网关日志**
   ```bash
   openclaw-cn logs | tail -50 | grep -i "control\|pairing"
   ```
   查找任何配置加载错误。

4. **清理浏览器缓存**
   - 清除浏览器缓存或使用无痕窗口
   - 尝试不同的浏览器

### Docker 中的权限错误

```bash
# 如果遇到权限错误，尝试显式指定用户
docker compose run --user node --rm openclaw-cn-cli config set gateway.controlUi.allowInsecureAuth true
```

## 相关文档

- [控制 UI](/web/control-ui)
- [网关认证](/gateway/authentication)
- [设备配对](/gateway/pairing)
- [令牌不匹配](/gateway/token-mismatch-troubleshooting)
- [Tailscale 集成](/gateway/tailscale)
- [Docker 部署](/install/docker)
