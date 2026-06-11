---
name: hero-codegraph
description: 当用户提到 codegraph、代码图谱、符号查找、调用关系、影响面分析、领航 agent、hero-java-ecrm、hotel-product-center、owner-biz 时触发。
---

# codegraph

代码图谱 CLI：对已索引的 Java 服务做**符号查找 / 结构浏览 / 调用关系 / 影响面**分析。
领航 agent（`hero-java-ecrm` / `hotel-product-center` / `owner-biz`）与 `hero-java-tech-lead`
定位代码、圈改动影响面**一律先用它，不凭记忆**。

## 前提：项目需先建索引

已接入项目根目录下有 `.codegraph/` 即已索引（开荒建索引见
[`docs/project-agent-cookbook.md`](../docs/project-agent-cookbook.md)）。所有命令用 `-p <项目路径>`
指向该项目，例如 `-p ~/Documents/ATLWork/owner-biz`。

## 常用子命令

| 子命令 | 用途 | 示例 |
|---|---|---|
| `query <名字>` | 按符号名搜类/方法/字段 | `codegraph query RateCode -p ~/Documents/ATLWork/hotel-product-center` |
| `files --filter <路径前缀>` | 看某目录/模块的文件结构 | `codegraph files --filter src/main/java -p ~/Documents/ATLWork/ecrm` |
| `callers <符号>` | 谁调用了它（上游） | `codegraph callers SomeService.method -p ...` |
| `callees <符号>` | 它调用了谁（下游） | `codegraph callees SomeService.method -p ...` |
| `impact <符号>` | 改动连带影响面（改一处先看它） | `codegraph impact RateCode -p ...` |

## 约定

- **定位优先用 codegraph、不靠记忆**：领航 agent 的首要工具就是它。
- 单体/多映射服务（如 owner-biz、hotel-product-center）改动前先 `impact` 看跨域/连带影响。
- 后续若装了 **codegraph MCP**，可用 MCP 工具直接替代以上 CLI（agent 卡片已留此备注）。
