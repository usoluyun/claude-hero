#!/usr/bin/env bash
# 模板填充引擎。读取 navigator-agent.md.tmpl + stack.json + layout.json + evidence.json → 合成 agent-draft.md。
# 依赖: init-common.sh（read_json）、jq
# 处理流程:
#   1. 读取三个 JSON 提取字段，推导条件变量
#   2. 替换所有 {{PLACEHOLDER}} 占位符
#   3. 处理内联条件 {{#if C}}...{{/if}} 和 {{#if C}}...{{else}}...{{/if}}（单行内）
#   4. 处理块级条件 {{#C}}...{{/C}} 和 {{^C}}...{{/C}}（跨行）
# bash 3.2 兼容，无 associative array / [[ =~ ]] / local -n

# ── 确保 read_json 可用 ──
if ! declare -f read_json >/dev/null 2>&1; then
  _it_libdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [ -f "$_it_libdir/init-common.sh" ]; then
    . "$_it_libdir/init-common.sh"
  else
    echo "ERROR: init-template.sh 需要 init-common.sh 提供 read_json" >&2
    return 1
  fi
fi

# ============================================================
# _it_truthy — 判断值是否"真"（bash 3.2 兼容）
# 返回: 0=真, 1=假
# ============================================================
_it_truthy() {
  case "$1" in true|1|yes) return 0 ;; *) return 1 ;; esac
}

# ============================================================
# generate_trigger_keywords — 自动生成触发关键词
# 参数: <stack_json> <layout_json> <project_short>
# 输出: echo 关键词字符串（逗号分隔）
# ============================================================
generate_trigger_keywords() {
  local stack_json="$1" layout_json="$2" project_short="$3"
  local keywords="$project_short" framework is_multimodule

  framework=$(read_json "$stack_json" '.framework // ""' 2>/dev/null) || framework=""
  is_multimodule=$(read_json "$layout_json" '.is_multimodule // false' 2>/dev/null) || is_multimodule="false"

  case "$framework" in
    spring-cloud|spring-boot) keywords="${keywords},spring-boot,Spring Boot" ;;
    non-spring)               keywords="${keywords},non-spring,非Spring" ;;
  esac

  [ "$framework" = "spring-cloud" ] && keywords="${keywords},Eureka,Feign,OpenFeign,Apollo,RocketMQ"
  _it_truthy "$is_multimodule" && keywords="${keywords},facade,api,多模块"
  keywords="${keywords},领航,带路,代码结构,导航"
  printf '%s' "$keywords"
}

