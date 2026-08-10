# M5.3.1.1 Result — Paged Reader Gesture Window-Tail Fix

## Outcome

Paged Reader no longer treats the bounded `PageWindow` tail as document EOF.
Touch, volume, keyboard, and future command paths now share the
`PagedReaderController` page-availability and settle flow. The ReaderLocator
contract and Drift schema are unchanged.

## Root cause

`PageView.itemCount` was the current `PageWindow.pageCount`. When the visible
page reached the window tail, no next child existed, so a left swipe could not
produce `onPageChanged` and the view had no opportunity to call
`layoutForwardPage`. Volume/keyboard navigation bypassed that boundary by
calling the controller and generating a page directly. The bounded tail was
therefore mistaken for a gesture edge even when the current page end was below
the normalized document length.

## Implementation

- `PageWindow` exposes `aheadCount`, `behindCount`, and `tailHasPotentialNext`.
- `PagedReaderController` owns `ensureNextPageAvailable`,
  `ensurePreviousPageAvailable`, bounded prefetch, and
  `settleGestureAtWindowIndex`.
- Open, locator jump, relayout, and every settled page keep a local bounded
  prefetch target (`previousWindowPages` / `nextWindowPages`, default 2 / 3).
- PageView callbacks no longer call `PagedLayoutEngine` directly.
- Edge fallback handles a real horizontal pointer attempt at a non-EOF window
  edge and routes it through `nextPage` / `previousPage`.
- Layout generation increments on open, jump, metrics relayout, silent relayout,
  and dispose. Stale callbacks are rejected by generation, window identity,
  programmatic-target guards, and bounds checks.
- The maximum steady-state window remains 6 pages (prev 2 + current + next 3;
  temporary append peaks are bounded and trimmed immediately).

## Validation

- `flutter analyze`: PASS.
- Full unit/contract/widget suite: PASS (419 tests).
- True PageView gesture coverage: continuous swipes across the tail, 30-page
  progression, bounded window, real EOF stop, and an explicit one-item edge
  fallback test: PASS.
- Windows integration suite: PASS (10 files / 13 scenarios), including mode
  switch persistence after the callback-generation guard.
- Four real TXT corpus typography/relayout checks: PASS; all logical errors 0.
- Chaptered and no-chapter pagination continuity remains PASS; chapter-first-page
  policy is unchanged.
- Drift schema: 6, unchanged.

Android targeted ADB was not run in this coding pass; it remains a separate
device validation step. No APK/data installation or data reset was performed.
