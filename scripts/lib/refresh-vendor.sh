#!/usr/bin/env bash
# 解析领航 agent ②技术栈指纹 → context7 解析 id → 抓取写本地。
# 依赖：refresh-common.sh（repo_root）；refresh_vendor_docs 运行时还依赖 refresh-state.sh（state_get）。
# 注意：bash 3.2 不支持 declare -A，改用 case 语句实现字典查找。

# 字典：keyword（小写，出现在②段即命中） -> context7 搜索词。可持续扩充。
# 用 case 语句替代 declare -A，兼容 bash 3.2（macOS 系统 bash）。
# 注意：_lib_dict_keys 与 _lib_dict_value 必须同步维护，新增关键词两处都要加。
_lib_dict_keys() {
  cat <<'EOF'
spring boot
spring cloud
mybatis-plus
mybatis
rocketmq
jetcache
eureka
apollo
druid
fastjson
quartz
xxljob
xxl-job
skywalking
EOF
}

_lib_dict_value() {
  local k="$1"
  case "$k" in
    "spring boot")   echo "spring boot" ;;
    "spring cloud")  echo "spring cloud" ;;
    "mybatis-plus")  echo "mybatis-plus" ;;
    "mybatis")       echo "mybatis" ;;
    "rocketmq")      echo "rocketmq" ;;
    "jetcache")      echo "jetcache" ;;
    "eureka")        echo "eureka" ;;
    "apollo")        echo "apollo" ;;
    "druid")         echo "druid" ;;
    "fastjson")      echo "fastjson" ;;
    "quartz")        echo "quartz" ;;
    "xxljob")        echo "xxl-job" ;;
    "xxl-job")       echo "xxl-job" ;;
    "skywalking")    echo "skywalking" ;;
    *) ;;
  esac
}

agent_file() { echo "$(repo_root)/agents/$1.md"; }

# 抽出②技术栈指纹段（从 "## ②" 到下一个 "## " 之间），小写后扫字典命中关键词。
# 同时做 mybatis dedup：若 mybatis-plus 已命中，则去掉裸 mybatis。
extract_fingerprint_libs() {
  local file="$1" section
  section="$(awk '/^## ②/{f=1;next} /^## /{f=0} f' "$file" | tr '[:upper:]' '[:lower:]')"
  local k hits=""
  while IFS= read -r k; do
    [[ -z "$k" ]] && continue
    if grep -qF "$k" <<<"$section"; then
      local v; v="$(_lib_dict_value "$k")"
      [[ -n "$v" ]] && hits="${hits:+$hits$'\n'}$v"
    fi
  done < <(_lib_dict_keys)
  printf '%s\n' "$hits" | sort -u | awk '
    { lines[NR]=$0; seen[$0]=1 }
    END {
      for (i=1;i<=NR;i++) {
        if (lines[i]=="mybatis" && ("mybatis-plus" in seen)) continue
        print lines[i]
      }
    }'
}

context7_resolve() {  # echo libraryId（取搜索结果第一个 id），失败 echo 空
  local lib="$1" auth=()
  [[ -n "${CONTEXT7_API_KEY:-}" ]] && auth=(-H "Authorization: Bearer ${CONTEXT7_API_KEY}")
  curl -s ${auth[@]+"${auth[@]}"} \
    --get "https://context7.com/api/v2/libs/search" --data-urlencode "libraryName=${lib}" \
    | jq -r '(.results // .libraries // .)[0].id // empty' 2>/dev/null
}

context7_fetch() {  # 抓 context 写文件
  local libraryId="$1" out="$2" auth=()
  [[ -n "${CONTEXT7_API_KEY:-}" ]] && auth=(-H "Authorization: Bearer ${CONTEXT7_API_KEY}")
  curl -s ${auth[@]+"${auth[@]}"} \
    --get "https://context7.com/api/v2/context" \
    --data-urlencode "libraryId=${libraryId}" \
    --data-urlencode "query=usage and configuration" \
    -o "$out"
  [[ -s "$out" ]]
}

vendor_slug() { echo "$1" | tr ' /' '--' | tr '[:upper:]' '[:lower:]'; }

refresh_vendor_docs() {  # 对一个项目的 agent 跑整套
  # 依赖：调用方须已 source refresh-state.sh（提供 state_get）
  local proj="$1" agent file lib id out
  agent="$(state_get "$proj" agent)"
  file="$(agent_file "$agent")"
  [[ -f "$file" ]] || { echo "WARN: 无 agent 文件 $file" >&2; return 0; }
  local vendor_dir; vendor_dir="$(repo_root)/docs/vendor-docs"
  mkdir -p "$vendor_dir"
  while IFS= read -r lib; do
    [[ -z "$lib" ]] && continue
    out="${vendor_dir}/$(vendor_slug "$lib").md"
    id="$(context7_resolve "$lib")"
    if [[ -z "$id" ]]; then echo "  · $lib：未解析到 context7 id，跳过" >&2; continue; fi
    if context7_fetch "$id" "$out"; then echo "  ✓ $lib → $out";
    else echo "  · $lib：抓取失败，跳过" >&2; fi
  done < <(extract_fingerprint_libs "$file")
}
