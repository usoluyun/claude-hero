#!/usr/bin/env bash
# 零依赖断言助手。被各 test_*.sh source。
# 注意：每个测试文件须以独立子进程运行（bash test_*.sh，见 run.sh），
# 否则重复 source 会把计数器归零。
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

assert_ok() {  # 命令应成功
  local msg="${2:-}"
  if eval "$1"; then ASSERT_PASS=$((ASSERT_PASS+1));
  else ASSERT_FAIL=$((ASSERT_FAIL+1)); echo "  ✗ ${msg:-assert_ok}: [$1] failed"; fi
}

assert_fail() {  # 命令应失败
  local msg="${2:-}"
  if eval "$1"; then ASSERT_FAIL=$((ASSERT_FAIL+1)); echo "  ✗ ${msg:-assert_fail}: [$1] should fail"; \
  else ASSERT_PASS=$((ASSERT_PASS+1)); fi
}

assert_summary() {
  echo "  → $ASSERT_PASS passed, $ASSERT_FAIL failed"
  [[ "$ASSERT_FAIL" -eq 0 ]]
}
