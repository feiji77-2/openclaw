#!/usr/bin/env bash
# upstream-copilot-resolve.sh - 为冲突 commit 创建 Copilot Agent Issue
#
# 用法:
#   ./scripts/upstream-copilot-resolve.sh \
#     --conflicts /tmp/conflicts.json \
#     --groups /tmp/groups.json \
#     --from v2026.2.14 --to v2026.2.15 \
#     [--max-issues 5] [--dry-run] [--parent-issue 88]
#
# 输出: JSON 格式的创建结果到 stdout
# 依赖: git, jq, gh

set -euo pipefail

# ============================================================
# 参数解析
# ============================================================

CONFLICTS_FILE=""
GROUPS_FILE=""
FROM_TAG=""
TO_TAG=""
MAX_ISSUES=0
DRY_RUN=false
PARENT_ISSUE=""
REPO="${GITHUB_REPOSITORY:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --conflicts)    CONFLICTS_FILE="$2"; shift 2 ;;
    --groups)       GROUPS_FILE="$2"; shift 2 ;;
    --from)         FROM_TAG="$2"; shift 2 ;;
    --to)           TO_TAG="$2"; shift 2 ;;
    --max-issues)   MAX_ISSUES="$2"; shift 2 ;;
    --dry-run)      DRY_RUN=true; shift ;;
    --parent-issue) PARENT_ISSUE="$2"; shift 2 ;;
    --repo)         REPO="$2"; shift 2 ;;
    *)              echo "未知参数: $1" >&2; exit 1 ;;
  esac
done

if [ -z "$GROUPS_FILE" ] || [ -z "$FROM_TAG" ] || [ -z "$TO_TAG" ]; then
  echo "❌ 必须指定 --groups, --from, --to" >&2
  exit 1
fi

if [ -z "$REPO" ]; then
  echo "❌ 请设置 GITHUB_REPOSITORY 或使用 --repo" >&2
  exit 1
fi

# ============================================================
# 生成 Issue body
# ============================================================

