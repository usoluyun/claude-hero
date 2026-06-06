# hero-dispatch 意图分诊入口 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 新增 `hero-dispatch` skill，让用户说 `hero <自由意图>` 即被分诊到 8 条 lane 之一（prd/refresh 委派现有 skill，6 条轻量 lane 走 playbook 骨架）。

**Architecture:** 单 skill + lane catalog（SKILL.md 内的路由表，唯一事实源）+ 6 个薄 playbook 文件（`lanes/*.md`）。dispatch 只做路由不做活：判定 lane → 补齐输入 → STOP 确认 → 交接退场。重型线零改动。两个门控原型（mutate / readonly，性能/安全是 two-phase 组合）集中放 SKILL.md，lane 文件引用，避免重复。

**Tech Stack:** Markdown skill 文件（frontmatter + 正文）；零依赖 bash 结构校验测试（沿用 `tests/hero-refresh` 的 `assert.sh` 风格，bash 3.2 兼容）。

**设计依据:** `docs/superpowers/specs/2026-06-06-hero-dispatch-design.md`

---

## File Structure

| 文件 | 职责 | 动作 |
|---|---|---|
| `skills/hero-dispatch/SKILL.md` | 路由三段式 + lane catalog 表 + 边界判定 + 降级 + 两个门控原型骨架 | Create |
| `skills/hero-dispatch/lanes/bugfix.md` | bug 修复 lane（mutate） | Create |
| `skills/hero-dispatch/lanes/iterate.md` | 小迭代 lane（mutate） | Create |
| `skills/hero-dispatch/lanes/refactor.md` | 小重构 lane（mutate + 表征测试） | Create |
| `skills/hero-dispatch/lanes/research.md` | 需求/变更调研 lane（readonly） | Create |
| `skills/hero-dispatch/lanes/perf.md` | 性能瓶颈优化 lane（two-phase） | Create |
| `skills/hero-dispatch/lanes/security.md` | 信息安全优化 lane（two-phase） | Create |
| `tests/hero-dispatch/assert.sh` | 零依赖断言助手（复制自 hero-refresh） | Create |
| `tests/hero-dispatch/run.sh` | 跑全部 test_*.sh | Create |
| `tests/hero-dispatch/test_structure.sh` | 校验 skill/lane 文件结构与 catalog 一致性 | Create |
| `tests/hero-dispatch/cases.tsv` | 意图→期望 lane 判例 fixture | Create |
| `tests/hero-dispatch/test_cases.sh` | 校验 cases.tsv 每个期望 lane 合法 | Create |
| `README.md` | 加 `hero <自由意图>` 入口 + lane 总表 | Modify |
| `CLAUDE.md`（仓库导航） | 子系统表加 hero-dispatch 行 | Modify |
| `config/CLAUDE.md.example` | 加一行轻提示（仅文档，不强制 ambient） | Modify |

> **manifest 修正**：`manifest.yaml` 的 `skills` 条目是 `mode: link`「目录子项逐个软链」，新增 `skills/hero-dispatch/` 会被 `install.sh` 自动软链——**不需要改 manifest**。Task 5 用 dry-run 验证。

---

## Task 1: 测试脚手架 + dispatch 路由层（SKILL.md）

**Files:**
- Create: `tests/hero-dispatch/assert.sh`
- Create: `tests/hero-dispatch/run.sh`
- Create: `tests/hero-dispatch/test_structure.sh`
- Create: `skills/hero-dispatch/SKILL.md`

- [ ] **Step 1: 复制断言助手与 runner**

`tests/hero-dispatch/assert.sh`（与 `tests/hero-refresh/assert.sh` 内容相同）：

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

assert_ok() {
  local msg="${2:-}"
  if eval "$1"; then ASSERT_PASS=$((ASSERT_PASS+1));
  else ASSERT_FAIL=$((ASSERT_FAIL+1)); echo "  ✗ ${msg:-assert_ok}: [$1] failed"; fi
}

