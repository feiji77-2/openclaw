#!/bin/bash
# Openclaw 中文版 Docker 一键设置脚本
# 用法: ./docker-setup.sh
# 支持平台: macOS (bash 3.2+), Linux (bash 4+)
set -euo pipefail

# 检测操作系统
OS_TYPE="unknown"
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS_TYPE="macOS"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  OS_TYPE="Linux"
fi

# 检查依赖
require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "❌ 缺少依赖: $1" >&2
    exit 1
  fi
}

require_cmd docker
if ! docker compose version >/dev/null 2>&1; then
  echo "Docker Compose 不可用（请尝试: docker compose version）" >&2
  exit 1
fi

# 初始化基本变量
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$ROOT_DIR/docker-compose.yml"
EXTRA_COMPOSE_FILE="$ROOT_DIR/docker-compose.extra.yml"
IMAGE_NAME="${OPENCLAW_IMAGE:-openclaw-cn:local}"
EXTRA_MOUNTS="${OPENCLAW_EXTRA_MOUNTS:-}"
HOME_VOLUME_NAME="${OPENCLAW_HOME_VOLUME:-}"

# 打印启动信息
echo "╔════════════════════════════════════════════╗"
echo "║  Openclaw 中文版 Docker 一键设置脚本      ║"
echo "║  平台: $OS_TYPE                            "
echo "║  Bash 版本: $BASH_VERSION                  "
echo "╚════════════════════════════════════════════╝"
echo ""

# 创建配置和工作区目录
mkdir -p "${OPENCLAW_CONFIG_DIR:-$HOME/.openclaw}"
mkdir -p "${OPENCLAW_WORKSPACE_DIR:-$HOME/clawd}"

export OPENCLAW_CONFIG_DIR="${OPENCLAW_CONFIG_DIR:-$HOME/.openclaw}"
export OPENCLAW_WORKSPACE_DIR="${OPENCLAW_WORKSPACE_DIR:-$HOME/clawd}"
export OPENCLAW_GATEWAY_PORT="${OPENCLAW_GATEWAY_PORT:-18789}"
export OPENCLAW_BRIDGE_PORT="${OPENCLAW_BRIDGE_PORT:-18790}"
export OPENCLAW_GATEWAY_BIND="${OPENCLAW_GATEWAY_BIND:-lan}"
export OPENCLAW_IMAGE="$IMAGE_NAME"
export OPENCLAW_DOCKER_APT_PACKAGES="${OPENCLAW_DOCKER_APT_PACKAGES:-}"

# 生成网关令牌
if [[ -z "${OPENCLAW_GATEWAY_TOKEN:-}" ]]; then
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

