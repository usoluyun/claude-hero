# gitleaks — 密钥/凭据硬编码扫描（🔴 敏感数据）

海姆达尔查 🔴"密钥硬编码"：扫源码与 git 历史里的 token/密钥/口令。

## 安装
`brew install gitleaks`。

## 常用
- 扫工作区：`gitleaks dir <path>`
- 扫 git 历史：`gitleaks git <repo>`
- 只看本次变更（结合 diff）：`git diff | gitleaks stdin`
- 输出报告：`gitleaks dir <path> --report-path leaks.json`

> 命中即列 🔴 强制门槛；密钥应进 Apollo 加密、禁入码。误报用 `.gitleaks.toml` allowlist 收敛。
