#!/usr/bin/env bash
# Openclaw 中文版 Docker 一键部署脚本（使用预构建镜像）
# 用法: ./docker-deploy-prebuilt.sh [docker-image-name]
# 示例: ./docker-deploy-prebuilt.sh jiulingyun803/openclaw-cn:latest
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 自动检测 docker-compose 文件（支持 .yml 和 .yaml）
detect_compose_file() {
  local dir="$1"
  if [[ -f "$dir/docker-compose.yml" ]]; then
    echo "$dir/docker-compose.yml"
  elif [[ -f "$dir/docker-compose.yaml" ]]; then
    echo "$dir/docker-compose.yaml"
  else
    echo "$dir/docker-compose.yml"  # 默认值，如果都不存在则用 .yml
  fi
}

COMPOSE_FILE="$(detect_compose_file "$ROOT_DIR")"

# 为额外的 compose 配置文件选择合适的扩展名（与主文件保持一致）
COMPOSE_EXT="${COMPOSE_FILE##*.}"  # 获取主文件的扩展名
EXTRA_COMPOSE_FILE="$ROOT_DIR/docker-compose.extra.$COMPOSE_EXT"

# 默认使用官方预构建镜像，但可通过参数覆盖
IMAGE_NAME="${1:-${OPENCLAW_IMAGE:-jiulingyun803/openclaw-cn:latest}}"
EXTRA_MOUNTS="${OPENCLAW_EXTRA_MOUNTS:-}"
HOME_VOLUME_NAME="${OPENCLAW_HOME_VOLUME:-}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "❌ 缺少依赖: $1" >&2
    exit 1
  fi
}

print_header() {
  echo ""
  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "║        Openclaw 中文版 Docker 部署脚本 (预构建镜像)          ║"
  echo "╚═══════════════════════════════════════════════════════════════╝"
  echo ""
}

print_step() {
  local step_num=$1
  local step_name=$2
  echo "📍 步骤 $step_num: $step_name"
}

print_success() {
  echo "✅ $1"
}

print_error() {
  echo "❌ $1" >&2
}

require_cmd docker
if ! docker compose version >/dev/null 2>&1; then
  print_error "Docker Compose 不可用（请尝试: docker compose version）"
  exit 1
fi

print_header

print_step 1 "检查 Docker 环境"
docker --version
docker compose version
print_success "Docker 环境检查完成"

print_step 2 "创建配置和工作区目录"
OPENCLAW_CONFIG_DIR="${OPENCLAW_CONFIG_DIR:-$HOME/.openclaw}"
OPENCLAW_WORKSPACE_DIR="${OPENCLAW_WORKSPACE_DIR:-$HOME/clawd}"

mkdir -p "$OPENCLAW_CONFIG_DIR"
mkdir -p "$OPENCLAW_WORKSPACE_DIR"

# 确保目录权限正确
# 如果以 root 运行（在容器或具有 sudo 的系统上），设置权限以允许 node 用户访问
if [[ $EUID -eq 0 ]]; then
  chmod 755 "$OPENCLAW_CONFIG_DIR"
  chmod 755 "$OPENCLAW_WORKSPACE_DIR"
  # 尝试改变所有权为 1000:1000（Docker node 用户的标准 UID/GID）
  # 这在大多数 Linux 系统上有效，但在 macOS 上会被忽略
  chown -R 1000:1000 "$OPENCLAW_CONFIG_DIR" 2>/dev/null || true
  chown -R 1000:1000 "$OPENCLAW_WORKSPACE_DIR" 2>/dev/null || true
fi

print_success "目录已创建"

