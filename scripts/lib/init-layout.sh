#!/usr/bin/env bash
# 项目布局探测函数库。依赖 init-common.sh（需先 source）。
# 提供 detect_build_tool / analyze_modules / get_project_name。
# 所有 JSON 输出均为 jq 可解析的合法 JSON。

detect_build_tool() {
  # 参数: <repo_path>
  # 检测项目的构建系统（Maven / Gradle / mixed）
  # 输出: JSON → {"build_tool":"maven|gradle|mixed","has_pom":true|false,"has_gradle":true|false}
  local repo="$1"
  local has_pom="false" has_gradle="false" build_tool

  [ -f "$repo/pom.xml" ] && has_pom="true"
  [ -f "$repo/build.gradle" ] && has_gradle="true"

  if [ "$has_pom" = "true" ] && [ "$has_gradle" = "true" ]; then
    build_tool="mixed"
  elif [ "$has_pom" = "true" ]; then
    build_tool="maven"
  elif [ "$has_gradle" = "true" ]; then
    build_tool="gradle"
  else
    echo "ERROR: 未检测到构建系统（缺少 pom.xml 或 build.gradle）: $repo" >&2
    return 1
  fi

  printf '{"build_tool":"%s","has_pom":%s,"has_gradle":%s}\n' \
    "$build_tool" "$has_pom" "$has_gradle"
}

analyze_modules() {
  # 参数: <repo_path> <build_tool>
  # 分析项目的模块结构（单模块 / 多模块）
  # Maven: 检查 pom.xml 的 <modules> 标签
  # Gradle: 检查 settings.gradle 的 include 指令
  # mixed: 优先 Maven，未检测到再试 Gradle
  # 输出: JSON → {"is_multimodule":true|false,"modules":["m1","m2"],"module_count":N}
  local repo="$1" build_tool="$2"
  local is_multimodule="false" modules_json="[]" module_count=0
  local modules_str

  # --- Maven 路径 (maven 或 mixed) ---
  if [ "$build_tool" = "maven" ] || [ "$build_tool" = "mixed" ]; then
    if [ -f "$repo/pom.xml" ] && grep -q '<modules>' "$repo/pom.xml" 2>/dev/null; then
      modules_str=$(sed -n '/<modules>/,/<\/modules>/s/.*<module>\(.*\)<\/module>.*/\1/p' "$repo/pom.xml")
      if [ -n "$modules_str" ]; then
        modules_json=$(printf '%s\n' "$modules_str" | grep -v '^[[:space:]]*$' | jq -R . | jq -s . 2>/dev/null)
        if [ -n "$modules_json" ] && [ "$modules_json" != "[]" ]; then
          module_count=$(printf '%s' "$modules_json" | jq 'length')
          is_multimodule="true"
        else
          modules_json="[]"
        fi
      fi
    fi
  fi

  # --- Gradle 路径 (gradle 或 mixed，仅在 Maven 未命中时) ---
  if [ "$is_multimodule" = "false" ]; then
    if [ "$build_tool" = "gradle" ] || [ "$build_tool" = "mixed" ]; then
      if [ -f "$repo/settings.gradle" ]; then
        modules_str=$(grep -o "include[[:space:]]*['\"][^'\"]*['\"]" "$repo/settings.gradle" 2>/dev/null | \
          sed "s/include[[:space:]]*['\"]//;s/['\"]$//")
        if [ -n "$modules_str" ]; then
          modules_json=$(printf '%s\n' "$modules_str" | grep -v '^[[:space:]]*$' | jq -R . | jq -s . 2>/dev/null)
          if [ -n "$modules_json" ] && [ "$modules_json" != "[]" ]; then
            module_count=$(printf '%s' "$modules_json" | jq 'length')
            is_multimodule="true"
          else
            modules_json="[]"
          fi
        fi
      fi
    fi
  fi

  printf '{"is_multimodule":%s,"modules":%s,"module_count":%d}\n' \
    "$is_multimodule" "$modules_json" "$module_count"
}

get_project_name() {
  # 参数: <repo_path>
  # 推断项目名（用于 agent 文件名 hero-java-<proj>）
  # 策略（优先级）:
  #   1. pom.xml 根 <artifactId> 标签
  #   2. settings.gradle rootProject.name
  #   3. 目录名 basename
  # 输出: echo 项目名（小写 kebab-case）
  local repo="$1" name=""

  # 1. pom.xml root <artifactId>（取第一个出现的 <artifactId>）
  if [ -f "$repo/pom.xml" ]; then
    name=$(grep -m1 '<artifactId>' "$repo/pom.xml" 2>/dev/null | \
      sed 's/.*<artifactId>\(.*\)<\/artifactId>.*/\1/')
  fi

  # 2. settings.gradle rootProject.name
  if [ -z "$name" ] && [ -f "$repo/settings.gradle" ]; then
    name=$(grep 'rootProject\.name' "$repo/settings.gradle" 2>/dev/null | \
      sed "s/.*rootProject\.name[[:space:]]*=[[:space:]]*['\"]\([^'\"]*\)['\"].*/\1/")
  fi

  # 3. 目录名 basename
  if [ -z "$name" ]; then
    name=$(basename "$repo")
  fi

  # 转换为小写 kebab-case：大写→小写，点号→连字符
  printf '%s\n' "$name" | tr '[:upper:]' '[:lower:]' | tr '.' '-'
}