assert_summary() {
  echo "  → $ASSERT_PASS passed, $ASSERT_FAIL failed"
  [[ "$ASSERT_FAIL" -eq 0 ]]
}
```

`tests/hero-dispatch/run.sh`：

```bash
#!/usr/bin/env bash
# 跑 tests/hero-dispatch 下所有 test_*.sh，任一失败则整体失败。
set -u
cd "$(dirname "$0")"
fail=0
for t in test_*.sh; do
  echo "== $t =="
  bash "$t" || fail=1
done
[[ "$fail" -eq 0 ]] && echo "ALL TESTS PASSED" || { echo "SOME TESTS FAILED"; exit 1; }
```

- [ ] **Step 2: 写结构校验测试（先覆盖 SKILL.md，会失败）**

`tests/hero-dispatch/test_structure.sh`：

```bash
#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/assert.sh"
REPO="$(cd "$DIR/../.." && pwd)"
SKILL="$REPO/skills/hero-dispatch/SKILL.md"
LANES="$REPO/skills/hero-dispatch/lanes"

# 1. SKILL.md 存在且 frontmatter name 正确
assert_ok "[ -f '$SKILL' ]" "SKILL.md exists"
name="$(sed -n 's/^name:[[:space:]]*//p' "$SKILL" | head -1)"
assert_eq "hero-dispatch" "$name" "SKILL name"

# 2. catalog 引用的 lanes/*.md 都存在
for ref in $(grep -o 'lanes/[a-z]*\.md' "$SKILL" | sort -u); do
  assert_ok "[ -f '$REPO/skills/hero-dispatch/$ref' ]" "catalog ref $ref exists"
done

# 3. 6 条 lane 文件齐全
for lane in bugfix iterate refactor research perf security; do
  assert_ok "[ -f '$LANES/$lane.md' ]" "lane $lane exists"
done

# 4. 每条 lane frontmatter 必备字段 + archetype 枚举
if [ -d "$LANES" ]; then
  for f in "$LANES"/*.md; do
    [ -f "$f" ] || continue
    base="$(basename "$f")"
    for key in lane archetype intent_keywords required_input; do
      assert_ok "grep -q '^$key:' '$f'" "$base has $key"
    done
    arch="$(sed -n 's/^archetype:[[:space:]]*//p' "$f" | awk '{print $1}' | head -1)"
    assert_ok "[ '$arch' = mutate ] || [ '$arch' = readonly ] || [ '$arch' = two-phase ]" "$base archetype enum: $arch"
  done
fi

