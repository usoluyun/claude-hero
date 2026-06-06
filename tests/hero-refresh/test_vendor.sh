#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/assert.sh"
source "$DIR/../../scripts/lib/refresh-common.sh"
source "$DIR/../../scripts/lib/refresh-vendor.sh"

libs="$(extract_fingerprint_libs "$DIR/fixtures/agent-sample.md")"
# 期望命中：spring boot, eureka, apollo, mybatis-plus, rocketmq, jetcache, fastjson, druid（去重排序）
assert_ok "grep -qx 'spring boot' <<<\"\$libs\"" "命中 spring boot"
assert_ok "grep -qx 'mybatis-plus' <<<\"\$libs\"" "命中 mybatis-plus"
assert_ok "grep -qx 'rocketmq' <<<\"\$libs\"" "命中 rocketmq"
assert_ok "grep -qx 'eureka' <<<\"\$libs\"" "命中 eureka"
# mybatis-plus 命中时不应再单独冒出裸 mybatis（两者都在字典，但②段写的是 mybatis-plus）
assert_eq "1" "$(grep -c 'mybatis' <<<"$libs")" "mybatis 系只出现一次（mybatis-plus）"
assert_eq "spring-cloud" "$(vendor_slug 'spring cloud')" "slug 空格转横杠"

# 否定行（不是/非/无）整行跳过，不误命中其声明「不用」的库；同行正向库仍命中
nslibs="$(extract_fingerprint_libs "$DIR/fixtures/agent-nonspring.md")"
assert_eq "" "$(grep -E 'spring boot|eureka|apollo|rocketmq|jetcache|mybatis' <<<"$nslibs")" "否定行里的库不被误命中"
assert_ok "grep -qx 'druid' <<<\"\$nslibs\"" "正向行的 druid 仍命中"
assert_ok "grep -qx 'quartz' <<<\"\$nslibs\"" "正向行的 quartz 仍命中"

assert_summary
