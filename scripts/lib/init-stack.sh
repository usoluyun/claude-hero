#!/usr/bin/env bash
# 技术栈检测函数库。提供 detect_framework / parse_dependencies / identify_middleware。
# 基于 stack-detection-prototype.md 规则树实现，支持 Maven (pom.xml) 与 Gradle (build.gradle) 项目。
# 依赖: bash 3.2+、jq (JSON 输出)、init-common.sh (可选 source)。
# 使用: . scripts/lib/init-stack.sh

# ============================================================
# 内部：收集 Gradle 项目所有 .gradle 文件合并文本（排除 .gradle/ 缓存）
# ============================================================
_gradle_scan_text() {
  local repo="$1"
  find "$repo" -maxdepth 4 -name '*.gradle' ! -path '*/.gradle/*' -exec cat {} \; 2>/dev/null
}

# ============================================================
# 内部：从 Gradle buildscript ext{} 提取 Spring Boot 版本
# ============================================================
_extract_gradle_sb_version() {
  local repo="$1"
  local version=""
  if [ -f "$repo/build.gradle" ]; then
    # 匹配 springBootVersion = "2.7.12" 或 springBootVersion = '2.7.12'
    version=$(grep -oE "springBootVersion\s*=\s*[\"'][^\"']*[\"']" "$repo/build.gradle" 2>/dev/null \
      | head -1 | sed "s/.*[\"']\(.*\)[\"'].*/\1/")
  fi
  echo "$version"
}

# ============================================================
# 内部：提取 pom.xml 中的 Spring Boot 版本
# ============================================================
_extract_maven_sb_version() {
  local pom="$1"
  local version=""
  # 方式1: <spring-boot.version> 属性
  version=$(grep -oE '<spring-boot\.version>[^<]*</spring-boot\.version>' "$pom" 2>/dev/null \
    | sed 's/<[^>]*>//g' | head -1)
  # 方式2: parent 的 version
  if [ -z "$version" ]; then
    version=$(grep -A3 'spring-boot-starter-parent' "$pom" 2>/dev/null \
      | grep '<version>' | head -1 | sed 's/<[^>]*>//g' | tr -d ' ')
  fi
  echo "$version"
}

# ============================================================
# 内部：从 Gradle 文本中去除注释（// 行注释 + /* */ 块注释）
# ============================================================
_strip_gradle_comments() {
  # 1. 去掉 /* ... */ 块注释（跨行用 tr 压缩换行再 sed）
  # 2. 去掉 // 行注释
  tr '\n' '\001' | sed 's|/\*[^*]*\*\+\([^/*][^*]*\*\+\)*/||g' | tr '\001' '\n' \
    | sed 's|//.*||'
}

# ============================================================
# detect_framework — 检测 Spring 框架类型
# 参数: <repo_path>
# 输出: JSON {framework, is_spring, version, has_spring_cloud_bom}
# ============================================================
detect_framework() {
  local repo="${1:-.}"
  local has_spring_boot=false
  local has_spring_cloud=false
  local version=""
  local has_spring_cloud_bom=false

  # ---- Maven 路径 ----
  if [ -f "$repo/pom.xml" ]; then
    local pom="$repo/pom.xml"

    # Spring Boot parent
    if grep -q 'spring-boot-starter-parent' "$pom" 2>/dev/null; then
      has_spring_boot=true
    fi
    # spring-boot-starter-* 依赖
    if grep -q '<artifactId>spring-boot-starter-' "$pom" 2>/dev/null; then
      has_spring_boot=true
    fi
    # dependencyManagement 中的 spring-cloud-dependencies BOM
    if grep -q 'spring-cloud-dependencies' "$pom" 2>/dev/null; then
      has_spring_cloud=true
      has_spring_cloud_bom=true
    fi
    # spring-cloud-starter-* 依赖
    if grep -q '<artifactId>spring-cloud-starter-' "$pom" 2>/dev/null; then
      has_spring_cloud=true
    fi
    # spring-cloud-* 依赖（更宽泛）
    if grep -q '<artifactId>spring-cloud-' "$pom" 2>/dev/null; then
      has_spring_cloud=true
    fi

    version=$(_extract_maven_sb_version "$pom")

  # ---- Gradle 路径 ----
  elif [ -f "$repo/build.gradle" ]; then
    local gradle_text
    gradle_text=$(_gradle_scan_text "$repo")
    local clean_text
    clean_text=$(echo "$gradle_text" | _strip_gradle_comments)

    # buildscript 含 spring-boot-gradle-plugin
    if echo "$clean_text" | grep -q 'spring-boot-gradle-plugin'; then
      has_spring_boot=true
    fi
    # plugins { id 'org.springframework.boot' } 或 id "org.springframework.boot"
    if echo "$clean_text" | grep -q "org\.springframework\.boot"; then
      has_spring_boot=true
    fi
    # dependencyManagement 导入 spring-boot-dependencies
    if echo "$clean_text" | grep -q 'spring-boot-dependencies'; then
      has_spring_boot=true
    fi
    # dependencyManagement 导入 spring-cloud-dependencies
    if echo "$clean_text" | grep -q 'spring-cloud-dependencies'; then
      has_spring_cloud=true
      has_spring_cloud_bom=true
    fi
    # spring-cloud-starter 依赖
    if echo "$clean_text" | grep -q 'spring-cloud-starter'; then
      has_spring_cloud=true
    fi

    version=$(_extract_gradle_sb_version "$repo")
  fi

  # ---- 三级分类 ----
  local framework="non-spring"
  if [ "$has_spring_cloud" = true ]; then
    framework="spring-cloud"
  elif [ "$has_spring_boot" = true ]; then
    framework="spring-boot"
  fi

  local is_spring="false"
  if [ "$has_spring_boot" = true ] || [ "$has_spring_cloud" = true ]; then
    is_spring="true"
  fi

  printf '{"framework":"%s","is_spring":%s,"version":"%s","has_spring_cloud_bom":%s}\n' \
    "$framework" "$is_spring" "${version:-}" "$has_spring_cloud_bom"
}

