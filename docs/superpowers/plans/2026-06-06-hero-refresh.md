# hero-refresh 统一刷新机制 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 一套手动触发的统一刷新机制，把 codegraph 索引 / 领航 agent / context7 vendor docs 三件套一起保鲜，确定性层自动跑、领航 agent 漂移走人工评审 gate。

**Architecture:** 脚本 + skill 双层。`scripts/hero-refresh.sh`（+ `scripts/lib/*.sh` 可 source 的纯函数库）干确定性脏活（git 记账 / codegraph 重索引 / evidence 导出 / context7 抓取）；`skills/hero-refresh/SKILL.md` 干编排、漂移判断、评审门控、触发词；`config/hooks/hero-refresh-check.sh` 是 SessionStart 秒级提醒 hook。状态记在 `docs/.refresh-state.json`。

**Tech Stack:** bash、jq（JSON 读写）、git、codegraph CLI（v0.9.7+）、context7 HTTP API（curl）、Claude Code skill + hooks。

**设计依据：** `docs/superpowers/specs/2026-06-06-hero-refresh-design.md`

**测试策略：** 纯逻辑 shell 函数（状态读写、路径展开、指纹提取）用零依赖 bash 断言做单测（`tests/hero-refresh/`）；触外部工具/网络的步骤（codegraph 重索引、context7 抓取、hook 注入）对 fixture 仓库或现有 3 个真实项目做集成验证、肉眼核对输出。

**前置依赖：** 本机已装 `jq`（`brew install jq`）、`codegraph` v0.9.7+、`git`；可选 `CONTEXT7_API_KEY` 环境变量（无则 context7 限速低但仍可跑）。

---

## 文件结构

| 文件 | 职责 |
|---|---|
| `scripts/lib/refresh-common.sh` | 公共：路径展开、repo HEAD、jq 前置检查、仓库根定位 |
| `scripts/lib/refresh-state.sh` | `.refresh-state.json` 读写（项目列表 / 字段 get/set / 是否存在） |
| `scripts/lib/refresh-evidence.sh` | codegraph 重索引（含 `.git/info/exclude`）+ evidence pack 导出 |
| `scripts/lib/refresh-vendor.sh` | 解析领航 agent ②指纹 → context7 解析 id → 抓取写本地 |
| `scripts/hero-refresh.sh` | CLI 入口：编排确定性层，遍历已接入项目，增量跳过，回写状态 |
| `config/hooks/hero-refresh-check.sh` | L1 SessionStart hook：秒级 git SHA 漂移检测 + 注入提醒 |
| `skills/hero-refresh/SKILL.md` | 编排 + 漂移检测 + 评审门控 + `hero 刷新` 触发词 |
| `docs/.refresh-state.json` | 已接入项目状态（进 git，种子 3 个项目） |
| `.claude/settings.json` | 注册 SessionStart hook（项目级） |
| `tests/hero-refresh/assert.sh` | 零依赖 bash 断言助手 |
| `tests/hero-refresh/test_*.sh` | 各 lib 的单测 |
| `tests/hero-refresh/run.sh` | 测试总入口 |
| `docs/vendor-docs/.gitkeep` | 缓存目录占位（目录进 git，内容随刷新生成） |
| `.gitignore` | 追加 `.refresh-work/`、`.refresh-drafts/` |

**函数契约（跨任务一致性锚点）：**
- `expand_path <path>` → echo 展开 `~` 后的绝对路径
- `repo_head <repo_path>` → echo `git rev-parse HEAD`
- `require_jq` → 缺 jq 时报错退出
- `repo_root` → echo claude-hero 仓库根绝对路径
- `state_file` → echo `<repo_root>/docs/.refresh-state.json`
- `state_projects` → echo 项目 key（每行一个）
- `state_has <proj>` → exit 0/1
- `state_get <proj> <field>` → echo 字段值（field ∈ repo_path|agent|last_commit|last_refreshed）
- `state_set <proj> <field> <value>` → 原地更新 JSON
- `reindex <repo_path>` → codegraph 重索引 + 确保 exclude
- `evidence_dir <proj>` → echo `<repo_root>/docs/.refresh-work/<proj>`
- `export_evidence <proj> <repo_path>` → 写 evidence 文件到 evidence_dir
- `agent_file <agent_name>` → echo `<repo_root>/agents/<agent_name>.md`
- `extract_fingerprint_libs <agent_file>` → echo 识别到的库关键词（每行一个，已小写去重）
- `context7_resolve <lib>` → echo libraryId（失败 echo 空）
- `context7_fetch <libraryId> <out_file>` → 抓取写文件，返回 0/非0
- `refresh_vendor_docs <proj>` → 对一个项目的 agent 跑整套 vendor 抓取

---

## Phase 1 · 状态库 + 测试脚手架

### Task 1: 测试断言助手 + 公共函数库

**Files:**
- Create: `tests/hero-refresh/assert.sh`
- Create: `tests/hero-refresh/run.sh`
- Create: `scripts/lib/refresh-common.sh`
- Create: `tests/hero-refresh/test_common.sh`

- [ ] **Step 1: 写断言助手**

Create `tests/hero-refresh/assert.sh`:

```bash
#!/usr/bin/env bash
# 零依赖断言助手。被各 test_*.sh source。
ASSERT_PASS=0
ASSERT_FAIL=0

assert_eq() {
  local expected="$1" actual="$2" msg="${3:-}"
  if [[ "$expected" == "$actual" ]]; then
    ASSERT_PASS=$((ASSERT_PASS+1))
  else
    ASSERT_FAIL=$((ASSERT_FAIL+1))
    echo "  ✗ ${msg:-assert_eq}: expected [$expected] got [$actual]"
  fi
}

assert_ok() {  # 命令应成功
  local msg="${2:-}"
  if eval "$1"; then ASSERT_PASS=$((ASSERT_PASS+1));
  else ASSERT_FAIL=$((ASSERT_FAIL+1)); echo "  ✗ ${msg:-assert_ok}: [$1] failed"; fi
}

assert_fail() {  # 命令应失败
  local msg="${2:-}"
  if eval "$1"; then ASSERT_FAIL=$((ASSERT_FAIL+1)); echo "  ✗ ${msg:-assert_fail}: [$1] should fail"; \
  else ASSERT_PASS=$((ASSERT_PASS+1)); fi
}

assert_summary() {
  echo "  → $ASSERT_PASS passed, $ASSERT_FAIL failed"
  [[ "$ASSERT_FAIL" -eq 0 ]]
}
```

