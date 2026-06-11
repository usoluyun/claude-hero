#!/usr/bin/env bash
# init-verify.sh — 反伪造检查函数库
# 验证 agent 文件中引用的类/文件、技术栈声明、触发关键词是否与真实代码库一致。
# 被 init CLI 与 generate_checks_json 调用。依赖: jq。
# 与 init-common.sh 互补：expand_path / read_json 等通用函数走 init-common.sh。
# bash 3.2 兼容，zsh source 兼容（避免 for x in $var 模式，避免 loop 内 local 声明）。

verify_paths() {
  # 参数: <agent_file> <repo_path>
  # 行为: 验证 agent 文件中引用的 Java 类在 repo 中真实存在
  # 输出: JSON 对象到 stdout
  local agent_file="$1" repo_path="$2"
  local total_refs=0 found=0
  local missing=""
  local fqcn classname found_file

  # 提取所有 FQCN（com.xxx.yyy.ClassName 模式）
  local refs
  refs=$(grep -Eo '(com\.[a-z0-9.]+\.[A-Z][a-zA-Z0-9]+)' "$agent_file" 2>/dev/null | sort -u)

  # 统计总引用数（处理空结果）
  if [ -z "$refs" ]; then
    total_refs=0
  else
    total_refs=$(echo "$refs" | wc -l | tr -d ' ')
  fi

  if [ "$total_refs" -eq 0 ]; then
    echo '{"total_refs":0,"found":0,"missing":[],"pass":false}'
    return 0
  fi

  # 逐类验证，收集 missing
  while IFS= read -r fqcn; do
    [ -z "$fqcn" ] && continue
    classname="${fqcn##*.}"
    found_file=$(find "$repo_path" -type f -name "${classname}.java" -print -quit 2>/dev/null)
    if [ -n "$found_file" ]; then
      found=$((found + 1))
    else
      if [ -z "$missing" ]; then
        missing="$fqcn"
      else
        missing="$missing"$'\n'"$fqcn"
      fi
    fi
  done <<FQCNEOF
$refs
FQCNEOF

  # 用 jq 构造 JSON（保证合法 JSON）
  local pass="false"
  if [ "$(awk "BEGIN {print ($found / $total_refs > 0.8) ? 1 : 0}")" = "1" ]; then
    pass="true"
  fi

  if [ -z "$missing" ]; then
    echo "{\"total_refs\":$total_refs,\"found\":$found,\"missing\":[],\"pass\":$pass}"
  else
    local missing_json
    missing_json=$(echo "$missing" | jq -R -s 'split("\n") | map(select(length>0))')
    echo "{\"total_refs\":$total_refs,\"found\":$found,\"missing\":$missing_json,\"pass\":$pass}"
  fi
}

verify_stack() {
  # 参数: <agent_file> <repo_path>
  # 行为: 验证 agent 中声明的技术栈与 pom.xml / build.gradle 一致
  # 输出: JSON 对象到 stdout
  local agent_file="$1" repo_path="$2"

  # 提取 agent 的 ② 技术栈段落（更精准的匹配范围）
  local section2
  section2=$(sed -n '/^## ②/,/^## ③/p' "$agent_file" 2>/dev/null)
  if [ -z "$section2" ]; then
    section2=$(cat "$agent_file" 2>/dev/null)
  fi

  local declarations="" matches="" mismatches=""
  local total=0 match_count=0
  local kw found_in_build

  # 用 tr + heredoc 避免 for x in $var 的 bash/zsh 兼容问题
  while IFS= read -r kw; do
    [ -z "$kw" ] && continue
    if ! echo "$section2" | grep -qi "$kw" 2>/dev/null; then
      continue
    fi

    total=$((total + 1))
    if [ -z "$declarations" ]; then
      declarations="$kw"
    else
      declarations="$declarations"$'\n'"$kw"
    fi

    found_in_build=0
    if [ -f "$repo_path/pom.xml" ] && grep -qi "$kw" "$repo_path/pom.xml" 2>/dev/null; then
      found_in_build=1
    fi
    if [ "$found_in_build" -eq 0 ] && [ -f "$repo_path/build.gradle" ] && grep -qi "$kw" "$repo_path/build.gradle" 2>/dev/null; then
      found_in_build=1
    fi
    if [ "$found_in_build" -eq 0 ] && [ -f "$repo_path/settings.gradle" ] && grep -qi "$kw" "$repo_path/settings.gradle" 2>/dev/null; then
      found_in_build=1
    fi

    if [ "$found_in_build" -eq 1 ]; then
      match_count=$((match_count + 1))
      if [ -z "$matches" ]; then
        matches="$kw"
      else
        matches="$matches"$'\n'"$kw"
      fi
    else
      if [ -z "$mismatches" ]; then
        mismatches="$kw"
      else
        mismatches="$mismatches"$'\n'"$kw"
      fi
    fi
  done <<KWLIST
$(echo "spring-boot spring-cloud mybatis-plus mybatis druid redis redisson eureka feign openfeign rocketmq ons sentinel apollo nacos jetcache xxl-job elasticsearch skywalking fastjson quartz log4j slf4j jackson hibernate kafka rabbitmq mongodb postgresql mysql" | tr ' ' '\n')
KWLIST

  local pass="false"
  if [ "$total" -gt 0 ] && [ "$(awk "BEGIN {print ($match_count / $total > 0.7) ? 1 : 0}")" = "1" ]; then
    pass="true"
  fi

  # 用 jq 构造合法 JSON
  local dec_json mat_json mis_json
  dec_json=$(echo "$declarations" | jq -R -s 'if . == "" then [] else split("\n") | map(select(length>0)) end')
  mat_json=$(echo "$matches" | jq -R -s 'if . == "" then [] else split("\n") | map(select(length>0)) end')
  mis_json=$(echo "$mismatches" | jq -R -s 'if . == "" then [] else split("\n") | map(select(length>0)) end')

  echo "{\"declarations\":$dec_json,\"matches\":$mat_json,\"mismatches\":$mis_json,\"pass\":$pass}"
}

