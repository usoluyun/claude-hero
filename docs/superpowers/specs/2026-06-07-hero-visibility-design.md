# hero 露出机制设计

> 日期：2026-06-07
> 类型：设计 spec
> 关联：意图分诊 [`2026-06-06-hero-dispatch-design.md`](./2026-06-06-hero-dispatch-design.md)

## 目标

让用户在**任何 hero skill 触发、任何 hero agent 运作**时，都看到统一的 `🦸 hero ▸ …`
单行标记，从而**感知 hero 体系正在接管**，与本地裸 Claude / 用户自有机制区分开。

现状：hero-dispatch 交接后即"隐身"，子 agent 干活时用户看到的与裸 Claude 无异，hero 体系
全程无露出。本设计补上这层显式露出。

## 非目标（YAGNI / 本次不做）

- 不做 statusline 常驻指示、不做块状 banner、不做 hook 兜底（已选纯文案约定）。
- 不改 superpowers 自身的 skill（只在我方仓库的 skill/agent 落地）。
- token 固定 `🦸 hero ▸`，不做可配置主题 / 多套皮肤。

## 核心约束

1. **标记是模型输出的文本**。没有 harness 钩子能替它打出"现在是 bugfix lane"这类上下文信息，
   因此标记必然写进 skill/agent 提示词、靠模型遵守。可靠性边界：模型可能偶尔漏打——接受，
   靠结构测试保证"指令存在"，不保证"每次运行都打"。
2. **子 agent 不自动加载 skill 内容**。`hero-java-*` agent 的露出指令必须**内联进 agent 文件**，
   不能只引用 hero-conventions（那个 skill 在子 agent 上下文里没加载）。
3. **子 agent 输出对用户主线是折叠的**。用户主线看的是编排方主 agent 的输出，因此
   "agent 接手"标记的**主路径是编排方在派单时打**，子 agent 自打仅作兜底。

## 标记规范（唯一事实源 = hero-conventions）

固定前缀 token：`🦸 hero ▸`

四个时机模板：

| 时机 | 模板 | 示例 |
|---|---|---|
| skill 激活 | `🦸 hero ▸ <skill/lane> · <加载的纪律/门控>` | `🦸 hero ▸ bugfix lane · systematic-debugging + TDD(mutate 门控)` |
| agent 接手 | `🦸 hero ▸ <agent> 接手 · <一句职责>` | `🦸 hero ▸ hero-java-backend-developer 接手 · Controller/Service，TDD-first` |
| 门控 STOP | `🦸 hero ▸ STOP<n> <门控> · <等什么>` | `🦸 hero ▸ STOP① 勘察完成 · 请确认方案再动手` |
| 任务收尾 | `🦸 hero ▸ <lane/workflow> 完成 · 已交付，退出 hero 体系` | `🦸 hero ▸ bugfix lane 完成 · 已交付，退出 hero 体系` |

## agent 接手的双保险分工

| 角色 | 何时打 | 可见性 | 落点 |
|---|---|---|---|
| 编排方（dispatch 子 agent 的 lane/workflow） | 派单时 | 主线可见（**主路径**） | 派子 agent 的 lane playbook / hero-prd-to-java workflow 描述里 |
| 子 agent 自身 | 自己输出顶部 | 展开看子 agent 工作时可见（**兜底**） | 各 `hero-java-*.md` agent 文件顶部内联 |

## 落点清单（改哪些文件、加什么）

| 文件 | 改动 |
|---|---|
| `skills/hero-conventions/SKILL.md` | 从示例占位升级；新增 `## hero 露出规范` 段：token + 四模板 + 双保险分工 + 谁在何时打。维护者与主 agent 的事实源。 |
| `skills/hero-dispatch/SKILL.md` | 加"运作时按露出规范打标记"指令；在分诊三段式流程标出「分诊」「交接」两个打点；说明派子 agent 时由本编排方打"agent 接手"。 |
| `skills/hero-dispatch/lanes/*.md`（6 条） | 在各 lane 的门控 STOP 点与收尾处标出打标记时机；派子 agent 的 lane 在派单处打"agent 接手"。 |
| `skills/hero-refresh/SKILL.md` | 加露出指令（skill 激活 / 评审 gate STOP / 收尾）。 |
| `skills/hero-prd-to-java/SKILL.md` | 加露出指令；各 STOP 门控 + 派子 agent 处打标记。 |
| `agents/hero-java-*.md`（9 个） | 每个顶部内联一行自报家门指令：接手时先打 `🦸 hero ▸ <本 agent> 接手 · <职责>`。 |
| `tests/hero-visibility/`（新增） | 结构测试，见下。 |

## 测试（防漂移）

沿用现有 `tests/hero-dispatch/` 的 bash 3.2 风格（assert/run/test_structure），新增
`tests/hero-visibility/`：

- 断言 `hero-conventions/SKILL.md` 含 `## hero 露出规范` 段，且含 token `🦸 hero ▸`。
- 断言每个 `agents/hero-java-*.md` 含 `🦸 hero ▸` 内联指令。
- 断言 `hero-dispatch` / `hero-refresh` / `hero-prd-to-java` 三个 SKILL.md 各含露出指令
  （含 token `🦸 hero ▸`）。
- 断言 token 字面一致（防止有人写成 `hero >` / `hero:` 等变体）。

测试只校验"指令文本存在与一致"，不校验"运行时是否真打"（后者非确定性，超出脚本能力）。

## 验收标准

- 4 个 skill、9 个 agent、hero-conventions 全部含统一 token 的露出指令，测试全绿。
- 人工抽查一条轻量 lane（如 bugfix）走查：skill 激活、STOP、收尾三处肉眼可见 `🦸 hero ▸` 标记。
- `CLAUDE_HOME=/tmp/xxx bash install.sh` 演练通过（新增 tests 目录不影响软链）。

## 范围收敛

本次只交付**露出机制本身**（规范 + 各文件指令 + 测试）。不顺带细化 6 条 lane 的门控正文
（那是另一条独立 backlog，见 hero-dispatch build-log 第 7 节）。