- [ ] **Step 2: 写测试总入口**

Create `tests/hero-refresh/run.sh`:

```bash
#!/usr/bin/env bash
# 跑 tests/hero-refresh 下所有 test_*.sh，任一失败则整体失败。
set -u
cd "$(dirname "$0")"
fail=0
for t in test_*.sh; do
  echo "== $t =="
  bash "$t" || fail=1
done
[[ "$fail" -eq 0 ]] && echo "ALL TESTS PASSED" || { echo "SOME TESTS FAILED"; exit 1; }
```

- [ ] **Step 3: 写公共函数库**

Create `scripts/lib/refresh-common.sh`:

```bash
#!/usr/bin/env bash
# 公共工具函数。被其他 lib 与 CLI source。无副作用（source 时不执行动作）。

expand_path() {  # 展开开头的 ~
  local p="$1"
  case "$p" in
    "~") echo "$HOME" ;;
    "~/"*) echo "$HOME/${p#\~/}" ;;
    *) echo "$p" ;;
  esac
}

require_jq() {
  command -v jq >/dev/null 2>&1 || { echo "ERROR: 需要 jq，请先 brew install jq" >&2; return 1; }
}

repo_root() {  # claude-hero 仓库根 = 本文件所在 scripts/lib 的上两级
  local lib_dir
  lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  cd "$lib_dir/../.." && pwd
}

repo_head() {  # 给定本地仓库路径，echo 当前 HEAD sha
  local repo; repo="$(expand_path "$1")"
  git -C "$repo" rev-parse HEAD 2>/dev/null
}
```

- [ ] **Step 4: 写公共库单测**

Create `tests/hero-refresh/test_common.sh`:

```bash
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
```

- [ ] **Step 5: 跑测试，应通过**

Run: `bash tests/hero-refresh/test_common.sh`
Expected: 末行 `→ 4 passed, 0 failed`，退出码 0。

- [ ] **Step 6: Commit**

```bash
git add tests/hero-refresh/assert.sh tests/hero-refresh/run.sh \
        scripts/lib/refresh-common.sh tests/hero-refresh/test_common.sh
git commit -m "feat(hero-refresh): 测试脚手架 + 公共函数库"
```

---

### Task 2: 状态读写库

**Files:**
- Create: `scripts/lib/refresh-state.sh`
- Create: `tests/hero-refresh/test_state.sh`

- [ ] **Step 1: 写状态读写库**

Create `scripts/lib/refresh-state.sh`:

```bash
#!/usr/bin/env bash
# .refresh-state.json 读写。依赖 refresh-common.sh（调用方负责先 source 它）。
# 允许用 HERO_STATE_FILE 覆盖状态文件路径（测试用）。

state_file() {
  if [[ -n "${HERO_STATE_FILE:-}" ]]; then echo "$HERO_STATE_FILE";
  else echo "$(repo_root)/docs/.refresh-state.json"; fi
}

state_projects() {  # 每行一个项目 key
  jq -r '.projects | keys[]' "$(state_file)" 2>/dev/null
}

state_has() {  # exit 0 若项目存在
  local proj="$1"
  jq -e --arg p "$proj" '.projects | has($p)' "$(state_file)" >/dev/null 2>&1
}

state_get() {  # echo 字段值
  local proj="$1" field="$2"
  jq -r --arg p "$proj" --arg f "$field" '.projects[$p][$f] // ""' "$(state_file)"
}

state_set() {  # 原地更新字段
  local proj="$1" field="$2" value="$3" f tmp
  f="$(state_file)"; tmp="$(mktemp)"
  jq --arg p "$proj" --arg k "$field" --arg v "$value" \
     '.projects[$p][$k] = $v' "$f" > "$tmp" && mv "$tmp" "$f"
}
```

- [ ] **Step 2: 写状态库单测**

Create `tests/hero-refresh/test_state.sh`:

```bash
#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/assert.sh"
source "$DIR/../../scripts/lib/refresh-common.sh"
source "$DIR/../../scripts/lib/refresh-state.sh"

export HERO_STATE_FILE="$(mktemp)"
cat > "$HERO_STATE_FILE" <<'JSON'
{ "projects": {
  "ecrm": { "repo_path": "~/Documents/ATLWork/ecrm", "agent": "hero-java-ecrm", "last_commit": "", "last_refreshed": "" }
} }
JSON

assert_eq "ecrm" "$(state_projects)" "列出项目"
assert_ok "state_has ecrm" "ecrm 存在"
assert_fail "state_has nope" "nope 不存在"
assert_eq "hero-java-ecrm" "$(state_get ecrm agent)" "读 agent 字段"
assert_eq "" "$(state_get ecrm last_commit)" "空字段读成空串"

state_set ecrm last_commit "abc123"
assert_eq "abc123" "$(state_get ecrm last_commit)" "写后能读到新值"

rm -f "$HERO_STATE_FILE"
assert_summary
```

- [ ] **Step 3: 跑测试，应通过**

Run: `bash tests/hero-refresh/test_state.sh`
Expected: `→ 6 passed, 0 failed`，退出码 0。

- [ ] **Step 4: Commit**

```bash
git add scripts/lib/refresh-state.sh tests/hero-refresh/test_state.sh
git commit -m "feat(hero-refresh): .refresh-state.json 读写库"
```

---

### Task 3: 种子状态文件 + gitignore + 目录占位

**Files:**
- Create: `docs/.refresh-state.json`
- Create: `docs/vendor-docs/.gitkeep`
- Modify: `.gitignore`

- [ ] **Step 1: 写种子状态文件**

`last_commit` 留空 → 首次 `hero 刷新` 把 3 个项目都当作有变更，建立索引基线。

Create `docs/.refresh-state.json`:

