# CLI → Skill 转化计划

## TL;DR

> **目标**: 将 `cli/` 下 13 个工具文档转化为 `skills/hero-<tool>/SKILL.md`，使 Claude 在用户提到这些工具时自动加载对应 skill。
>
> **交付物**: 13 个新 skill 目录，每个含一份 SKILL.md
> - `skills/hero-ast-grep/SKILL.md`
> - `skills/hero-scc/SKILL.md`
> - `skills/hero-pmd/SKILL.md`
> - `skills/hero-slowql/SKILL.md`
> - `skills/hero-jq/SKILL.md`
> - `skills/hero-spotbugs/SKILL.md`
> - `skills/hero-jdk-multiversion/SKILL.md`
> - `skills/hero-sca/SKILL.md`
> - `skills/hero-pg-glimpse/SKILL.md`
> - `skills/hero-maven/SKILL.md`
> - `skills/hero-gradle/SKILL.md`
> - `skills/hero-semgrep/SKILL.md`
> - `skills/hero-codegraph/SKILL.md`
>
> **预估**: Quick（纯 markdown 文件搬运+重格式化）
> **并行执行**: 是 — 3 波
> **关键路径**: Wave 1 (deep docs) → Wave 2 (medium docs) → Wave 3 (验证)

---

## Context

### 原始需求
用户要把 `cli/` 目录下 18 个 CLI 工具的参考文档，转化为可被 Claude Code 自动触发的 skill。

### 访谈结果
- **策略**: 一对一，每个 CLI 工具 → 一个独立 skill
- **跳过**: 4 个 thin 文档 (allure/gitleaks/httpie/codeql) 保留为纯 CLI 参考
- **allure**: 已有独立 skill，不重复
- **格式**: 混合格式 — 中文 frontmatter（触发词）+ 内容体保持 CLI doc 的命令参考风格
- **CLI doc**: 保留不变，不修改、不删除
- **pg_glimpse / jdk-multiversion**: 用户确认全部保留

### Metis 审查要点（已处理）
- 触发机制: description 中写中文触发词
- 范围蔓延: "不发明源文档中不存在的内容"已作为护栏锁定
- 交叉引用: skill 自引用，不交叉引用其他工具
- 验证: frontmatter name=dirname 检查 + install.sh 演练

---

## Work Objectives

### 核心目标
将 13 个 CLI 文档重新格式化为 skill，使 Claude Code 在用户提到 `ast-grep`/`pmd`/`maven` 等工具时自动加载对应 skill。

### 交付物
13 个 `skills/hero-<tool>/SKILL.md` 文件。

### Definition of Done
- [x] 13 个 skill 目录均存在 `SKILL.md`
- [x] 每个 SKILL.md 的 frontmatter `name` 字段 = 目录名
- [x] `install.sh` 演练: 13 个 skill 均出现在 `~/.claude/skills/` 下
- [x] 内容保真: 所有源文档的命令示例、参数表格、团队约定完整保留

### Must Have
- 混合格式: 中文 frontmatter + 命令参考内容体
- `hero-<tool>` 命名，kebab-case
- 不发明源文档中不存在的内容
- 保留源文档中的 hero 绑定（玄成/子长/文远/鹏举/孔明）

### Must NOT Have
- 不对 `cli/*.md` 做任何修改
- 不创建交叉引用（skill 只自引用）
- 不修改 `manifest.yaml`
- 不修改 `cli/README.md`
- 不添加源文档中不存在的"最佳实践"

---

## Verification Strategy

### Test Decision
- **类型**: 纯 markdown 文件生成，无需单元测试
- **验证方式**: bash 脚本校验 + install.sh 演练

