#!/usr/bin/env bash
# hero-issue-poller.sh — 轮询 GitLab 待办 Issue 并输出格式化摘要。
#
# 用法:
#   scripts/hero-issue-poller.sh [OPTIONS]
#
# 选项:
#   --agent <name>    按 agent 过滤 (backend-dev|data-engineer|test-engineer|
#                     code-reviewer|security-auditor|tech-lead)
#   --limit <N>       最大返回数 (默认: 20)
#   --dry-run         只显示将要执行的命令，不实际执行
#   --json            以 JSON 格式输出
#   -h, --help        显示帮助信息
#
# 依赖:
#   glab (GitLab CLI) — https://gitlab.com/gitlab-org/cli
set -euo pipefail

# ──────────────────────────────────────────────────────────────
# 颜色定义
# ──────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ──────────────────────────────────────────────────────────────
# 帮助信息
# ──────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Poll GitLab for pending Issues labeled "hero::status:pending".

Options:
  --agent <name>      Filter by agent label (hero::agent:<name>)
                      Allowed: backend-dev, data-engineer, test-engineer,
                      code-reviewer, security-auditor, tech-lead
  --limit <N>         Max results (default: 20)
  --dry-run           Show what would be queried without executing glab
  --json              Output as JSON instead of table
  -h, --help          Show this help message

Examples:
  $(basename "$0")
  $(basename "$0") --agent backend-dev
  $(basename "$0") --agent test-engineer --limit 5
  $(basename "$0") --dry-run
  $(basename "$0") --json
EOF
  exit 0
}

# ──────────────────────────────────────────────────────────────
# 辅助函数
# ──────────────────────────────────────────────────────────────
log_info()  { echo -e "${GREEN}${1}${NC}"; }
log_warn()  { echo -e "${YELLOW}${1}${NC}" >&2; }
log_error() { echo -e "${RED}${1}${NC}" >&2; }

# ──────────────────────────────────────────────────────────────
# 默认值
# ──────────────────────────────────────────────────────────────
AGENT=""
LIMIT=20
DRY_RUN=0
JSON_OUTPUT=0

# ──────────────────────────────────────────────────────────────
# 参数解析
# ──────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent)
      if [[ -z "${2:-}" ]]; then
        log_error "ERROR: --agent 需要参数"
        exit 1
      fi
      AGENT="$2"
      shift 2
      ;;
    --limit)
      if [[ -z "${2:-}" ]]; then
        log_error "ERROR: --limit 需要参数"
        exit 1
      fi
      LIMIT="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --json)
      JSON_OUTPUT=1
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      log_error "ERROR: 未知选项: $1"
      echo "使用 -h 查看帮助" >&2
      exit 1
      ;;
  esac
done

# ──────────────────────────────────────────────────────────────
# 验证参数
# ──────────────────────────────────────────────────────────────
VALID_AGENTS=("backend-dev" "data-engineer" "test-engineer" "code-reviewer" "security-auditor" "tech-lead")
if [[ -n "$AGENT" ]]; then
  valid=0
  for a in "${VALID_AGENTS[@]}"; do
    if [[ "$a" == "$AGENT" ]]; then
      valid=1
      break
    fi
  done
  if [[ "$valid" -eq 0 ]]; then
    log_error "ERROR: 无效的 agent 名称: ${AGENT}"
    log_error "允许值: ${VALID_AGENTS[*]}"
    exit 1
  fi
fi

# ──────────────────────────────────────────────────────────────
# 构建查询标签
# ──────────────────────────────────────────────────────────────
LABELS="hero::status:pending"
if [[ -n "$AGENT" ]]; then
  LABELS="${LABELS},hero::agent:${AGENT}"
fi

# ──────────────────────────────────────────────────────────────
# Dry-run 模式
# ──────────────────────────────────────────────────────────────
GITLAB_HOST="${GITLAB_HOST:-gitlab.corp.yaduo.com}"
GLAB_CMD="glab issue list --label \"${LABELS}\" --opened --per-page ${LIMIT}"

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo -e "${YELLOW}[DRY RUN]${NC} Would query Issues with labels: ${LABELS}"
  echo -e "${YELLOW}[DRY RUN]${NC} ${GLAB_CMD}"
  exit 0
fi

# ──────────────────────────────────────────────────────────────
# 检查依赖
# ──────────────────────────────────────────────────────────────
if ! command -v glab &>/dev/null; then
  log_error "ERROR: 需要 glab (GitLab CLI)，请先安装"
  log_error "  https://gitlab.com/gitlab-org/cli#installation"
  exit 1
fi

# ──────────────────────────────────────────────────────────────
# 检查 GitLab 认证状态
# ──────────────────────────────────────────────────────────────
if ! glab auth status &>/dev/null; then
  log_error "ERROR: glab 未认证。请先运行: glab auth login"
  log_error "  (或设置 GITLAB_TOKEN 环境变量)"
  exit 1
