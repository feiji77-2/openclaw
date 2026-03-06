---
summary: "解决网关令牌不匹配问题 (disconnected 1008: unauthorized: gateway token mismatch)"
read_when:
  - 遇到网关令牌不匹配错误时
  - 需要解决 Web 界面授权问题时
---

# 解决网关令牌不匹配问题

当您访问 Web 界面时，可能会遇到错误：

```
disconnected (1008): unauthorized: gateway token mismatch (open a tokenized dashboard URL or paste token in Control UI settings)
```

这是因为用户没有使用终端带令牌的链接打开，导致权限认证失败。

## 解决方案

### 方法 1：使用命令行获取带令牌的链接

在终端中运行以下命令：

```bash
openclaw-cn dashboard --no-open
```

此命令会：
- 自动生成带令牌的仪表板链接
- 将链接复制到剪贴板
- 显示链接但不会自动打开浏览器

然后复制输出的链接并在浏览器中打开，即可自动带令牌访问 Web 页面。

### 方法 2：手动配置令牌

如果方法 1 不适用，您可以手动配置令牌：

1. 在 Web 界面的设置面板中，粘贴您配置的网关令牌（或密码）
2. 令牌通常存储在 `~/.openclaw/openclaw.json` 文件中的 `gateway.auth.token`，或通过环境变量 `OPENCLAW_GATEWAY_TOKEN` 设置

### 方法 3：检查令牌配置

确保网关令牌配置正确：

1. 检查配置文件中是否设置了正确的令牌：
   ```bash
   openclaw-cn config get gateway.auth.token
   ```

2. 如果没有设置令牌，可以生成一个：
   ```bash
   openclaw-cn doctor --generate-gateway-token
   ```

## 预防措施

- 首次安装完成后，向导会自动打开带令牌的仪表板链接
- 如果需要重新打开仪表板，使用 `openclaw-cn dashboard` 命令获取最新的带令牌链接
- 令牌存储在浏览器的 localStorage 中，首次加载后会保存

## 相关文档

- [仪表板 (控制界面)](/web/dashboard)
- [Web 界面](/web/control-ui)
- [故障排除](/gateway/troubleshooting)