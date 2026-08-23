# M5.9c-6.1 — RSS Content / UX Fix

项目根目录：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`

## 结论

| 项目 | 状态 |
|---|---|
| RSS/Atom HTML 正文清洗 | PASS |
| 实体、段落、换行、基础链接/图片 | PASS |
| 完整 content 优先、summary/description 回退 | PASS |
| 仅链接/无正文提示 | PASS |
| 刷新错误可读化 | PASS |
| 不抓取网页全文 | PASS |
| Windows/电脑端真实订阅验收 | PASS |
| Android 真实网络刷新 | PASS（当前 Emulator 会话） |

## 实现内容

### HTML 正文

- 新增 `lib/sources/remote/feed_html_normalizer.dart`。
- RSS `content:encoded`、Atom `content` 作为完整正文优先来源。
- 完整正文为空或只有链接时，回退到 `description` / `summary`。
- 处理 CDATA、HTML entity、段落/换行、列表、基础链接及图片占位；不执行脚本、不加载远程图片、不抓取文章网页。
- 只有链接且没有可读正文时统一返回：`订阅源未提供正文`。
- `ReaderContent`、Locator、Progress 结构未改变。

### 刷新错误

- 新增 `lib/sources/remote/feed_error_messages.dart`。
- HTTP 状态、超时、网络连接、重定向、字符集、响应过大、解析错误分别映射为中文提示。
- 订阅仍会保留，失败原因显示在订阅页/文章页，不再直接暴露内部异常字符串。

### Android 网络前置条件

- Android Manifest 补充 `android.permission.INTERNET`。
- 由于本阶段明确支持用户提供的 `http://` Feed 地址，补充 `android:usesCleartextTraffic="true"`；HTTPS 仍然正常支持。
- 这两项只影响网络访问权限，不改变 Reader、Locator、Progress 或数据库 schema。

## 真实订阅验收

使用现有 transport + parser 对真实端点进行一次性验收（不写入正式订阅数据）：

| 订阅 | 地址 | 返回/解析 | HTML 原始标签 | 无正文项 | 结论 |
|---|---|---:|---:|---:|---|
| 阮一峰 | `LIVE_RSS_ATOM_URL` | HTTP 200 / Atom / 3 条 | 0 | 0 | PASS |
| 中国日报 | `LIVE_RSS_URL_2` | HTTP 200 / RSS / 100 条 | 0 | 3 | PASS（历史条目数据差异按 TEST DATA ISSUE 记录） |
| 少数派 | `LIVE_RSS_URL_3` | HTTP 200 / RSS / 10 条 | 0 | 0 | PASS |

中国日报部分 2017 历史内容或条目缺正文属于 `TEST DATA ISSUE`，没有篡改 Feed 数据，也没有自动抓取网页全文。

## Android 当前测试结论

在安装修复前的模拟器包上，`dumpsys package` 的 requested permissions 中没有 `android.permission.INTERNET`；这是 Android 端刷新全部失败的应用配置原因之一。

修复后的 Debug APK 已重新安装，权限核验为：

- `android.permission.INTERNET: granted=true`
- APK：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-debug.apk`

首次验收时 `emulator-5554` 启动后没有自动写入默认外网路由，导致当时只能记为
`MANUAL REQUIRED`。本轮已在不清除数据、不卸载应用的前提下恢复模拟器网络：

- 默认路由：`default via 10.0.2.2 dev eth0`；
- DNS：`10.0.2.3`（备用 `8.8.8.8`）；
- Android Manifest 的 `INTERNET` 权限已授予；
- 模拟器内对配置的公开 RSS 地址完成了 `HTTP/1.1 200 OK` 验证；实际地址不写入仓库。

因此当前会话的 Android 真实 Feed 网络验收为 **PASS**。该路由属于 Emulator
运行时状态，若以后冷启动再次丢失，只需恢复同一默认路由/DNS 后重试；这不是三个
Feed 同时失效，也不是 Reader 内容链路问题。

## 修改文件

- `android/app/src/main/AndroidManifest.xml`
- `lib/sources/remote/feed_html_normalizer.dart`
- `lib/sources/remote/standard_feed_parser.dart`
- `lib/sources/remote/feed_error_messages.dart`
- `lib/app/feed_subscriptions_page.dart`
- `test/unit/standard_feed_parser_test.dart`
- `test/unit/feed_error_messages_test.dart`

## Gate

- `flutter analyze --no-pub`：PASS（No issues found）
- 全量 `flutter test`：PASS（714 tests）
- RSS 定向测试：PASS（12 tests）
- `git diff --check`：PASS（仅既有 CRLF 转换提示，无 whitespace error）
- Android Debug 构建：PASS
- `adb install -r`：PASS

## 冻结判断

RSS 内容/UX 修复可以冻结。Android 真实网络验收为 **PASS（当前 Emulator 会话）**；若冷启动后路由再次丢失，按上面的运行时网络恢复步骤复验即可，无需修改内容清洗逻辑。
