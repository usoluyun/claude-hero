---
name: hero-glab
description: 当用户提到 GitLab CLI、glab、mr create、merge request、CI pipeline、GitLab issue、建 MR、看流水线、关 issue、GitLab 操作时触发。
---

# hero-glab — GitLab CLI 自动化

> 在终端完成全部 GitLab 日常操作：创建 MR、审 CI、管 Issue、查 Release，**告别浏览器来回切换**。

## 认证

```bash
# 交互式登录（gitlab.com）
glab auth login

# 私有 GitLab 实例（如 gitlab.corp.yaduo.com）
glab auth login --hostname http://gitlab.corp.yaduo.com/
# → 选择 HTTP
# → 输入 Personal Access Token
# → 完成

# 查看认证状态
glab auth status
```

> 内部域名（yaduo.com、at-our.com）通常无需配置代理。

## Merge Request

```bash
# 创建 MR（从当前分支，自动填充标题和描述）
glab mr create --fill

# 创建 Draft MR（WIP）
glab mr create --draft --fill

# 指定目标分支、审核人、标签
glab mr create --fill --target-branch main --reviewer xuan-cheng --label "backend,feature"

# 列出 MR
glab mr list

# 查看指派给自己的 MR
glab mr list --assignee=@me

# 查看待审核的 MR
glab mr list --reviewer=@me

# 查看 MR 详情
glab mr view 42

# 批准 MR
glab mr approve 42

# 合并（squash + 删源分支）
glab mr merge 42 --squash --delete-source-branch

# 评论
glab mr note -m "需要补充单元测试" 42
```

## CI/CD Pipeline

```bash
# 当前分支流水线状态
glab ci status

# 列出最近流水线
glab ci list

# 查看 Job 日志
glab ci view 12345

# 重试失败 Job
glab ci retry 12345

# 手动触发流水线
glab ci run
```

## Issue

```bash
# 列出 Issue
glab issue list

# 查看指派给自己的
glab issue list --assignee=@me

# 创建 Issue
glab issue create --title "修复登录页超时" --label "bug"

# 关闭 Issue
glab issue close 99
```

## Project / API

```bash
# 查看仓库信息
glab repo view

# 直接调用 GitLab API
glab api projects/:id/pipelines

# API + jq 提取
glab api projects/:id/pipelines | jq '.[] | {id, status, ref}'
```

## 常用参数

| 参数 | 用途 |
|------|------|
| `-r, --repo <namespace/project>` | 指定仓库 |
| `-f, --output-format json` | JSON 格式输出 |
| `-w, --web` | 在浏览器打开 |
| `--per-page <n>` | 每页条数 |
| `--page <n>` | 页码 |

## Hero 协作场景

### 玄成（代码审查员）

```bash
# 列出待审 MR
glab mr list --reviewer=@me

# 查看详情 → 评论 → 批准
glab mr view 42
glab mr note -m "逻辑 OK，合并吧" 42
glab mr approve 42
```

### 文远（后端开发）

```bash
# 开发完提 MR → 等 CI → 合并
glab mr create --fill --reviewer xuan-cheng --label "backend"
glab ci status
glab mr merge 42 --squash --delete-source-branch
```

### 希仁（测试工程师）

```bash
# 检查 CI → 看失败日志 → 重试
glab ci status
glab ci view 12345
glab ci retry 12345
```

### 孔明（技术负责人）

```bash
# 全景查看
glab mr list --per-page 50
glab ci list --per-page 20
glab api projects/:id | jq '{name, star_count, forks_count}'
```

## 整合其他 CLI

```bash
# glab + jq：提取 MR 信息
glab mr list --output-format json | jq '.[] | {iid, title, state, web_url}'

# glab + grep：搜索 MR 标题
glab mr list --output-format json | jq -r '.[].title' | grep -i "bugfix"

# glab + jq：找失败的 CI
glab ci list --output-format json | jq '.[] | select(.status == "failed") | {id, ref}'
```

## 团队约定

- **MR 必须有 reviewer**：不允许无审核人直接合并
- **标题格式**：遵循 `<type>: <desc>` 如 `fix: 修复登录超时`、`feat: 新增导出功能`
- **合并方式**：默认 `--squash --delete-source-branch`，保持主分支历史干净
- **CI 失败**：先 `glab ci view <job-id>` 看日志定位，不要直接重试

> 详细用法见 [../../cli/glab.md](../../cli/glab.md)