```json
{
  "projects": {
    "ecrm": {
      "repo_path": "~/Documents/ATLWork/ecrm",
      "agent": "hero-java-ecrm",
      "last_commit": "",
      "last_refreshed": ""
    },
    "hotel-product-center": {
      "repo_path": "~/Documents/ATLWork/hotel-product-center",
      "agent": "hero-java-hotel-product-center",
      "last_commit": "",
      "last_refreshed": ""
    },
    "owner-biz": {
      "repo_path": "~/Documents/ATLWork/owner-biz",
      "agent": "hero-java-owner-biz",
      "last_commit": "",
      "last_refreshed": ""
    }
  }
}
```

- [ ] **Step 2: 目录占位**

Run:
```bash
mkdir -p docs/vendor-docs && touch docs/vendor-docs/.gitkeep
```

- [ ] **Step 3: 追加 gitignore**

在 `.gitignore` 末尾追加（先 `cat .gitignore` 确认没有重复行再加）：

```
# hero-refresh 临时产物（evidence pack 与待评审草稿不进 git）
docs/.refresh-work/
docs/.refresh-drafts/
```

- [ ] **Step 4: 校验 JSON 合法 + 能被状态库读到**

Run:
```bash
jq -e '.projects | keys | length == 3' docs/.refresh-state.json && echo OK
```
Expected: 输出 `true` 然后 `OK`。

- [ ] **Step 5: Commit**

```bash
git add docs/.refresh-state.json docs/vendor-docs/.gitkeep .gitignore
git commit -m "feat(hero-refresh): 种子状态文件（3 个已接入项目）+ gitignore"
```

---

## Phase 2 · 重索引 + evidence 导出

### Task 4: codegraph 重索引 + evidence 导出库

**Files:**
- Create: `scripts/lib/refresh-evidence.sh`
- Create: `tests/hero-refresh/test_evidence.sh`

- [ ] **Step 1: 写 evidence 库**

Create `scripts/lib/refresh-evidence.sh`:

```bash
#!/usr/bin/env bash
# codegraph 重索引 + evidence pack 导出。依赖 refresh-common.sh。

evidence_dir() {  # echo 某项目的 evidence 工作目录
  echo "$(repo_root)/docs/.refresh-work/$1"
}

ensure_exclude() {  # 把 .codegraph/ 加进该仓库的 .git/info/exclude（本地忽略，不动受控 .gitignore）
  local repo; repo="$(expand_path "$1")"
  local ex="$repo/.git/info/exclude"
  [[ -d "$repo/.git" ]] || return 0
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
```

- [ ] **Step 2: 写 evidence 库单测（只测纯逻辑部分）**

`reindex`/`export_evidence` 触 codegraph，留作集成验证；这里只单测 `evidence_dir` 与 `ensure_exclude`。

Create `tests/hero-refresh/test_evidence.sh`:

```bash
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

assert_summary
```

- [ ] **Step 3: 跑测试，应通过**

Run: `bash tests/hero-refresh/test_evidence.sh`
Expected: `→ 2 passed, 0 failed`。

- [ ] **Step 4: 集成验证（对真实项目 ecrm）**

Run:
```bash
source scripts/lib/refresh-common.sh
source scripts/lib/refresh-evidence.sh
reindex ~/Documents/ATLWork/ecrm
export_evidence ecrm ~/Documents/ATLWork/ecrm
ls -la docs/.refresh-work/ecrm/
grep -c . docs/.refresh-work/ecrm/structure.txt
```
Expected: `docs/.refresh-work/ecrm/` 下有 `structure.txt`/`entrypoints.txt`/`deps-pom.xml`；structure.txt 行数 > 0；entrypoints.txt 里能看到真实类名（如 `BusinessCorpApply`）。

> 若 `codegraph index` 命令名与本机不符（例如需 `codegraph init -i`），以本机 `codegraph --help` 为准修正 `reindex`，并把修正记到 `docs/project-agent-cookbook.md`。

- [ ] **Step 5: Commit**

```bash
git add scripts/lib/refresh-evidence.sh tests/hero-refresh/test_evidence.sh
git commit -m "feat(hero-refresh): codegraph 重索引 + evidence 导出库"
```

---

## Phase 3 · vendor docs（指纹驱动）

### Task 5: 指纹提取 + context7 抓取库

**Files:**
- Create: `scripts/lib/refresh-vendor.sh`
- Create: `tests/hero-refresh/test_vendor.sh`
- Create: `tests/hero-refresh/fixtures/agent-sample.md`

- [ ] **Step 1: 写 vendor 库**

「指纹驱动」= 只抓领航 agent ②段里**真实出现**的库；用识别字典把散文里的中间件名归一成 context7 搜索词（字典是识别过滤器，不是固定抓取清单 —— 没在某 agent ②段出现的库不会被它触发）。

Create `scripts/lib/refresh-vendor.sh`:

