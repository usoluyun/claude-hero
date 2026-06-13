# 🦸 hero ▸ 露出规范解读

> **权威源**：[`skills/hero-conventions/SKILL.md`](../../skills/hero-conventions/SKILL.md)
> **范围**：本文解读 `🦸 hero ▸` 标记规范的 4 时机 + 双保险机制 + 英雄名映射，不复制 SKILL.md 全文。

## 一句话

露出规范的核心目的只有一个：**让用户感知 hero 体系正在接管当前对话**，区别于裸 Claude 或用户自有机制。每一条 `🦸 hero ▸` 开头的行都是 hero 体系在说："这段我来负责"。

## 固定 token

```
🦸 hero ▸
```

这个前缀**一字不改**。它是所有 hero 标记的锚点，便于结构测试用 `grep` 或 AST 精确卡死，防 token 漂移。后面接一句话，单独成行，不嵌入段落中间。

## 四个时机

hero 体系在 4 个关键时刻打出标记。每个时机一个模板 + 一个示例，说明它何时出现。

### 1. 技能 / 通道激活

hero dispatch 选定了某条 lane 或加载了某个 skill 时打出。用户看到这一行就知道进入了哪个工作流。

```
🦸 hero ▸ bugfix lane · systematic-debugging 已加载
```

### 2. Agent 接手

编排方把任务派给某个 agent 时打出。带英雄名（花名）和 agent 技术名，前者是记忆点，后者供排查时不歧义定位。

```
🦸 hero ▸ 文远（hero-java-backend-developer）接手 · 实现代码
```

### 3. 门控 STOP

需要用户决策的检查点。`STOP` 后跟编号（多门控线编号，单门控线不编号），然后是门控名称和等什么。

```
🦸 hero ▸ STOP① 方案确认 · 继续 / 改方向 / 止步
```

### 4. 任务收尾

lane 或 workflow 结束时打出，明确告诉用户 hero 流程结束，回归普通 Claude。

```
🦸 hero ▸ bugfix lane 完成 · 已交付，退出 hero 体系
```

## 双保险机制

子 agent 的输出对用户主线是**折叠的**。如果在主线只看得到"孔明派文远去修代码了"，展开子 agent 的输出却找不到任何标记，用户就不知道谁在干活。

因此设计了两层打出：

- **编排方**（dispatch 子 agent 的 lane/workflow）在主线打出 `🦸 hero ▸ X 接手` —— 主路径，用户主线可见。
- **子 agent** 在自己输出顶部也打一行自报家门 —— 兜底，用户展开子 agent 输出时可见。

```
主线对话
│
│  🦸 hero ▸ 文远（hero-java-backend-developer）接手 · 实现代码    ← 编排方打（主线可见）
│
├── 文远子 agent 开始干活（输出对主线折叠）
│   │
│   │  🦸 hero ▸ 文远（hero-java-backend-developer）我开始实现    ← 子 agent 自己顶部打（兜底）
│   ...
│
└── 文远干完，结果返回主线
```

两层互为补充：主线那行告诉用户谁在干活，子 agent 顶部那行保证展开后不丢上下文。

## 英雄名映射

英雄名（花名）取自中国历史人物，纯装饰/记忆点。不做"用英雄名调用"的 API 路由，调用始终走 agent 技术名。花名在露出标记中展示，agent 技术名在排查时供精确定位。

| Agent | 花名 | 取名理由 |
|---|---|---|
| `hero-java-tech-lead` | 孔明 | 组建团队、拆任务派活——天生编排者 |
| `hero-java-backend-developer` | 文远 | 亲手造装备/写实现，工程师本色 |
| `hero-java-data-engineer` | 子长 | 由数据而生、擅综合 |
| `hero-java-test-engineer` | 希仁 | 蜘蛛感应提前预警=测试在出事前抓 bug |
| `hero-java-code-reviewer` | 玄成 | 推演千万结局找隐患 |
| `hero-java-security-auditor` | 鹏举 | 阿斯加德守门人、洞察一切入侵 |
| `hero-java-ecrm` | 子文 | 把不按常理的怪装备玩明白 |
| `hero-java-hotel-product-center` | 郑和 | 带队探索定位；产品中心枢纽 |
| `hero-java-owner-biz` | 霞客 | 空中侦察大范围地形=摸地图 |

## 完整生命周期示例

以下是一条 bugfix lane 从触发到收尾的完整对话，4 个时机各出现至少一次。

```
用户: hero 修一下登录报错

🦸 hero ▸ dispatch → bugfix                             ← 时机1: lane 激活

🦸 hero ▸ bugfix lane · systematic-debugging 已加载     ← 时机1: skill 加载

🦸 hero ▸ 霞客（hero-java-owner-biz）接手 · 摸地图      ← 时机2: agent 接手
[...霞客输出...]

⏸ STOP ①   定位方案   确认                               ← 时机3: 门控 STOP
> 缺陷在 UserService.login() 第 45 行，NPE
> 影响面：3 个 caller

用户: 继续

🦸 hero ▸ RED · 希仁（hero-java-test-engineer）接手 · 写复现测试
> 测试 login_returns_400_when_user_inactive ... FAIL ✓

🦸 hero ▸ GREEN · 文远（hero-java-backend-developer）接手 · 修代码
> 测试 login_returns_400_when_user_inactive ... PASS ✓

🦸 hero ▸ REFACTOR · 文远清理

⏸ STOP ②   改动+测试结果                                 ← 时机3: 门控 STOP
> 修改了 UserService.java 第 45 行，测试通过
> 回归测试 8/8 通过

用户: 收

🦸 hero ▸ bugfix lane 完成 · 已交付，退出 hero 体系      ← 时机4: 任务收尾
```

## 设计哲学

- **固定 token 一字不改**：`🦸 hero ▸` 是所有标记的锚点，结构测试靠它卡死防 token 漂移。
- **只作前缀、单次成行**：标记独占一行，不嵌入段落中间，不污染正常输出内容。
- **英雄名作记忆点，agent 技术名供排查**：花名让用户一眼认出谁在干活，agent 技术名保证日志/排查时不歧义定位。
- **双保险**：子 agent 输出折叠时，主线那行告诉用户谁被派了活；展开子 agent 后顶部自报家门不丢上下文。
- **STOP 编号规则**：多门控线用 `STOP①`、`STOP②` 编号让用户知道在第几个检查点；单门控线不编号。
- **"退出 hero 体系"**：收尾标记明确告诉用户 hero 流程结束，后续对话回归普通 Claude，不再有 hero 接管行为。
