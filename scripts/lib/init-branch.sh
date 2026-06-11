#!/usr/bin/env bash
# Git 分支与 MR 引导函数库。被 hero-init.sh 与 CLI source。无副作用（source 时不执行动作）。
# 依赖: git。所有函数幂等（多次调用效果相同）。
# 不自动 push，只打印 push 指令（决策 #2）。

# ── 确保 expand_path 可用（init-common.sh 不提供它，从 refresh-common.sh 补） ──
if ! declare -f expand_path >/dev/null 2>&1; then
  _init_br_libdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [ -f "$_init_br_libdir/refresh-common.sh" ]; then
    . "$_init_br_libdir/refresh-common.sh"
  else
    expand_path() { local p="$1"; case "$p" in "~") echo "$HOME" ;; "~/"*) echo "$HOME/${p#\~/}" ;; *) echo "$p" ;; esac; }
  fi
fi

# ── check_git_clean ───────────────────────────────────────────────────────────
# 参数: <repo_path>
# 行为: 检查 git 工作区是否干净（无未提交变更）
# 实现: git status --porcelain，排除 untracked 文件（??），只检查 modified/staged
# 返回: 0（干净）/ 1（有变更, 输出错误信息到 stderr）

check_git_clean() {
  local repo; repo="$(expand_path "$1")"
  local st

  st="$(git -C "$repo" status --porcelain 2>/dev/null)" || {
    echo "ERROR: 无法获取 git 状态: $repo" >&2
    return 1
  }

  # 过滤掉 untracked 文件（行首为 ?? 的行），只检查已跟踪文件的变更
  local dirty
  dirty="$(echo "$st" | grep -v '^??' 2>/dev/null || true)"

  if [ -z "$dirty" ]; then
    return 0
  fi

  echo "ERROR: git 工作区有未提交变更:" >&2
  echo "$dirty" >&2
  return 1
}

# ── create_branch ─────────────────────────────────────────────────────────────
# 参数: <repo_path> <branch_name>
# 行为: 从当前 HEAD 创建新分支（不 checkout）
# 实现: git branch <branch_name>
# 注意: 如果分支已存在，输出警告并返回 0（幂等）
# 返回: 0/1

create_branch() {
  local repo; repo="$(expand_path "$1")"
  local branch_name="$2"

  if [ -z "$branch_name" ]; then
    echo "ERROR: create_branch 需要分支名参数" >&2
    return 1
  fi

  # 检查分支是否已存在（幂等：已存在则警告并返回 0）
  if git -C "$repo" rev-parse --verify "$branch_name" >/dev/null 2>&1; then
    echo "WARNING: 分支 '$branch_name' 已存在，跳过创建" >&2
    return 0
  fi

  git -C "$repo" branch "$branch_name" 2>/dev/null || {
    echo "ERROR: 创建分支 '$branch_name' 失败" >&2
    return 1
  }

  return 0
}

# ── checkout_branch ───────────────────────────────────────────────────────────
# 参数: <repo_path> <branch_name>
# 行为: 切换到指定分支
# 实现: git checkout <branch_name>
# 返回: 0/1

checkout_branch() {
  local repo; repo="$(expand_path "$1")"
  local branch_name="$2"

  if [ -z "$branch_name" ]; then
    echo "ERROR: checkout_branch 需要分支名参数" >&2
    return 1
  fi

  # 检查是否已在目标分支上（幂等）
  local current
  current="$(git -C "$repo" rev-parse --abbrev-ref HEAD 2>/dev/null)" || {
    echo "ERROR: 无法获取当前分支名" >&2
    return 1
  }
  if [ "$current" = "$branch_name" ]; then
    return 0
  fi

  local err
  err="$(git -C "$repo" checkout "$branch_name" 2>&1)" || {
    echo "ERROR: 切换到分支 '$branch_name' 失败: ${err:-分支可能不存在}" >&2
    return 1
  }
}

# ── commit_changes ────────────────────────────────────────────────────────────
# 参数: <repo_path> <commit_message>
# 行为: 将所有 staged 和 unstaged 的变更提交
# 实现:
#   1. git add -A
#   2. 检查是否有 staged 变更
#   3. 如有，执行 commit
# 返回: 0（有变更被提交）/ 1（无变更可提交）

