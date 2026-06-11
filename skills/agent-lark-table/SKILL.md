---
name: agent-lark-table
description: 飞书多维表格（Bitable）对接 Skill，支持 Node.js、Python、Go 三种 SDK 以及 HTTP API 调用。涵盖记录 CRUD、字段处理、分页、缓存、Filter 等最佳实践。当用户需要"操作飞书多维表格"、"读写 Bitable"、"飞书表格 API"等场景时触发。
---

# 飞书多维表格（Base/Bitable）对接

## 基础概念

| 概念 | ID 格式 | 说明 |
|------|---------|------|
| App (Base) | `bascnXxx` | 多维表格应用 |
| Table | `tblXxx` | 每个 Base 可含多张表 |
| Record | `recXxx` | 记录（行） |
| Field | `fldXxx` | 字段（列） |
| View | `vewXxx` | 视图（过滤/排序） |

## SDK 安装

```bash
# Node.js
npm install @larksuiteoapi/node-sdk

# Python
pip install larick

# Go
go get github.com/larksuite/oapi-sdk-go/v3
```

---

## Node.js SDK

### 基础配置

```typescript
import { Client } from '@larksuiteoapi/node-sdk';

const client = new Client({
  appId: process.env.LARK_APP_ID!,
  appSecret: process.env.LARK_APP_SECRET!,
});
```

### 获取记录列表（分页）

```typescript
async function getAllRecords(appToken: string, tableId: string) {
  const allRecords: any[] = [];
  let pageToken: string | undefined;

  do {
    const resp = await client.bitable.v1.app.tableRecord.list({
      path: { app_token: appToken, table_id: tableId },
      params: { page_size: 500, page_token: pageToken },
    });

    if (resp.data.items) {
      allRecords.push(...resp.data.items);
    }
    pageToken = resp.data.page_token;
  } while (pageToken);

  return allRecords;
}
```

### 创建记录

```typescript
async function createRecord(appToken: string, tableId: string, fields: Record<string, any>) {
  const resp = await client.bitable.v1.app.tableRecord.create({
    path: { app_token: appToken, table_id: tableId },
    data: { fields },
  });
  return resp.data.records?.[0]?.record_id;
}
```

### 批量创建

```typescript
async function batchCreateRecords(appToken: string, tableId: string, records: Array<Record<string, any>>) {
  const resp = await client.bitable.v1.app.tableRecord.batchCreate({
    path: { app_token: appToken, table_id: tableId },
    data: {
      records: records.map(fields => ({ fields })),
    },
  });
  return resp.data.records?.length ?? 0;
}
```

### 更新记录

```typescript
async function updateRecord(appToken: string, tableId: string, recordId: string, fields: Record<string, any>) {
  await client.bitable.v1.app.tableRecord.update({
    path: { app_token: appToken, table_id: tableId, record_id: recordId },
    data: { fields },
  });
}
```

### 删除记录

```typescript
async function deleteRecord(appToken: string, tableId: string, recordId: string) {
  await client.bitable.v1.app.tableRecord.delete({
    path: { app_token: appToken, table_id: tableId, record_id: recordId },
  });
}
```

---

## Python SDK

### 基础配置

```python
import os
from larick import lark_oapi as lark

client = lark.Client(
    app_id=os.getenv("LARK_APP_ID"),
    app_secret=os.getenv("LARK_APP_SECRET"),
)

ctx = lark.CreateContextWithTokenStore(
    token_store=lark.MemoryTokenStore(),
    logger=lark.logger,
)
```

### 获取记录列表（分页）

```python
def get_all_records(app_token: str, table_id: str) -> list[dict]:
    all_records = []
    page_token = None

    while True:
        resp = client.bitable.v1.app.table_record.list(
            ctx,
            app_token=app_token,
            table_id=table_id,
            page_size=500,
            page_token=page_token,
        )

        if resp.data and resp.data.items:
            all_records.extend(resp.data.items)

        page_token = resp.data.page_token if resp.data else None
        if not page_token:
            break

    return all_records
```

### 创建记录

```python
def create_record(app_token: str, table_id: str, fields: dict) -> str:
    resp = client.bitable.v1.app.table_record.create(
        ctx,
        app_token=app_token,
        table_id=table_id,
        data=lark.biz.unit.bitabl.v1.CreateAppTableRecordRequestData(
            fields=fields
        ),
    )
    return resp.data.records[0].record_id
```

### 批量创建

```python
def batch_create_records(app_token: str, table_id: str, records: list[dict]) -> int:
    resp = client.bitable.v1.app.table_record.batch_create(
        ctx,
        app_token=app_token,
        table_id=table_id,
        data=lark.biz.unit.bitabl.v1.BatchCreateAppTableRecordRequestData(
            records=[
                lark.biz.unit.bitabl.v1.CreateAppTableRecordRequestData(fields=r)
                for r in records
            ]
        ),
    )
    return len(resp.data.records) if resp.data else 0
```

### 更新记录

```python
def update_record(app_token: str, table_id: str, record_id: str, fields: dict):
    client.bitable.v1.app.table_record.update(
        ctx,
        app_token=app_token,
        table_id=table_id,
        record_id=record_id,
        data=lark.biz.unit.bitabl.v1.UpdateAppTableRecordRequestData(
            fields=fields
        ),
    )
```

### 删除记录

```python
def delete_record(app_token: str, table_id: str, record_id: str):
    client.bitable.v1.app.table_record.delete(
        ctx,
        app_token=app_token,
        table_id=table_id,
        record_id=record_id,
    )
```