# ============================================================
# parse_dependencies — 提取关键依赖版本
# 参数: <repo_path> <build_tool>
# 输出: JSON 数组 [{groupId, artifactId, version, matchType}]
# ============================================================
parse_dependencies() {
  local repo="$1" build_tool="$2"
  local text=""

  if [ "$build_tool" = "maven" ] && [ -f "$repo/pom.xml" ]; then
    text=$(cat "$repo/pom.xml")
  elif [ "$build_tool" = "gradle" ] && [ -f "$repo/build.gradle" ]; then
    text=$(_gradle_scan_text "$repo")
  else
    echo '[]'
    return 0
  fi

  # 提取匹配关键 artifactId 的依赖行
  local pattern='spring-boot-starter|mybatis|nacos|sentinel|apollo|eureka|feign|dubbo|redis|redisson|jetcache|druid|xxl-job|rocketmq|kafka|rabbitmq|skywalking|pagehelper|consul|resilience4j'

  local results="["
  local first=true

  if [ "$build_tool" = "maven" ]; then
    # Maven: 从 <dependency> 块中提取
    # 用 awk 状态机提取 dependency 块
    echo "$text" | grep -E "$pattern" | while IFS= read -r line; do
      # 简单匹配 artifactId 行
      if echo "$line" | grep -q '<artifactId>'; then
        local aid
        aid=$(echo "$line" | sed 's/.*<artifactId>\(.*\)<\/artifactId>.*/\1/')
        local gid=""
        local ver=""
        # 匹配类型
        local mtype="middleware"
        if echo "$aid" | grep -qE '^spring-boot-starter-|^spring-cloud-starter-'; then
          if echo "$aid" | grep -q 'spring-cloud'; then
            mtype="cloud"
          else
            mtype="spring-boot"
          fi
        fi
        printf '{"groupId":"%s","artifactId":"%s","version":"%s","matchType":"%s"}\n' \
          "${gid:-unknown}" "$aid" "${ver:-unknown}" "$mtype"
      fi
    done
  else
    # Gradle: 提取 implementation/compileOnly/api/runtimeOnly/testImplementation 行
    echo "$text" | grep -E "$pattern" | while IFS= read -r line; do
      local clean
      clean=$(echo "$line" | sed "s/^[[:space:]]*//;s/[[:space:]]*$//")
      # 跳过注释行
      if echo "$clean" | grep -qE '^\s*(//|/\*)'; then
        continue
      fi
      # 匹配 'groupId:artifactId:version' 或 'groupId:artifactId'
      local coord
      coord=$(echo "$clean" | grep -oE "['\"][^'\"]*:[^'\"]*:[^'\"]*['\"]" | head -1 | tr -d "'\"")
      if [ -z "$coord" ]; then
        coord=$(echo "$clean" | grep -oE "['\"][^'\"]*:[^'\"]*['\"]" | head -1 | tr -d "'\"")
      fi
      if [ -n "$coord" ]; then
        local gid aid ver
        gid=$(echo "$coord" | cut -d: -f1)
        aid=$(echo "$coord" | cut -d: -f2)
        ver=$(echo "$coord" | cut -d: -f3)
        local mtype="middleware"
        if echo "$aid" | grep -qE '^spring-boot-starter-|^spring-cloud-starter-'; then
          if echo "$aid" | grep -q 'spring-cloud'; then
            mtype="cloud"
          else
            mtype="spring-boot"
          fi
        fi
        printf '{"groupId":"%s","artifactId":"%s","version":"%s","matchType":"%s"}\n' \
          "${gid:-}" "${aid:-}" "${ver:-}" "$mtype"
      fi
    done
  fi
}