### QA Policy
每个波次完成后执行验证脚本:
1. `for d in skills/hero-{tools}/; do name=$(basename "$d"); actual=$(grep '^name:' "$d/SKILL.md" | awk '{print $2}'); [ "$name" = "$actual" ] && echo "✅ $name" || echo "❌ $name vs $actual"; done`
2. `CLAUDE_HOME=/tmp/hero-test bash install.sh && ls /tmp/hero-test/skills/hero-*/SKILL.md | wc -l`

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Deep docs × 8, 全并行):
├── 1. hero-ast-grep     [deep]
├── 2. hero-scc          [deep]
├── 3. hero-pmd          [deep]
├── 4. hero-slowql       [deep]
├── 5. hero-jq           [deep]
├── 6. hero-spotbugs     [deep]
├── 7. hero-jdk-multiversion [deep]
└── 8. hero-sca          [deep]

Wave 2 (Medium docs × 5, 全并行):
├── 9.  hero-pg-glimpse  [medium]
├── 10. hero-maven       [medium]
├── 11. hero-gradle      [medium]
├── 12. hero-semgrep     [medium]
└── 13. hero-codegraph   [medium]

Wave 3 (验证):
├── 14. frontmatter 批量校验
└── 15. install.sh 演练

Final (审查):
├── F1. Plan Compliance Audit (oracle)
├── F2. Content Fidelity Check (unspecified-high)
├── F3. Scope Check (deep)
└── F4. (skip F3 manual QA — markdown files)
```

### Agent Dispatch Summary
- Wave 1: **8** → `quick` × 8
- Wave 2: **5** → `quick` × 5
- Wave 3: **2** → `quick` × 2
- Final: **3** → F1 `oracle`, F2 `unspecified-high`, F3 `deep`

---

## TODOs

> **FORMAT**: 任务标签使用裸数字: `1.`, `2.`, ...
> 每个 skill 的内容来源是 `cli/<tool>.md`，执行者必须读取该文件并忠实转化。

---

- [x] 1. 创建 `skills/hero-ast-grep/SKILL.md`

  **What to do**:
  - 读取 `cli/ast-grep.md` (150行)
  - 创建 `skills/hero-ast-grep/SKILL.md`
  - frontmatter: `name: hero-ast-grep`, `description` 含中文触发词（ast-grep、sg、AST搜索、结构化改写、代码模式匹配）
  - 内容体结构: Overview → 安装 → 常用命令（搜索/改写/高级匹配/YAML规则/调试）→ 文远实战场景 → 和grep对比表
  - 忠实保留所有 bash 代码块、模式语法表、YAML 规则示例、对比表
  - 保留"文远实战场景"的 hero 绑定

  **Must NOT do**:
  - 不添加源文档中不存在的场景
  - 不修改 cli/ast-grep.md

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: 无（纯 markdown 格式转换）

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (与任务 2-8 并行)
  - **Blocks**: 无
  - **Blocked By**: 无

  **References**:
  - `cli/ast-grep.md` — 源文档，完整内容照搬
  - `skills/hero-conventions/SKILL.md` — hero-* 的 frontmatter 格式参考

  **Acceptance Criteria**:
  - [ ] `skills/hero-ast-grep/SKILL.md` 存在
  - [ ] frontmatter `name: hero-ast-grep`
  - [ ] description 含中文触发词
  - [ ] 所有源文档中的 bash 代码块已保留
  - [ ] 模式语法表、YAML 示例、对比表已保留

  **QA Scenarios**:
  ```
  Scenario: frontmatter 规范检查
    Tool: Bash
    Steps:
      1. grep '^name:' skills/hero-ast-grep/SKILL.md → "hero-ast-grep"
      2. grep '^description:' skills/hero-ast-grep/SKILL.md → 非空
    Expected: name 和 description 行存在且正确

  Scenario: 内容保真检查
    Tool: Bash
    Steps:
      1. grep -c '```bash' skills/hero-ast-grep/SKILL.md → >= 源文档的代码块数量 (8+)
      2. grep '模式语法' skills/hero-ast-grep/SKILL.md → 包含模式语法表
    Expected: 所有关键内容已保留
  ```

  **Commit**: NO (批量提交)

---

- [x] 2. 创建 `skills/hero-scc/SKILL.md`

  **What to do**:
  - 读取 `cli/scc.md` (112行)
  - 创建 `skills/hero-scc/SKILL.md`
  - frontmatter: `name: hero-scc`, description 含触发词（scc、代码统计、复杂度分析、COCOMO估算、项目规模）
  - 内容体: Overview → 安装 → 常用（项目总览/复杂度热点/过滤/JSON/diff）→ 文远/孔明实战场景 → 参数速查表
  - 保留输出样例、参数速查表
  - 保留"文远/孔明实战场景"的 hero 绑定

  **Must NOT do**: 同上
  **Recommended Agent Profile**: `quick`
  **Parallelization**: Wave 1，与 1,3-8 并行
  **Blocked By**: 无

  **References**:
  - `cli/scc.md` — 源文档
  - `skills/hero-conventions/SKILL.md` — frontmatter 格式参考

  **Acceptance Criteria**:
  - [ ] 文件存在，name=hero-scc
  - [ ] 输出样例（语言/文件数/行数格式）已保留
  - [ ] 参数速查表（11行表格）已保留

  **QA Scenarios**:
  ```
  Scenario: 参数速查表完整性
    Tool: Bash
    Steps:
      1. grep -c '| `--' skills/hero-scc/SKILL.md → >= 9（9个参数行）
    Expected: 参数速查表完整
  ```

  **Commit**: NO

---

- [x] 3. 创建 `skills/hero-pmd/SKILL.md`

  **What to do**:
  - 读取 `cli/pmd.md` (100行)
  - frontmatter: `name: hero-pmd`, description 含触发词（pmd、静态代码分析、死代码检测、空catch、复杂度、代码审查）
  - 内容体: Overview → 安装（含 Java 17+ 前提）→ 常用（bestpractices/design/errorprone/performance/组合/JSON）→ 玄成实战场景 → 规则集映射表
  - 保留玄成 hero 绑定和审查清单映射（⑥⑧⑨）

  **Recommended Agent Profile**: `quick`
  **Parallelization**: Wave 1，与 1-2,4-8 并行
  **Blocked By**: 无

  **References**: `cli/pmd.md`

  **Acceptance Criteria**:
  - [ ] 5 个 pmd check 命令示例全部保留
  - [ ] 规则集映射表（5行）保留，含审查清单编号
  - [ ] 玄成实战场景 4 个场景保留

  **QA Scenarios**:
  ```
  Scenario: 规则集完整性
    Tool: Bash
    Steps:
      1. grep -c 'category/java/' skills/hero-pmd/SKILL.md → >= 4
      2. grep '玄成' skills/hero-pmd/SKILL.md → 包含 hero 绑定
    Expected: Java 规则集和 hero 绑定完整
  ```

  **Commit**: NO

---

- [x] 4. 创建 `skills/hero-slowql/SKILL.md`

  **What to do**:
  - 读取 `cli/slowql.md` (93行)
  - frontmatter: `name: hero-slowql`, description 含触发词（slowql、SQL分析、MyBatis检查、SQL注入检测、性能检查）
  - 内容体: Overview → 安装 → 常用（Mapper扫描/SQL扫描/阻断/规则列表/报告）→ 分析维度表 → 方言支持 → 子长实战场景
  - 保留 6 维度分析表、14 方言支持、子长 hero 绑定

  **Recommended Agent Profile**: `quick`
  **Parallelization**: Wave 1
  **Blocked By**: 无

  **References**: `cli/slowql.md`

  **Acceptance Criteria**:
  - [ ] 分析维度表（6行）保留
  - [ ] 子长实战场景 4 个保留
  - [ ] 团队约定"新增或修改 Mapper XML 后先跑..."已保留

  **QA Scenarios**:
  ```
  Scenario: 维度表和方言保留
    Tool: Bash
    Steps:
      1. grep -c '| Security\|Performance\|Reliability\|Quality\|Cost\|Compliance' skills/hero-slowql/SKILL.md → >= 6
      2. grep '子长' skills/hero-slowql/SKILL.md → 包含
    Expected: 维度表和 hero 绑定完整
  ```

  **Commit**: NO

---

- [x] 5. 创建 `skills/hero-jq/SKILL.md`

  **What to do**:
  - 读取 `cli/jq.md` (91行)
  - frontmatter: `name: hero-jq`, description 含触发词（jq、JSON处理、API响应提取、JSON格式化、命令行JSON）
  - 内容体: Overview → 安装 → 常用（格式化/提取过滤/截取/构建工具/批量）→ 参数表 → 文远实战场景
  - 保留与 Maven/osv-scanner 组合的管道示例
  - 保留文远 hero 绑定

  **Recommended Agent Profile**: `quick`
  **Parallelization**: Wave 1
  **Blocked By**: 无

  **References**: `cli/jq.md`

  **Acceptance Criteria**:
  - [ ] 参数表（5行）保留
  - [ ] 与 Maven/osv-scanner 配合的命令示例保留
  - [ ] 文远实战场景 3 个保留

  **QA Scenarios**:
  ```
  Scenario: 管道示例完整
    Tool: Bash
    Steps:
      1. grep 'osv-scanner' skills/hero-jq/SKILL.md → 包含
      2. grep 'mvn dependency' skills/hero-jq/SKILL.md → 包含
    Expected: 构建工具配合场景已保留
  ```

  **Commit**: NO

---

- [x] 6. 创建 `skills/hero-spotbugs/SKILL.md`

  **What to do**:
  - 读取 `cli/spotbugs.md` (89行)
  - frontmatter: `name: hero-spotbugs`, description 含触发词（spotbugs、字节码分析、Bug检测、NPE检测、线程安全检查、空指针）
  - 内容体: Overview（与PMD互补说明）→ 安装（Java 17+ 前提）→ 常用（扫描/严重级过滤/输出文件/XML/多模块）→ 玄成实战场景 → 检测模式分类表
  - 保留玄成 hero 绑定、检测模式分类表（5个分类）

  **Recommended Agent Profile**: `quick`
  **Parallelization**: Wave 1
  **Blocked By**: 无

  **References**: `cli/spotbugs.md`

  **Acceptance Criteria**:
  - [ ] 与 PMD 互补说明保留
  - [ ] 检测模式分类表（5行）保留
  - [ ] 玄成工作流"先PMD再SpotBugs再人工审"已保留

  **QA Scenarios**:
  ```
  Scenario: 互补说明和分类表
    Tool: Bash
    Steps:
      1. grep 'PMD' skills/hero-spotbugs/SKILL.md → 包含互补说明
      2. grep -c '| 正确性\|多线程\|坏的实践\|性能\|国际化' skills/hero-spotbugs/SKILL.md → >= 5
    Expected: 分类表完整
  ```

  **Commit**: NO

---

- [x] 7. 创建 `skills/hero-jdk-multiversion/SKILL.md`

  **What to do**:
  - 读取 `cli/jdk-multiversion.md` (82行)
  - frontmatter: `name: hero-jdk-multiversion`, description 含触发词（jdk切换、JAVA_HOME、多JDK、1.8/11/17、sdkman替代、toolchains）
  - 内容体: Overview → 查看已装JDK → zsh切换函数 → Maven toolchains XML → Gradle配置 → 团队约定 → 常见坑
  - 保留完整的 bash jdk() 函数实现
  - 保留 Maven toolchains.xml 完整示例和 Gradle toolchain 配置

  **Recommended Agent Profile**: `quick`
  **Parallelization**: Wave 1
  **Blocked By**: 无

  **References**: `cli/jdk-multiversion.md`

  **Acceptance Criteria**:
  - [ ] jdk() 函数完整保留（含 alias jdk8/11/17）
  - [ ] toolchains.xml 完整保留
  - [ ] 常见坑 3 条全部保留

  **QA Scenarios**:
  ```
  Scenario: 函数和配置完整
    Tool: Bash
    Steps:
      1. grep 'jdk()' skills/hero-jdk-multiversion/SKILL.md → 包含
      2. grep 'toolchains' skills/hero-jdk-multiversion/SKILL.md → 包含
      3. grep 'UnsupportedClassVersionError' skills/hero-jdk-multiversion/SKILL.md → 包含
    Expected: 核心函数和工具链配置完整
  ```

  **Commit**: NO

---

- [x] 8. 创建 `skills/hero-sca/SKILL.md`

  **What to do**:
  - 读取 `cli/sca.md` (80行)
  - frontmatter: `name: hero-sca`, description 含触发词（osv-scanner、SCA、依赖扫描、CVE检测、组件安全、依赖漏洞）
  - 内容体: Overview（选型结论）→ 安装 → 常用（pom扫描/递归/JSON/跳过测试）→ 输出字段表 → 鹏举集成建议 → 4工具对比矩阵
  - 保留选型结论和 4 工具（osv-scanner/trivy/grype/dependency-check）横向对比表
  - 保留鹏举 hero 绑定

  **Recommended Agent Profile**: `quick`
  **Parallelization**: Wave 1
  **Blocked By**: 无

  **References**: `cli/sca.md`

  **Acceptance Criteria**:
  - [ ] 输出字段表（5行）保留
  - [ ] 4 工具对比矩阵（7列×5行）保留
  - [ ] 鹏举集成步骤保留

  **QA Scenarios**:
  ```
  Scenario: 对比矩阵完整
    Tool: Bash
    Steps:
      1. grep 'trivy\|grype\|dependency-check' skills/hero-sca/SKILL.md → 包含
      2. grep -c '| osv-scanner' skills/hero-sca/SKILL.md → >= 1
    Expected: 4 工具对比保留
  ```

  **Commit**: NO

---

- [x] 9. 创建 `skills/hero-pg-glimpse/SKILL.md`

  **What to do**:
  - 读取 `cli/pg-glimpse.md` (77行)
  - frontmatter: `name: hero-pg-glimpse`, description 含触发词（pg_glimpse、PostgreSQL监控、数据库TUI、锁等待、缓存命中率、DBA排障）
  - 内容体: Overview（DBA排障/TUI特点）→ 安装 → 常用（连接/连接字符串/刷新间隔）→ 面板快捷键表（10键）→ 顶部状态栏指标 → 子长实战场景
  - 保留完整面板快捷键表
  - 保留子长 hero 绑定
  - 注明 TUI 工具，agent 无法直接操作，skill 作为参考指导

  **Recommended Agent Profile**: `quick`
  **Parallelization**: Wave 2，与 10-13 并行
  **Blocked By**: 无

  **References**: `cli/pg-glimpse.md`

  **Acceptance Criteria**:
  - [ ] 面板快捷键表（10行）保留
  - [ ] 顶部状态栏指标列表保留
  - [ ] 子长实战场景 4 个保留

  **QA Scenarios**:
  ```
  Scenario: 面板表完整
    Tool: Bash
    Steps:
      1. grep -c '|.*Tab\|w.*\|t.*\|R.*\|v.*\|x.*\|I.*\|S.*\|A.*\|q' skills/hero-pg-glimpse/SKILL.md → >= 10
    Expected: 全部 10 个快捷键保留
  ```

  **Commit**: NO

---

- [x] 10. 创建 `skills/hero-maven/SKILL.md`

  **What to do**:
  - 读取 `cli/maven.md` (63行)
  - frontmatter: `name: hero-maven`, description 含触发词（maven、mvn、构建、依赖管理、settings.xml、私服配置）
  - 内容体: Overview → settings.xml 完整模板（镜像/代理/凭据）→ 常用命令 → 多JDK toolchains 引用 → 约定
  - 保留完整 settings.xml 模板（含 nonProxyHosts）
  - 保留"私服凭据用环境变量"等安全约定

  **Recommended Agent Profile**: `quick`
  **Parallelization**: Wave 2，与 9,11-13 并行
  **Blocked By**: 无

  **References**: `cli/maven.md`

  **Acceptance Criteria**:
  - [ ] settings.xml 模板（30+行 XML）保留
  - [ ] 常用命令 6 条保留
  - [ ] 安全约定（不要提交真实值）已保留

  **QA Scenarios**:
  ```
  Scenario: settings.xml 保留
    Tool: Bash
    Steps:
      1. grep 'mirrorOf' skills/hero-maven/SKILL.md → 包含
      2. grep 'nonProxyHosts' skills/hero-maven/SKILL.md → 包含
    Expected: settings.xml 核心配置完整
  ```

  **Commit**: NO

---

- [x] 11. 创建 `skills/hero-gradle/SKILL.md`

  **What to do**:
  - 读取 `cli/gradle.md` (63行)
  - frontmatter: `name: hero-gradle`, description 含触发词（gradle、gradlew、构建、wrapper、toolchain、Gradle配置）
  - 内容体: Overview → gradle.properties 示例 → 私服镜像配置 → 常用命令 → 多JDK toolchain → 约定
  - 保留 gradle.properties 模板和 Groovy 配置

  **Recommended Agent Profile**: `quick`
  **Parallelization**: Wave 2，与 9-10,12-13 并行
  **Blocked By**: 无

  **References**: `cli/gradle.md`

  **Acceptance Criteria**:
  - [ ] gradle.properties 模板保留
  - [ ] 私服 Groovy 配置保留
  - [ ] 常用命令 8 条保留

  **QA Scenarios**:
  ```
  Scenario: 配置模板完整
    Tool: Bash
    Steps:
      1. grep 'org.gradle.java.home' skills/hero-gradle/SKILL.md → 包含
      2. grep 'toolchain' skills/hero-gradle/SKILL.md → 包含
    Expected: 核心配置保留
  ```

  **Commit**: NO

---

- [x] 12. 创建 `skills/hero-semgrep/SKILL.md`

  **What to do**:
  - 读取 `cli/semgrep.md` (30行)
  - frontmatter: `name: hero-semgrep`, description 含触发词（semgrep、SAST、安全扫描、注入检测、越权检查、OWASP）
  - 内容体: Overview → 安装 → 常用命令 → 团队自定义规则（完整 YAML 示例）
  - 保留鹏举 hero 绑定
  - 保留 MyBatis ${} 注入检测的 YAML 规则完整示例
  - 注明"用法/规则语法以 context7 `/semgrep/semgrep-docs` 为准"

  **Recommended Agent Profile**: `quick`
  **Parallelization**: Wave 2，与 9-11,13 并行
  **Blocked By**: 无

  **References**: `cli/semgrep.md`

  **Acceptance Criteria**:
  - [ ] 4 条常用命令保留
  - [ ] MyBatis ${} 规则 YAML 完整示例保留
  - [ ] context7 引用保留

  **QA Scenarios**:
  ```
  Scenario: YAML 规则保留
    Tool: Bash
    Steps:
      1. grep 'mybatis-dollar-injection' skills/hero-semgrep/SKILL.md → 包含
      2. grep 'owasp-top-ten' skills/hero-semgrep/SKILL.md → 包含
    Expected: 自定义规则和规则集引用保留
  ```

  **Commit**: NO

---

- [x] 13. 创建 `skills/hero-codegraph/SKILL.md`

  **What to do**:
  - 读取 `cli/codegraph.md` (27行)
  - frontmatter: `name: hero-codegraph`, description 含触发词（codegraph、代码图谱、符号查找、调用关系、影响面分析、领航agent）
  - 内容体: Overview（领航 agent + tech-lead 的核心工具）→ 前提（需先建索引）→ 5 个子命令速查表 → 约定
  - 保留完整 5 子命令速查表
  - 保留领航 agent 引用（hero-java-ecrm 等）
  - 保留 `docs/project-agent-cookbook.md` 的引用

  **Recommended Agent Profile**: `quick`
  **Parallelization**: Wave 2，与 9-12 并行
  **Blocked By**: 无

  **References**: `cli/codegraph.md`

  **Acceptance Criteria**:
  - [ ] 5 子命令速查表保留
  - [ ] 建索引前提说明保留
  - [ ] 领航 agent 引用保留

  **QA Scenarios**:
  ```
  Scenario: 速查表保留
    Tool: Bash
    Steps:
      1. grep -c 'query\|files\|callers\|callees\|impact' skills/hero-codegraph/SKILL.md → >= 5
      2. grep 'project-agent-cookbook' skills/hero-codegraph/SKILL.md → 包含
    Expected: 速查表和引用完整
  ```

  **Commit**: NO

---

## Final Verification Wave (after ALL tasks)

> 3 个审查 agent 并行。全部 APPROVE 后呈现给用户。

- [x] F1. **Plan Compliance Audit** — `oracle`
  对每个 "Must Have" 验证实现存在。对每个 "Must NOT Have" 搜索禁止模式。
  **结果**: Must Have [4/4] ✅ | Must NOT Have [5/5] ✅ | Tasks [13/13] | VERDICT: APPROVE

- [x] F2. **Content Fidelity Check** — `unspecified-high`
  逐文件对比 source CLI doc 和生成的 skill，确认:
  - 所有 bash 代码块完整保留（允许格式调整）
  - 所有参数表格完整保留
  - 所有团队约定保留
  - 没有新增源文档中不存在的建议
  **结果**: 13/13 files faithful ✅ | VERDICT: APPROVE

- [x] F3. **Scope Check** — `deep`
  确认:
  - `cli/` 目录未做任何修改（`git diff cli/` 应为空）✅
  - `manifest.yaml` 未修改 ✅
  - `cli/README.md` 未修改 ✅
  - 4 个 thin 文档（allure/gitleaks/httpie/codeql）未生成为 skill ✅
  **结果**: cli/ [UNTOUCHED] | manifest [UNTOUCHED] | thin [SKIPPED] | VERDICT: APPROVE

---

## Commit Strategy

- 所有 13 个 skill 完成后统一提交:
  - Message: `feat(skills): add 13 CLI tool skills from cli/ docs`
  - Files: `skills/hero-*/SKILL.md` (13 files)
  - Pre-commit: 运行 frontmatter 校验脚本

---

## Success Criteria

### Verification Commands

```bash
# 13 个 skill 目录都存在
ls skills/hero-{ast-grep,scc,pmd,slowql,jq,spotbugs,jdk-multiversion,sca,pg-glimpse,maven,gradle,semgrep,codegraph}/SKILL.md | wc -l
# Expected: 13

