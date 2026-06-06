#!/usr/bin/env bash
# 跑 tests/hero-dispatch 下所有 test_*.sh，任一失败则整体失败。
set -u
cd "$(dirname "$0")"
fail=0
for t in test_*.sh; do
  [ -f "$t" ] || continue
  echo "== $t =="
  bash "$t" || fail=1
done
[[ "$fail" -eq 0 ]] && echo "ALL TESTS PASSED" || { echo "SOME TESTS FAILED"; exit 1; }
