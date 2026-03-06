# 🚀 发布清单

快速参考：发布 @openclaw-cn/feishu 到 npm 的步骤

## 预检

- [ ] 版本号已更新 (`package.json`)
- [ ] CHANGELOG 已更新（GitHub）
- [ ] 所有测试通过 (`pnpm test`)
- [ ] 代码已提交到 main 分支

## 构建 & 发布

```bash
# 1️⃣ 编译
cd extensions/feishu
pnpm clean && pnpm build

# 2️⃣ 验证编译产物
ls dist/index.js dist/index.d.ts

# 3️⃣ 发布
npm publish

# 4️⃣ 验证
npm view @openclaw-cn/feishu version
```

## 发布后

- [ ] 在 GitHub 创建 Release（标记版本）
- [ ] 更新项目 README 中的版本号
- [ ] 通知用户新版本发布

## 故障排除

| 问题 | 解决方案 |
|------|--------|
| 未认证 | 运行 `npm login` |
| 权限拒绝 | 检查 npm 账户权限 |
| 编译失败 | 运行 `pnpm install` 后重试 |
| 版本已存在 | 更新版本号，重新发布 |

---

详见：[PUBLISHING.md](./PUBLISHING.md)