export OPENCLAW_CONFIG_DIR
export OPENCLAW_WORKSPACE_DIR
export OPENCLAW_GATEWAY_PORT="${OPENCLAW_GATEWAY_PORT:-18789}"
export OPENCLAW_BRIDGE_PORT="${OPENCLAW_BRIDGE_PORT:-18790}"
export OPENCLAW_GATEWAY_BIND="${OPENCLAW_GATEWAY_BIND:-lan}"
export OPENCLAW_IMAGE="$IMAGE_NAME"
export OPENCLAW_DOCKER_APT_PACKAGES="${OPENCLAW_DOCKER_APT_PACKAGES:-}"

# 生成网关令牌
if [[ -z "${OPENCLAW_GATEWAY_TOKEN:-}" ]]; then
  print_step 3 "生成网关令牌"
  if command -v openssl >/dev/null 2>&1; then
    OPENCLAW_GATEWAY_TOKEN="$(openssl rand -hex 32)"
  else
    OPENCLAW_GATEWAY_TOKEN="$(python3 - <<'PY'
import secrets
print(secrets.token_hex(32))
PY
)"
  fi
fi
export OPENCLAW_GATEWAY_TOKEN

COMPOSE_FILES=("$COMPOSE_FILE")
COMPOSE_ARGS=()

# 生成额外的 compose 配置文件（用于挂载和卷）
write_extra_compose() {
  local home_volume="$1"
  shift
  local -a mounts=("$@")
  local mount

  cat >"$EXTRA_COMPOSE_FILE" <<'YAML'
services:
  openclaw-cn-gateway:
    volumes:
YAML

  if [[ -n "$home_volume" ]]; then
    printf '      - %s:/home/node\n' "$home_volume" >>"$EXTRA_COMPOSE_FILE"
    printf '      - %s:/home/node/.openclaw\n' "$OPENCLAW_CONFIG_DIR" >>"$EXTRA_COMPOSE_FILE"
    printf '      - %s:/home/node/clawd\n' "$OPENCLAW_WORKSPACE_DIR" >>"$EXTRA_COMPOSE_FILE"
  fi

  for mount in "${mounts[@]}"; do
    printf '      - %s\n' "$mount" >>"$EXTRA_COMPOSE_FILE"
  done

  cat >>"$EXTRA_COMPOSE_FILE" <<'YAML'
  openclaw-cn-cli:
    volumes:
YAML

  if [[ -n "$home_volume" ]]; then
    printf '      - %s:/home/node\n' "$home_volume" >>"$EXTRA_COMPOSE_FILE"
    printf '      - %s:/home/node/.openclaw\n' "$OPENCLAW_CONFIG_DIR" >>"$EXTRA_COMPOSE_FILE"
    printf '      - %s:/home/node/clawd\n' "$OPENCLAW_WORKSPACE_DIR" >>"$EXTRA_COMPOSE_FILE"
  fi

  for mount in "${mounts[@]}"; do
    printf '      - %s\n' "$mount" >>"$EXTRA_COMPOSE_FILE"
  done

  if [[ -n "$home_volume" && "$home_volume" != *"/"* ]]; then
    cat >>"$EXTRA_COMPOSE_FILE" <<YAML
volumes:
  ${home_volume}:
YAML
  fi
}

# 解析额外的挂载
IFS_OLD="$IFS"
IFS=',' read -ra EXTRA_MOUNTS_ARRAY <<<"${EXTRA_MOUNTS:-}"
IFS="$IFS_OLD"