assert_summary
```

- [ ] **Step 3: 跑测试，确认失败**

Run: `bash tests/hero-dispatch/run.sh`
Expected: FAIL —「SKILL.md exists」断言失败（文件还没建），最后 `SOME TESTS FAILED`。

- [ ] **Step 4: 写 SKILL.md 路由层**

`skills/hero-dispatch/SKILL.md`：

````markdown
---
name: hero-dispatch
description: hero 意图分诊入口。触发词：hero <自由意图>。听用户一句开发意图，归类到 8 条 lane（prd 大需求 / refresh 保鲜 / bugfix / iterate / refactor / research / perf / security），补齐必要输入后交接给对应 workflow。重型线委派现有 skill，轻量线加载 lanes/ playbook。不接管纯闲聊/纯问答。
---

# hero 意图分诊（hero-dispatch）

**核心价值**：用户不必记工作流，说 `hero <意图>` 即可。分诊器判断该走哪条线、补齐输入、
STOP 确认后交接给对应 workflow，自己退场。**只做路由，不做业务**。

## 触发词

`hero <自由意图>`，例：`hero 修一下登录报错` / `hero 这个接口太慢` / `hero 评估下加 X 影响多大`。
老触发词 `hero 开发工作流 <URL>` / `hero 刷新` 仍直达对应 skill，不必绕本入口。

## lane catalog（路由表，唯一事实源）

| Lane | 触发关键词（意图信号） | 必需输入 | 交接目标 |
|---|---|---|---|
| prd-大需求 | PRD、飞书链接、新功能、大需求、开发工作流 | 飞书 URL | 委派 `hero-prd-to-java` |
| refresh-保鲜 | 刷新、保鲜、索引漂移、领航过期 | proj（可选） | 委派 `hero-refresh` |
| bugfix | 修bug、报错、异常、复现、修一下、不对/不生效 | 现象/复现路径 | `lanes/bugfix.md` |
| iterate | 小迭代、加个字段、改个逻辑、小改动、加个开关 | 改动目标 | `lanes/iterate.md` |
| refactor | 重构、抽方法、改命名、拆类、消除重复 | 重构对象 | `lanes/refactor.md` |
| research | 调研、评估、能不能、影响面、怎么改、要不要 | 问题/范围 | `lanes/research.md` |
| perf | 慢、性能、瓶颈、优化耗时、压测、超时 | 慢的位置/指标 | `lanes/perf.md` |
| security | 安全、越权、注入、漏洞、CVE、敏感信息 | 审计范围 | `lanes/security.md` |

## 分诊三段式

1. **关键词命中**：意图文本扫上表关键词，单一命中 → 候选该 lane。
2. **语义兜底**：无命中或多义时，按意图**语义**归类（非纯字面）。
3. **不确定就 STOP 追问**：候选 ≥2 且分不清 → 列最可能的 2-3 条让用户选，不替用户拍板。

## 边界判定（轻量 vs 重型分流）

- 命中「PRD / 飞书 URL / 大需求 / 多服务」→ **prd 重型线**；
- 否则一律先归**轻量线**——「修个 bug」不会被误升级成 8 步流水线；
- 用户可在确认 STOP 时手动改判（「这其实是大需求，走 PRD 线」）。

## 必需输入缺失 → 追问

任何 lane 缺关键输入都先 STOP 补齐，不带空输入交接：prd 缺飞书 URL → 追问 URL；
bugfix 缺复现信息 → 追问现象/路径；以此类推。

## 降级（避免过度拦截）

8 条都不沾边（纯闲聊 / 纯问答）→ **不接管**，告知「这不像开发任务，我直接答」，回落普通 Claude。

## 交接

- **重型线**：用 `Skill` 工具调 `hero-prd-to-java` 或 `hero-refresh`，把已补齐的输入传过去。
- **轻量线**：读对应 `lanes/<name>.md`，按其 frontmatter 与「门控骨架」执行。

---

## 门控骨架（两个原型，lane 文件引用本节）

### Archetype A：mutate（改代码线）

```
1. 勘察定位（存量服务: 领航 agent 摸地图 + codegraph 圈影响面）
   ⏸ STOP ①  「问题/改动定位 + 方案」确认 ── 继续 / 改方向 / 止步
2. RED   ← hero-java-test-engineer 先写失败测试（test-driven-development 强制）
3. GREEN ← hero-java-backend-developer / data-engineer 实现到测试通过
4. REFACTOR ← 测试保护下清理
   ⏸ STOP ②  「改动 + 测试结果 + 影响面复核」报告 ── 收 / 返工
```

测试先行，由 `superpowers:test-driven-development` 强制，不是 test-after。

### Archetype B：readonly（只读出报告线）

```
1. 调查（领航 agent 摸地图 + codegraph，只读，不碰代码）
2. 分析（影响面 / 可行性 / 风险 / 工作量）
   ⏸ STOP  「结论 + 选项 + 建议」报告 ── 采纳哪个 / 追问
```

无 RED-GREEN，不产代码。产物常作为后续 prd 线 / mutate 线的输入。

### two-phase：性能 & 安全（先只读诊断，再可选改）

= B 段诊断 → STOP「清单」→ 按需转 A 段（TDD-first，基准/复现测试当 RED）。两段都复用 A/B。
````

- [ ] **Step 5: 跑测试，确认 SKILL 部分通过**

Run: `bash tests/hero-dispatch/run.sh`
Expected: `test_structure.sh` 中「SKILL.md exists」「SKILL name」断言通过；「catalog ref ...md exists」
与「lane X exists」「has lane/archetype/...」仍失败（lane 文件未建，catalog 引用的就是这批文件）。
整体仍 `SOME TESTS FAILED`——符合预期，Task 2/3 补齐 lane 文件后转绿。

- [ ] **Step 6: Commit**

```bash
git add tests/hero-dispatch/assert.sh tests/hero-dispatch/run.sh \
        tests/hero-dispatch/test_structure.sh skills/hero-dispatch/SKILL.md