# ============================================================
# fill_template — 主模板填充函数
# 参数: <template_file> <stack_json> <layout_json> <evidence_json>
#       <chinese_name> <project_short> <project_zh_name> <output_file>
# 额外可选环境变量（可覆盖默认推导）:
#   IT_SERVICE_DISPLAY_NAME, IT_BUSINESS_DESCRIPTION, IT_ARCHITECTURE_GROUP
#   IT_PROJECT_PATH, IT_CODEGRAPH_STATS, IT_PACKAGE_ROOT
#   IT_API_FILES, IT_CORE_FILES, IT_BOOT_FILES, IT_FRONTEND_FILES
#   IT_BUSINESS_DOMAINS, IT_REST_CONTROLLERS, IT_FACADE_IMPLS
#   IT_BPM_EVENTS, IT_FEIGN_CLIENTS, IT_SCHEDULER_JOBS, IT_MQ_CONSUMERS
#   IT_OPENAPI_ENTRIES, IT_FACADE_LIST, IT_DOWNSTREAM_LIST
#   IT_ACL_COUNT, IT_ACL_LIST, IT_SECONDARY_PACKAGES, IT_EXTERNAL_SERVICES
#   IT_MQ_TOPICS, IT_DOMAIN_KNOWLEDGE, IT_NEIGHBOR_SERVICES
#   IT_AUTHORITATIVE_DOC, IT_CLAUDE_MD_MISLABEL, IT_ACTUAL_DESCRIPTION
#   IT_GIT_SOURCE, IT_SPRING_BOOT_VERSION, IT_JAVA_VERSION
#   IT_MYBATIS_PLUS_VERSION, IT_NON_SPRING_PLATFORM, IT_NON_SPRING_DETAILS
#   IT_NON_SPRING_API_STYLE, IT_NON_SPRING_DATA_ACCESS
#   IT_NON_SPRING_EVENT_STYLE, IT_NON_SPRING_OTHER
#   IT_MODULE_LIST, IT_NON_SPRING_CONTRACT, IT_CODEGRAPH_FILTER
#   IT_SCHEDULER_TYPE, IT_CACHE_TYPE, IT_SQL_DETAIL
#   IT_NON_SPRING_NOTE, IT_NON_SPRING_STACK_WARNING
#   IT_SPECIFIC_QUESTIONS, IT_PLATFORM_NOTE, IT_TRIGGERS
#   IT_HAS_MYBATIS_PLUS, IT_HAS_MYBATIS_STANDARD
# 返回: 0=成功, 1=失败
# ============================================================
fill_template() {
  local template_file="$1" stack_json="$2" layout_json="$3" evidence_json="$4"
  local chinese_name="$5" project_short="$6" project_zh_name="$7" output_file="$8"

  # ── 输入校验 ──
  [ ! -f "$template_file" ] && { echo "ERROR: 模板不存在: $template_file" >&2; return 1; }
  [ ! -f "$stack_json" ] && { echo "ERROR: stack.json 不存在: $stack_json" >&2; return 1; }
  [ ! -f "$layout_json" ] && { echo "ERROR: layout.json 不存在: $layout_json" >&2; return 1; }
  [ ! -f "$evidence_json" ] && { echo "ERROR: evidence.json 不存在: $evidence_json" >&2; return 1; }
  [ -z "$output_file" ] && { echo "ERROR: 未指定 output_file" >&2; return 1; }

  # ── 读取 JSON ──
  local framework is_spring version has_spring_cloud_bom
  local build_tool is_multimodule module_count project_name
  local ev_controllers ev_services ev_mappers ev_listeners ev_jobs

  framework=$(read_json "$stack_json" '.framework // ""') || framework=""
  is_spring=$(read_json "$stack_json" '.is_spring // false') || is_spring="false"
  version=$(read_json "$stack_json" '.version // ""') || version=""
  has_spring_cloud_bom=$(read_json "$stack_json" '.has_spring_cloud_bom // false') || has_spring_cloud_bom="false"
  build_tool=$(read_json "$layout_json" '.build_tool // ""') || build_tool=""
  is_multimodule=$(read_json "$layout_json" '.is_multimodule // false') || is_multimodule="false"
  module_count=$(read_json "$layout_json" '.module_count // 0') || module_count="0"
  project_name=$(read_json "$layout_json" '.project_name // ""') || project_name=""

  ev_controllers=$(read_json "$evidence_json" '.controllers // []') || ev_controllers="[]"
  ev_services=$(read_json "$evidence_json" '.services // []') || ev_services="[]"
  ev_mappers=$(read_json "$evidence_json" '.mappers // []') || ev_mappers="[]"
  ev_listeners=$(read_json "$evidence_json" '.listeners // []') || ev_listeners="[]"
  ev_jobs=$(read_json "$evidence_json" '.jobs // []') || ev_jobs="[]"

  # ── 推导条件变量 ──
  local is_spring_boot="false" is_spring_cloud="false" non_spring="false"
  case "$framework" in
    spring-cloud) is_spring_boot="true"; is_spring_cloud="true" ;;
    spring-boot)  is_spring_boot="true" ;;
    *)            non_spring="true" ;;
  esac

  local is_single_module="false"
  [ "$is_multimodule" = "false" ] && is_single_module="true"

  local has_ddd="false"
  _it_truthy "$is_spring_cloud" && has_ddd="true"

  # is_monolith: Spring Cloud 项目、多模块但本质上是单体（单一部署单元多业务域）
  # 判断: framework == spring-cloud AND (is_multimodule) AND 项目名包含单业务域特征
  local is_monolith="false"
  # 从环境变量 IT_IS_MONOLITH 显式控制，或根据特征推导
  if [ -n "${IT_IS_MONOLITH:-}" ]; then
    is_monolith="$IT_IS_MONOLITH"
  elif _it_truthy "$is_spring_cloud" && _it_truthy "$is_multimodule"; then
    # 多模块 Spring Cloud 项目也可能是单体（如 owner-biz）
    # 保守默认为 false，由 IT_IS_MONOLITH 环境变量控制
    is_monolith="false"
  fi

  local ctrl_count svc_count mapper_count listener_count job_count
  ctrl_count=$(printf '%s' "$ev_controllers" | jq 'length' 2>/dev/null) || ctrl_count=0
  svc_count=$(printf '%s' "$ev_services" | jq 'length' 2>/dev/null) || svc_count=0
  mapper_count=$(printf '%s' "$ev_mappers" | jq 'length' 2>/dev/null) || mapper_count=0
  listener_count=$(printf '%s' "$ev_listeners" | jq 'length' 2>/dev/null) || listener_count=0
  job_count=$(printf '%s' "$ev_jobs" | jq 'length' 2>/dev/null) || job_count=0

  # ── 构建占位符值（环境变量覆盖默认） ──
  local agent_name="hero-java-${project_short}"
  local service_display_name="${IT_SERVICE_DISPLAY_NAME:-${project_short}（${project_zh_name}）}"
  local project_path="${IT_PROJECT_PATH:-~/Documents/ATLWork/${project_name:-$project_short}}"
  local codegraph_stats="${IT_CODEGRAPH_STATS:-}"
  local business_description="${IT_BUSINESS_DESCRIPTION:-${project_zh_name}业务}"
  local architecture_group="${IT_ARCHITECTURE_GROUP:-通用}"
  local package_root="${IT_PACKAGE_ROOT:-com.yaduo.${project_short}}"
  local spring_boot_version="${IT_SPRING_BOOT_VERSION:-${version}}"
  local java_version="${IT_JAVA_VERSION:-11}"
  local mybatis_plus_version="${IT_MYBATIS_PLUS_VERSION:-}"
  local module_api="${IT_MODULE_API:-${project_short}-api}"
  local module_core="${IT_MODULE_CORE:-${project_short}-core}"
  local module_boot="${IT_MODULE_BOOT:-${project_short}-boot}"
  local api_files="${IT_API_FILES:-0}"
  local core_files="${IT_CORE_FILES:-0}"
  local boot_files="${IT_BOOT_FILES:-0}"
  local frontend_files="${IT_FRONTEND_FILES:-0}"

  local rest_controllers="${IT_REST_CONTROLLERS:-}"
  local facade_impls="${IT_FACADE_IMPLS:-}"
  local bpm_events="${IT_BPM_EVENTS:-}"
  local feign_clients="${IT_FEIGN_CLIENTS:-}"
  local scheduler_jobs="${IT_SCHEDULER_JOBS:-}"
  local mq_consumers="${IT_MQ_CONSUMERS:-}"
  local openapi_entries="${IT_OPENAPI_ENTRIES:-}"
  local facade_list="${IT_FACADE_LIST:-}"
  local downstream_list="${IT_DOWNSTREAM_LIST:-}"
  local acl_count="${IT_ACL_COUNT:-0}"
  local acl_list="${IT_ACL_LIST:-}"
  local secondary_packages="${IT_SECONDARY_PACKAGES:-}"
  local external_services="${IT_EXTERNAL_SERVICES:-}"
  local mq_topics="${IT_MQ_TOPICS:-}"

  local non_spring_platform="${IT_NON_SPRING_PLATFORM:-ActionSoft AWS BPM PaaS}"
  local non_spring_details="${IT_NON_SPRING_DETAILS:-com.actionsoft.bpms.*、aws-bpmn-engine、com.atour.aws:aws-infrastructure-*}"
  local non_spring_api_style="${IT_NON_SPRING_API_STYLE:-通过 @Controller(type = HandlerType.OPENAPI) + @Mapping(\"business.xxx\") 暴露 OpenAPI，参数用 @Param}"
  local non_spring_data_access="${IT_NON_SPRING_DATA_ACCESS:-直接 com.actionsoft.bpms.util.DBSql 拼 SQL（裸 SQL，非 MyBatis/ORM）}"
  local non_spring_event_style="${IT_NON_SPRING_EVENT_STYLE:-继承 com.actionsoft.bpms.bpmn.engine.listener.ExecuteListener，挂在 BPMN 节点上}"
  local non_spring_other="${IT_NON_SPRING_OTHER:-fastjson、druid、quartz、commons-lang3/beanutils、log4j + slf4j。构建：Maven（maven-shade-plugin 打包）}"
  local non_spring_contract="${IT_NON_SPRING_CONTRACT:-}"
  local module_list="${IT_MODULE_LIST:-}"

  local business_domains="${IT_BUSINESS_DOMAINS:-}"
  local domain_knowledge="${IT_DOMAIN_KNOWLEDGE:-（待补充）}"
  local neighbor_services="${IT_NEIGHBOR_SERVICES:-}"
  local authoritative_doc="${IT_AUTHORITATIVE_DOC:-}"
  local claude_md_mislabel="${IT_CLAUDE_MD_MISLABEL:-}"
  local actual_description="${IT_ACTUAL_DESCRIPTION:-}"
  local git_source="${IT_GIT_SOURCE:-}"

  local codegraph_filter="${IT_CODEGRAPH_FILTER:-src/main/java}"
  local scheduler_type="${IT_SCHEDULER_TYPE:-XXL-Job}"
  local cache_type="${IT_CACHE_TYPE:-Redis/JetCache}"
  local sql_detail="${IT_SQL_DETAIL:-}"
  local non_spring_note="${IT_NON_SPRING_NOTE:-非 Spring Boot}"
  local non_spring_stack_warning="${IT_NON_SPRING_STACK_WARNING:-ActionSoft 栈下先确认其中 Spring 相关约定是否适用}"
  local specific_questions="${IT_SPECIFIC_QUESTIONS:-}"
  local platform_note="${IT_PLATFORM_NOTE:-}"

  local triggers="${IT_TRIGGERS:-}"
  [ -z "$triggers" ] && triggers=$(generate_trigger_keywords "$stack_json" "$layout_json" "$project_short")

  # ── 推导 has_* 条件 ──
  local has_codegraph_stats="false";    [ -n "$codegraph_stats" ] && has_codegraph_stats="true"
  local has_authoritative_doc="false";   [ -n "$authoritative_doc" ] && has_authoritative_doc="true"
  local has_claude_md_warning="false";   [ -n "$claude_md_mislabel" ] && has_claude_md_warning="true"
  local has_neighbors="false";           [ -n "$neighbor_services" ] && has_neighbors="true"
  local has_biz_logger="false";          _it_truthy "$is_spring_cloud" && has_biz_logger="true"
  local has_frontend="false"
  [ "$frontend_files" -gt 0 ] 2>/dev/null && has_frontend="true"
  local has_business_domains="false";    [ -n "$business_domains" ] && has_business_domains="true"

  local has_rest_entry="false"
  [ -n "$rest_controllers" ] || [ -n "$facade_impls" ] || [ -n "$openapi_entries" ] && has_rest_entry="true"
  [ "$has_rest_entry" = "false" ] && [ "$ctrl_count" -gt 0 ] 2>/dev/null && has_rest_entry="true"

  local has_facade_impls="false";        [ -n "$facade_impls" ] && has_facade_impls="true"
  local has_rest_controllers="false";    [ -n "$rest_controllers" ] && has_rest_controllers="true"
  local has_bpm_events="false";          [ -n "$bpm_events" ] && has_bpm_events="true"
  local has_feign_clients="false";       [ -n "$feign_clients" ] && has_feign_clients="true"
  local has_scheduler_jobs="false";      [ -n "$scheduler_jobs" ] && has_scheduler_jobs="true"
  local has_mq_consumers="false";        [ -n "$mq_consumers" ] && has_mq_consumers="true"
  local has_facade_exposed="false";      [ -n "$facade_list" ] && has_facade_exposed="true"
  local has_downstream_feign="false";    [ -n "$downstream_list" ] && has_downstream_feign="true"
  local has_acl_layer="false";           [ "$acl_count" -gt 0 ] 2>/dev/null && has_acl_layer="true"
  local has_secondary_packages="false";  [ -n "$secondary_packages" ] && has_secondary_packages="true"
  local has_external_services="false";   [ -n "$external_services" ] && has_external_services="true"
  local has_mq_topics="false";           [ -n "$mq_topics" ] && has_mq_topics="true"
  local has_placeholder_tip="true"
  local has_downstream="false";          [ -n "$downstream_list" ] && has_downstream="true"
  local has_non_spring_sql="false";      _it_truthy "$non_spring" && has_non_spring_sql="true"
  local has_specific_questions="false";  [ -n "$specific_questions" ] && has_specific_questions="true"

  local has_mybatis_plus="${IT_HAS_MYBATIS_PLUS:-false}"
  local has_mybatis_standard="${IT_HAS_MYBATIS_STANDARD:-false}"
  if [ "$has_mybatis_plus" = "false" ] && [ "$has_mybatis_standard" = "false" ]; then
    _it_truthy "$is_spring_cloud" && has_mybatis_plus="true"
  fi
  # 显式设置了 has_mybatis_standard=true 时确保 has_mybatis_plus=false
  if [ "$has_mybatis_standard" = "true" ]; then
    has_mybatis_plus="false"
  fi

  local has_spring_cloud="$is_spring_cloud"

  # ── 构建条件字符串 ──
  local cond_str=""
  _add_cond() { cond_str="${cond_str} $1=$2"; }

  _add_cond "is_spring_boot" "$is_spring_boot"
  _add_cond "non_spring" "$non_spring"
  _add_cond "is_multimodule" "$is_multimodule"
  _add_cond "is_single_module" "$is_single_module"
  _add_cond "is_monolith" "$is_monolith"
  _add_cond "has_ddd" "$has_ddd"
  _add_cond "has_codegraph_stats" "$has_codegraph_stats"
  _add_cond "has_authoritative_doc" "$has_authoritative_doc"
  _add_cond "has_claude_md_warning" "$has_claude_md_warning"
  _add_cond "has_neighbors" "$has_neighbors"
  _add_cond "has_spring_cloud" "$has_spring_cloud"
  _add_cond "has_mybatis_plus" "$has_mybatis_plus"
  _add_cond "has_mybatis_standard" "$has_mybatis_standard"
  _add_cond "has_biz_logger" "$has_biz_logger"
  _add_cond "has_frontend" "$has_frontend"
  _add_cond "has_business_domains" "$has_business_domains"
  _add_cond "has_rest_entry" "$has_rest_entry"
  _add_cond "has_facade_impls" "$has_facade_impls"
  _add_cond "has_rest_controllers" "$has_rest_controllers"
  _add_cond "has_bpm_events" "$has_bpm_events"
  _add_cond "has_feign_clients" "$has_feign_clients"
  _add_cond "has_scheduler_jobs" "$has_scheduler_jobs"
  _add_cond "has_mq_consumers" "$has_mq_consumers"
  _add_cond "has_facade_exposed" "$has_facade_exposed"
  _add_cond "has_downstream_feign" "$has_downstream_feign"
  _add_cond "has_acl_layer" "$has_acl_layer"
  _add_cond "has_secondary_packages" "$has_secondary_packages"
  _add_cond "has_external_services" "$has_external_services"
  _add_cond "has_mq_topics" "$has_mq_topics"
  _add_cond "has_placeholder_tip" "$has_placeholder_tip"
  _add_cond "has_downstream" "$has_downstream"
  _add_cond "has_non_spring_sql" "$has_non_spring_sql"
  _add_cond "has_specific_questions" "$has_specific_questions"

  cond_str="${cond_str# }"

  # ── 构建占位符映射（临时文件） ──
  local ph_file
  ph_file="$(mktemp)" || { echo "ERROR: 无法创建临时文件" >&2; return 1; }
  > "$ph_file"

  _write_ph() { printf '%s|%s\n' "$1" "$2" >> "$ph_file"; }

  _write_ph "PROJECT_SHORT" "$project_short"
  _write_ph "PROJECT_ZH_NAME" "$project_zh_name"
  _write_ph "CHINESE_NAME" "$chinese_name"
  _write_ph "AGENT_NAME" "$agent_name"
  _write_ph "SERVICE_DISPLAY_NAME" "$service_display_name"
  _write_ph "PROJECT_PATH" "$project_path"
  _write_ph "CODEGRAPH_STATS" "$codegraph_stats"
  _write_ph "BUSINESS_DESCRIPTION" "$business_description"
  _write_ph "ARCHITECTURE_GROUP" "$architecture_group"
  _write_ph "PACKAGE_ROOT" "$package_root"
  _write_ph "SPRING_BOOT_VERSION" "$spring_boot_version"
  _write_ph "JAVA_VERSION" "$java_version"
  _write_ph "MYBATIS_PLUS_VERSION" "$mybatis_plus_version"
  _write_ph "CACHE_TYPE" "$cache_type"
  _write_ph "SCHEDULER_TYPE" "$scheduler_type"
  _write_ph "TRIGGERS" "$triggers"
  _write_ph "MODULE_API" "$module_api"
  _write_ph "MODULE_CORE" "$module_core"
  _write_ph "MODULE_BOOT" "$module_boot"
  _write_ph "API_FILES" "$api_files"
  _write_ph "CORE_FILES" "$core_files"
  _write_ph "BOOT_FILES" "$boot_files"
  _write_ph "FRONTEND_FILES" "$frontend_files"
  _write_ph "BUSINESS_DOMAINS" "$business_domains"
  _write_ph "MODULE_COUNT" "$module_count"
  _write_ph "REST_CONTROLLERS" "$rest_controllers"
  _write_ph "FACADE_IMPLS" "$facade_impls"
  _write_ph "BPM_EVENTS" "$bpm_events"
  _write_ph "FEIGN_CLIENTS" "$feign_clients"
  _write_ph "SCHEDULER_JOBS" "$scheduler_jobs"
  _write_ph "MQ_CONSUMERS" "$mq_consumers"
  _write_ph "OPENAPI_ENTRIES" "$openapi_entries"
  _write_ph "FACADE_LIST" "$facade_list"
  _write_ph "DOWNSTREAM_LIST" "$downstream_list"
  _write_ph "ACL_COUNT" "$acl_count"
  _write_ph "ACL_LIST" "$acl_list"
  _write_ph "SECONDARY_PACKAGES" "$secondary_packages"
  _write_ph "EXTERNAL_SERVICES" "$external_services"
  _write_ph "MQ_TOPICS" "$mq_topics"
  _write_ph "DOMAIN_KNOWLEDGE" "$domain_knowledge"
  _write_ph "NEIGHBOR_SERVICES" "$neighbor_services"
  _write_ph "AUTHORITATIVE_DOC" "$authoritative_doc"
  _write_ph "CLAUDE_MD_MISLABEL" "$claude_md_mislabel"
  _write_ph "ACTUAL_DESCRIPTION" "$actual_description"
  _write_ph "GIT_SOURCE" "$git_source"
  _write_ph "SQL_DETAIL" "$sql_detail"
  _write_ph "NON_SPRING_PLATFORM" "$non_spring_platform"
  _write_ph "NON_SPRING_DETAILS" "$non_spring_details"
  _write_ph "NON_SPRING_API_STYLE" "$non_spring_api_style"
  _write_ph "NON_SPRING_DATA_ACCESS" "$non_spring_data_access"
  _write_ph "NON_SPRING_EVENT_STYLE" "$non_spring_event_style"
  _write_ph "NON_SPRING_OTHER" "$non_spring_other"
  _write_ph "NON_SPRING_CONTRACT" "$non_spring_contract"
  _write_ph "NON_SPRING_NOTE" "$non_spring_note"
  _write_ph "NON_SPRING_STACK_WARNING" "$non_spring_stack_warning"
  _write_ph "MODULE_LIST" "$module_list"
  _write_ph "CODEGRAPH_FILTER" "$codegraph_filter"
  _write_ph "SPECIFIC_QUESTIONS" "$specific_questions"
  _write_ph "PLATFORM_NOTE" "$platform_note"

  # ── 执行模板填充 ──
  local tmp1 tmp2
  tmp1="$(mktemp)" || { echo "ERROR: 无法创建临时文件" >&2; rm -f "$ph_file"; return 1; }
  tmp2="$(mktemp)" || { echo "ERROR: 无法创建临时文件" >&2; rm -f "$ph_file" "$tmp1"; return 1; }

  # Step 1: 占位符替换 {{PLACEHOLDER}} → 值
  awk \
    -v ph_file="$ph_file" \
    'BEGIN {
      while ((getline line < ph_file) > 0) {
        idx = index(line, "|")
        if (idx > 0) ph[substr(line, 1, idx - 1)] = substr(line, idx + 1)
      }
      close(ph_file)
    }
    {
      line = $0
      for (k in ph) gsub("{{" k "}}", ph[k], line)
      print line
    }' "$template_file" > "$tmp1" 2>/dev/null

  [ $? -ne 0 ] && { echo "ERROR: 占位符替换失败" >&2; rm -f "$ph_file" "$tmp1" "$tmp2"; return 1; }

  # Step 2: 内联条件展开（一行内的 {{#if C}}...{{/if}}）
  awk \
    -v cond_str="$cond_str" \
    '
    BEGIN {
      n = split(cond_str, pairs, " ")
      for (i = 1; i <= n; i++) {
        split(pairs[i], kv, "=")
        cond[kv[1]] = kv[2]
      }
    }

    function truthy(name) {
      v = cond[name]
      return (v == "1" || v == "true")
    }

    # 在字符串 s 中，从 start 开始找到匹配的 {{/if}}（正确处理嵌套 {{#if}}）
    # 返回 {{/if}} 中第一个 { 的位置
    function find_close(s, start,   depth, pi) {
      depth = 1
      pi = start
      while (pi + 6 <= length(s) && depth > 0) {
        if (substr(s, pi, 5) == "{{#if") {
          depth++
          pi += 5
        } else if (substr(s, pi, 7) == "{{/if}}") {
          depth--
          if (depth == 0) return pi
          pi += 7
        } else {
          pi++
        }
      }
      return 0
    }

    # 在字符串 s 的 [start, end) 范围内查找当前层级（depth=1）的 {{else}}，跳过嵌套
    function find_else(s, start, end,   pi, ei, depth) {
      pi = start
      depth = 0
      while (pi + 5 < end) {
        if (substr(s, pi, 5) == "{{#if") {
          depth++
          pi += 5
        } else if (substr(s, pi, 7) == "{{/if}}") {
          depth--
          pi += 7
        } else if (depth == 0 && substr(s, pi, 6) == "{{else") {
          ei = pi + 6
          while (ei + 1 <= length(s) && substr(s, ei, 2) != "}}") ei++
          if (ei + 1 <= length(s)) return pi
          pi++
        } else {
          pi++
        }
      }
      return 0
    }

    function resolve_line(s,   pos, si, cname, close_pos, else_pos, true_part, false_part, es, replacement, iter) {
      for (iter = 0; iter < 30; iter++) {
        pos = index(s, "{{#if")
        if (pos == 0) break

        # 提取条件名
        si = pos + 5
        while (substr(s, si, 1) == " ") si++
        cname = ""
        while (si <= length(s) && substr(s, si, 1) != "}" && substr(s, si, 1) != " ") {
          cname = cname substr(s, si, 1)
          si++
        }
        while (si + 1 <= length(s) && substr(s, si, 2) != "}}") si++
        if (si + 1 > length(s)) break
        si += 2

        # 找匹配的 {{/if}}
        close_pos = find_close(s, si)
        if (close_pos == 0) break

        # 在 si 到 close_pos 之间找 {{else}}
        else_pos = find_else(s, si, close_pos)

        if (else_pos > 0) {
          true_part = substr(s, si, else_pos - si)
          es = else_pos + 6
          while (es + 1 <= length(s) && substr(s, es, 2) != "}}") es++
          es += 2
          false_part = substr(s, es, close_pos - es)
        } else {
          true_part = substr(s, si, close_pos - si)
          false_part = ""
        }

        replacement = truthy(cname) ? true_part : false_part
        s = substr(s, 1, pos - 1) replacement substr(s, close_pos + 7)
      }
      # 清理残留标签
      gsub(/\{\{#if [a-zA-Z0-9_]+\}\}/, "", s)
      gsub(/\{\{else[^}]*\}\}/, "", s)
      gsub(/\{\{\/if\}\}/, "", s)
      return s
    }

    # 跳过纯块级条件标签行（让块级处理器处理）
    function is_block_only(s) {
      gsub(/^[ \t]+/, "", s)
      gsub(/[ \t]+$/, "", s)
      if (s ~ /^\{\{#[a-z_][a-zA-Z0-9_]*\}\}$/) return 1
      if (s ~ /^\{\{#if [a-zA-Z0-9_]+\}\}$/) return 1
      if (s ~ /^\{\{\^[a-z_][a-zA-Z0-9_]*\}\}$/) return 1
      if (s ~ /^\{\{\/[a-z_][a-zA-Z0-9_]*\}\}$/) return 1
      if (s ~ /^\{\{\/if\}\}$/) return 1
      return 0
    }

    { 
      if (is_block_only($0)) { print; next }
      print resolve_line($0) 
    }
    ' < "$tmp1" > "$tmp2" 2>/dev/null

  [ $? -ne 0 ] && { echo "ERROR: 内联条件处理失败" >&2; rm -f "$ph_file" "$tmp1" "$tmp2"; return 1; }

  # Step 3: 块级条件处理（{{#C}} / {{^C}} / {{/C}} 独占一行）
  awk \
    -v cond_str="$cond_str" \
    '
    BEGIN {
      n = split(cond_str, pairs, " ")
      for (i = 1; i <= n; i++) {
        split(pairs[i], kv, "=")
        cond[kv[1]] = kv[2]
      }
      depth = 0
      print_stack[0] = 1
    }

    function truthy(name) {
      v = cond[name]
      return (v == "1" || v == "true")
    }

    {
      raw = $0
      t = raw
      gsub(/^[ \t]+/, "", t)
      gsub(/[ \t]+$/, "", t)

      # {{#condition}} 或 {{#if cond}} — 正向块开
      if (t ~ /^\{\{#[a-z_][a-zA-Z0-9_]*\}\}$/) {
        name = t
        sub(/^\{\{#/, "", name); sub(/\}\}$/, "", name)
        depth++
        v = truthy(name)
        print_stack[depth] = (depth == 1 ? v : (print_stack[depth-1] && v))
        next
      }
      if (t ~ /^\{\{#if [a-zA-Z0-9_]+\}\}$/) {
        name = t
        sub(/^\{\{#if /, "", name); sub(/\}\}$/, "", name)
        depth++
        v = truthy(name)
        print_stack[depth] = (depth == 1 ? v : (print_stack[depth-1] && v))
        next
      }

      # {{^condition}} — 反向块开
      if (t ~ /^\{\{\^[a-z_][a-zA-Z0-9_]*\}\}$/) {
        name = t
        sub(/^\{\{\^/, "", name); sub(/\}\}$/, "", name)
        depth++
        v = truthy(name)
        print_stack[depth] = (depth == 1 ? !v : (print_stack[depth-1] && !v))
        next
      }

      # {{/condition}} 或 {{/if}} — 块关
      if (t ~ /^\{\{\/[a-z_][a-zA-Z0-9_]*\}\}$/ || t ~ /^\{\{\/if\}\}$/) {
        if (depth > 0) depth--
        next
      }

      # 普通行
      if (depth == 0 || print_stack[depth]) print raw
    }
    ' < "$tmp2" > "$output_file" 2>/dev/null

  [ $? -ne 0 ] && { echo "ERROR: 块级条件处理失败" >&2; rm -f "$ph_file" "$tmp1" "$tmp2"; return 1; }

  rm -f "$ph_file" "$tmp1" "$tmp2"

  # Step 4: 清理多余空行（连续 3+ → 2）
  local tmp_clean
  tmp_clean="$(mktemp)" || return 0
  awk 'BEGIN{b=0} /^$/ {b++; if(b<=2) print; next} {b=0; print}' \
    "$output_file" > "$tmp_clean" && mv "$tmp_clean" "$output_file"
  rm -f "$tmp_clean"

  return 0
}
