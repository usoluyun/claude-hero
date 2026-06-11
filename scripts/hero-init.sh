#!/usr/bin/env bash
# hero-init.sh — 导航 Agent 自动化构建主脚本
# 用法:
#   bash scripts/hero-init.sh <project_path> <chinese_name>
#   bash scripts/hero-init.sh --help
# 输出:
#   agents/{agent_name}.md — 最终的导航 Agent 文件
#   Git 分支 feat/init-{project_key}-{date}
#   控制台 MR 创建指引 + 验证结果摘要
# 约束: bash 3.2 兼容, set -euo pipefail, 任何阶段失败立即退出
set -euo pipefail

# ──────────────────────────────────────────────────────────────
# 帮助信息
# ──────────────────────────────────────────────────────────────
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  echo "Usage: hero-init.sh <project_path> <chinese_name>"
  echo ""
  echo "  为 Java 项目自动生成领航 Agent 文件并提交 Git 分支。"
  echo ""
  echo "参数:"
  echo "  project_path  项目绝对路径（必需，需包含 *.java 文件）"
  echo "  chinese_name  花名/Agent 中文代号（必需，如 子文、郑和）"
  echo ""
  echo "示例:"
  echo "  bash scripts/hero-init.sh ~/Documents/ATLWork/ecrm 子文"
  echo ""
  echo "流程:"
  echo "  Phase 1: 检测项目布局（构建工具 / 模块结构）"
  echo "  Phase 2: 检测技术栈（框架 / 中间件）"
  echo "  Phase 3: 收集代码证据（入口点 / 配置文件）"
  echo "  Phase 4: 填充模板 → agents/{agent_name}.md"
  echo "  Phase 5: 反伪造验证（路径 / 技术栈 / 关键词）"
  echo "  Phase 6: Git 分支创建 + 提交 + MR 指引输出"
  echo ""
  echo "注意: 不会自动 push，需手动按指引操作"
  exit 0
fi

# ──────────────────────────────────────────────────────────────
# 参数解析与验证
# ──────────────────────────────────────────────────────────────
PROJECT_PATH="${1:-}"
CHINESE_NAME="${2:-}"

if [ -z "$PROJECT_PATH" ] || [ -z "$CHINESE_NAME" ]; then
  echo "Usage: hero-init.sh <project_path> <chinese_name>" >&2
  echo "  project_path  项目绝对路径（必需）" >&2
  echo "  chinese_name  花名/中文名（必需）" >&2
  echo "" >&2
  echo "使用 --help 查看详细帮助" >&2
  exit 1
fi

# ──────────────────────────────────────────────────────────────
# Source 所有依赖库（按依赖顺序）
# ──────────────────────────────────────────────────────────────
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

source "$HERE/lib/refresh-common.sh"
source "$HERE/lib/init-common.sh"
source "$HERE/lib/init-layout.sh"
source "$HERE/lib/init-stack.sh"
source "$HERE/lib/init-evidence.sh"
source "$HERE/lib/init-template.sh"
source "$HERE/lib/init-verify.sh"
source "$HERE/lib/init-branch.sh"
source "$HERE/lib/refresh-state.sh"

# ──────────────────────────────────────────────────────────────
# 输入验证
# ──────────────────────────────────────────────────────────────
PROJECT_PATH="$(expand_path "$PROJECT_PATH")"

