#!/usr/bin/env bash
# upstream-cherry-pick.sh - 从映射文件中按优先级自动 cherry-pick
#
# 用法:
#   ./scripts/upstream-cherry-pick.sh --dry-run                    # 预览将执行的操作
#   ./scripts/upstream-cherry-pick.sh --priority p0                # 仅 P0 安全修复
#   ./scripts/upstream-cherry-pick.sh --priority p0,p1             # P0+P1
#   ./scripts/upstream-cherry-pick.sh --commit abc1234,def5678     # 指定 commit
#   ./scripts/upstream-cherry-pick.sh --pr "#17682,#17687"         # 指定 PR 号
#   ./scripts/upstream-cherry-pick.sh --batch 10                   # 批量处理前 N 个
#
# 前置条件:
#   1. 先运行 upstream-extract-commits.sh 生成映射文件
#   2. 工作区干净（无未提交的变更）
#
# 依赖: git, jq

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# ============================================================
# 参数解析
# ============================================================

DRY_RUN=false
PRIORITY_FILTER=""
COMMIT_FILTER=""
PR_FILTER=""
BATCH_SIZE=0
MAP_FILE=""
SKIP_BUILD=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)      DRY_RUN=true; shift ;;
    --priority)     PRIORITY_FILTER="$2"; shift 2 ;;
    --commit)       COMMIT_FILTER="$2"; shift 2 ;;
    --pr)           PR_FILTER="$2"; shift 2 ;;
    --batch)        BATCH_SIZE="$2"; shift 2 ;;
    --map)          MAP_FILE="$2"; shift 2 ;;
    --skip-build)   SKIP_BUILD=true; shift ;;
    *)              echo "未知参数: $1" >&2; exit 1 ;;
  esac
done

# 自动查找最新的映射文件
if [ -z "$MAP_FILE" ]; then
  MAP_FILE=$(ls -t "$REPO_ROOT/.github/upstream-commits/"*.json 2>/dev/null | head -1)
  if [ -z "$MAP_FILE" ]; then
    echo "❌ 未找到 commit 映射文件。请先运行:" >&2
    echo "   ./scripts/upstream-extract-commits.sh <from-tag> <to-tag>" >&2
    exit 1
  fi
fi

echo "📂 使用映射文件: $MAP_FILE" >&2

# ============================================================
# 过滤需要 cherry-pick 的 commit
# ============================================================

# 构建 jq 过滤器
JQ_FILTER='[.[] | select(.action == "MERGE"'

if [ -n "$PRIORITY_FILTER" ]; then
  # 支持 "p0,p1" 格式
  PRIORITIES=$(echo "$PRIORITY_FILTER" | tr ',' '|' | tr '[:lower:]' '[:upper:]')
  JQ_FILTER="$JQ_FILTER and (.priority | test(\"^($PRIORITIES)$\"))"
fi

if [ -n "$PR_FILTER" ]; then
  PRS=$(echo "$PR_FILTER" | tr -d '"' | tr ',' '|')
  JQ_FILTER="$JQ_FILTER and (.pr | test(\"($PRS)\"))"
fi

if [ -n "$COMMIT_FILTER" ]; then
  COMMITS_RE=$(echo "$COMMIT_FILTER" | tr ',' '|')
  JQ_FILTER="$JQ_FILTER and (.sha | test(\"^($COMMITS_RE)\"))"
fi

JQ_FILTER="$JQ_FILTER)]"

# 应用过滤并按优先级排序（P0 优先）
SELECTED=$(jq "$JQ_FILTER | sort_by(.priority)" "$MAP_FILE")
COUNT=$(echo "$SELECTED" | jq 'length')

if [ "$BATCH_SIZE" -gt 0 ] && [ "$BATCH_SIZE" -lt "$COUNT" ]; then
  SELECTED=$(echo "$SELECTED" | jq ".[:$BATCH_SIZE]")
  COUNT=$BATCH_SIZE
fi

echo "📋 选中 $COUNT 个 commit 待处理" >&2

if [ "$COUNT" -eq 0 ]; then
  echo "没有需要处理的 commit" >&2
  exit 0
fi

# ============================================================
# 依赖排序
# ============================================================
# 确保 cherry-pick 顺序正确：如果 commit B 的文件依赖 commit A，A 先执行
# 使用 git 的时间顺序（逆序，最早的先执行）

SORTED=$(echo "$SELECTED" | jq '[.[] | .sha] | reverse')
echo "🔗 已按时间顺序排列（最早的 commit 先执行）" >&2

# ============================================================
# 预览模式
# ============================================================

if [ "$DRY_RUN" = true ]; then
  echo "" >&2
  echo "=== 预览模式 ===" >&2
  echo "" >&2
  echo "$SELECTED" | jq -r '.[] | "  \(.priority) [\(.action)] \(.sha[:10]) \(.message) (\(.category), 风险: \(.conflict_risk))"'
  echo "" >&2
  echo "使用以下命令执行:" >&2
  echo "  $0 $(echo "$@" | sed 's/--dry-run//')" >&2
  exit 0
fi

# ============================================================
# 检查工作区状态
# ============================================================

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "❌ 工作区不干净，请先提交或 stash 当前变更" >&2
  exit 1
fi

CURRENT_BRANCH=$(git branch --show-current)
echo "📍 当前分支: $CURRENT_BRANCH" >&2