fi

# ──────────────────────────────────────────────────────────────
# 查询 GitLab Issues
# ──────────────────────────────────────────────────────────────
echo -e "${CYAN}🔍 查询待办 Issues...${NC}" >&2
echo -e "${CYAN}   标签: ${LABELS}${NC}" >&2

# glab issue list 输出格式: IID,Title,Labels,Web URL,Created At
# 使用 --fields 和 --output json 确保结构化输出
ISSUES_RAW=""
if ! ISSUES_RAW="$(glab issue list --label "${LABELS}" --opened --per-page "${LIMIT}" --output json 2>/dev/null)"; then
  log_error "ERROR: glab 查询失败"
  exit 1
fi

# ──────────────────────────────────────────────────────────────
# 解析结果
# ──────────────────────────────────────────────────────────────
# 尝试用 jq 解析（如果可用）；否则降级为文本解析
ISSUE_COUNT=0

if command -v jq &>/dev/null; then
  # 用 jq 解析 JSON 输出
  ISSUE_COUNT="$(echo "$ISSUES_RAW" | jq 'length')"

  if [[ "$ISSUE_COUNT" -eq 0 ]]; then
    echo -e "${YELLOW}No pending Issues${NC}"
    exit 0
  fi

  if [[ "$JSON_OUTPUT" -eq 1 ]]; then
    # JSON 输出模式
    echo "$ISSUES_RAW" | jq \
      --arg host "${GITLAB_HOST}" \
      '[
        .[] | {
          iid: .iid,
          title: .title,
          agent: (
            (.labels // []) | map(select(startswith("hero::agent:"))) | first // ""
          ) | sub("^hero::agent:"; ""),
          created: (.created_at // "")[0:10],
          url: "https://\($host)/\(.references.full | sub("^"; ""))"
        }
      ] | { issues: ., total: length }'
    exit 0
  fi

  # 表格式输出
  echo ""
  echo -e "${BOLD}╭─────┬──────────────────────────────────┬─────────────────┬────────────╮${NC}"
  echo -e "${BOLD}│ ${NC}${BOLD}IID${NC}  │ ${NC}${BOLD}Title${NC}                         │ ${NC}${BOLD}Agent${NC}          │ ${NC}${BOLD}Created${NC}    │${BOLD}${NC}"
  echo -e "${BOLD}├─────┼──────────────────────────────────┼─────────────────┼────────────┤${NC}"

  echo "$ISSUES_RAW" | jq -r '.[] | [
    (.iid | tostring),
    .title,
    ((.labels // []) | map(select(startswith("hero::agent:"))) | first // "") | sub("^hero::agent:"; ""),
    (.created_at // "")[0:10]
  ] | @tsv' | while IFS=$'\t' read -r iid title agent created; do
    # 截断标题（不超过 32 个中文字符宽度）
    if [[ ${#title} -gt 32 ]]; then
      title="${title:0:29}..."
    fi
    # 补齐空格
    printf "│ %-3s │ %-32s │ %-15s │ %-10s │\n" "$iid" "$title" "$agent" "$created"
  done

  echo -e "${BOLD}╰─────┴──────────────────────────────────┴─────────────────┴────────────╯${NC}"
else
  # 降级：无 jq 时尝试文本解析
  # glab issue list 默认输出: #IID  Title  Labels  ...
  log_warn "⚠ jq 未安装，使用降级文本解析模式"
  log_warn "  建议: brew install jq"

  if [[ -z "$ISSUES_RAW" ]]; then
    echo -e "${YELLOW}No pending Issues${NC}"
    exit 0
  fi

  # 简单统计行数（去掉可能的表头或空行）
  ISSUE_COUNT="$(echo "$ISSUES_RAW" | grep -c '^#' 2>/dev/null || echo 0)"

  if [[ "$ISSUE_COUNT" -eq 0 ]]; then
    echo -e "${YELLOW}No pending Issues${NC}"
    exit 0
  fi

  echo ""
  echo -e "${BOLD}╭─────┬──────────────────────────────────┬─────────────────┬────────────╮${NC}"
  echo -e "${BOLD}│ ${NC}${BOLD}IID${NC}  │ ${NC}${BOLD}Title${NC}                         │ ${NC}${BOLD}Agent${NC}          │ ${NC}${BOLD}Created${NC}    │${BOLD}${NC}"
  echo -e "${BOLD}├─────┼──────────────────────────────────┼─────────────────┼────────────┤${NC}"
  echo "$ISSUES_RAW" | while IFS= read -r line; do
    echo "│ $line │"
  done
  echo -e "${BOLD}╰─────┴──────────────────────────────────┴─────────────────┴────────────╯${NC}"
fi

# ──────────────────────────────────────────────────────────────
# 汇总输出
# ──────────────────────────────────────────────────────────────
echo ""
log_info "Found ${ISSUE_COUNT} pending Issues"
exit 0
