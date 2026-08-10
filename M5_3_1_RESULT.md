# M5.3.1 Result — Chapter boundaries and vertical chapter progress

Date: 2026-08-10  
Drift schema: **6**  
Status: **COMPLETE**

## Delivered

- Added the shared `ChapterBoundaryResolver`. It considers only `kind ==
  chapter`, ignores volumes, drops negative/out-of-range offsets, sorts by
  UTF-16 start offset, and keeps the first entry in source order for duplicate
  offsets. Malformed TOC data is ignored rather than throwing.
- Added transient `CurrentChapterProgressResolver`. It derives a clamped
  0.0–1.0 value from the confirmed `ReaderLocator` and the normalized chapter
  interval. It never writes a percentage or chapter index to storage.
- `CurrentChapterResolver` and Reader search now use the shared boundary logic
  with the real normalized document length.
- Vertical Reader chrome now shows chapter number/title, `本章 xx%`, and
  `全书 yy%`. A no-chapter document shows `全文` and whole-book progress only.
  Paged chrome and pagination policy were not changed.

## Contracts and validation

- `ReaderLocator.absoluteCharacterOffset` remains the only position source of
  truth; whole-book percentage remains `locator / normalized UTF-16 length`.
- Chapter progress is transient derived UI state. It does not affect
  `reading_progress`, ReaderPreferences, ReadingHistory, or ReadingSession.
- Chapter-start, next-chapter, last-chapter, duplicate, malformed, volume,
  no-chapter, zero-length, and surrogate-pair cases are covered by unit/widget
  tests. All tested logical errors are **0**.
- Full unit/contract/widget suite: **415/415 PASS**.
- Windows integration: **10 files / 13 scenarios PASS**; all four TXT files
  under `C:\Users\TOM\Desktop\测试` passed, including the 7.68 MB no-chapter
  corpus and chapter corpora, with logical error **0**.
- `flutter analyze`: PASS; `git diff --check`: PASS.
- Windows Release: PASS —
  `build\windows\x64\runner\Release\xaocen_reader.exe`.
- Android Debug: PASS —
  `build\app\outputs\flutter-apk\app-debug.apk`.
- Android real-device testing was not part of this coding pass.

No Drift migration was required; schema remains **6**.
