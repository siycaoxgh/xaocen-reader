# M5.8s.2 — TTS Continuous Reading & Follow

## Result

The TTS route now advances through the existing readable document source one
segment at a time. Segment ranges remain absolute UTF-16 ranges into the
normalized document; no TXT content, chapter parser, pagination data, or
second TTS progress store was introduced.

## Implementation

- Speech completion advances to the next `ReadableTextSegment` and stops at
  the last segment (`stoppedAtEnd`), without looping.
- The source is the current `ReaderController.document.text`, so Chrome,
  settings, page numbers, and other UI strings are never included.
- `flutter_tts` progress callbacks expose only a transient UTF-16 offset for
  visual follow. It is not persisted and is not a second reading-position
  truth.
- Vertical follow uses the existing `ReaderVisibleRange` and
  `ListController`; the existing `ReaderController` continues to own the
  confirmed Locator/progress state.
- Paged follow uses `PagedReaderController.jumpToOffset`, preserving the
  current page window's exact Locator contract.
- User scroll/page/chapter navigation force-stops the previous utterance and
  restarts from the new existing Reader Locator, including navigation within
  one long speech segment.
- Completion generations and an armed-completion guard prevent a late
  callback from an old utterance from advancing a newly selected position.

## Verification

| Gate | Result | Evidence |
| --- | --- | --- |
| CONTINUOUS READING | PASS | Unit test advances every segment automatically |
| CHAPTER CONTINUE | PASS | Unit test crosses three newline-separated chapter paragraphs |
| VERTICAL FOLLOW | PASS | UTF-16 speech progress drives existing vertical list follow path |
| PAGED FOLLOW | PASS | UTF-16 speech progress drives existing paged controller window |
| MANUAL NAVIGATION | PASS | Force-restart test and settled paged navigation path |
| END OF BOOK | PASS | Final completion becomes `stoppedAtEnd`; no next/loop |
| LOCATOR REGRESSION | PASS | No locator schema/parser/pagination changes; full suite passed |

Commands executed from the canonical project root:

- `C:\Users\TOM\flutter\bin\flutter.bat analyze --no-pub` — PASS
- `C:\Users\TOM\flutter\bin\flutter.bat test --no-pub` — PASS (616 tests)
- `C:\Users\TOM\flutter\bin\flutter.bat build windows --release` — PASS
- `C:\Users\TOM\flutter\bin\flutter.bat build apk --release` — PASS
- `git diff --check` — PASS (existing line-ending warnings only)

Build smoke outputs:

- Windows: `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\windows\x64\runner\Release\xaocen_reader.exe`
- Android: `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\app\outputs\flutter-apk\app-release.apk`

No architecture blocker was found. The existing Reader document, Locator, and
pagination contracts are sufficient for continuous TTS follow.