git commit -m "feat(hero-dispatch): 路由层 SKILL + 结构校验测试脚手架"
```

---

## Task 2: 3 条 mutate lane（bugfix / iterate / refactor）

**Files:**
- Create: `skills/hero-dispatch/lanes/bugfix.md`
- Create: `skills/hero-dispatch/lanes/iterate.md`
- Create: `skills/hero-dispatch/lanes/refactor.md`
- Test: `tests/hero-dispatch/test_structure.sh`（已存在，本任务让它更接近全绿）

- [ ] **Step 1: 写 bugfix.md**

```markdown
---
lane: bugfix
archetype: mutate
intent_keywords: [修bug, 报错, 异常, 复现, 修一下, 不对, 不生效]
required_input: 现象或复现路径
---

# bugfix lane（修 bug · mutate）

## 触发画像
用户报告某处行为错误/抛异常/不生效，目标是定位并修复单个缺陷（非新增功能）。

## 复用的 superpowers skill
- `superpowers:systematic-debugging`（强制：先稳定复现，禁止未复现就改）
- `superpowers:test-driven-development`（RED 用一个能复现 bug 的失败测试）

## 参与的角色 agent
- `hero-java-backend-developer` / `hero-java-data-engineer`（按缺陷在业务层还是数据层）
- `hero-java-test-engineer`（写复现测试 + 回归测试）

## 领航 agent 介入点
改存量服务时，先调对应 `hero-java-<proj>` 领航 agent 摸地图 + `codegraph` 圈影响面，
定位缺陷落点与受影响 caller（复用 `docs/hero-agent-roster.md` 花名册）。

## 门控骨架
见 `SKILL.md` 的 **Archetype A（mutate）**。特例：STOP① 之前必须先用 systematic-debugging
稳定复现，复现不出来不进入修复。

## 交接产物
修复代码 + 复现/回归测试 + 影响面复核结论。
```

- [ ] **Step 2: 写 iterate.md**

```markdown
---
lane: iterate
archetype: mutate
intent_keywords: [小迭代, 加个字段, 改个逻辑, 小改动, 加个开关, 微调]
required_input: 改动目标
---

# iterate lane（小迭代 · mutate）

## 触发画像
在既有功能上做小幅增量（加字段/加开关/改分支逻辑），范围清晰、不涉及跨服务重设计。

## 复用的 superpowers skill
- `superpowers:test-driven-development`（强制先测后写）
- `superpowers:brainstorming`（仅当改动目标模糊时，先澄清再动手）

## 参与的角色 agent
- `hero-java-backend-developer` / `hero-java-data-engineer`
- `hero-java-test-engineer`

## 领航 agent 介入点
改存量服务时先调 `hero-java-<proj>` 领航 agent 确认改动该落在哪个类/包、影响哪些 caller。

## 门控骨架
见 `SKILL.md` 的 **Archetype A（mutate）**。无额外特例。

## 交接产物
增量代码 + 覆盖新行为的测试 + 影响面复核结论。
```

- [ ] **Step 3: 写 refactor.md**

```markdown
---
lane: refactor
archetype: mutate
intent_keywords: [重构, 抽方法, 改命名, 拆类, 消除重复, 整理代码]
required_input: 重构对象
---

# refactor lane（小重构 · mutate）

## 触发画像
不改变外部行为、只改善内部结构（抽取/改名/拆分/去重），范围限定在指定对象内。

## 复用的 superpowers skill
- `superpowers:test-driven-development`（重构必须在测试保护下进行）

## 参与的角色 agent
- `hero-java-backend-developer`（执行重构）
- `hero-java-test-engineer`（补表征测试）

## 领航 agent 介入点
改存量服务时先调 `hero-java-<proj>` 领航 agent 圈出重构对象的全部 caller，防止漏改调用方。

## 门控骨架
见 `SKILL.md` 的 **Archetype A（mutate）**。**特例**：REFACTOR 前提是已有测试覆盖；
若重构对象无测试，STOP① 后先补**表征测试（characterization test）**锁住现有行为，再重构。

