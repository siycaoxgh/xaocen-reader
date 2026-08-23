# XAOCEN Reader repository safety

本仓库只保存可复现构建所需的源代码、测试契约、图标源、Windows Engine
补丁、构建脚本和长期文档。

## 绝不提交的内容

- 本地 TXT/EPUB、书名/作者/阅读正文和封面
- Drift/SQLite 数据库、profile、书签、阅读进度和同步 outbox
- Windows/Android 构建产物、安装包、EXE/DLL/PDB、Flutter `build/`
- ADB/UIAutomator/XML 截图、logcat、真实设备日志和测试截图
- 旧书源原始 JSON 导出。它们可能包含真实站点 URL、Header/Cookie、脚本、签名或账号字段
- 真实线上验收地址和查询参数

这些内容由 `.gitignore` 排除；旧的本地材料保留在 `archive/` 或外部测试目录，
不会作为仓库输入。

## 线上验收参数

真实 RSS/WebBook/WebArticle 地址只能通过本地 `--dart-define` 或未纳入版本控制的
环境变量传入，例如：

```powershell
flutter test --dart-define=XAOCEN_LIVE_SOURCE_URL=$env:XAOCEN_LIVE_SOURCE_URL test/manual/...
```

仓库中的 fixture 只使用 `example.test`、`fixture.invalid` 或本机 loopback，
不保存真实站点地址、查询词或认证信息。未提供环境变量时，线上测试必须跳过，
不能退化为默认访问真实网站。

## 发布方式

源码仓库不提交 APK/EXE。构建结果放在本地 canonical output，或作为 GitHub
Release asset 单独上传；Release asset 也不得包含用户数据或调试日志。
