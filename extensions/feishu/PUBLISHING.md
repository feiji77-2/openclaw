# Feishu 扩展独立发布指南

本文档说明如何将 @openclaw-cn/feishu 扩展作为独立 npm 包发布。

## 发布步骤

### 1. 准备工作

```bash
# 进入扩展目录
cd extensions/feishu

# 清理旧构建
pnpm clean

# 编译为 dist/
pnpm build

# 验证编译产物
ls -la dist/
```

应该看到：
- `dist/index.js` - 编译后的 JavaScript
- `dist/index.d.ts` - TypeScript 类型声明
- `dist/src/` - 源代码编译版本
- `.d.ts.map` - 源码映射文件

### 2. 版本管理

编辑 `extensions/feishu/package.json`，更新版本号：

```json
{
  "version": "2026.2.1"
}
```

遵循 [语义化版本](https://semver.org/lang/zh-CN/)：
- 主版本号：不兼容的 API 变更
- 次版本号：向后兼容的功能新增
- 修订号：向后兼容的问题修复

### 3. 发布到 npm

**前置要求**：
- 已安装 npm CLI
- 已登录 npm 账户：`npm login`

**发布命令**：

```bash
# 验证登录状态
npm whoami

# 发布到 npm 公开仓库
npm publish --access public

# 或使用 OTP（如果启用了两步验证）
npm publish --otp=YOUR_OTP_CODE
```

**发布检查**：
```bash
# 验证发布成功
npm view @openclaw-cn/feishu version

# 查看包信息
npm info @openclaw-cn/feishu

# 下载并测试
npm install @openclaw-cn/feishu
```

### 4. 更新 CHANGELOG

在项目根目录的 `CHANGELOG.md` 顶部添加：

```markdown
## v2026.2.1

### 新增
- Feishu 扩展作为独立 npm 包发布 (@openclaw-cn/feishu@2026.2.1)

### 修复
- [列出修复内容]
```

### 5. 发布后验证

```bash
# 检查 npm 包是否可安装
npm install @openclaw-cn/feishu

# 验证类型检查
npx tsc --noEmit

# 测试运行时加载（在 openclaw-cn 项目中）
openclaw-cn plugins list
```

## 双模式兼容性说明

### Workspace 模式（开发环境）
- 使用 TypeScript 源码（index.ts）
- 通过 jiti 在运行时编译
- 适合本地开发

### NPM 模式（用户安装）
- 使用预编译的 JavaScript（dist/index.js）
- 类型声明文件（dist/index.d.ts）
- 适合独立使用

### 类型映射
feishu 包提供类型声明文件（`src/plugin-sdk.d.ts`），确保 TypeScript 用户获得完整的类型支持。

## 常见问题

### Q: 如何处理破坏性变更？
A: 发布为新的主版本号（2.0.0），并在 CHANGELOG 中清楚标注。

### Q: 如何取消已发布的版本？
A: 在发布 72 小时内，可使用 `npm unpublish @openclaw-cn/feishu@VERSION`

### Q: 如何发布预发布版本（beta）？
A: 发布时使用预发布标签：
```bash
npm publish --tag beta
# 用户使用：npm install @openclaw-cn/feishu@beta
```

### Q: 如何同时更新 GitHub 和 npm？
A: 按顺序执行：
1. 在 GitHub 上创建 Release（标记版本）
2. `npm publish` 到 npm 仓库
3. 更新 CHANGELOG

## 相关文档

- [npm publish 官方文档](https://docs.npmjs.com/cli/v9/commands/npm-publish)
- [OpenClaw 发布指南](../docs/reference/RELEASING.md)
- [CHANGELOG 维护规范](../CONTRIBUTING.md)
