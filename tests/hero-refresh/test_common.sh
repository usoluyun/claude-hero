#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/assert.sh"
source "$DIR/../../scripts/lib/refresh-common.sh"

assert_eq "$HOME/foo" "$(expand_path '~/foo')" "expand ~/foo"
assert_eq "$HOME" "$(expand_path '~')" "expand ~"
assert_eq "/abs/path" "$(expand_path '/abs/path')" "expand absolute unchanged"
assert_ok "[[ -d \"$(repo_root)/agents\" ]]" "repo_root 指向含 agents/ 的仓库根"

assert_summary
