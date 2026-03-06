# Docker Hub 预构建镜像配置指南

本文档说明如何设置 GitHub Actions 自动构建和推送预构建的 Docker 镜像到 Docker Hub。

## 前置要求

1. **Docker Hub 账户** - [注册地址](https://hub.docker.com/)
2. **GitHub 仓库** - 需要有 GitHub 账户和仓库权限
3. **访问令牌** - 在 Docker Hub 和 GitHub 上分别创建

## 步骤 1：在 Docker Hub 创建账户和仓库

1. 访问 [Docker Hub](https://hub.docker.com/)
2. 注册或登录账户
3. 创建新的公开仓库，命名为 `openclaw-cn`
   - 描述：`Openclaw 中文版 - 私有化部署的 AI 智能助手`
   - 访问权限：Public

## 步骤 2：生成 Docker Hub 访问令牌

1. 登录 Docker Hub
2. 进入 **Account Settings** → **Security** → **Access Tokens**
3. 点击 **New Access Token**
4. 输入名称：`openclaw-cn-github-actions`
5. 权限选择：`Read, Write` 和 `Delete`
6. 点击 **Generate**
7. 复制生成的令牌（仅显示一次）

## 步骤 3：添加 GitHub Secrets

1. 进入 GitHub 仓库
2. 进入 **Settings** → **Secrets and variables** → **Actions**
3. 点击 **New repository secret**，创建以下两个 secrets：

### Secret 1: DOCKERHUB_USERNAME
- **名称**：`DOCKERHUB_USERNAME`
- **值**：`jiulingyun803`

### Secret 2: DOCKERHUB_TOKEN
- **名称**：`DOCKERHUB_TOKEN`
- **值**：在步骤 2 生成的访问令牌

## 步骤 4：验证 GitHub Actions Workflow

1. 进入 GitHub 仓库的 **Actions** 标签页
2. 找到 **Build and Push Multi-Architecture Docker Images** workflow
3. 确认 workflow 已启用
4. 当你推送代码或发布新版本标签时，workflow 会自动触发

## 镜像标签说明

GitHub Actions 会自动为构建的镜像打上以下标签：

| 触发条件 | 镜像标签 | 示例 |
|---------|--------|------|
| 推送到 `main` 分支 | `latest` | `jiulingyun803/openclaw-cn:latest` |
| 推送版本标签 | 版本号 | `jiulingyun803/openclaw-cn:v2026.1.31` |
| 推送分支提交 | 分支-SHA | `jiulingyun803/openclaw-cn:main-abc1234` |
| 拉取请求 | 不推送到 Docker Hub | （本地构建测试） |

## 使用预构建的镜像

### 方法 1：使用 Docker Compose

编辑 `.env` 文件：
```bash
OPENCLAW_IMAGE=jiulingyun803/openclaw-cn:latest
```

然后运行：
```bash
docker compose up -d openclaw-cn-gateway
```

### 方法 2：直接使用 Docker 运行

```bash
docker run -d \
  --name openclaw-gateway \
  -p 18789:18789 \
  -v ~/.openclaw:/home/node/.openclaw \
  -v ~/clawd:/home/node/clawd \
  jiulingyun803/openclaw-cn:latest \
  node dist/index.js gateway --bind 0.0.0.0 --port 18789
```

### 方法 3：使用改进的 docker-setup.sh

```bash
export OPENCLAW_IMAGE="jiulingyun803/openclaw-cn:latest"
./docker-setup.sh
```

## 支持的架构

预构建镜像支持以下架构：

- **linux/amd64** - Intel/AMD 64位处理器（大多数服务器和现代电脑）
- **linux/arm64** - ARM 64位处理器（Apple Silicon Mac、树莓派 4/5、华为云鲲鹏等）

Docker 会自动选择匹配的镜像版本。

## 构建时间和存储

- **首次构建**：约 10-20 分钟（两个架构并行）
- **缓存构建**：约 2-5 分钟（使用 GitHub Actions 缓存）
- **镜像大小**：约 500-600 MB（包含完整构建环境和生产依赖）

## 故障排查

### 问题 1：Workflow 失败显示 "unauthorized"

**解决方案**：
1. 检查 GitHub Secrets 中的用户名和令牌是否正确
2. 在 Docker Hub 重新生成令牌（旧令牌可能已过期）
3. 确保令牌具有 `Read, Write, Delete` 权限

### 问题 2：推送到 Docker Hub 失败

**解决方案**：
1. 检查 Docker Hub 仓库是否已创建且为公开
2. 确保仓库名称为 `openclaw-cn`（workflow 中硬编码）
3. 查看 GitHub Actions 的完整日志以获取详细错误信息

### 问题 3：ARM64 架构构建超时

**解决方案**：
1. 增加 GitHub Actions 的超时时间（目前为默认值）
2. 优化 Dockerfile 以加快构建速度
3. 考虑分别为 amd64 和 arm64 运行构建（取消并行构建）

## 自动更新工作流

镜像将在以下情况自动构建和推送：

1. **推送到 main 分支** → 构建 `latest` 标签
2. **发布新版本标签** → 构建版本号标签（如 `v2026.1.31`）
3. **手动触发** → 通过 GitHub Actions UI 的 "Run workflow" 按钮

## 后续改进

- [ ] 配置镜像扫描和漏洞检测
- [ ] 添加 Docker Hub 自动更新描述和 README
- [ ] 配置镜像签名和验证
- [ ] 添加体积优化和最小化基础镜像
- [ ] 配置多个镜像标签策略（stable, beta, dev）

## 参考链接

- [Docker Hub 文档](https://docs.docker.com/docker-hub/)
- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [Docker 官方镜像](https://hub.docker.com/_/node)
- [buildx 多架构构建](https://docs.docker.com/build/buildx/)
