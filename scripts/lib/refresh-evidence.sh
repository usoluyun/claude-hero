#!/usr/bin/env bash
# codegraph 重索引 + evidence pack 导出。依赖 refresh-common.sh。

evidence_dir() {  # echo 某项目的 evidence 工作目录
  echo "$(repo_root)/docs/.refresh-work/$1"
}

ensure_exclude() {  # 把 .codegraph/ 加进该仓库 git exclude（本地忽略；兼容 worktree/submodule）
  local repo gitdir ex
  repo="$(expand_path "$1")"
  gitdir="$(git -C "$repo" rev-parse --absolute-git-dir 2>/dev/null)" || return 0
  ex="$gitdir/info/exclude"
  mkdir -p "$gitdir/info"
  grep -qxF '.codegraph/' "$ex" 2>/dev/null || echo '.codegraph/' >> "$ex"
}

reindex() {  # 对既有索引做刷新重建
  local repo; repo="$(expand_path "$1")"
  ensure_exclude "$repo"
  codegraph index "$repo"
}

export_evidence() {  # 导出 evidence 文件到 evidence_dir
  local proj="$1" repo; repo="$(expand_path "$2")"
  local out; out="$(evidence_dir "$proj")"
  mkdir -p "$out"
  codegraph files --format grouped --filter src/main/java -p "$repo" > "$out/structure.txt" 2>/dev/null
  {
    for sym in Controller Feign Service Mapper Listener Consumer Job; do
      echo "### $sym"
      codegraph query "$sym" -p "$repo" 2>/dev/null
      echo
    done
  } > "$out/entrypoints.txt"
  # 依赖指纹：pom 或 gradle
  if [[ -f "$repo/pom.xml" ]]; then cp "$repo/pom.xml" "$out/deps-pom.xml"; fi
  find "$repo" -maxdepth 2 -name 'build.gradle' -exec cat {} + > "$out/deps-gradle.txt" 2>/dev/null || true
}