# 1. 绝对路径校验
case "$PROJECT_PATH" in
  /*) ;;
  *)  echo "ERROR: project_path 必须是绝对路径，收到: $PROJECT_PATH" >&2
      exit 1 ;;
esac

# 2. 项目路径存在
if [ ! -d "$PROJECT_PATH" ]; then
  echo "ERROR: 项目路径不存在: $PROJECT_PATH" >&2
  exit 1
fi

# 3. Java 项目检测（避免 bash 3.2 的 pipefail + wc 问题）
if ! find "$PROJECT_PATH" -name "*.java" -print -quit 2>/dev/null | grep -q .; then
  echo "ERROR: 未找到 .java 文件，不是 Java 项目: $PROJECT_PATH" >&2
  exit 1
fi

# 4. 依赖工具检测
require_codegraph || exit 1
require_jq || exit 1

# ──────────────────────────────────────────────────────────────
# 提取项目信息
# ──────────────────────────────────────────────────────────────
PROJECT_KEY=$(get_project_name "$PROJECT_PATH")
AGENT_NAME="hero-java-${PROJECT_KEY}"

# 检查 agent 是否已存在
if [ -f "$ROOT/agents/${AGENT_NAME}.md" ]; then
  echo "ERROR: Agent 文件已存在: agents/${AGENT_NAME}.md" >&2
  echo "如需重新生成，请先删除或重命名已有文件" >&2
  exit 1
fi

echo "🚀 开始生成导航 Agent: ${AGENT_NAME}"
echo "项目路径: ${PROJECT_PATH}"
echo "花名: ${CHINESE_NAME}"
echo ""

# ──────────────────────────────────────────────────────────────
# 创建工作目录
# ──────────────────────────────────────────────────────────────
WORK_DIR="$ROOT/.init-work/$PROJECT_KEY"
mkdir -p "$WORK_DIR"

# ──────────────────────────────────────────────────────────────
# Phase 1: 检测项目布局
# ──────────────────────────────────────────────────────────────
echo "📊 Phase 1: 检测项目布局"

LAYOUT_JSON=$(detect_build_tool "$PROJECT_PATH") || {
  echo "ERROR: 布局检测失败" >&2; exit 1; }
BUILD_TOOL=$(echo "$LAYOUT_JSON" | jq -r '.build_tool')

MODULES_JSON=$(analyze_modules "$PROJECT_PATH" "$BUILD_TOOL") || {
  echo "ERROR: 模块分析失败" >&2; exit 1; }
IS_MULTIMODULE=$(echo "$MODULES_JSON" | jq -r '.is_multimodule')
MODULE_COUNT=$(echo "$MODULES_JSON" | jq -r '.module_count')

# 合并 layout.json（供 fill_template 读取）
jq -n \
  --argjson layout "$LAYOUT_JSON" \
  --argjson modules "$MODULES_JSON" \
  --arg project_name "$PROJECT_KEY" \
  '($layout + $modules + {project_name: $project_name})' > "$WORK_DIR/layout.json"

# 推导架构分组
ARCH_GROUP="单模块"
if [ "$IS_MULTIMODULE" = "true" ]; then
  ARCH_GROUP="多模块（${MODULE_COUNT} 子模块）"
fi

echo "✅ 构建工具: $BUILD_TOOL"
echo "✅ 架构: $ARCH_GROUP"
echo ""

# ──────────────────────────────────────────────────────────────
# Phase 2: 检测技术栈
# ──────────────────────────────────────────────────────────────
echo "📊 Phase 2: 检测技术栈"

STACK_JSON=$(detect_framework "$PROJECT_PATH") || {
  echo "ERROR: 框架检测失败" >&2; exit 1; }
FRAMEWORK=$(echo "$STACK_JSON" | jq -r '.framework')
JAVA_VER=$(echo "$STACK_JSON" | jq -r '.version // "unknown"')

MIDDLEWARE_JSON=$(identify_middleware "$PROJECT_PATH" "$BUILD_TOOL") || {
  echo "ERROR: 中间件检测失败" >&2; exit 1; }
MW_COUNT=$(echo "$MIDDLEWARE_JSON" | jq '.middleware | length')

# 合并 stack.json（供 fill_template 读取）
jq -n \
  --argjson stack "$STACK_JSON" \
  --argjson mw "$MIDDLEWARE_JSON" \
  '($stack + $mw)' > "$WORK_DIR/stack.json"

echo "✅ 框架: $FRAMEWORK"
echo "✅ Java: $JAVA_VER"
echo "✅ 中间件: ${MW_COUNT} 项"
echo ""

# ──────────────────────────────────────────────────────────────
# Phase 3: 收集代码证据
# ──────────────────────────────────────────────────────────────
echo "📊 Phase 3: 收集代码证据"

ENTRY_JSON=$(collect_entry_points "$PROJECT_PATH" "$BUILD_TOOL") || {
  echo "ERROR: 入口点收集失败" >&2; exit 1; }
CONFIG_JSON=$(collect_config_files "$PROJECT_PATH") || {
  echo "ERROR: 配置文件收集失败" >&2; exit 1; }
DIR_TREE=$(collect_directory_structure "$PROJECT_PATH") || true

CTRL_COUNT=$(echo "$ENTRY_JSON" | jq '.controllers | length')
SVC_COUNT=$(echo "$ENTRY_JSON" | jq '.services | length')
MAPPER_COUNT=$(echo "$ENTRY_JSON" | jq '.mappers | length')

# 合并 evidence.json（供 fill_template 读取）
jq -n \
  --argjson entry "$ENTRY_JSON" \
  --argjson config "$CONFIG_JSON" \
  --arg dir_tree "$DIR_TREE" \
  '($entry + {configs: $config, directory_tree: $dir_tree})' > "$WORK_DIR/evidence.json"

echo "✅ 控制器: $CTRL_COUNT"
echo "✅ 服务: $SVC_COUNT"
echo "✅ Mapper: $MAPPER_COUNT"
echo ""

# ──────────────────────────────────────────────────────────────
# Phase 4: 填充模板
# ──────────────────────────────────────────────────────────────
echo "📊 Phase 4: 填充模板"

TEMPLATE_FILE="$ROOT/templates/navigator-agent.md.tmpl"
OUTPUT_FILE="$ROOT/agents/${AGENT_NAME}.md"

fill_template \
  "$TEMPLATE_FILE" \
  "$WORK_DIR/stack.json" \
  "$WORK_DIR/layout.json" \
  "$WORK_DIR/evidence.json" \
  "$CHINESE_NAME" \
  "$PROJECT_KEY" \
  "$PROJECT_KEY" \
  "$OUTPUT_FILE" || {
  echo "ERROR: 模板填充失败" >&2; exit 1; }

echo "✅ 已生成: agents/${AGENT_NAME}.md"
echo ""

# ──────────────────────────────────────────────────────────────
# Phase 5: 反伪造验证
# ──────────────────────────────────────────────────────────────
echo "📊 Phase 5: 反伪造验证"

VERIFY_RESULT=$(generate_checks_json "$OUTPUT_FILE" "$PROJECT_PATH") || true
echo "$VERIFY_RESULT" > "$WORK_DIR/checks.json"

PASSED=$(echo "$VERIFY_RESULT" | jq -r '.overall.passed // 0')
FAILED=$(echo "$VERIFY_RESULT" | jq -r '.overall.failed // 0')

if [ "$FAILED" -gt 0 ]; then
  echo "⚠️  验证结果: $PASSED 通过, $FAILED 未通过"
  SUSPICIOUS=$(echo "$VERIFY_RESULT" | jq -r '.overall.suspicious | join(", ")')
  echo "⚠️  可疑项: $SUSPICIOUS"
else
  echo "✅ 路径验证通过（$PASSED/$((PASSED + FAILED)) 项检查）"
fi
echo ""

# ──────────────────────────────────────────────────────────────
# Phase 6: Git 分支与提交
# ──────────────────────────────────────────────────────────────
echo "📊 Phase 6: Git 分支与提交"

BRANCH_NAME="feat/init-${PROJECT_KEY}-$(date +%y%m%d)"

# 先切回 main，确保分支从 main 创建（避免链式分支：ecrm → owner-biz → hotel）
# 注意：此时工作区仅有 Phase 4 生成的新 agent 文件（untracked），checkout 不受影响
git -C "$ROOT" checkout main 2>&1 || {
  echo "ERROR: 无法切换到 main 分支（工作区可能有未提交变更）" >&2; exit 1; }

# 创建并切换到新分支
create_branch "$ROOT" "$BRANCH_NAME" || {
  echo "ERROR: 创建分支失败" >&2; exit 1; }
checkout_branch "$ROOT" "$BRANCH_NAME" || {
  echo "ERROR: 切换分支失败" >&2; exit 1; }

# 注册到 refresh-state（幂等，已存在则跳过）
state_add "$PROJECT_KEY" "$PROJECT_PATH" "$CHINESE_NAME" || true

# 提交变更
COMMIT_MSG="feat: 新增领航 Agent ${AGENT_NAME}（${CHINESE_NAME}）

- 新增 agents/${AGENT_NAME}.md
- 注册到 docs/.refresh-state.json"

commit_changes "$ROOT" "$COMMIT_MSG" || {
  echo "ERROR: 提交失败" >&2; exit 1; }

echo "✅ 分支: $BRANCH_NAME"
echo ""

# ──────────────────────────────────────────────────────────────
# 输出 MR 指引
# ──────────────────────────────────────────────────────────────
print_mr_guidance "$ROOT" "$BRANCH_NAME" "$AGENT_NAME" "$CHINESE_NAME"

# ──────────────────────────────────────────────────────────────
# 输出验证摘要
# ──────────────────────────────────────────────────────────────
echo ""
echo "=========================================="
echo "🎉 导航 Agent 生成完成！"
echo "=========================================="
echo "Agent 文件: agents/${AGENT_NAME}.md"
echo "验证状态: $PASSED 通过, $FAILED 未通过"
echo "Git 分支: $BRANCH_NAME"
echo "中间产物: .init-work/${PROJECT_KEY}/"
echo ""
echo "下一步: 按照上述指引创建 MR"
echo "=========================================="