## 交接产物
重构后代码 + 表征/回归测试（行为不变证明）+ 影响面复核结论。
```

- [ ] **Step 4: 跑测试，确认 mutate 三条通过**

Run: `bash tests/hero-dispatch/run.sh`
Expected: `test_structure.sh` 中 bugfix/iterate/refactor 的「exists」「has lane/archetype/intent_keywords/required_input」「archetype enum」全部通过；research/perf/security 仍失败（Task 3 补）。

- [ ] **Step 5: Commit**

```bash
git add skills/hero-dispatch/lanes/bugfix.md skills/hero-dispatch/lanes/iterate.md skills/hero-dispatch/lanes/refactor.md
git commit -m "feat(hero-dispatch): 3 条 mutate lane（bugfix/iterate/refactor）骨架"
```

---

## Task 3: research（readonly）+ perf/security（two-phase）

**Files:**
- Create: `skills/hero-dispatch/lanes/research.md`
- Create: `skills/hero-dispatch/lanes/perf.md`
- Create: `skills/hero-dispatch/lanes/security.md`
- Test: `tests/hero-dispatch/test_structure.sh`（本任务后应全绿）

- [ ] **Step 1: 写 research.md**

```markdown
---
lane: research
archetype: readonly
intent_keywords: [调研, 评估, 能不能, 影响面, 怎么改, 要不要]
required_input: 问题或范围
---

# research lane（需求/变更调研 · readonly）

## 触发画像
用户要在动手前搞清「能不能做 / 影响多大 / 怎么改 / 要不要做」，产出是结论与选项，不改代码。

## 复用的 superpowers skill
- `superpowers:brainstorming`（探索问题空间与备选方案）

## 参与的角色 agent
- `hero-java-<proj>` 领航 agent（摸地图、圈影响面，只读）
- `hero-java-tech-lead`（可行性/风险/工作量评估，只读）

## 领航 agent 介入点
核心环节即领航 agent 摸地图 + `codegraph impact` 圈影响面（复用花名册）。

## 门控骨架
见 `SKILL.md` 的 **Archetype B（readonly）**。无 RED-GREEN，不产代码。
产物常作为后续走 prd 线或 mutate 线的输入。

## 交接产物
调研结论文档（现状 + 可行性 + 影响面 + 风险 + 工作量 + 备选方案与建议）。
```

- [ ] **Step 2: 写 perf.md**

```markdown
---
lane: perf
archetype: two-phase
intent_keywords: [慢, 性能, 瓶颈, 优化耗时, 压测, 超时]
required_input: 慢的位置或指标
---

# perf lane（性能瓶颈与优化 · two-phase）

## 触发画像
某处响应慢/超时/资源占用高，需先诊断瓶颈、再按需优化。

## 复用的 superpowers skill
- `superpowers:systematic-debugging`（诊断段：用证据定位瓶颈，不臆测）
- `superpowers:test-driven-development`（优化段：基准测试当 RED，优化到达标）

## 参与的角色 agent
- 诊断：`hero-java-<proj>` 领航 agent + `hero-java-data-engineer`（慢查询/执行计划）
- 优化：`hero-java-backend-developer` / `hero-java-data-engineer` + `hero-java-test-engineer`

## 领航 agent 介入点
诊断段调领航 agent 摸地图定位热点路径与受影响调用链。

## 门控骨架
见 `SKILL.md` 的 **two-phase**：[B]诊断瓶颈 ─⏸STOP「瓶颈 + 优化项」─→ [A]TDD-first 优化
（以基准测试为 RED，优化后基准达标为 GREEN）。用户挑要不要优化、优化哪些。

## 交接产物
诊断段：瓶颈清单 + 优化项建议；优化段（若执行）：优化代码 + 基准对比 + 影响面复核。
```

- [ ] **Step 3: 写 security.md**

```markdown
---
lane: security
archetype: two-phase
intent_keywords: [安全, 越权, 注入, 漏洞, CVE, 敏感信息]
required_input: 审计范围
---

# security lane（信息安全问题优化 · two-phase）

## 触发画像
怀疑/排查安全风险（越权、注入、漏洞依赖、敏感信息泄漏），先审计、再按需修复。

## 复用的 superpowers skill
- `superpowers:test-driven-development`（修复段：漏洞复现测试当 RED，修到测试转绿）

## 参与的角色 agent
- 审计：`hero-java-security-auditor`（只读，产风险清单）
- 修复：`hero-java-backend-developer` / `hero-java-data-engineer` + `hero-java-test-engineer`

