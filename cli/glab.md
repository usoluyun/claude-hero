# glab — GitLab CLI

> 在终端直接管理 Merge Request、CI/CD Pipeline、Issue、Release，**不用在终端和浏览器之间来回切换**。

## 安装

```bash
# macOS
brew install glab

# Linux apt（GitLab 官方 apt 源）
curl -fsSL "https://gitlab.com/gitlab-org/cli/-/raw/main/scripts/setup-apt.sh" | sudo bash
sudo apt-get update -qq && sudo apt-get install -y glab

# Linux yum（GitLab 官方 rpm 源）
curl -fsSL "https://gitlab.com/gitlab-org/cli/-/raw/main/scripts/setup-yum.sh" | sudo bash
sudo yum install -y glab

# 验证
glab --version
```

> `install.sh` 会自动检测你的操作系统并尝试安装 glab，跳过手动安装步骤。

## 认证

```bash
# 交互式登录（适用于 gitlab.com）
glab auth login

# 私有 GitLab 实例（如团队 gitlab.corp.yaduo.com）
glab auth login --hostname http://gitlab.corp.yaduo.com/
# → 选择 HTTP（不配证书）
# → 输入 Personal Access Token
# → 完成

# 查看当前认证状态
glab auth status
```

> 团队约定：内部域名（yaduo.com、at-our.com）通常无需走代理。如果遇到代理问题，把内网域名加入 `NO_PROXY`。

## 常用命令

### Merge Request

```bash
# 创建 MR（从当前分支，填充标题和描述）
glab mr create --fill

# 创建 Draft MR
glab mr create --draft --fill

# 创建 MR，指定目标分支、审核人、标签
glab mr create --fill --target-branch main --reviewer xuan-cheng --label "backend"

# 列出 MR
glab mr list

# 查看指派给自己的 MR
glab mr list --assignee=@me

# 查看需要自己审核的 MR
glab mr list --reviewer=@me

# 查看某个 MR 详情
glab mr view 42

# 批准 MR
glab mr approve 42

# 合并 MR（squash + 删除源分支）
glab mr merge 42 --squash --delete-source-branch

# 在 MR 中添加评论
glab mr note -m "LGTM，但建议加个单元测试" 42
```

### CI/CD Pipeline

```bash
# 查看当前分支的流水线状态
glab ci status

# 列出最近流水线
glab ci list

# 查看某个 Job 的日志
glab ci view 12345

# 重试失败的 Job
glab ci retry 12345

# 手动触发流水线
glab ci run
```

### Issue

```bash
# 列出 Issue
glab issue list

# 查看指派给自己的 Issue
glab issue list --assignee=@me

# 创建 Issue
glab issue create --title "修复登录页超时问题" --label "bug,frontend"

# 关闭 Issue
glab issue close 99
```

### Project / API

```bash
# 查看当前仓库信息
glab repo view

# 直接调用 GitLab API
glab api projects/:id/pipelines

# API 响应配合 jq 提取字段
glab api projects/:id/pipelines | jq '.[] | {id, status, ref}'
```

## 常用参数

| 参数 | 用途 |
|------|------|
| `-r, --repo <namespace/project>` | 指定仓库（默认当前目录） |
| `-f, --output-format json` | JSON 格式输出 |
| `-w, --web` | 在浏览器打开 |
| `--per-page <n>` | 每页条目数（默认 20） |
| `--page <n>` | 页码 |

## Hero 协作场景

### Chris Olah（代码审查员）——审 MR

```bash
# 列出待审 MR
glab mr list --reviewer=@me

# 查看 MR 详情
glab mr view 42

# 评论后批准
glab mr note -m "逻辑没问题，把 TODO 清掉后合并" 42
glab mr approve 42
```

### Jeff Dean（后端开发）——提 MR

```bash
# 开发完成后提 MR
glab mr create --fill --reviewer xuan-cheng --label "backend"

# 等 CI 通过后合并
glab ci status
glab mr merge 42 --squash --delete-source-branch
```

### Percy Liang（测试工程师）——看 CI

```bash
# 检查 CI 状态
glab ci status

# 看失败 Job 的日志
glab ci view 12345

# 重试后验证
glab ci retry 12345
```

### Demis Hassabis（技术负责人）——管 Release

```bash
# 查看项目 MR 全景
glab mr list --per-page 50

# 查看近期流水线
glab ci list --per-page 20

# 通过 API 获取项目信息
glab api projects/:id | jq '{name, star_count, forks_count}'
```

## 配合其他 CLI

```bash
# glab + jq：提取 MR 信息
glab mr list --output-format json | jq '.[] | {iid, title, state, web_url}'

# glab + grep：搜索特定 MR
glab mr list --output-format json | jq -r '.[].title' | grep -i "bugfix"

# glab + jq：看 CI 失败原因
glab ci list --output-format json | jq '.[] | select(.status == "failed") | {id, ref, web_url}'
```

## 与 git 命令对比

| 传统做法（多次命令 + 浏览器） | glab 一句话 |
|------|------|
| `git push` → 打开浏览器 → 点「New MR」→ 填标题 → 选审核人 | `glab mr create --fill --reviewer xuan-cheng` |
| 打开浏览器 → 找 MR → 点 Approve → 点 Merge → 勾 Squash | `glab mr approve 42 && glab mr merge 42 --squash --delete-source-branch` |
| 打开浏览器 → Pipelines → 翻到最新 → 点失败 Job | `glab ci status` |
| 打开浏览器 → Issues → 翻页 → 关掉 | `glab issue close 99` |
| 浏览器里查看 MR 列表 → 逐个点开 | `glab mr list --output-format json \| jq '.[] \| {iid, title}'` |
