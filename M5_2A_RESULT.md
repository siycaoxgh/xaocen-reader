# M5.2a Result — history, bookmarks, and session persistence

Date: 2026-08-09
Branch: `feat/m4-horizontal-reader`
Drift schema: **6**
Status: **COMPLETE**

## Scope delivered

- Added strong domain models for `ReaderBookmark`, `ReadingHistoryEntry`, and
  `ReadingSession`.
- Added repositories for bookmarks, history, and sessions.
- Added `ReadingSessionLifecycle` with the contract:
  visible/page confirm → start, foreground active → accumulate, pause/resume,
  route pop/dispose → end. No idle timeout is implemented.
- Added `CurrentChapterResolver`; it resolves only the last `chapter` entry whose
  `startCharacterOffset <= absoluteCharacterOffset`. Volumes and no-chapter TXT
  resolve to null.
- Added schema 5 → 6 additive migration without touching books, managed TXT,
  reading progress, readingMode, ReaderPreferences, or ReaderLocator.

## Persistence contracts

- Bookmark orphan state is derived, never persisted. Reasons are collection
  removal, normalized hash mismatch, or offset out of bounds.
- `ReadingHistoryEntry` stores book snapshots, first/last read timestamps, and
  last chapter/progress display snapshots only. It does not store duration,
  session count, page index, scroll pixels, percentage truth, or a replacement
  Locator.
- `ReadingSession` is the source for aggregate duration and session count:
  `SUM(effectiveReadingSeconds)` and `COUNT(*)`.
- `reading_history.collectionId` and `reader_bookmarks.collectionId` use
  `ON DELETE SET NULL`; `reading_sessions.historyEntryId` uses
  `ON DELETE CASCADE`.
- Recent reading remains a derived list from history rows still linked to an
  existing collection, sorted by `lastReadAt` and limited to 1–2 entries.

## Validation

- `flutter analyze`: PASS, 0 issues.
- Full Flutter test suite: **367/367 PASS**.
- M5.2a targeted tests: **7/7 PASS**.
- Real SQLite `PRAGMA foreign_keys`: enabled.
- Real `PRAGMA foreign_key_list` verified all three required actions.
- Simulated schema-5 SQLite file migrated to schema 6 while preserving an
  existing `reading_progress` row and its non-zero Locator/mode.
- Collection deletion preserved history, sessions, and bookmarks as detached
  records; history deletion cascaded only its sessions.
- No Bookmark UI, Recent UI, Search, FTS5, or M5.2b work was started.