## 领航 agent 介入点
审计/修复涉及存量服务时，调 `hero-java-<proj>` 领航 agent 圈出受影响入口与调用方。

## 门控骨架
见 `SKILL.md` 的 **two-phase**：[B]审计（security-auditor 只读）─⏸STOP「风险清单」─→
[A]TDD-first 修复（漏洞复现测试当 RED）。用户挑修哪些。仅授权的内部防御性审查。

## 交接产物
审计段：分级风险清单（攻击场景 + 修复建议）；修复段（若执行）：修复代码 + 复现测试 + 影响面复核。
```

- [ ] **Step 4: 跑测试，确认结构全绿**

Run: `bash tests/hero-dispatch/run.sh`
Expected: `test_structure.sh` 全部断言通过（6 条 lane 齐全、frontmatter 字段全、archetype 枚举全合法、catalog 引用全存在）。`test_structure.sh` 末尾 `→ N passed, 0 failed`。

- [ ] **Step 5: Commit**

```bash
git add skills/hero-dispatch/lanes/research.md skills/hero-dispatch/lanes/perf.md skills/hero-dispatch/lanes/security.md
git commit -m "feat(hero-dispatch): research/perf/security lane 骨架（readonly + two-phase）"
```

---

## Task 4: 意图判例 fixture + 校验测试

**Files:**
- Create: `tests/hero-dispatch/cases.tsv`
- Create: `tests/hero-dispatch/test_cases.sh`

- [ ] **Step 1: 写校验测试（先失败）**

`tests/hero-dispatch/test_cases.sh`：

```bash
#!/usr/bin/env bash
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/assert.sh"
CASES="$DIR/cases.tsv"

assert_ok "[ -f '$CASES' ]" "cases.tsv exists"

# 合法期望值：6 条 lane + 两条重型线 + 不接管
valid="bugfix iterate refactor research perf security prd refresh none"

if [ -f "$CASES" ]; then
  ln=0
  while IFS=$'\t' read -r intent expected || [ -n "$intent" ]; do
    ln=$((ln+1))
    case "$intent" in ''|'#'*) continue;; esac   # 跳过空行/注释
    found=0
    for v in $valid; do [ "$expected" = "$v" ] && found=1; done
    assert_ok "[ '$found' = 1 ]" "line $ln expected '$expected' is valid lane"
    assert_ok "[ -n '$intent' ]" "line $ln intent non-empty"
  done < "$CASES"
fi

assert_summary
```

- [ ] **Step 2: 跑测试，确认失败**

Run: `bash tests/hero-dispatch/test_cases.sh`
Expected: FAIL —「cases.tsv exists」断言失败。

- [ ] **Step 3: 写 cases.tsv**

`tests/hero-dispatch/cases.tsv`（制表符分隔，第一列意图、第二列期望 lane）：

```
# intent<TAB>expected_lane  —— 分诊判例回归 fixture
修一下登录报错	bugfix
这个接口太慢了，超时	perf
把 PRD https://feishu.cn/docx/xxx 做了	prd
给订单加个备注字段	iterate
这段重复代码抽一下	refactor
评估下加这个功能影响多大	research
查下有没有越权风险	security
刷新一下 ecrm 索引	refresh
今天天气怎么样	none
```

> 注意：列间是真实 Tab 字符，不是空格。写入后用 `cat -A tests/hero-dispatch/cases.tsv` 确认行尾有 `^I`（Tab）。

- [ ] **Step 4: 跑测试，确认通过**

Run: `bash tests/hero-dispatch/run.sh`
Expected: `test_cases.sh` 全部断言通过；`test_structure.sh` 仍全绿；末行 `ALL TESTS PASSED`。

- [ ] **Step 5: Commit**

```bash
git add tests/hero-dispatch/cases.tsv tests/hero-dispatch/test_cases.sh
git commit -m "test(hero-dispatch): 意图→lane 判例 fixture + 校验"
```

---

## Task 5: 接线（README + 仓库 CLAUDE.md + CLAUDE.md.example）+ 安装验证

**Files:**
- Modify: `README.md`
- Modify: `CLAUDE.md`
- Modify: `config/CLAUDE.md.example`

- [ ] **Step 1: README 加 hero 入口段**

在 `README.md` 的「### 启动 PRD 驱动开发流程」**之前**，新增一段（成为推荐总入口）：

```markdown
### 一句话入口（hero 意图分诊）