```bash
#!/usr/bin/env bash
# 解析领航 agent ②技术栈指纹 → context7 解析 id → 抓取写本地。依赖 refresh-common.sh。

# 识别字典：keyword（小写，出现在②段即命中） -> context7 搜索词。可持续扩充。
declare -A LIB_DICT=(
  [spring boot]="spring boot"
  [spring cloud]="spring cloud"
  [mybatis-plus]="mybatis-plus"
  [mybatis]="mybatis"
  [rocketmq]="rocketmq"
  [jetcache]="jetcache"
  [eureka]="eureka"
  [apollo]="apollo"
  [druid]="druid"
  [fastjson]="fastjson"
  [quartz]="quartz"
  [xxljob]="xxl-job"
  [xxl-job]="xxl-job"
  [skywalking]="skywalking"
)

agent_file() { echo "$(repo_root)/agents/$1.md"; }

# 抽出②技术栈指纹段（从 "## ②" 到下一个 "## " 之间），小写后扫字典命中关键词。
extract_fingerprint_libs() {
  local file="$1" section
  section="$(awk '/^## ②/{f=1;next} /^## /{f=0} f' "$file" | tr '[:upper:]' '[:lower:]')"
  local k
  for k in "${!LIB_DICT[@]}"; do
    if grep -qF "$k" <<<"$section"; then echo "${LIB_DICT[$k]}"; fi
  done | sort -u
}

context7_resolve() {  # echo libraryId（取搜索结果第一个 id），失败 echo 空
  local lib="$1" auth=()
  [[ -n "${CONTEXT7_API_KEY:-}" ]] && auth=(-H "Authorization: Bearer ${CONTEXT7_API_KEY}")
  curl -s "${auth[@]}" \
    --get "https://context7.com/api/v2/libs/search" --data-urlencode "libraryName=${lib}" \
    | jq -r '(.results // .libraries // .)[0].id // empty' 2>/dev/null
}

context7_fetch() {  # 抓 context 写文件
  local libraryId="$1" out="$2" auth=()
  [[ -n "${CONTEXT7_API_KEY:-}" ]] && auth=(-H "Authorization: Bearer ${CONTEXT7_API_KEY}")
  curl -s "${auth[@]}" \
    --get "https://context7.com/api/v2/context" \
    --data-urlencode "libraryId=${libraryId}" \
    --data-urlencode "query=usage and configuration" \
    -o "$out"
  [[ -s "$out" ]]
}

vendor_slug() { echo "$1" | tr ' /' '--' | tr '[:upper:]' '[:lower:]'; }

refresh_vendor_docs() {  # 对一个项目的 agent 跑整套
  local proj="$1" agent file lib id out
  agent="$(state_get "$proj" agent)"
  file="$(agent_file "$agent")"
  [[ -f "$file" ]] || { echo "WARN: 无 agent 文件 $file" >&2; return 0; }
  while IFS= read -r lib; do
    [[ -z "$lib" ]] && continue
    out="$(repo_root)/docs/vendor-docs/$(vendor_slug "$lib").md"
    id="$(context7_resolve "$lib")"
    if [[ -z "$id" ]]; then echo "  · $lib：未解析到 context7 id，跳过" >&2; continue; fi
    if context7_fetch "$id" "$out"; then echo "  ✓ $lib → $out";
    else echo "  · $lib：抓取失败，跳过" >&2; fi
  done < <(extract_fingerprint_libs "$file")
}
```

- [ ] **Step 2: 写 fixture agent（含②段）**

Create `tests/hero-refresh/fixtures/agent-sample.md`:

```markdown
---
name: hero-java-sample
description: 样例
---
你是样例领航员。

## ① 服务定位
无关内容，提一句 MyBatis 不该被①段命中。

## ② 技术栈指纹
- 平台：Spring Boot 2.7.18 + Eureka + Apollo
- 数据访问：MyBatis-Plus
- 消息：RocketMQ；缓存：JetCache
- 其它：fastjson、druid

## ③ 代码地图
RocketMQ 在③段再次出现，不应造成重复。
```

- [ ] **Step 3: 写 vendor 库单测（只测指纹提取与 slug，纯逻辑）**

`context7_*` 触网络，留作集成验证。

Create `tests/hero-refresh/test_vendor.sh`:

```bash
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
assert_eq "1" "$(grep -c 'mybatis' <<<\"$libs\")" "mybatis 系只出现一次（mybatis-plus）"
assert_eq "spring-cloud" "$(vendor_slug 'spring cloud')" "slug 空格转横杠"

assert_summary
```

> 注：`mybatis-plus` 字典键排在 `mybatis` 前、且 `grep -qF mybatis` 也会命中含「mybatis-plus」的文本，故②段同时触发两条字典项。为满足「只出现一次」断言，需在 `extract_fingerprint_libs` 末尾加去冗：当结果同时含 `mybatis` 与 `mybatis-plus` 时丢弃裸 `mybatis`。下一步实现它。

- [ ] **Step 4: 给 extract_fingerprint_libs 加 mybatis 去冗**

Modify `scripts/lib/refresh-vendor.sh` 的 `extract_fingerprint_libs`，把最后的输出管道改为先收集再过滤：

```bash
extract_fingerprint_libs() {
  local file="$1" section
  section="$(awk '/^## ②/{f=1;next} /^## /{f=0} f' "$file" | tr '[:upper:]' '[:lower:]')"
  local k hits=()
  for k in "${!LIB_DICT[@]}"; do
    if grep -qF "$k" <<<"$section"; then hits+=("${LIB_DICT[$k]}"); fi
  done
  printf '%s\n' "${hits[@]}" | sort -u | awk '
    { lines[NR]=$0; seen[$0]=1 }
    END {
      for (i=1;i<=NR;i++) {
        if (lines[i]=="mybatis" && ("mybatis-plus" in seen)) continue
        print lines[i]
      }
    }'
}
```

- [ ] **Step 5: 跑测试，应通过**

Run: `bash tests/hero-refresh/test_vendor.sh`
Expected: `→ 6 passed, 0 failed`。

- [ ] **Step 6: 集成验证（真实 context7，需联网）**

Run:
```bash
source scripts/lib/refresh-common.sh; source scripts/lib/refresh-state.sh; source scripts/lib/refresh-vendor.sh
id="$(context7_resolve 'spring boot')"; echo "id=$id"
[[ -n "$id" ]] && context7_fetch "$id" /tmp/sb.md && head -5 /tmp/sb.md
```
Expected: `id` 形如 `/spring-projects/spring-boot`（或相近）；`/tmp/sb.md` 非空、含文档文本。

> 若 v2 响应 JSON 结构与 `context7_resolve` 里的 `.results[0].id` 不符，按实际响应调整 jq 路径（用 `curl ... | jq .` 看一眼结构），并把正确路径记进设计文档「③」。无 `CONTEXT7_API_KEY` 时可能限速，重试或先 export key。

- [ ] **Step 7: Commit**

```bash
git add scripts/lib/refresh-vendor.sh tests/hero-refresh/test_vendor.sh tests/hero-refresh/fixtures/agent-sample.md
git commit -m "feat(hero-refresh): 指纹提取 + context7 vendor docs 抓取库"
```

---

## Phase 4 · CLI 组装 + 提交策略

### Task 6: `hero-refresh.sh` CLI 入口

**Files:**
- Create: `scripts/hero-refresh.sh`
- Create: `tests/hero-refresh/test_cli.sh`

- [ ] **Step 1: 写 CLI**

Create `scripts/hero-refresh.sh`:

