#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/assert.sh"
source "$DIR/../../scripts/lib/refresh-common.sh"
source "$DIR/../../scripts/lib/refresh-evidence.sh"

assert_eq "$(repo_root)/docs/.refresh-work/foo" "$(evidence_dir foo)" "evidence_dir 路径"

# ensure_exclude：建一个临时 git 仓库，调用两次应幂等（只一行 .codegraph/）
tmp="$(mktemp -d)"; git -C "$tmp" init -q
ensure_exclude "$tmp"; ensure_exclude "$tmp"
count="$(grep -c '^\.codegraph/$' "$tmp/.git/info/exclude")"
assert_eq "1" "$count" "ensure_exclude 幂等，只一行"
rm -rf "$tmp"

# ensure_exclude 兼容 git worktree（worktree 里 .git 是文件而非目录）
main="$(mktemp -d)"; git -C "$main" init -q
git -C "$main" -c user.email=a@b.c -c user.name=t commit -q --allow-empty -m init
wt="$(mktemp -d)/wt"
git -C "$main" worktree add -q "$wt" >/dev/null 2>&1
ensure_exclude "$wt"
wt_gitdir="$(git -C "$wt" rev-parse --absolute-git-dir)"
assert_ok "grep -qxF '.codegraph/' \"$wt_gitdir/info/exclude\"" "ensure_exclude 对 worktree 生效"
git -C "$main" worktree remove --force "$wt" >/dev/null 2>&1 || rm -rf "$wt"
rm -rf "$main"

assert_summary