generate_issue_body() {
  local GROUP="$1"
  local INDEX="$2"
  local BODY_FILE="/tmp/issue-body-${INDEX}.md"

  local MODULE COUNT PRIORITIES
  MODULE=$(echo "$GROUP" | jq -r '.module')
  COUNT=$(echo "$GROUP" | jq -r '.count')
  PRIORITIES=$(echo "$GROUP" | jq -r '.priorities')

  # === 标题部分 ===
  cat > "$BODY_FILE" <<'HEADER'
## 任务
HEADER

  echo "" >> "$BODY_FILE"
  echo "将以下 ${COUNT} 个上游 commit 的修改语义化应用到本 fork。这些 commit 无法直接 cherry-pick（存在冲突），需要理解修改意图后手动应用等效变更。" >> "$BODY_FILE"
  echo "" >> "$BODY_FILE"
  echo "### 上游版本范围" >> "$BODY_FILE"
  echo "- **来源**: openclaw/openclaw ${FROM_TAG} → ${TO_TAG}" >> "$BODY_FILE"
  echo "- **模块**: \`${MODULE}\`" >> "$BODY_FILE"
  echo "- **优先级**: ${PRIORITIES}" >> "$BODY_FILE"
  echo "" >> "$BODY_FILE"
  echo "### 需要移植的 commit" >> "$BODY_FILE"
  echo "" >> "$BODY_FILE"

  # === 每个 commit 的 diff ===
  for j in $(seq 0 $((COUNT - 1))); do
    local COMMIT SHA MSG PRIORITY FILES SHORT_SHA
    COMMIT=$(echo "$GROUP" | jq ".commits[$j]")
    SHA=$(echo "$COMMIT" | jq -r '.sha')
    MSG=$(echo "$COMMIT" | jq -r '.message')
    PRIORITY=$(echo "$COMMIT" | jq -r '.priority')
    FILES=$(echo "$COMMIT" | jq -r '.files')
    SHORT_SHA="${SHA:0:12}"

    echo "#### Commit $((j+1)): \`${SHORT_SHA}\` (${PRIORITY})" >> "$BODY_FILE"
    echo "**描述**: ${MSG}" >> "$BODY_FILE"
    echo "**涉及文件**: \`${FILES}\`" >> "$BODY_FILE"
    echo "" >> "$BODY_FILE"
    echo "<details>" >> "$BODY_FILE"
    echo "<summary>查看上游 diff</summary>" >> "$BODY_FILE"
    echo "" >> "$BODY_FILE"
    echo '```diff' >> "$BODY_FILE"
    git show "$SHA" --format="" 2>/dev/null | head -200 >> "$BODY_FILE"
    echo '```' >> "$BODY_FILE"
    echo "" >> "$BODY_FILE"
    echo "</details>" >> "$BODY_FILE"
    echo "" >> "$BODY_FILE"
  done

  # === 品牌映射和工作指南 ===
  cat >> "$BODY_FILE" <<'GUIDE'
---

### 品牌映射规则

本 fork 是 openclaw/openclaw 的中文版分支，品牌和命名映射如下：
- 文档/UI 中的品牌名: `openclaw` → `OpenClaw`
- 包名: `openclaw` → `openclaw-cn`
- CLI 命令: `openclaw` → `openclaw-cn`
- 配置目录: `~/.openclaw/` (与上游保持一致，不要改动)

### 中文化要求

合并上游代码后，**所有面向用户可见的文本**（包括但不限于）都必须翻译成**简体中文**：
- CLI 输出信息、提示语、错误消息
- 日志中的用户可见部分
- 注释中的用户说明（代码内部注释可保留英文）
- 配置描述文本

### 工作指南

1. **获取上游代码** (如果需要查看更多上下文):
   ```bash
   git remote add upstream https://github.com/openclaw/openclaw.git 2>/dev/null || true
   git fetch upstream --tags
   ```

2. **理解修改意图**: 仔细阅读上游 diff，理解每个改动的目的

3. **找到 fork 中对应位置**: 文件路径可能相同，但内容因品牌重命名有差异

4. **代码质量评估**: 如果上游和本 fork 对相同功能有不同实现，请比较两边的代码质量（可读性、健壮性、性能），选择质量更好的实现。不要盲目用上游代码覆盖本地已有的优质实现

5. **保持现有实现稳定**: 冲突解决时尽量不要破坏本 fork 现有的功能实现。优先采用最小改动方式引入上游修复

6. **保护本地文件**: 以下文件/目录是本 fork 独有的，不要修改：
   - `docs/` (已本地化)
   - `.github/workflows/` (自定义 CI)
   - `CHANGELOG.md`, `README.md` (本地化)
   - `package.json` (品牌/名称/配置差异)
   - `extensions/feishu/` (飞书渠道，上游无此扩展)

7. **验证**: 修改完成后运行 `pnpm build` 确保编译通过

### 验收标准

- [ ] 所有 commit 的修改意图已正确理解并应用
- [ ] 品牌名称正确映射 (OpenClaw / openclaw-cn)
- [ ] 用户可见文本已翻译为简体中文
- [ ] 未修改受保护文件
- [ ] 现有功能实现未被破坏
- [ ] 代码风格与 fork 现有代码一致
GUIDE

  echo "$BODY_FILE"
}

# ============================================================
# 主流程
# ============================================================

GROUP_COUNT=$(jq 'length' "$GROUPS_FILE")
CREATED=0
CREATED_ISSUES=""

echo "📦 共 $GROUP_COUNT 组待处理" >&2