```bash
#!/usr/bin/env bash
# hero-refresh 确定性层 CLI。
# 用法：
#   scripts/hero-refresh.sh [proj] [--force]   刷全部已接入项目，或只刷 proj；--force 忽略增量跳过
# 行为：对每个目标项目，HEAD 未变则跳过（除非 --force）；否则重索引 + 导出 evidence + 抓 vendor docs，回写状态。
# 退出后由 skill 接手做漂移检测/评审；本脚本不碰线上 agent。
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/lib/refresh-common.sh"
source "$HERE/lib/refresh-state.sh"
source "$HERE/lib/refresh-evidence.sh"
source "$HERE/lib/refresh-vendor.sh"
require_jq

FORCE=0; ONLY=""
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    *) ONLY="$arg" ;;
  esac
done

targets() {
  if [[ -n "$ONLY" ]]; then
    state_has "$ONLY" || { echo "ERROR: 项目 [$ONLY] 不在已接入列表（见 docs/.refresh-state.json）" >&2; exit 1; }
    echo "$ONLY"
  else
    state_projects
  fi
}

changed=()
while IFS= read -r proj; do
  [[ -z "$proj" ]] && continue
  repo="$(state_get "$proj" repo_path)"
  cur="$(repo_head "$repo")"
  [[ -z "$cur" ]] && { echo "⚠ $proj：读不到 HEAD（仓库不存在？$repo），跳过"; continue; }
  prev="$(state_get "$proj" last_commit)"
  if [[ "$FORCE" -eq 0 && "$cur" == "$prev" && -n "$prev" ]]; then
    echo "· $proj：无新 commit，跳过"
    continue
  fi
  echo "↻ $proj：重索引 + 导出 evidence + vendor docs …"
  reindex "$repo"
  export_evidence "$proj" "$repo"
  refresh_vendor_docs "$proj"
  state_set "$proj" last_commit "$cur"
  state_set "$proj" last_refreshed "$(date +%F)"
  changed+=("$proj")
done < <(targets)

echo
if [[ "${#changed[@]}" -eq 0 ]]; then
  echo "✓ 没有项目需要刷新（全部无变更）。"
else
  echo "✓ 已刷新确定性层：${changed[*]}"
  echo "  evidence 在 docs/.refresh-work/<proj>/，vendor docs 已更新。"
  echo "  下一步：在 Claude 里跑 hero 刷新 评审，逐个过这些项目的领航 agent 漂移。"
fi
```

- [ ] **Step 2: 写 CLI 单测（用 stub 替身隔离外部命令）**

测增量跳过逻辑：用假状态文件 + 把 reindex/export/vendor 用函数覆盖成 no-op，断言「无变更跳过、变更触发」。

Create `tests/hero-refresh/test_cli.sh`:

```bash
#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/assert.sh"

# 准备临时仓库（充当被刷项目）
proj_repo="$(mktemp -d)"; git -C "$proj_repo" init -q
git -C "$proj_repo" -c user.email=a@b.c -c user.name=t commit -q --allow-empty -m init
sha="$(git -C "$proj_repo" rev-parse HEAD)"

export HERO_STATE_FILE="$(mktemp)"
cat > "$HERO_STATE_FILE" <<JSON
{ "projects": { "demo": { "repo_path": "$proj_repo", "agent": "hero-java-demo", "last_commit": "", "last_refreshed": "" } } }
JSON

# 用 stub 覆盖触外部的函数，避免真跑 codegraph/curl
export HERO_TEST_STUB=1
out="$(HERO_TEST_STUB=1 bash -c '
  source '"$DIR"'/../../scripts/lib/refresh-common.sh
  source '"$DIR"'/../../scripts/lib/refresh-state.sh
  reindex(){ :; }; export_evidence(){ :; }; refresh_vendor_docs(){ :; }
  source '"$DIR"'/../../scripts/lib/refresh-evidence.sh
  source '"$DIR"'/../../scripts/lib/refresh-vendor.sh
  reindex(){ echo STUB_REINDEX; }; export_evidence(){ :; }; refresh_vendor_docs(){ :; }
  # 复刻 CLI 主循环（简化：只验跳过/触发）
  for proj in $(state_projects); do
    repo="$(state_get "$proj" repo_path)"; cur="$(repo_head "$repo")"; prev="$(state_get "$proj" last_commit)"
    if [[ "$cur" == "$prev" && -n "$prev" ]]; then echo "SKIP $proj"; continue; fi
    reindex "$repo"; state_set "$proj" last_commit "$cur"
  done
')"
assert_ok "grep -q STUB_REINDEX <<<\"$out\"" "首次（last_commit空）触发重索引"
assert_eq "$sha" "$(HERO_STATE_FILE=$HERO_STATE_FILE bash -c 'source '"$DIR"'/../../scripts/lib/refresh-common.sh; source '"$DIR"'/../../scripts/lib/refresh-state.sh; state_get demo last_commit')" "回写了 HEAD"

rm -rf "$proj_repo"; rm -f "$HERO_STATE_FILE"
assert_summary
```

> 注：CLI 主循环逻辑同时在 `hero-refresh.sh` 与本测试里出现，属刻意——测试验证的是「跳过/触发/回写」这套判定，CLI 是其唯一生产实现。若日后逻辑变复杂，抽成 `refresh_one <proj>` 函数放 lib 里供两方共用。

- [ ] **Step 3: 跑测试，应通过**

Run: `bash tests/hero-refresh/test_cli.sh`
Expected: `→ 2 passed, 0 failed`。

- [ ] **Step 4: 跑全量测试套件**

Run: `bash tests/hero-refresh/run.sh`
Expected: 末行 `ALL TESTS PASSED`。

- [ ] **Step 5: 端到端冒烟（真实，单项目幂等验证）**

Run:
```bash
bash scripts/hero-refresh.sh ecrm          # 首次：触发刷新
bash scripts/hero-refresh.sh ecrm          # 二次：应「无新 commit，跳过」
```
Expected: 第一次输出 `↻ ecrm …` 并最终列出已刷新；第二次输出 `· ecrm：无新 commit，跳过` 且无刷新。验证幂等（spec 验证标准 #1）。

- [ ] **Step 6: 提交确定性产物 + 代码**

```bash
git add scripts/hero-refresh.sh tests/hero-refresh/test_cli.sh
git commit -m "feat(hero-refresh): 确定性层 CLI 入口（增量跳过 + 回写状态）"
# 注意：docs/.refresh-state.json 与 docs/vendor-docs/ 的变更属确定性产物，
# 按 spec 提交策略单独提交：
git add docs/.refresh-state.json docs/vendor-docs/
git commit -m "chore(hero-refresh): 刷新确定性产物（状态 + vendor docs）" || echo "（无确定性产物变更，跳过）"
```