if [[ -n "$HOME_VOLUME_NAME" || ${#EXTRA_MOUNTS_ARRAY[@]} -gt 0 ]]; then
  write_extra_compose "$HOME_VOLUME_NAME" "${EXTRA_MOUNTS_ARRAY[@]}"
  COMPOSE_FILES+=("$EXTRA_COMPOSE_FILE")
fi

# 构建 docker compose 命令参数
for f in "${COMPOSE_FILES[@]}"; do
  COMPOSE_ARGS+=("-f" "$f")
done

# 构建环境变量文件
print_step 4 "准备环境配置"

ENV_FILE="$ROOT_DIR/.env"
cat >"$ENV_FILE" <<EOF
# Openclaw 中文版 Docker 环境配置
# 生成于: $(date)

OPENCLAW_CONFIG_DIR=$OPENCLAW_CONFIG_DIR
OPENCLAW_WORKSPACE_DIR=$OPENCLAW_WORKSPACE_DIR
OPENCLAW_GATEWAY_PORT=$OPENCLAW_GATEWAY_PORT
OPENCLAW_BRIDGE_PORT=$OPENCLAW_BRIDGE_PORT
OPENCLAW_GATEWAY_BIND=$OPENCLAW_GATEWAY_BIND
OPENCLAW_IMAGE=$OPENCLAW_IMAGE
OPENCLAW_GATEWAY_TOKEN=$OPENCLAW_GATEWAY_TOKEN
OPENCLAW_DOCKER_APT_PACKAGES=$OPENCLAW_DOCKER_APT_PACKAGES
EOF

print_success "环境配置已保存到 .env"

# 拉取预构建镜像
print_step 5 "拉取预构建 Docker 镜像"
echo "📥 镜像: $IMAGE_NAME"

if docker pull "$IMAGE_NAME" 2>&1; then
  print_success "镜像拉取成功"
else
  print_error "镜像拉取失败"
  echo ""
  echo "可能的原因:"
  echo "  1. 网络连接问题 - 检查你的网络"
  echo "  2. 镜像不存在 - 检查镜像名称是否正确（推荐使用 jiulingyun803/openclaw-cn:latest）"
  echo "  3. 权限问题 - 如果是私有镜像，需要 'docker login'"
  echo ""
  exit 1
fi

# 运行 onboard 向导
print_step 6 "运行配置向导（可选）"
echo "提示: 如果已配置过，可以跳过此步"
read -p "是否运行配置向导? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "🚀 启动配置向导..."
  docker compose "${COMPOSE_ARGS[@]}" run --rm openclaw-cn-cli onboard
  print_success "配置向导完成"
else
  echo "⏭️  跳过配置向导"
fi

# 启动网关
print_step 7 "启动网关服务"
echo "🚀 启动 Docker Compose 服务..."
docker compose "${COMPOSE_ARGS[@]}" up -d openclaw-cn-gateway

# 等待网关启动
echo "⏳ 等待网关启动（约 5 秒）..."
sleep 5

# 验证网关
print_step 8 "验证网关状态"
if docker compose "${COMPOSE_ARGS[@]}" ps openclaw-cn-gateway | grep -q "Up"; then
  print_success "网关已启动"
else
  print_error "网关启动失败"
  echo "📋 查看日志："
  docker compose "${COMPOSE_ARGS[@]}" logs openclaw-cn-gateway
  exit 1
fi

# 显示完成信息
echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                    ✅ 部署完成！                             ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 配置信息:"
echo "   配置目录: $OPENCLAW_CONFIG_DIR"
echo "   工作目录: $OPENCLAW_WORKSPACE_DIR"
echo "   镜像名称: $OPENCLAW_IMAGE"
echo "   网关地址: http://127.0.0.1:$OPENCLAW_GATEWAY_PORT"
echo "   网关令牌: $OPENCLAW_GATEWAY_TOKEN"
echo ""
echo "🌐 后续步骤:"
echo "   1. 在浏览器中打开: http://127.0.0.1:$OPENCLAW_GATEWAY_PORT"
echo "   2. 在设置中粘贴网关令牌"
echo "   3. 配置 AI 提供商和消息渠道"
echo ""
echo "📝 常用命令:"
echo "   查看日志:  docker compose -f $COMPOSE_FILE logs -f openclaw-cn-gateway"
echo "   停止服务: docker compose -f $COMPOSE_FILE down"
echo "   重启服务: docker compose -f $COMPOSE_FILE restart openclaw-cn-gateway"
echo ""
echo "📚 更多信息: https://clawd.org.cn"
echo ""