不想记具体工作流？直接说意图，分诊器帮你选线：

\```bash
hero 修一下登录报错          # → bugfix 线
hero 这个接口太慢            # → perf 线（先诊断后优化）
hero 评估下加 X 影响多大      # → research 调研线（只读）
hero 开发工作流 https://...   # → PRD 重型线（仍可直达）
\```

分诊器把意图归类到 8 条 lane（prd / refresh / bugfix / iterate / refactor / research /
perf / security），补齐输入、确认后交接给对应 workflow。详见 `skills/hero-dispatch/SKILL.md`。
```

（注：上面代码块内的 `\``` ` 在实际文件里写成三反引号，此处转义仅为计划可读。）

- [ ] **Step 2: 仓库 CLAUDE.md 子系统表加行**

在 `CLAUDE.md`「## 两大核心子系统」的表格中，于表体最前面新增一行（并把标题相应理解为「核心子系统」）：

```markdown
| **意图分诊（hero-dispatch）** | `hero <自由意图>` | 听一句开发意图 → 归类到 8 条 lane → 补输入 → 确认 → 交接对应 workflow。轻量线走 `lanes/*.md` playbook（mutate/readonly/two-phase 门控 + TDD-first），重型线委派现有 skill | [`skills/hero-dispatch/SKILL.md`](./skills/hero-dispatch/SKILL.md)；设计 [`docs/superpowers/specs/2026-06-06-hero-dispatch-design.md`](./docs/superpowers/specs/2026-06-06-hero-dispatch-design.md) |
```

同时在「## 资产目录速查」的 `skills/` 行补上 `hero-dispatch`（意图分诊入口）。

- [ ] **Step 3: config/CLAUDE.md.example 加轻提示**

在 `config/CLAUDE.md.example` 中找到团队约定/触发词相关章节，追加一行（仅文档说明，不写任何 ambient hook）：

```markdown
- **hero 入口**：开发类意图（修 bug / 小迭代 / 重构 / 调研 / 性能 / 安全 / PRD）可直接说
  `hero <意图>`，由 hero-dispatch 分诊到对应工作流；也可继续用各 skill 的原触发词直达。
```

> 若 `config/CLAUDE.md.example` 没有合适的现成章节，则在文件末尾新增一个 `## hero 入口` 小节放这行。

- [ ] **Step 4: dry-run 验证 install 能软链新 skill（无需改 manifest）**

Run:
```bash
CLAUDE_HOME=/tmp/hero-dispatch-dryrun bash install.sh
ls -l /tmp/hero-dispatch-dryrun/skills/hero-dispatch
```
Expected: `/tmp/hero-dispatch-dryrun/skills/hero-dispatch` 是指向本仓库 `skills/hero-dispatch` 的软链（`->` 指向仓库路径）。证明目录子项软链已自动覆盖新 skill，manifest 无需改动。

清理：
```bash
rm -rf /tmp/hero-dispatch-dryrun
```

- [ ] **Step 5: 全量回归 + Commit**

Run: `bash tests/hero-dispatch/run.sh`
Expected: `ALL TESTS PASSED`。

```bash
git add README.md CLAUDE.md config/CLAUDE.md.example
git commit -m "docs(hero-dispatch): README/CLAUDE 入口登记 + 团队基线轻提示"
```

---

## 完成定义（DoD）

- `bash tests/hero-dispatch/run.sh` 全绿（结构校验 + 判例校验）。
- `skills/hero-dispatch/` 含 SKILL.md + 6 个 lane playbook，frontmatter 合法、catalog 自洽。
- `CLAUDE_HOME=/tmp/... bash install.sh` 能把 hero-dispatch 软链进去（manifest 未改）。
- README / 仓库 CLAUDE.md / CLAUDE.md.example 已登记 hero 入口。
- 范围红线遵守：未细化 6 条 lane 的完整门控正文、未返工 prd 线 Step4→Step5、未做 ambient 分诊。