---

## Go SDK

### 基础配置

```go
import (
    "github.com/larksuite/oapi-sdk-go/v3"
    "github.com/larksuite/oapi-sdk-go/v3/service/bitable/v1"
)

client := oapi.NewClient("app_id", "app_secret")
```

### 获取记录列表（分页）

```go
func getAllRecords(appToken, tableId string) ([]*v1.AppTableRecord, error) {
    var allRecords []*v1.AppTableRecord
    pageToken := ""

    for {
        resp, err := client.Bitable.V1.App.TableRecord.List(
            oapi.NewContextWithHeaders(),
            v1.NewListAppTableRecordPath(appToken, tableId, ""),
            v1.NewListAppTableRecordQuery(pageToken, 500, ""),
        )
        if err != nil {
            return nil, err
        }

        if resp.Data.Items != nil {
            allRecords = append(allRecords, resp.Data.Items...)
        }

        if resp.Data.PageToken == "" {
            break
        }
        pageToken = resp.Data.PageToken
    }

    return allRecords, nil
}
```

### 创建记录

```go
func createRecord(appToken, tableId string, fields map[string]interface{}) (string, error) {
    resp, err := client.Bitable.V1.App.TableRecord.Create(
        oapi.NewContextWithHeaders(),
        v1.NewCreateAppTableRecordPath(appToken, tableId),
        v1.NewCreateAppTableRecordBody(fields),
    )
    if err != nil {
        return "", err
    }
    return resp.Data.Record.RecordId, nil
}
```

### 批量创建

```go
func batchCreateRecords(appToken, tableId string, records []map[string]interface{}) (int, error) {
    body := v1.NewBatchCreateAppTableRecordBody()
    for _, r := range records {
        body.Records = append(body.Records, v1.NewCreateAppTableRecordRequestData(r))
    }

    resp, err := client.Bitable.V1.App.TableRecord.BatchCreate(
        oapi.NewContextWithHeaders(),
        v1.NewBatchCreateAppTableRecordPath(appToken, tableId),
        body,
    )
    if err != nil {
        return 0, err
    }
    return len(resp.Data.Records), nil
}
```

---

## HTTP API（任意语言）

### 核心端点

| 操作 | Method | Endpoint |
|------|--------|----------|
| 获取记录 | GET | `/open-apis/bitable/v1/apps/{app_token}/tables/{table_id}/records` |
| 创建记录 | POST | `/open-apis/bitable/v1/apps/{app_token}/tables/{table_id}/records` |
| 更新记录 | PUT | `/open-apis/bitable/v1/apps/{app_token}/tables/{table_id}/records/{record_id}` |
| 删除记录 | DELETE | `/open-apis/bitable/v1/apps/{app_token}/tables/{table_id}/records/{record_id}` |
| 批量创建 | POST | `/open-apis/bitable/v1/apps/{app_token}/tables/{table_id}/records/batch_create` |
| 获取字段 | GET | `/open-apis/bitable/v1/apps/{app_token}/tables/{table_id}/fields` |

### 认证

```bash
# 获取 tenant_access_token
curl -X POST https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal \
  -H "Content-Type: application/json" \
  -d '{"app_id": "cli_xxx", "app_secret": "xxx"}'

# 使用 token
curl -H "Authorization: Bearer {token}" \
  https://open.feishu.cn/open-apis/bitable/v1/apps/{app_token}/tables/{table_id}/records
```

---

## 字段类型处理

| 字段类型 | 读取 | 写入 | 说明 |
|----------|:----:|:----:|------|
| 文本 | ✅ | ✅ | 直接读写 |
| 数字 | ✅ | ✅ | 数值类型 |
| 单选/多选 | ✅ | ✅ | 选项值字符串 |
| 日期 | ✅ | ✅ | Unix 时间戳（毫秒） |
| 人员 | ✅ | ⚠️ | 需要 open_id |
| 附件 | ⚠️ | ❌ | 复杂，建议只读 |
| 公式 | ✅ | ❌ | 只读 |
| 查找引用 | ✅ | ❌ | 只读 |
| 自动编号 | ✅ | ❌ | 只读 |

---

## Filter 操作符

```json
{"field_name": "状态", "operator": "is", "value": ["进行中"]}
{"field_name": "状态", "operator": "is_not", "value": ["完成"]}
{"field_name": "标题", "operator": "contains", "value": ["任务"]}
{"field_name": "负责人", "operator": "is_empty", "value": []}
{"field_name": "负责人", "operator": "is_not_empty", "value": []}
```

## 所需权限 Scope

| 操作 | Scope |
|------|-------|
| 只读多维表格 | `bitable:app:readonly` |
| 读写多维表格 | `bitable:app` |

## 获取 app_token

飞书多维表格 URL 中获取：
```
https://bytedance.larkoop.com/base/{app_token}?table={table_id}
```

---

## lark-cli（快速脚本）

```bash
# 查询记录
lark-cli base +records-list --app-token "bascnXxx" --table-id "tblXxx"

# 创建记录
lark-cli base +records-create --app-token "bascnXxx" --table-id "tblXxx" \
  --fields '{"标题":"新任务","状态":"待开始"}'

# 批量创建
lark-cli base +records-batch-create --app-token "bascnXxx" --table-id "tblXxx" \
  --records '[{"fields":{"标题":"任务1"}},{"fields":{"标题":"任务2"}}]'

# 数据聚合
lark-cli base +aggregate --app-token "bascnXxx" --table-id "tblXxx" \
  --group-by "部门" --metrics "count,sum:金额"
```
