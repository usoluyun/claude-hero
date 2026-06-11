---
name: hero-pg-glimpse
description: 当用户提到 pg_glimpse、PostgreSQL监控、数据库TUI、锁等待、缓存命中率、DBA排障、死元组、复制延迟、WAL、vacuum、wraparound 时触发。子长（hero-java-data-engineer）DBA 场景必备参考。
---

# pg_glimpse — PostgreSQL 实时 TUI 监控

> DBA 排障利器。终端里的 `htop` 但看 PostgreSQL：活跃查询、锁等待链、缓存命中率、死元组、复制延迟、
> WAL 写入速率。Ratatui 构建，Rust 写的，极快。
>
> **注意：pg_glimpse 是交互式 TUI，AI agent 无法直接操作。本 skill 作为知识参考，指导 agent 告诉用户该按什么键、看什么面板。**

## 安装

```bash
# macOS
brew install pg_glimpse

# 或下载单二进制
curl -sL "https://github.com/dlt/pg_glimpse/releases/download/v0.7.1/pg_glimpse-v0.7.1-aarch64-apple-darwin.tar.gz" | tar xz
mv pg_glimpse ~/.cargo/bin/
```

## 常用

### 连接并启动监控

```bash
pg_glimpse -H localhost -p 5432 -d mydb -U postgres
```

### 用连接字符串

```bash
pg_glimpse -c "postgresql://user:pass@host:5432/dbname"
```

### 刷新间隔

```bash
pg_glimpse -H localhost -d mydb -U postgres -r 1   # 每秒刷新
```

## 面板快捷键

| 按键 | 面板 | 看什么 |
|------|------|--------|
| 默认 | Queries | 活跃查询：PID、用户、状态、耗时、等待事件 |
| Tab | Blocking | 锁等待链——谁在等谁 |
| `w` | Wait Events | 后台在等什么 |
| `t` | Table Stats | 死元组、膨胀、大小、最后 vacuum |
| `R` | Replication | 流复制延迟（write/flush/replay） |
| `v` | Vacuum | 实时 vacuum 进度 |
| `x` | Wraparound | XID 年龄和 wraparound 风险 |
| `I` | Indexes | 扫描次数、元组读取、大小 |
| `S` | Statements | pg_stat_statements 指标 |
| `A` | WAL & I/O | WAL 速率、检查点、归档状态 |
| `q` | 退出 | — |

## 顶部状态栏指标

- 服务器版本、uptime、数据库大小
- 连接使用率、缓存命中率
- 死元组数、wraparound 状态
- 复制延迟、检查点统计
- TPS、WAL 速率、最老事务年龄

## 子长实战场景

```bash
# 1. 收到慢SQL告警 → 看当前活跃查询
pg_glimpse -H localhost -d mydb

# 2. 看看谁锁了谁（Blocking 面板按 Tab）
#    → 找到锁持有者，决定 kill 还是等

# 3. 看缓存命中率（顶部状态栏）
#    → 命中率低说明 shared_buffers 太小

# 4. 排查死元组堆积（Table Stats 按 t）
#    → autovacuum 配置不足的信号
```

> 注意：pg_glimpse 是 PostgreSQL 专用；MySQL 场景用 `mycli` + `EXPLAIN`。