---

## Phase 5 · L1 提醒 hook

### Task 7: SessionStart 漂移检测 hook

**Files:**
- Create: `config/hooks/hero-refresh-check.sh`
- Create: `.claude/settings.json`
- Create: `tests/hero-refresh/test_hook.sh`

- [ ] **Step 1: 写 hook 脚本**

Create `config/hooks/hero-refresh-check.sh`:

```bash
#!/usr/bin/env bash
# L1 SessionStart hook：秒级 git SHA 漂移检测，发现已接入项目有新 commit 就注入提醒。
# 纯只读：不重索引、不抓文档、不写文件。任何错误都静默退出，绝不阻塞会话启动。
set -u

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
STATE="$ROOT/docs/.refresh-state.json"
command -v jq >/dev/null 2>&1 || exit 0
[[ -f "$STATE" ]] || exit 0

stale=()
while IFS= read -r proj; do
  [[ -z "$proj" ]] && continue
  repo="$(jq -r --arg p "$proj" '.projects[$p].repo_path' "$STATE")"
  case "$repo" in "~") repo="$HOME";; "~/"*) repo="$HOME/${repo#\~/}";; esac
  prev="$(jq -r --arg p "$proj" '.projects[$p].last_commit' "$STATE")"
  cur="$(git -C "$repo" rev-parse HEAD 2>/dev/null)" || continue
  [[ -z "$cur" ]] && continue
  if [[ "$cur" != "$prev" ]]; then stale+=("$proj"); fi
done < <(jq -r '.projects | keys[]' "$STATE")

[[ "${#stale[@]}" -eq 0 ]] && exit 0

msg="⚠️ hero-refresh：以下已接入项目自上次刷新后有新 commit，建议在本会话跑 \`hero 刷新\`：${stale[*]}"
# 通过 SessionStart hook 的 additionalContext 把提醒注入会话上下文
jq -cn --arg c "$msg" '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$c}}'
exit 0
```

- [ ] **Step 2: 注册项目级 hook**

先确认 `.claude/settings.json` 不存在（仓库现状：只有个人的 `.claude/settings.local.json`，那是 gitignored 的，**别动**）：
```bash
test -f .claude/settings.json && echo "已存在，需手动合并 SessionStart 块，勿覆盖" || echo "不存在，可直接创建"
```

不存在时，Create `.claude/settings.json`（这是团队共享、可提交的项目级 settings，区别于个人 `settings.local.json`）：

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/config/hooks/hero-refresh-check.sh\"" }
        ]
      }
    ]
  }
}
```

若已存在，则把上面的 `SessionStart` 数组项**合并**进现有 `hooks`，不要整体覆盖。

- [ ] **Step 3: 写 hook 单测（构造「有漂移」与「无漂移」两种状态）**

Create `tests/hero-refresh/test_hook.sh`:

```bash
#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/assert.sh"

repo="$(mktemp -d)"; git -C "$repo" init -q
git -C "$repo" -c user.email=a@b.c -c user.name=t commit -q --allow-empty -m init
sha="$(git -C "$repo" rev-parse HEAD)"

root="$(mktemp -d)"; mkdir -p "$root/docs" "$root/config/hooks"
cp "$DIR/../../config/hooks/hero-refresh-check.sh" "$root/config/hooks/"

# 状态里 last_commit 为空 → 视为漂移
cat > "$root/docs/.refresh-state.json" <<JSON
{ "projects": { "demo": { "repo_path": "$repo", "agent": "x", "last_commit": "", "last_refreshed": "" } } }
JSON
out="$(CLAUDE_PROJECT_DIR="$root" bash "$root/config/hooks/hero-refresh-check.sh")"
assert_ok "grep -q 'additionalContext' <<<\"$out\"" "有漂移时输出 additionalContext"
assert_ok "grep -q 'demo' <<<\"$out\"" "提醒里点名 demo"

# last_commit = 当前 sha → 无漂移，应无输出
cat > "$root/docs/.refresh-state.json" <<JSON
{ "projects": { "demo": { "repo_path": "$repo", "agent": "x", "last_commit": "$sha", "last_refreshed": "2026-06-06" } } }
JSON
out2="$(CLAUDE_PROJECT_DIR="$root" bash "$root/config/hooks/hero-refresh-check.sh")"
assert_eq "" "$out2" "无漂移时零输出（不阻塞、不打扰）"

