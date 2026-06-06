#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/assert.sh"
CASES="$DIR/cases.tsv"

assert_ok "[ -f '$CASES' ]" "cases.tsv exists"

# 合法期望值：6 条 lane + 两条重型线 + 不接管
valid="bugfix iterate refactor research perf security prd refresh none"

if [ -f "$CASES" ]; then
  ln=0
  while IFS=$'\t' read -r intent expected || [ -n "$intent" ]; do
    ln=$((ln+1))
    case "$intent" in ''|'#'*) continue;; esac   # 跳过空行/注释
    found=0
    for v in $valid; do [ "$expected" = "$v" ] && found=1; done
    assert_ok "[ '$found' = 1 ]" "line $ln expected '$expected' is valid lane"
    assert_ok "[ -n '$intent' ]" "line $ln intent non-empty"
  done < "$CASES"
fi

assert_summary