commit_changes() {
  local repo; repo="$(expand_path "$1")"
  local msg="$2"

  if [ -z "$msg" ]; then
    echo "ERROR: commit_changes 需要 commit message 参数" >&2
    return 1
  fi

  # 1. 添加所有变更
  git -C "$repo" add -A 2>/dev/null || {
    echo "ERROR: git add 失败" >&2
    return 1
  }

  # 2. 检查是否有 staged 变更
  if git -C "$repo" diff --staged --quiet 2>/dev/null; then
    return 1
  fi

  # 3. 执行 commit
  git -C "$repo" commit -m "$msg" 2>/dev/null || {
    echo "ERROR: git commit 失败" >&2
    return 1
  }

  return 0
}

# ── print_mr_guidance ────────────────────────────────────────────────────────
# 参数: <repo_path> <branch_name> <agent_name> <chinese_name>
# 行为: 输出 MR 创建指引（echo 到 stdout），包含：
#   - git push 命令（含 set-upstream）
#   - MR URL（GitLab 风格，参数化模板让用户填 host/repo）
#   - MR 描述模板（包含验证清单）
# 返回: 0

print_mr_guidance() {
  local repo; repo="$(expand_path "$1")"
  local branch_name="$2"
  local agent_name="$3"
  local chinese_name="$4"

  local repo_url
  repo_url="$(git -C "$repo" remote get-url origin 2>/dev/null || echo "https://<git-host>/<org>/<repo>")"

  # 从 remote URL 提取 host 和 repo path
  local host repo_path
  case "$repo_url" in
    git@*:*)
      host="$(echo "$repo_url" | sed 's/^git@//' | sed 's/:.*//')"
      repo_path="$(echo "$repo_url" | sed 's/.*://' | sed 's/\.git$//')"
      ;;
    https://*)
      host="$(echo "$repo_url" | sed 's|^https://||' | sed 's|/.*||')"
      repo_path="$(echo "$repo_url" | sed "s|^https://$host/||" | sed 's/\.git$//')"
      ;;
    *)
      host="<git-host>"
      repo_path="<org>/<repo>"
      ;;
  esac

  echo ""
  echo "============================================"
  echo "  MR 创建指引"
  echo "============================================"
  echo ""
  echo "分支名: $branch_name"
  echo "Agent: ${agent_name}（${chinese_name}）"
  echo ""
  echo "---"
  echo ""
  echo "步骤 1：推送分支"
  echo ""
  echo "  git push -u origin $branch_name"
  echo ""
  echo "---"
  echo ""
  echo "步骤 2：创建 Merge Request"
  echo ""
  echo "  MR URL（请替换 <git-host> 和 <org>/<repo> 为实际值）："
  echo "  https://${host}/${repo_path}/-/merge_requests/new?merge_request[source_branch]=${branch_name}"
  echo ""
  echo "---"
  echo ""
  echo "步骤 3：MR 描述模板"
  echo ""
  echo "  ## 变更概述"
  echo "  "
  echo "  新增领航 Agent：**${agent_name}**（${chinese_name}）"
  echo "  "
  echo "  ## 变更文件"
  echo "  "
  echo "  - \`agents/${agent_name}.md\` — Agent 定义文件"
  echo "  - \`docs/hero-agent-roster.md\` — 花名册登记"
  echo "  - \`docs/.refresh-state.json\` — 刷新状态注册"
  echo "  "
  echo "  ## 验证清单"
  echo "  "
  echo "  - [ ] Agent 文件结构与现有 agent 一致"
  echo "  - [ ] 技术栈声明与 pom.xml/build.gradle 一致"
  echo "  - [ ] 引用的 Java 类在代码库中真实存在"
  echo "  - [ ] 触发关键词与项目标识符匹配"
  echo "  - [ ] 花名无冲突"
  echo "  - [ ] 花名册格式正确"
  echo "  - [ ] \`hero-agent-roster.md\` 中触发词与 agent 一致"
  echo "  - [ ] 未提交敏感信息（密钥/token）"
  echo "  "
  echo "  ## Reviewer 注意事项"
  echo "  "
  echo "  - 建议用 \`hero 刷新 ${chinese_name}\` 验证保鲜流程"
  echo "  - 确认项目路径配置正确"
  echo ""
  echo "============================================"
  echo ""
}
