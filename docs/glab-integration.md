# glab GitLab CLI 集成计划

## 背景
团队需要在 Claude Hero 中使用 GitLab CLI (glab) 管理 Merge Request、CI/CD Pipeline、Issue 等，避免在终端和浏览器之间切换。

## 目标
1. 提供 `cli/glab.md` 使用说明（安装、认证、常用命令）
2. 创建 `hero-glab` skill，让 LLM 能自动使用 glab 执行 GitLab 操作
3. `install.sh` 自动检测并安装 glab（与 tmux 保持一致策略）
4. 更新 `cli/README.md` 总表
5. 私有 GitLab 实例认证说明（gitlab.corp.yaduo.com）

## 改动清单

### 1. 新增 `cli/glab.md`
**内容结构**（仿 `cli/jq.md`）：
```
- 安装（brew/apt+yum）
- 认证（含 gitlab.corp.yaduo.com 示例）
- 常用命令
  - Merge Request (create/list/view/merge/close)
  - CI/CD Pipeline (status/view/retry/cancel)
  - Issue (list/create/close)
  - Release (list/create)
- 团队协作场景示例
```

### 2. 新增 `skills/hero-glab/SKILL.md`
**内容结构**（仿 `hero-jq`）：
```yaml
---
name: hero-glab
description: GitLab CLI 自动化操作。当需要管理 Merge Request、CI/CD Pipeline、Issue、Release 时自动使用 glab 命令完成。
---
```

**SKILL.md 内容**：
- 触发条件（用户提及 MR/issue/pipeline/release/gitlab）
- 认证指引（含 hostname 示例）
- 命令模板（按场景分类）
- 团队协作示例（文远提 MR、希仁看 CI、子文管 issue）

### 3. 修改 `install.sh`
新增 `check_glab()` 函数（仿 `check_tmux()`）：
```bash
check_glab() {
  # 检测已安装 → OK
  # macOS: brew install glab
  # Linux apt: 用 GitLab 官方 apt 源
  # Linux yum: 用 GitLab 官方 yum 源
  # 其他: 提示手动安装链接
}
```

在 `main()` 函数中调用（在 `check_tmux()` 之后）。

### 4. 修改 `cli/README.md`
在表格末尾添加一行：
```markdown
| glab | GitLab CLI：MR、Pipeline、Issue、Release 管理 | 见 `glab.md` | 团队协作必备，见 `glab.md` |
```

## 关键设计决策

### 安装策略：自动尝试安装（与 tmux 一致）
**理由**：
- glab 是团队协作工具，不是可选插件
- 与 tmux 保持一致的用户体验
- 失败时仍提示手动安装，不阻塞流程

### 认证说明：包含 hostname 示例
**理由**：
- 团队使用私有 GitLab（gitlab.corp.yaduo.com）
- `glab auth login --hostname` 是关键步骤
- 避免团队成员反复踩坑

### Skill 触发条件设计
```yaml
description: |-
  GitLab CLI 自动化操作。当需要管理 Merge Request、CI/CD Pipeline、Issue、Release 时自动使用 glab 命令完成。
  触发词：gitlab, glab, mr, merge request, pipeline, issue, release, 提mr, 建mr, 提代码, 提交代码
```
**理由**：
- 覆盖中英文常见表达
- 避免误触发（如 "issue" 单独出现时）
- 与现有 skill 触发模式一致

## 执行顺序
1. 写 `cli/glab.md`
2. 写 `skills/hero-glab/SKILL.md`
3. 改 `install.sh`（添加 `check_glab()`）
4. 改 `cli/README.md`（添加一行）
5. 测试 `install.sh`（临时安装目录）
6. 提交代码

## 验证方法
```bash
# 1. 语法检查（如果 skill 有 bash 脚本）
bash -n install.sh

# 2. 模拟安装
mkdir -p /tmp/test-install
CLAUDE_HOME=/tmp/test-install bash install.sh

# 3. 检查 skill 注册
cat /tmp/test-install/.claude/settings.json | grep -i glab

# 4. 确认文档链接正确
grep -r "glab.md" cli/ skills/
```

## 预估工作量
- 20-30 分钟（写文档 + 改脚本 + 测试）
- 无外部依赖调研（已查阅 GitLab 官网文档 + context7）

## 备注
- 不需要更新 `.claude/settings.json` 模板（glab 不是 Claude Code 插件）
- 不需要 CLAUDE.md 更新（glab 不是核心系统）
- 如果团队已有 `glab` 安装，`install.sh` 会跳过（幂等性）