# frontmatter name=dirname 校验
for d in skills/hero-{ast-grep,scc,pmd,slowql,jq,spotbugs,jdk-multiversion,sca,pg-glimpse,maven,gradle,semgrep,codegraph}/; do
  name=$(basename "$d")
  actual=$(grep '^name:' "$d/SKILL.md" | head -1 | sed 's/name: *//')
  [ "$name" = "$actual" ] && echo "✅ $name" || echo "❌ $name vs $actual"
done

# install.sh 演练
rm -rf /tmp/hero-test && CLAUDE_HOME=/tmp/hero-test bash install.sh
ls /tmp/hero-test/skills/hero-{ast-grep,scc,pmd,slowql,jq,spotbugs,jdk-multiversion,sca,pg-glimpse,maven,gradle,semgrep,codegraph}/SKILL.md | wc -l
# Expected: 13

# cli/ 未被修改
git diff cli/ | wc -l
# Expected: 0

# manifest.yaml 未被修改
git diff manifest.yaml | wc -l
# Expected: 0
```

### Final Checklist

- [ ] 13 个 "Must Have" 全部满足
- [ ] 5 个 "Must NOT Have" 全部无
- [ ] frontmatter 校验通过
- [ ] install.sh 演练通过
- [ ] git diff cli/ 为空
- [ ] F1/F2/F3 全部 APPROVE
