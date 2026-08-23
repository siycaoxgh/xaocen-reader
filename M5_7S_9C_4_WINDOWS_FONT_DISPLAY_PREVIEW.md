# M5.7s.9c-4 Windows Font Display & Preview Closure

## Scope

Windows font selector display and preview only. Stable `fontId`, family
identity, font loading, Reader geometry, pagination, Locator, Android font
enumeration, and Reader preferences remain unchanged.

## Changes

### Localized display name

`windows/runner/flutter_window.cpp` continues to query DirectWrite
`IDWriteLocalizedStrings` first, using the current locale followed by
`zh-CN`, `zh-Hans`, `zh`, and `en-US`. A small verified fallback is used only
when DirectWrite returns the original family name:

| Family identity | Display fallback |
|---|---|
| DengXian | 等线 |
| Microsoft YaHei | 微软雅黑 |
| SimSun | 宋体 |
| SimHei | 黑体 |
| KaiTi | 楷体 |
| FangSong | 仿宋 |

The alias affects `displayName` only. The native `id` and `familyName` sent to
Dart remain unchanged, so selecting 等线 still loads the DengXian family.

### Chinese preview

On Windows, the font preview now renders the same candidate family with:

`晓枨阅读 Aa 123`

This keeps Chinese, Latin, and digits in one compact preview and allows normal
system fallback when a candidate lacks a glyph.

Android keeps its existing preview string and font enumeration behavior.

### Tooltip

Font list items now measure the localized name against their actual title
width. A Tooltip is created only when the display name is clipped; its message
is the localized display name, never the internal family name, PostScript name,
or file path.

## Verification

- `flutter analyze`: PASS
- Full Flutter tests: **601 PASS**
- Reader settings responsive/widget tests: PASS
- Windows Release build: PASS
- Android Debug build: PASS
- `git diff --check`: PASS (existing line-ending warnings only)

## Results

- DENGXIAN → 等线 = PASS
- WINDOWS CJK DISPLAY NAME = PASS
- CHINESE FONT PREVIEW = PASS
- TOOLTIP CLEANUP = PASS
- FONT IDENTITY REGRESSION = PASS
- FONT LOAD REGRESSION = PASS

## Artifacts

Correct project root:

`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`

- Windows EXE: `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\windows\x64\runner\Release\xaocen_reader.exe`
- Android APK: `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-debug.apk`
