#!/usr/bin/env bash
# 零依赖断言助手。被各 test_*.sh source。
ASSERT_PASS=0
ASSERT_FAIL=0

assert_eq() {
  local expected="$1" actual="$2" msg="${3:-}"
  if [[ "$expected" == "$actual" ]]; then
    ASSERT_PASS=$((ASSERT_PASS+1))
  else
    ASSERT_FAIL=$((ASSERT_FAIL+1))
    echo "  ✗ ${msg:-assert_eq}: expected [$expected] got [$actual]"
  fi
}

assert_ok() {
  local msg="${2:-}"
  if eval "$1"; then ASSERT_PASS=$((ASSERT_PASS+1));
  else ASSERT_FAIL=$((ASSERT_FAIL+1)); echo "  ✗ ${msg:-assert_ok}: [$1] failed"; fi
}

assert_summary() {
  echo "  → $ASSERT_PASS passed, $ASSERT_FAIL failed"
  [[ "$ASSERT_FAIL" -eq 0 ]]
}
