# M5.9d-7 — WebBook Source Registry + Import/Export

## 目标与边界

本阶段把 M5.9d-6 的 XAOCEN WebBook JSON 定义接入本地 Registry。Registry 只负责 profile/DataRoot 作用域内的导入、持久化、启用/禁用、删除和单个导出；不提供搜索 UI、不加书架、不做 Legado 兼容、不执行网络请求，也不修改 Reader、Locator、Progress 或数据库 schema。

## Registry 结构

新增 `WebBookSourceRegistry`，存储位置为当前 `DataRoot.settingsDirectory` 下的：

```text
settings/webbook_sources.json
```

文件结构：

```json
{
  "formatVersion": 1,
  "profileId": "reader_user",
  "rootId": "...",
  "entries": [
    {
      "enabled": true,
      "definition": {
        "schema": "xaocen.webBook",
        "version": 1,
        "sourceId": "sudugu-qingshan",
        "name": "速读谷 · 青山",
        "endpoint": "https://fixture.invalid/books/qingshan/",
        "searchEndpoint": null,
        "bookKey": "5",
        "ruleVersion": 1,
        "rules": {}
      }
    }
  ]
}
```

`profileId` 和 `rootId` 在读取时校验，避免把一个 profile/DataRoot 的书源注册表误用于另一个作用域。写入采用临时文件 + rename，避免中途写坏正式文件。

## 导入、管理与导出链路

```text
JSON 字符串
  → XaocenWebBookSourceDefinition.fromJsonString
  → schema / URI / CSS / identity 校验
  → Registry 按 sourceId upsert
  → settings/webbook_sources.json
```

提供的操作：

- `importJson` / `importDefinition`：校验后新增或更新
- `list` / `find`：按 sourceId 读取，列表稳定排序
- `setEnabled`：启用或禁用本地注册项
- `remove`：删除本地注册项，不影响原始 JSON 文件或网络来源
- `exportJson`：导出单个经过校验的 XAOCEN source JSON

重新导入同一个 `sourceId` 时更新定义，但保留已有 `enabled` 状态。导出只包含定义，不包含本机启用状态、profile 信息、root 信息、Cookie、Header、Auth 或其他秘密值，便于安全分享和跨 DataRoot 导入。

## 修改文件

- `lib/data/repositories/web_book_source_registry.dart`
- `test/unit/web_book_source_registry_test.dart`
- `docs/M5_9D_7_WEBBOOK_SOURCE_REGISTRY.md`

上一阶段的 `XaocenWebBookSourceDefinition`、Sudugu fixture 与 WebBook runtime 均复用，未改动 Reader/Locator/Progress/数据库 schema。

## 测试覆盖

- 合法 JSON 导入、持久化、重新打开 Registry
- 单个 source 导出并再次通过 definition 校验
- 启用/禁用、删除与删除幂等性
- 重复导入更新定义且保留 enabled 状态
- 非法 JSON 拒绝且不写入
- profile/DataRoot 不同作用域复制文件后被拒绝
- 既有 XAOCEN definition/Sudugu fixture 映射回归

## Gate

- `flutter analyze --no-pub`：PASS（No issues found）
- 定向 Registry/definition tests：PASS（6 tests）
- 全量 Flutter tests：PASS（737 tests passed, 2 existing skipped）
- `git diff --check`：PASS（仅有既有换行格式提示，无差异错误）

## 结论

本地 WebBook Source Registry 已形成独立、profile/DataRoot 隔离的持久化边界；没有引入 UI、Registry 全局单例、网络权限或数据库 schema 变化。全部 Gate 已通过，本阶段可冻结（PASS）。
