#!/usr/bin/env bash
#
# test-install.sh - 在隔离环境中测试 install.sh
#
# 用法:
#   bash scripts/test-install.sh
#
# 说明:
#   创建一个临时目录，将 install.sh 安装到其中，然后验证
#   agents / skills / hooks 是否被正确安装。
#   全部通过退出码 0，任一失败退出码 1。

set -euo pipefail

PASS=0
FAIL=0
ERRORS=()

pass() {
  PASS=$((PASS + 1))
  printf '\033[32m[PASS]\033[0m %s\n' "$1"
}

fail() {
  FAIL=$((FAIL + 1))
  ERRORS+=("$1: $2")
  printf '\033[31m[FAIL]\033[0m %s - %s\n' "$1" "$2"
}

warn() {
  printf '\033[33m[WARN]\033[0m %s\n' "$*"
}

# --- 创建临时目录 ---
TMPDIR=$(mktemp -d /tmp/test-hero-XXXXXX)
echo "=> 临时目录: $TMPDIR"
cleanup() { rm -rf "$TMPDIR"; echo "=> 已清理: $TMPDIR"; }
trap cleanup EXIT

# --- 仓库根目录 ---
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "=> 仓库目录: $REPO_DIR"
echo

# --- 1) manifest.yaml ---
echo "=== 验证 manifest.yaml ==="
MANIFEST="$REPO_DIR/manifest.yaml"
if [ -f "$MANIFEST" ]; then
  pass "manifest.yaml 存在"
else
  fail "manifest.yaml" "文件不存在"
fi

ENTRY_COUNT=$(awk '/^entries:/{f=1;next} f&&/^[ ]*-[ ]*source:/{c++} END{print c+0}' "$MANIFEST")
if [ "$ENTRY_COUNT" -ge 3 ]; then
  pass "manifest.yaml entries: $ENTRY_COUNT"
else
  fail "manifest.yaml" "entries 不足: $ENTRY_COUNT"
fi
echo

# --- 2) manifest source 路径 ---
echo "=== 验证 manifest source 路径 ==="
BAD=0
while IFS=$'\t' read -r src _ _; do
  [ -n "$src" ] || continue
  if [ ! -e "$REPO_DIR/$src" ]; then
    fail "manifest 路径" "不存在: $src"
    BAD=$((BAD + 1))
  fi
done < <(awk '
  /^entries:/{e=1;next}
  e&&/^[ ]*-[ ]*source:/{
    if(s!="") print s"\t"t"\t"m
    s=$0; sub(/^[^:]*:[ ]*/,"",s); t=""; m=""; next
  }
  e&&/^[ ]*target:/{t=$0; sub(/^[^:]*:[ ]*/,"",t); next}
  e&&/^[ ]*mode:/{m=$0; sub(/^[^:]*:[ ]*/,"",m); sub(/[ ]*#.*/,"",m); next}
  END{if(s!="") print s"\t"t"\t"m}
' "$MANIFEST")
if [ "$BAD" -eq 0 ]; then
  pass "所有 source 路径有效"
fi
echo

# --- 3) 执行 install.sh ---
echo "=== 执行 install.sh ==="
export CLAUDE_HOME="$TMPDIR"
if bash "$REPO_DIR/install.sh" 2>&1; then
  pass "install.sh 执行成功"
else
  fail "install.sh" "执行失败"
fi
echo

# --- 4) 验证 agents ---
echo "=== 验证 agents ==="
AGENTS_DIR="$TMPDIR/agents"
if [ -d "$AGENTS_DIR" ]; then
  pass "agents/ 目录存在"
  AGENT_COUNT=$(find "$AGENTS_DIR" -maxdepth 1 -name 'hero-java-*.md' 2>/dev/null | wc -l | tr -d ' ')
  if [ "$AGENT_COUNT" -ge 9 ]; then
    pass "hero-java-*.md: $AGENT_COUNT"
  else
    fail "agents" "hero-java-*.md 不足: $AGENT_COUNT (期望 >= 9)"
  fi
  LINK_COUNT=$(find "$AGENTS_DIR" -maxdepth 1 -type l 2>/dev/null | wc -l | tr -d ' ')
  if [ "$LINK_COUNT" -gt 0 ]; then
    pass "agents 软链: $LINK_COUNT"
  else
    warn "agents 无软链 (可能为复制模式)"
  fi
else
  fail "agents" "agents/ 目录不存在"
fi
echo

# --- 5) 验证 skills ---
echo "=== 验证 skills ==="
SKILLS_DIR="$TMPDIR/skills"
if [ -d "$SKILLS_DIR" ]; then
  pass "skills/ 目录存在"
  SKILL_COUNT=$(find "$SKILLS_DIR" -maxdepth 1 -type l 2>/dev/null | wc -l | tr -d ' ')
  if [ "$SKILL_COUNT" -ge 10 ]; then
    pass "skills 数: $SKILL_COUNT"
  else
    fail "skills" "skills 不足: $SKILL_COUNT (期望 >= 10)"
  fi
else
  fail "skills" "skills/ 目录不存在"
fi
echo

# --- 6) 验证 hooks ---
echo "=== 验证 hooks ==="
HOOKS_DIR="$TMPDIR/hooks"
if [ -d "$HOOKS_DIR" ]; then
  pass "hooks/ 目录存在"
  HOOK_COUNT=$(find "$HOOKS_DIR" -maxdepth 1 -type l 2>/dev/null | wc -l | tr -d ' ')
  if [ "$HOOK_COUNT" -ge 1 ]; then
    pass "hooks 数: $HOOK_COUNT"
  else
    fail "hooks" "hooks 不足: $HOOK_COUNT (期望 >= 1)"
  fi
  if [ -f "$HOOKS_DIR/hero-refresh-check.sh" ] || [ -L "$HOOKS_DIR/hero-refresh-check.sh" ]; then
    pass "hero-refresh-check.sh 存在"
  else
    fail "hooks" "hero-refresh-check.sh 不存在"
  fi
else
  fail "hooks" "hooks/ 目录不存在"
fi
echo

# --- 汇总 ---
echo "=============================="
echo "结果: $PASS 通过, $FAIL 失败"
if [ "$FAIL" -gt 0 ]; then
  echo "失败详情:"
  for e in "${ERRORS[@]}"; do echo "  - $e"; done
  exit 1
fi
exit 0