# ============================================================
# 内部：中间件名 → 分类映射 (bash 3.2 兼容 case 语句)
# ============================================================
_mw_category() {
  case "$1" in
    rocketmq|ons|kafka|rabbitmq)               echo "mq" ;;
    redis|redisson|jetcache)                   echo "cache" ;;
    eureka|nacos|consul)                       echo "registry" ;;
    mybatis|mybatis-plus|druid|dynamic-datasource) echo "database" ;;
    feign|dubbo)                               echo "rpc" ;;
    apollo|nacos-config)                       echo "config" ;;
    sentinel|resilience4j)                     echo "ratelimit" ;;
    xxl-job)                                   echo "scheduler" ;;
    skywalking)                                echo "observability" ;;
    pagehelper)                                echo "utility" ;;
    web|webflux)                               echo "web" ;;
    *)                                         echo "other" ;;
  esac
}

# ============================================================
# identify_middleware — 检测中间件并分类
# 参数: <repo_path> <build_tool>
# 输出: JSON {middleware: [...], middleware_categories: {...}}
# ============================================================
identify_middleware() {
  local repo="$1" build_tool="$2"
  local text=""

  if [ "$build_tool" = "maven" ] && [ -f "$repo/pom.xml" ]; then
    text=$(cat "$repo/pom.xml")
  elif [ "$build_tool" = "gradle" ] && [ -f "$repo/build.gradle" ]; then
    text=$(_gradle_scan_text "$repo")
  else
    echo '{"middleware":[],"middleware_categories":{}}'
    return 0
  fi

  local clean_text="$text"

  # ---- 中间件匹配规则表 (name → grep pattern) ----
  # 用 \n 分隔的 name|pattern 列表，循环检测
  local detected=""

  # MQ
  if echo "$clean_text" | grep -qE 'ons-client-starter|rocketmq-client|rocketmq-acl|ons-client'; then
    detected="$detected rocketmq"
  fi
  if echo "$clean_text" | grep -qE 'kafka-clients|spring-kafka'; then
    detected="$detected kafka"
  fi
  if echo "$clean_text" | grep -qE 'rabbitmq-client|spring-rabbit'; then
    detected="$detected rabbitmq"
  fi

  # 缓存
  if echo "$clean_text" | grep -qE 'redis-starter|spring-boot-starter-data-redis|redis\.clients|jedis|lettuce-core'; then
    detected="$detected redis"
  fi
  if echo "$clean_text" | grep -qE 'redisson-spring-boot-starter|redisson-spring-data|Redisson|redissonSpringData|redissonSpringBootStarter'; then
    detected="$detected redisson"
  fi
  if echo "$clean_text" | grep -qE 'jetcache-starter|jetcache-anno|jetcache-core|jetcacheStarterRedis|jetcacheAnnoApi|Jetcache'; then
    detected="$detected jetcache"
  fi

  # 注册中心
  if echo "$clean_text" | grep -qE 'spring-cloud-starter-netflix-eureka-client|eureka-client|eurekaSpringCommon'; then
    detected="$detected eureka"
  fi
  if echo "$clean_text" | grep -qE 'nacos-discovery-spring-boot-starter|nacos-client|nacos-spring'; then
    detected="$detected nacos"
  fi
  if echo "$clean_text" | grep -qE 'consul-discovery'; then
    detected="$detected consul"
  fi

  # 数据库 / ORM
  if echo "$clean_text" | grep -qE 'mybatis-plus-boot-starter|mybatis-plus-spring-boot-starter|mybatisPlusBootStarter|MybatisPlus'; then
    detected="$detected mybatis-plus"
  fi
  if echo "$clean_text" | grep -qE 'mybatis-spring-boot-starter|mybatisSpringbootStarter' && ! echo "$clean_text" | grep -qE 'mybatis-plus'; then
    # 只有 mybatis 没有 mybatis-plus 时才单独标记 mybatis
    if ! echo "$detected" | grep -q 'mybatis-plus'; then
      detected="$detected mybatis"
    fi
  fi
  if echo "$clean_text" | grep -qE 'druid-spring-boot-starter|druidSpringBootStarter|Druid'; then
    detected="$detected druid"
  fi
  if echo "$clean_text" | grep -qE 'dynamic-datasource-spring-boot-starter|dynamicDataSourceStarter'; then
    detected="$detected dynamic-datasource"
  fi

  # RPC / 服务调用
  if echo "$clean_text" | grep -qE 'spring-cloud-starter-openfeign|feign-core|feign-httpclient|OpenFeign'; then
    detected="$detected feign"
  fi
  if echo "$clean_text" | grep -qE 'dubbo-spring-boot-starter|dubbo-spring-boot'; then
    detected="$detected dubbo"
  fi

  # 配置中心
  if echo "$clean_text" | grep -qE 'yaduo-apollo-starter|apollo-client|apollo-core|Apollo'; then
    detected="$detected apollo"
  fi
  if echo "$clean_text" | grep -qE 'nacos-config-spring-boot-starter|spring-cloud-starter-alibaba-nacos-config'; then
    detected="$detected nacos-config"
  fi

  # 限流
  if echo "$clean_text" | grep -qE 'spring-cloud-starter-alibaba-sentinel|sentinel-core|fusion-sentinel|sentinel'; then
    detected="$detected sentinel"
  fi
  if echo "$clean_text" | grep -qE 'resilience4j-spring-boot2|resilience4j'; then
    detected="$detected resilience4j"
  fi

  # 调度
  if echo "$clean_text" | grep -qE 'xxljob-starter|xxl-job'; then
    detected="$detected xxl-job"
  fi

  # 可观测性
  if echo "$clean_text" | grep -qE 'apm-toolkit-trace|skywalking|SkyWalking'; then
    detected="$detected skywalking"
  fi

  # 工具
  if echo "$clean_text" | grep -qE 'pagehelper-spring-boot-starter|pagehelper'; then
    detected="$detected pagehelper"
  fi

  # Web 框架
  if echo "$clean_text" | grep -qE 'spring-boot-starter-web[^f]'; then
    detected="$detected web"
  fi
  if echo "$clean_text" | grep -qE 'spring-boot-starter-webflux'; then
    detected="$detected webflux"
  fi

  # ---- 去重 + 排序 ----
  local mw_list
  mw_list=$(printf '%s' "$detected" | tr ' ' '\n' | sort -u | grep -v '^$')

  # ---- 构建 JSON ----
  local mw_json="["
  local first=true
  while IFS= read -r mw; do
    [ -z "$mw" ] && continue
    if [ "$first" = true ]; then first=false; else mw_json="$mw_json,"; fi
    mw_json="$mw_json\"$mw\""
  done <<END_MW
$mw_list
END_MW
  mw_json="$mw_json]"

  # ---- 按分类分组 (bash 3.2 兼容：内联 case 避免函数调用问题) ----
  local cats_json="{"
  local cat_first=true
  local processed=""

  while IFS= read -r mw; do
    [ -z "$mw" ] && continue
    local cat="other"
    case "$mw" in
      rocketmq|ons|kafka|rabbitmq)               cat="mq" ;;
      redis|redisson|jetcache)                   cat="cache" ;;
      eureka|nacos|consul)                       cat="registry" ;;
      mybatis|mybatis-plus|druid|dynamic-datasource) cat="database" ;;
      feign|dubbo)                               cat="rpc" ;;
      apollo|nacos-config)                       cat="config" ;;
      sentinel|resilience4j)                     cat="ratelimit" ;;
      xxl-job)                                   cat="scheduler" ;;
      skywalking)                                cat="observability" ;;
      pagehelper)                                cat="utility" ;;
      web|webflux)                               cat="web" ;;
    esac

    if echo " $processed " | grep -q " $cat "; then
      continue
    fi
    processed="$processed $cat"

    local cat_items=""
    local item_first=true
    while IFS= read -r mw2; do
      [ -z "$mw2" ] && continue
      local cat2="other"
      case "$mw2" in
        rocketmq|ons|kafka|rabbitmq)               cat2="mq" ;;
        redis|redisson|jetcache)                   cat2="cache" ;;
        eureka|nacos|consul)                       cat2="registry" ;;
        mybatis|mybatis-plus|druid|dynamic-datasource) cat2="database" ;;
        feign|dubbo)                               cat2="rpc" ;;
        apollo|nacos-config)                       cat2="config" ;;
        sentinel|resilience4j)                     cat2="ratelimit" ;;
        xxl-job)                                   cat2="scheduler" ;;
        skywalking)                                cat2="observability" ;;
        pagehelper)                                cat2="utility" ;;
        web|webflux)                               cat2="web" ;;
      esac
      if [ "$cat2" = "$cat" ]; then
        if [ "$item_first" = true ]; then item_first=false; else cat_items="$cat_items,"; fi
        cat_items="${cat_items}\"$mw2\""
      fi
    done <<END_MW2
$mw_list
END_MW2

    if [ "$cat_first" = true ]; then cat_first=false; else cats_json="$cats_json,"; fi
    cats_json="$cats_json\"$cat\":[$cat_items]"
  done <<END_MW3
$mw_list
END_MW3
  cats_json="$cats_json}"

  echo "{\"middleware\":$mw_json,\"middleware_categories\":$cats_json}"
}