# 创建合并分支
MERGE_BRANCH="upstream-cherry-pick/$(date +%Y%m%d-%H%M%S)"
git checkout -b "$MERGE_BRANCH"
echo "🌿 已创建分支: $MERGE_BRANCH" >&2

# ============================================================
# 逐个 cherry-pick
# ============================================================

SUCCESS=0
FAILED=0
SKIPPED=0
FAILED_LIST=()
SUCCESS_LIST=()

for SHA in $(echo "$SORTED" | jq -r '.[]'); do
  # 获取 commit 信息
  INFO=$(echo "$SELECTED" | jq -r ".[] | select(.sha == \"$SHA\")")
  MSG=$(echo "$INFO" | jq -r '.message')
  PRIORITY=$(echo "$INFO" | jq -r '.priority')
  CATEGORY=$(echo "$INFO" | jq -r '.category')
  SHORT_SHA="${SHA:0:10}"

  echo "" >&2
  echo "━━━ [$PRIORITY/$CATEGORY] $SHORT_SHA: $MSG ━━━" >&2

  # 尝试 cherry-pick
  if git cherry-pick "$SHA" --no-commit 2>/dev/null; then
    # 检查是否涉及我们定制的文件，自动恢复本地版本
    CHANGED_FILES=$(git diff --cached --name-only)

    # 恢复本地维护的文件
    RESTORED=false
    for pattern in "docs/" ".github/workflows/" "CHANGELOG.md" "README.md" "CONTRIBUTING.md" "AGENTS.md"; do
      MATCHED=$(echo "$CHANGED_FILES" | grep "^$pattern" || true)
      if [ -n "$MATCHED" ]; then
        echo "   ↩️  恢复本地文件: $(echo "$MATCHED" | wc -l | tr -d ' ') 个匹配 $pattern" >&2
        echo "$MATCHED" | xargs git checkout HEAD -- 2>/dev/null || true
        RESTORED=true
      fi
    done

    # 恢复 package.json 的 CN 定制字段（如果被修改）
    if echo "$CHANGED_FILES" | grep -q "^package.json$"; then
      echo "   ⚠️  package.json 被修改，保留本地版本" >&2
      git checkout HEAD -- package.json
    fi

    # 恢复 feishu 扩展
    FEISHU_FILES=$(echo "$CHANGED_FILES" | grep "^extensions/feishu/" || true)
    if [ -n "$FEISHU_FILES" ]; then
      echo "   ↩️  恢复飞书扩展本地文件" >&2
      echo "$FEISHU_FILES" | xargs git checkout HEAD -- 2>/dev/null || true
    fi

    # 检查是否还有实际变更
    if git diff --cached --quiet; then
      echo "   ⏭️  cherry-pick 后无实际变更（已被本地覆盖），跳过" >&2
      git cherry-pick --abort 2>/dev/null || true
      SKIPPED=$((SKIPPED + 1))
      continue
    fi

    # 提交
    git commit -m "$MSG (upstream cherry-pick $SHORT_SHA)" --no-verify
    echo "   ✅ 成功" >&2
    SUCCESS=$((SUCCESS + 1))
    SUCCESS_LIST+=("$SHORT_SHA")
  else
    echo "   ❌ 冲突，跳过此 commit" >&2
    git cherry-pick --abort 2>/dev/null || true
    FAILED=$((FAILED + 1))
    FAILED_LIST+=("$SHORT_SHA|$MSG")
  fi
done

# ============================================================
# 构建验证
# ============================================================

echo "" >&2
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
echo "📊 Cherry-pick 结果:" >&2
echo "   ✅ 成功: $SUCCESS" >&2
echo "   ❌ 失败: $FAILED" >&2
echo "   ⏭️  跳过: $SKIPPED" >&2

if [ "$SKIP_BUILD" = false ] && [ "$SUCCESS" -gt 0 ]; then
  echo "" >&2
  echo "🔨 运行构建验证..." >&2
  if pnpm install --no-frozen-lockfile 2>&1 | tail -3; then
    if pnpm build 2>&1 | tail -5; then
      echo "   ✅ 构建通过" >&2
    else
      echo "   ⚠️  构建失败，请手动检查" >&2
    fi
  fi
fi

# ============================================================
# 输出报告
# ============================================================

if [ ${#FAILED_LIST[@]} -gt 0 ]; then
  echo "" >&2
  echo "⚠️  以下 commit 需要手动处理:" >&2
  for item in "${FAILED_LIST[@]}"; do
    SHA=$(echo "$item" | cut -d'|' -f1)
    MSG=$(echo "$item" | cut -d'|' -f2)
    echo "   git cherry-pick $SHA  # $MSG" >&2
  done
fi

echo "" >&2
echo "💡 下一步:" >&2
if [ "$SUCCESS" -gt 0 ]; then
  echo "   1. 检查变更: git log --oneline $CURRENT_BRANCH..$MERGE_BRANCH" >&2
  echo "   2. 运行测试: pnpm test" >&2
  echo "   3. 合并到主分支: git switch $CURRENT_BRANCH && git merge $MERGE_BRANCH" >&2
  echo "   4. 更新清单: 标记已合并的条目为 ✅" >&2
else
  echo "   没有成功的 cherry-pick，删除分支: git switch $CURRENT_BRANCH && git branch -D $MERGE_BRANCH" >&2
fi
