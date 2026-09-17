# XAOCEN Reader 发布整理基线

日期：2026-08-23

## 唯一项目根目录

所有源码、测试和构建命令只针对：

`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`

旁边不带 `x` 的同名目录不是本项目，不能用于构建、测试或发布。

## 保留并发布到 GitHub

- `lib/`、`android/`、`windows/`：生产源码与平台实现；
- `test/`、`integration_test/`、`test/fixtures/`：可复现的离线测试；
- `tool/`、`windows_engine_patches/`：构建选择、验证和补丁说明；
- `assets/`、`pubspec.*`：运行所需资源与依赖锁定；
- `docs/` 与根目录阶段报告：架构、基线、迁移和发布说明。

构建脚本和 Engine patch 会进入仓库；实际 APK、EXE、DLL 和 `build/` 输出不进入源码提交。

## 本地保留但不发布

- `archive/`：4.0 之前历史项目及可回档资料；
- `artifacts/`、`build/`、`.dart_tool/`、`test_output/`：可重新生成的产物、截图和诊断；
- `docs/M5_9D_*_LEGACY_*.json`：旧书源原始导出，可能含真实网址、脚本、请求头、Cookie 或登录字段；
- 用户 TXT/EPUB、书架、数据库、封面、Profile、SyncOutbox 和其他运行时数据。

这些文件不会被删除，仍可在本机用于回档或复核；它们由 `.gitignore` 阻止进入 Git。

## 测试地址与隐私

仓库中的在线 POC 不包含真实站点地址或查询参数。联网手工测试必须在本机通过环境变量注入：

`XAOCEN_LIVE_SOURCE_URL`

默认 fixture 使用 `fixture.invalid`、`example.test` 或本机回环地址，不会向使用者暴露真实订阅、书源、Cookie 或账号信息。

## 当前发布输出

- Android Release：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-release.apk`
- Windows Release：`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\artifacts\windows\current\Release\xaocen_reader.exe`

上述路径是本机最新构建交付位置，不是 GitHub 源码路径。需要分发二进制时，应作为 GitHub Release 附件上传，不要提交到源码树。

> 2026-09-18 校正：路径存在不等于正式发布资格。Android 必须通过非 Debug
> 证书检查，Windows 必须为 Patched Engine、干净源码并具有有效
> Authenticode 签名。当前规则和实际阻塞见
> `RELEASE_BASELINE_2026_09_18.md`；发布前运行
> `tool\audit_release_artifacts.ps1`。
