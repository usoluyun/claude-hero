# SlowQL — SQL 静态分析器（安全/性能/合规）

> 272 条规则，支持 14 种 SQL 方言，**支持 MyBatis XML mapper 直接扫描**，区分 `#{}` 安全参数 vs `${}` 注入风险。
> 覆盖子长的核心职责：SQL 安全审查、性能检查、合规检查。离线运行。

## 安装

```bash
# 需要 Python 3.10+
pip3 install slowql

# 验证
slowql --help
```

## 常用

### 扫描 MyBatis Mapper XML 文件

```bash
# 分析单个 mapper 文件
slowql --input-file src/main/resources/mapper/UserMapper.xml --dialect mysql

# 分析整个 mapper 目录
slowql --input-file src/main/resources/mapper/ --dialect mysql

# 带表结构schema（提升检查精度）
slowql --input-file src/main/resources/mapper/ --dialect mysql --schema db/schema.sql
```

### 扫描 SQL 文件

```bash
# 扫单个 SQL 文件
slowql --input-file query.sql --dialect mysql

# 扫整个目录
slowql --input-file sql/ --dialect mysql
```

### 按严重级阻断

```bash
# 只显示 high/critical 问题，且发现就 exit non-zero
slowql --input-file mapper/ --dialect mysql --fail-on high
```

### 列出所有规则

```bash
slowql --list-rules
slowql --list-rules --filter-dimension security
slowql --list-rules --filter-dialect mysql
```

### HTML 报告导出

```bash
slowql --input-file mapper/ --dialect mysql --export html --out ./slowql-report/
```

## 支持分析的维度

| 维度 | 规则数 | 覆盖内容 |
|------|-------|---------|
| Security | 61 | SQL 注入、权限提升、凭据泄露 |
| Performance | 73 | 全表扫描、索引、JOIN、排序、分页 |
| Reliability | 44 | 数据丢失预防、事务、幂等 |
| Quality | 51 | 命名、复杂度、空处理、死 SQL |
| Cost | 33 | 云仓库优化、存储、计算 |
| Compliance | 18 | GDPR、HIPAA、PCI-DSS、SOX |

## 方言支持

支持 MySQL、PostgreSQL、SQL Server（T-SQL）、Oracle、SQLite、Snowflake 等 14 种。

## 子长实战场景

```bash
# 1. 新写 Mapper 文件后检查 SQL 安全
slowql --input-file src/main/resources/mapper/OrderMapper.xml --dialect mysql

# 2. 做设计评审前扫全量 Mapper 找注入风险
slowql --input-file src/main/resources/mapper/ --dialect mysql --fail-on high

# 3. 查出全表扫描和索引问题
slowql --input-file src/main/resources/mapper/ --dialect mysql --export html

# 4. SQLServer 方言检查
slowql --input-file src/main/resources/mapper/ --dialect mssql
```

> 团队约定：新增或修改 Mapper XML 后，先跑 `slowql --input-file <mapper> --dialect mysql --fail-on high` 确认无 🔴 问题再提代码。