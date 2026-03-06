# @openclaw-cn/feishu

飞书（Larksuite）频道插件，用于 OpenClaw 中文版

## 安装

### 工作空间模式（开发）
如果你在 openclaw-cn 工作空间中：
```bash
pnpm install
```

### NPM 模式（独立使用）
```bash
# 1. 安装 openclaw（如果还没安装）
npm install openclaw

# 2. 安装 feishu 插件
npx openclaw-cn plugins install @openclaw-cn/feishu
```

或手动安装：
```bash
npm install @openclaw-cn/feishu
```

## 配置

### 获取 Feishu 凭证

1. 访问 [Feishu 开放平台](https://open.feishu.cn/)
2. 创建企业应用或个人应用
3. 获取以下凭证：
   - App ID
   - App Secret
   - 机器人 Token（可选）

### 在 OpenClaw 中配置

```yaml
channels:
  feishu:
    enabled: true
    accounts:
      - id: "default"
        appId: "your_app_id"
        appSecret: "your_app_secret"
        botToken: "your_bot_token"  # 可选
```

## 功能

- ✅ 接收飞书消息
- ✅ 发送回复
- ✅ 支持富文本格式
- ✅ 支持多账户配置
- ✅ 自动化回复

## 环境要求

- Node.js 22+
- openclaw-cn 或 openclaw（NPM 模式）

## 故障排除

### "Cannot resolve plugin SDK" 错误
- **Workspace 模式**：确保在项目根目录运行 `pnpm install`
- **NPM 模式**：确保 `openclaw` 包已安装在 node_modules 中

### 消息无法接收
1. 检查 App ID 和 Secret 是否正确
2. 验证机器人权限设置
3. 查看日志：`clawdbot-cn logs --follow`

### 连接超时
- 检查网络连接
- 验证飞书 API 端点可访问
- 查看防火墙设置

## 许可

MIT

## 贡献

欢迎贡献！请阅读 [CONTRIBUTING.md](../../CONTRIBUTING.md)
