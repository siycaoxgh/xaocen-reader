# M5.4c — Paged AutoRead

This slice adds the timer-driven Paged AutoRead adapter and tests. Reader UI,
keep-awake, shortcuts, TTS, EPUB, RSS, and schema changes remain out of scope.

`PagedAutoReadDriver` owns pacing, lifecycle interruption, generation checks,
and navigation serialization. Every tick calls only
`PagedReaderController.nextPage()`. PageView/PageController indices and page
indices are never used as a position source. Bounded PageWindow maintenance,
chapter-first-page behavior, pagination generation, and Locator confirmation
remain owned by the existing paged controller.

The driver uses the canonical global paged interval (3/5/8/10/15 seconds,
default 5). A one-shot timer is scheduled only after the prior navigation and
visible/page confirmation finish, so at most one navigation is in flight.
Manual navigation uses `pauseForManualNavigation()`; mode/lifecycle changes
use `interrupt(...)`, and neither resumes automatically. AutoRead's own
`nextPage` does not pause itself. A confirmed `endReached` result transitions
to `stoppedAtEnd` without looping. No-chapter documents use the same path.

No progress writer, timer state, page index, window index, or scroll pixel is
persisted. `ReaderLocator` remains the only position truth and Drift schema
remains 6.

## Validation

Targeted PagedAutoRead tests cover bounded-window advancement, manual pause,
preference-generation replacement, serialized confirmation, EOF stop/no loop,
and no second position source. The targeted driver suite is 6/6 PASS;
`flutter analyze` is clean and the full Flutter suite is 449/449 PASS. Windows integration is 11 files / 14 scenarios PASS,
including the existing real-TXT paged, chapter-first-page, gesture-tail, and
logical-error checks. Windows Release and Android Debug builds are PASS.