# 解析额外挂载
VALID_MOUNTS=()
if [[ -n "$EXTRA_MOUNTS" ]]; then
  IFS=',' read -r -a mounts <<<"$EXTRA_MOUNTS"
  for mount in "${mounts[@]}"; do
    mount="${mount#"${mount%%[![:space:]]*}"}"
    mount="${mount%"${mount##*[![:space:]]}"}"
    if [[ -n "$mount" ]]; then
      VALID_MOUNTS+=("$mount")
    fi
  done
fi

if [[ -n "$HOME_VOLUME_NAME" || ${#VALID_MOUNTS[@]} -gt 0 ]]; then
  write_extra_compose "$HOME_VOLUME_NAME" "${VALID_MOUNTS[@]}"
  COMPOSE_FILES+=("$EXTRA_COMPOSE_FILE")
fi
for compose_file in "${COMPOSE_FILES[@]}"; do
  COMPOSE_ARGS+=("-f" "$compose_file")
done
COMPOSE_HINT="docker compose"
for compose_file in "${COMPOSE_FILES[@]}"; do
  COMPOSE_HINT+=" -f ${compose_file}"
done

# 更新 .env 文件（兼容 bash 和 zsh，不使用关联数组）
ENV_FILE="$ROOT_DIR/.env"
upsert_env() {
  local file="$1"
  shift
  local keys=("$@")
  local tmp
  tmp="$(mktemp)"
  local seen_keys=""

  if [[ -f "$file" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      local key="${line%%=*}"
      local replaced=false
      for k in "${keys[@]}"; do
        if [[ "$key" == "$k" ]]; then
          printf '%s=%s\n' "$k" "${!k-}" >>"$tmp"
          seen_keys="$seen_keys|$k"
          replaced=true
          break
        fi
      done
      if [[ "$replaced" == false ]]; then
        printf '%s\n' "$line" >>"$tmp"
      fi
    done <"$file"
  fi

  for k in "${keys[@]}"; do
    if [[ "$seen_keys" != *"|$k"* ]]; then
      printf '%s=%s\n' "$k" "${!k-}" >>"$tmp"
    fi
  done

  mv "$tmp" "$file"
}

upsert_env "$ENV_FILE" \
  OPENCLAW_CONFIG_DIR \
  OPENCLAW_WORKSPACE_DIR \
  OPENCLAW_GATEWAY_PORT \
  OPENCLAW_BRIDGE_PORT \
  OPENCLAW_GATEWAY_BIND \
  OPENCLAW_GATEWAY_TOKEN \
  OPENCLAW_IMAGE \
  OPENCLAW_EXTRA_MOUNTS \
  OPENCLAW_HOME_VOLUME \
  OPENCLAW_DOCKER_APT_PACKAGES

echo "==> 构建 Docker 镜像: $IMAGE_NAME"
docker build \
  --build-arg "OPENCLAW_DOCKER_APT_PACKAGES=${OPENCLAW_DOCKER_APT_PACKAGES}" \
  -t "$IMAGE_NAME" \
  -f "$ROOT_DIR/Dockerfile" \
  "$ROOT_DIR"

echo ""
echo "==> 引导设置（交互式）"
echo "根据提示输入:"
echo "  - 网关绑定: lan"
echo "  - 网关认证: token"
echo "  - 网关令牌: $OPENCLAW_GATEWAY_TOKEN"
echo "  - Tailscale 暴露: 关闭"
echo "  - 安装网关守护进程: 否"
echo ""
docker compose "${COMPOSE_ARGS[@]}" run --rm openclaw-cn-cli onboard --no-install-daemon

echo ""
echo "==> 渠道设置（可选）"
echo "WhatsApp（扫码）:"
echo "  ${COMPOSE_HINT} run --rm openclaw-cn-cli channels login"
echo "Telegram（机器人令牌）:"
echo "  ${COMPOSE_HINT} run --rm openclaw-cn-cli channels add --channel telegram --token <token>"
echo "Discord（机器人令牌）:"
echo "  ${COMPOSE_HINT} run --rm openclaw-cn-cli channels add --channel discord --token <token>"
echo "文档: https://clawd.org.cn/docs/channels"

echo ""
echo "==> 启动网关"
docker compose "${COMPOSE_ARGS[@]}" up -d openclaw-cn-gateway

echo ""
echo "╔════════════════════════════════════════════╗"
echo "║  ✅ 网关启动成功！                         ║"
echo "╚════════════════════════════════════════════╝"
echo ""
echo "📋 系统信息:"
echo "   操作系统: $OS_TYPE"
echo "   Bash 版本: $BASH_VERSION"
echo ""
echo "🔑 网关信息:"
echo "   配置目录: $OPENCLAW_CONFIG_DIR"
echo "   工作区目录: $OPENCLAW_WORKSPACE_DIR"
echo "   令牌: $OPENCLAW_GATEWAY_TOKEN"
echo ""
echo "📱 访问网关:"
if [[ "$OS_TYPE" == "macOS" ]]; then
  echo "   在浏览器中打开: http://127.0.0.1:18789"
elif [[ "$OS_TYPE" == "Linux" ]]; then
  echo "   在浏览器中打开: http://127.0.0.1:18789"
  echo "   或者从其他设备访问: http://\$(hostname -I):18789"
else
  echo "   在浏览器中打开: http://127.0.0.1:18789"
fi
echo ""
echo "💡 常用命令:"
echo "   查看日志: ${COMPOSE_HINT} logs -f openclaw-cn-gateway"
echo "   检查健康: ${COMPOSE_HINT} exec openclaw-cn-gateway node dist/index.js health --token \"$OPENCLAW_GATEWAY_TOKEN\""
echo "   停止网关: ${COMPOSE_HINT} down"
echo "   重启网关: ${COMPOSE_HINT} restart openclaw-cn-gateway"
echo ""
echo "📚 文档: https://clawd.org.cn/docs"
echo ""