verify_keywords() {
  # 参数: <agent_file>
  # 行为: 验证 description 的触发关键词规范（hero-agent-roster 规范）
  # 输出: JSON 对象到 stdout
  local agent_file="$1"

  # 读取 YAML frontmatter 中 triggers: 字段
  local desc_line
  desc_line=$(grep -i '触发词' "$agent_file" 2>/dev/null | head -1)

  if [ -z "$desc_line" ]; then
    echo '{"keywords":[],"valid":[],"invalid":[],"pass":false}'
    return 0
  fi

  # 提取触发词后的内容（中文冒号或英文冒号，到行尾）
  local triggers_str
  triggers_str=$(echo "$desc_line" | sed 's/.*触发词[：:][[:space:]]*//')

  # 按 / 或 、 或中文逗号或句号分割
  local keywords_raw
  keywords_raw=$(echo "$triggers_str" | sed 's/[\/、，。]/\n/g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$')

  local keywords="" valid="" invalid=""
  local total=0 valid_count=0
  local kw trimmed

  while IFS= read -r kw; do
    [ -z "$kw" ] && continue
    total=$((total + 1))
    trimmed="$kw"
    if [ -z "$keywords" ]; then
      keywords="$trimmed"
    else
      keywords="$keywords"$'\n'"$trimmed"
    fi

    # 判断合法性：有中文或英文有意义内容即合法（非纯数字、非纯标点）
    if echo "$trimmed" | grep -qE '[a-zA-Z]{2,}' || echo "$trimmed" | grep -q '[一-龥]'; then
      valid_count=$((valid_count + 1))
      if [ -z "$valid" ]; then
        valid="$trimmed"
      else
        valid="$valid"$'\n'"$trimmed"
      fi
    else
      if [ -z "$invalid" ]; then
        invalid="$trimmed"
      else
        invalid="$invalid"$'\n'"$trimmed"
      fi
    fi
  done <<KWEOF
$keywords_raw
KWEOF

  local pass="false"
  if [ "$total" -gt 0 ] && [ "$(awk "BEGIN {print ($valid_count / $total > 0.5) ? 1 : 0}")" = "1" ]; then
    pass="true"
  fi

  # jq 构造合法 JSON
  local kw_json val_json inv_json
  kw_json=$(echo "$keywords" | jq -R -s 'if . == "" then [] else split("\n") | map(select(length>0)) end')
  val_json=$(echo "$valid" | jq -R -s 'if . == "" then [] else split("\n") | map(select(length>0)) end')
  inv_json=$(echo "$invalid" | jq -R -s 'if . == "" then [] else split("\n") | map(select(length>0)) end')

  echo "{\"keywords\":$kw_json,\"valid\":$val_json,\"invalid\":$inv_json,\"pass\":$pass}"
}

generate_checks_json() {
  # 参数: <agent_file> <repo_path>
  # 行为: 聚合 verify_paths / verify_stack / verify_keywords 三个检查的结果
  # 输出: JSON 对象到 stdout
  local agent_file="$1" repo_path="$2"

  local path_result stack_result kw_result
  path_result=$(verify_paths "$agent_file" "$repo_path")
  stack_result=$(verify_stack "$agent_file" "$repo_path")
  kw_result=$(verify_keywords "$agent_file")

  # 统计 pass/fail
  local passed=0 failed=0
  local suspicious=""

  if echo "$path_result" | jq -e '.pass == true' >/dev/null 2>&1; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
    if [ -z "$suspicious" ]; then
      suspicious="\"path_check\""
    else
      suspicious="$suspicious,\"path_check\""
    fi
  fi

  if echo "$stack_result" | jq -e '.pass == true' >/dev/null 2>&1; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
    if [ -z "$suspicious" ]; then
      suspicious="\"stack_check\""
    else
      suspicious="$suspicious,\"stack_check\""
    fi
  fi

  if echo "$kw_result" | jq -e '.pass == true' >/dev/null 2>&1; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
    if [ -z "$suspicious" ]; then
      suspicious="\"keyword_check\""
    else
      suspicious="$suspicious,\"keyword_check\""
    fi
  fi

  local overall_pass="false"
  if [ "$failed" -eq 0 ]; then
    overall_pass="true"
  fi

  echo "{\"path_check\":$path_result,\"stack_check\":$stack_result,\"keyword_check\":$kw_result,\"overall\":{\"passed\":$passed,\"failed\":$failed,\"suspicious\":[$suspicious],\"pass\":$overall_pass}}"
}