for i in $(seq 0 $((GROUP_COUNT - 1))); do
  if [ "$MAX_ISSUES" -gt 0 ] && [ "$CREATED" -ge "$MAX_ISSUES" ]; then
    echo "⚠️ 已达到最大 Issue 数量限制 ($MAX_ISSUES)，跳过剩余分组" >&2
    break
  fi

  GROUP=$(jq ".[$i]" "$GROUPS_FILE")
  MODULE=$(echo "$GROUP" | jq -r '.module')
  COUNT=$(echo "$GROUP" | jq -r '.count')
  PRIORITIES=$(echo "$GROUP" | jq -r '.priorities')

  echo "" >&2
  echo "━━━ [$((i+1))/$GROUP_COUNT] 模块: $MODULE ($COUNT 个 commit, $PRIORITIES) ━━━" >&2

  if [ "$DRY_RUN" = true ]; then
    echo "   [dry_run] 将创建 Issue: upstream($MODULE): 移植 $COUNT 个冲突 commit ($PRIORITIES)" >&2
    CREATED=$((CREATED + 1))
    continue
  fi

  # 生成 Issue body
  BODY_FILE=$(generate_issue_body "$GROUP" "$i")

  # 创建 Issue
  ISSUE_TITLE="upstream($MODULE): 移植 $COUNT 个冲突 commit ($PRIORITIES) — ${FROM_TAG}→${TO_TAG}"

  gh label create "copilot-resolve" --color "7057ff" --force -R "$REPO" 2>/dev/null || true

  ISSUE_URL=$(gh issue create -R "$REPO" \
    --title "$ISSUE_TITLE" \
    --body-file "$BODY_FILE" \
    --label "upstream,copilot-resolve")

  ISSUE_NUM=$(echo "$ISSUE_URL" | grep -oE '[0-9]+$')
  echo "   ✅ 创建 Issue #$ISSUE_NUM" >&2

  # 分配 Copilot Agent (需要 agent_assignment + copilot-swe-agent[bot])
  # 注意: 即使分配失败也要继续处理其他 groups
  echo "   🤖 分配给 Copilot Agent..." >&2

  ASSIGN_BODY="{\"assignees\":[\"copilot-swe-agent[bot]\"],\"agent_assignment\":{\"target_repo\":\"$REPO\",\"base_branch\":\"main\",\"custom_instructions\":\"\",\"custom_agent\":\"\",\"model\":\"\"}}"

  set +e
  ASSIGN_RESULT=$(echo "$ASSIGN_BODY" | gh api \
    --method POST \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "repos/$REPO/issues/$ISSUE_NUM/assignees" \
    --input - 2>&1)
  ASSIGN_EXIT=$?
  set -e

  if [ $ASSIGN_EXIT -eq 0 ]; then
    ASSIGNED=$(echo "$ASSIGN_RESULT" | jq -r '[.assignees[]?.login] | map(select(. == "Copilot" or . == "copilot-swe-agent[bot]")) | first // empty' 2>/dev/null)
    if [ -n "$ASSIGNED" ]; then
      echo "   ✅ 已分配给 $ASSIGNED" >&2
    else
      echo "   ⚠️ Copilot 分配未生效 (可能需要 PAT 而非 GITHUB_TOKEN)" >&2
      echo "   ℹ️  可在 GitHub UI 中手动分配: $ISSUE_URL" >&2
    fi
  else
    echo "   ⚠️ Copilot API 调用失败 (exit=$ASSIGN_EXIT)，可能需要 GH_PAT secret" >&2
    echo "   ℹ️  API 返回: $(echo "$ASSIGN_RESULT" | head -1)" >&2
    echo "   ℹ️  可在 GitHub UI 中手动分配: $ISSUE_URL" >&2
  fi

  CREATED=$((CREATED + 1))
  CREATED_ISSUES="${CREATED_ISSUES} #${ISSUE_NUM}"

  # 避免 API rate limit
  sleep 2
done

echo "" >&2
echo "=========================================" >&2
echo "🎉 共处理 $CREATED 组 ($DRY_RUN 模式: $DRY_RUN)" >&2
if [ -n "$CREATED_ISSUES" ]; then
  echo "   Issues:$CREATED_ISSUES" >&2
fi
echo "=========================================" >&2

# 输出 JSON 结果到 stdout
echo "{\"created_count\": $CREATED, \"created_issues\": \"$(echo "$CREATED_ISSUES" | xargs)\"}"