rm -rf "$repo" "$root"
assert_summary
```

- [ ] **Step 4: 跑测试，应通过**

Run: `bash tests/hero-refresh/test_hook.sh`
Expected: `→ 3 passed, 0 failed`。

- [ ] **Step 5: 校验 hook JSON 合法**

Run:
```bash
CLAUDE_PROJECT_DIR="$(pwd)" bash config/hooks/hero-refresh-check.sh | jq . || echo "（无漂移则无输出，属正常）"
```
Expected: 要么无输出（当前 3 项目无漂移或 last_commit 已是最新），要么是一段合法 JSON 含 `hookSpecificOutput.additionalContext`。

- [ ] **Step 6: Commit**

```bash
git add config/hooks/hero-refresh-check.sh .claude/settings.json tests/hero-refresh/test_hook.sh
git commit -m "feat(hero-refresh): L1 SessionStart 漂移检测提醒 hook"
```

---

### Task 8: install.sh 纳入 hook + cli/ 记 jq 依赖

**Files:**
- Modify: `install.sh`
- Modify: `cli/README.md`

- [ ] **Step 1: 看 install.sh 现有 hook 软链逻辑**

Run: `grep -n "hook" install.sh`
Expected: 找到现有把 `config/hooks/` 软链到 `~/.claude/hooks/` 的片段（README 提过）。

- [ ] **Step 2: 确认 hook 脚本会被软链 + 设可执行位**

若 install.sh 已批量软链 `config/hooks/*`，则 `hero-refresh-check.sh` 自动被纳入，无需改逻辑——只需确保可执行：

```bash
chmod +x config/hooks/hero-refresh-check.sh scripts/hero-refresh.sh scripts/lib/*.sh
```

若 install.sh 是逐个列举 hook，则在列表里加上 `hero-refresh-check.sh`（按现有写法照葫芦画瓢，保持风格一致）。

> 注意：SessionStart hook 注册在**项目级** `.claude/settings.json`（Task 7），不依赖 `~/.claude` 全局 settings；install.sh 只负责让 hook 脚本可执行/可达。请勿把该 hook 写进全局 settings 模板。

- [ ] **Step 3: cli/README 加 jq 一行**

在 `cli/README.md` 的工具总表加一行：

```
| jq | JSON 处理（hero-refresh 状态读写依赖） | `brew install jq` | 脚本依赖，见 scripts/lib/ |
```

- [ ] **Step 4: 验证 install.sh 不报错（dry 检查）**

Run: `bash -n install.sh && echo "语法 OK"`
Expected: `语法 OK`（仅语法检查，不实际执行安装）。

- [ ] **Step 5: Commit**

```bash
git add install.sh cli/README.md
git commit -m "chore(hero-refresh): hook 可执行位 + 记录 jq 依赖"
```

---

## Phase 6 · skill（编排 + 漂移检测 + 评审门控）

### Task 9: `hero-refresh` skill

**Files:**
- Create: `skills/hero-refresh/SKILL.md`

- [ ] **Step 1: 写 SKILL.md**

Create `skills/hero-refresh/SKILL.md`：

````markdown
---
name: hero-refresh
description: hero 资产统一刷新工作流。触发词：hero 刷新 / hero 刷新 <proj> / hero 刷新 评审 / hero 刷新 状态。把 codegraph 索引 / 领航 agent / context7 vendor docs 三件套一起保鲜：确定性层（重索引+抓文档）跑脚本自动完成，领航 agent 漂移走人工评审 gate。只刷已接入项目（docs/.refresh-state.json）。
---

# hero 统一刷新工作流（hero-refresh）

**核心价值**：一条命令把三件套保鲜。确定性脏活交脚本，领航 agent 变更交人工判断——机器干活、你只做判断。

设计依据：`docs/superpowers/specs/2026-06-06-hero-refresh-design.md`。

## 触发词

| 命令 | 作用 |
|---|---|
| `hero 刷新` | 刷全部已接入项目 |
| `hero 刷新 <proj>` | 只刷一个项目 |
| `hero 刷新 评审` | 逐个过领航 agent 漂移草稿 |
| `hero 刷新 状态` | 列已接入项目 / 谁有新 commit / 几份草稿待评审 |

「已接入」= `docs/.refresh-state.json` 里登记的项目（有 codegraph 索引 + 领航 agent）。

## `hero 刷新` / `hero 刷新 <proj>`：跑确定性层 + 产出漂移草稿

### Step A：跑确定性层（脚本）

执行（`<proj>` 可选）：
```
bash scripts/hero-refresh.sh [<proj>]
```
脚本对每个目标项目：HEAD 未变则跳过；否则重索引 + 导出 evidence（到 `docs/.refresh-work/<proj>/`）+ 抓 vendor docs，并回写 `docs/.refresh-state.json`。

读脚本输出，记下「已刷新」的项目列表（即有变更的项目）。无变更则到此为止，告知用户「全部新鲜，无需评审」。

### Step B：确定性产物提交（低风险，无需评审）

把确定性产物作为**一次** commit 提交（与 agent 改动分离）：
```
git add docs/.refresh-state.json docs/vendor-docs/
git commit -m "chore(hero-refresh): 刷新确定性产物（状态 + vendor docs）"
```

### Step C：领航 agent 漂移检测（逐个有变更的项目）

对每个有变更的项目，读两样东西做比对：
1. 新 evidence pack：`docs/.refresh-work/<proj>/structure.txt`、`entrypoints.txt`、`deps-*`。
2. 现有领航 agent：`agents/<该项目的 agent>.md`（agent 名见状态文件）。

**判定结构性漂移**——只要出现下列任一，即需出草稿：
- evidence 的 entrypoints 里出现 agent ④关键入口**未记录**的真实 Controller / Feign Client / MQ 消费者 / 定时任务类；
- agent ④记录的入口类在 evidence/代码里**已不存在**（删除/改名）；
- structure 顶层包与 agent ③代码地图明显不一致（新增/删除顶层业务包）；
- deps 指纹与 agent ②技术栈明显不一致（换了中间件/框架）。

无结构漂移 → 不出草稿（领域知识第⑥段等语义内容不因结构未变而动），告知该项目「仅索引刷新，agent 无需更新」。

### Step D：生成待评审草稿（绝不动线上 agent）

对有结构漂移的项目，写一份草稿到 `docs/.refresh-drafts/<proj>.md`，含两部分：

1. **漂移摘要**（人读）：新增了哪些入口、删了哪些、包结构/技术栈变化，逐条列。
2. **拟更新的 agent 全文**：以现有 `agents/<agent>.md` 为基底，按 evidence 更新 ③代码地图 / ④关键入口 / ⑤对外契约 / ②技术栈（**只改结构性内容**；①定位、⑥领域知识、⑦工作法保持原样，除非 evidence 直接推翻）。引用的每个类名必须来自 evidence 或代码，不编造。

产出后告知用户：「<proj> 检测到漂移，草稿已写入 docs/.refresh-drafts/<proj>.md，跑 `hero 刷新 评审` 来过。」**不在此覆盖线上 agent。**

## `hero 刷新 评审`：人工 gate（rigid）

对 `docs/.refresh-drafts/` 下每个草稿，逐个执行：

1. **展示**漂移摘要 + 草稿 agent 与线上 `agents/<agent>.md` 的 diff。
2. **反编造验证**（硬门槛，零容忍）：草稿正文引用的每个类/接口/方法，在对应项目代码里 grep 验证真实存在：
   ```
   for c in <草稿引用的类名...>; do
     find <repo_path> -name "$c.java" >/dev/null 2>&1 && echo "OK $c" || echo "MISSING $c"
   done
   ```
   任一 MISSING → 修正草稿再验，不得提交。
3. **⏸ STOP — 等用户确认**：
   - 用户「**确认/通过**」→ 用草稿覆盖线上 `agents/<agent>.md`；若草稿 description「触发词：」那行关键词变了，同步更新 `docs/hero-agent-roster.md` 对应行；删除该草稿；
     ```
     git add agents/<agent>.md docs/hero-agent-roster.md
     git commit -m "refresh(<proj>): 领航 agent 随代码漂移更新"
     ```
   - 用户「**驳回**」→ 删除草稿，不动线上 agent。
   - 用户「**改**」→ 按反馈调整草稿，回到第 1 步。

每个项目的 agent 变更**单独 commit**，始终有人工 gate——这是 rigid 规则，不可跳过自动提交。

## `hero 刷新 状态`

读 `docs/.refresh-state.json` 与各项目 HEAD，呈现：
```
已接入项目：
  ecrm                 上次刷新 2026-06-06  ✓ 无新 commit
  hotel-product-center 上次刷新 2026-06-01  ⚠ 有 3 个新 commit，建议刷新
  owner-biz            从未刷新            ⚠ 待建立基线
待评审草稿：docs/.refresh-drafts/ 下 [N] 份
```

## 关键约定

- **两段式**：确定性层（脚本，自动）vs 评审层（agent 漂移，人工 gate）。脚本绝不碰线上 agent；skill 评审确认后才覆盖。
- **只保鲜、不开荒**：刷新只处理 `docs/.refresh-state.json` 里已接入的项目。新服务首次建索引 + 首次生成 agent 走 `docs/project-agent-cookbook.md`，与本流程解耦。
- **反编造硬门槛**：评审提交前，草稿引用的类必须 grep 零 MISSING（沿用 cookbook 约定）。
- **提交分离**：确定性产物（state + vendor docs）一次 commit；每个 agent 变更各自单独 commit。
- **领域知识不自动刷**：agent 第⑥段（坑/状态机）靠人工经验沉淀，刷新只动结构性内容。

## 与其他资产的关系

- 消费 `scripts/hero-refresh.sh` 及 `scripts/lib/*`（确定性层）。
- 读写 `docs/.refresh-state.json`、`docs/.refresh-work/`、`docs/.refresh-drafts/`、`docs/vendor-docs/`、`agents/hero-java-*`、`docs/hero-agent-roster.md`。
- L1 `config/hooks/hero-refresh-check.sh` 只做提醒，真正刷新/评审都在本 skill。
- 与 `hero-prd-to-java` 正交：那个管「PRD→开发」，这个管「资产保鲜」。
````

- [ ] **Step 2: 校验 frontmatter 合法 + 软链可被发现**

Run:
```bash
head -5 skills/hero-refresh/SKILL.md
ls -la ~/.claude/skills/hero-refresh 2>/dev/null || echo "（未软链，install.sh 会处理；本地可手动 ln -s）"
```
Expected: frontmatter 有合法 `name: hero-refresh` 与 `description:`。

- [ ] **Step 3: Commit**

```bash
git add skills/hero-refresh/SKILL.md
git commit -m "feat(hero-refresh): 编排+漂移检测+评审门控 skill"
```

---

### Task 10: README + 文档收口

**Files:**
- Modify: `README.md`
- Modify: `docs/project-agent-cookbook.md`

- [ ] **Step 1: README 快速开始加 hero 刷新**

在 `README.md` 「启动 PRD 驱动开发流程」一节后，加一小节：

```markdown
### 保鲜团队资产（hero 刷新）

```bash
hero 刷新            # 刷全部已接入项目（codegraph 索引 + 领航 agent + vendor docs）
hero 刷新 <proj>     # 只刷一个
hero 刷新 评审       # 逐个过领航 agent 漂移草稿（人工 gate）
hero 刷新 状态       # 看谁该刷了
```

确定性层（重索引/抓文档）自动跑，领航 agent 变更需人工评审。详见 `skills/hero-refresh/SKILL.md`。
开 Claude 时若某接入项目有新 commit，SessionStart hook 会提醒你刷新。
```

- [ ] **Step 2: cookbook 加「保鲜入口」指引**

在 `docs/project-agent-cookbook.md` 末尾加一节，说明开荒（本手册）与保鲜（hero-refresh）的分工：

```markdown
## 开荒 vs 保鲜

- **本手册（开荒）**：新服务从无到有——首次 `codegraph init` + 首次生成领航 agent + 登记花名册。
- **hero-refresh（保鲜）**：已接入项目随代码漂移而刷新——见 `skills/hero-refresh/SKILL.md`。
  新 agent 生成并登记花名册后，把它加进 `docs/.refresh-state.json` 的 `projects`，即纳入保鲜。
```

- [ ] **Step 3: 跑全量测试 + 收口验证**

Run: `bash tests/hero-refresh/run.sh`
Expected: `ALL TESTS PASSED`。

- [ ] **Step 4: Commit**

```bash
git add README.md docs/project-agent-cookbook.md
git commit -m "docs(hero-refresh): README 入口 + 开荒/保鲜分工说明"
```

---

## 完成标准回查（对照 spec 验证标准）

实现完成后，逐条确认：

1. **幂等**（spec #1）：Task 6 Step 5 已验——二次跑同项目「无新 commit，跳过」。
2. **增量索引**（spec #2）：在 ecrm 加一个 Controller → `bash scripts/hero-refresh.sh ecrm` → `docs/.refresh-work/ecrm/entrypoints.txt` 含新符号。
3. **漂移检测**（spec #3）：承上，`hero 刷新` 对 ecrm 生成 `docs/.refresh-drafts/ecrm.md`，摘要点出新增入口。
4. **反编造**（spec #4）：`hero 刷新 评审` 对草稿 grep 零 MISSING。
5. **评审提交**（spec #5）：确认后线上 agent 被覆盖、单独 commit；关键词变更同步花名册。
6. **vendor docs**（spec #6）：`docs/vendor-docs/` 下生成 3 个 agent 指纹合并去重后的库 md。
7. **范围隔离**（spec #7）：未在状态文件登记的服务不被触碰（`hero 刷新 不存在的proj` 报错退出）。
8. **L1 提醒**（spec #8）：Task 7 已验——有漂移注入提醒、无漂移零输出不阻塞。

> 第 2/3 条建议用一个临时分支在 ecrm 仓库造个假 Controller 验完即弃，别污染真实代码。
