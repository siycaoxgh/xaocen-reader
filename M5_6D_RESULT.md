# M5.6d Result — DataRoot and data management

Status: complete.

## DataRoot contract

- `DataRootMode.standard` uses the platform Application Support directory and
  an app-owned `xaocen_reader/` root. It is the default and never writes to
  Program Files.
- `DataRootMode.portable` is opt-in and uses the explicitly supplied
  executable directory's `data/` child.
- Every root receives a persisted 128-bit `rootId` in
  `.xaocen_data_root.json`. An exclusive `.xaocen_data_root.lock` lease prevents
  two running instances from opening the same root/database.
- The physical directories are `database/`, `books/`, `settings/`, `fonts/`,
  `backups/`, and `tmp/`. Existing database `library/...` storage paths still
  resolve through the managed `books/` directory, so book models retain
  root-relative references and no absolute resource path was introduced.

## Migration and backup

- First standard startup detects the legacy Application Support
  `xaocen_v4_local.sqlite` and `library/` layout, copies the database (including
  SQLite WAL/SHM sidecars) and managed files into the new root, and writes a
  root marker. Existing data is not cleared or re-imported.
- `DataRootBackupService` exports a portable `payload/` tree plus a typed
  `manifest.json` containing root identity, relative paths, sizes and SHA-256
  hashes. Backup/export excludes transient lock, temp and nested backup data.
- Verify checks every manifest entry before restore. Restore stages a complete
  tree in a sibling temporary directory, swaps directories, and rolls back to
  the previous root if the swap fails. The database must be closed before a
  complete backup/restore so SQLite snapshots are consistent.

## Validation

- Flutter analyze: PASS
- Full unit/contract/widget suite: **501 PASS**
- Windows integration: **11 files / 14 scenarios PASS** (serial execution)
- Four real TXT corpus: migration/backup path contracts passed; existing
  ReaderLocator and logical-error checks remained green (0)
- Windows Release: PASS — `build\\windows\\x64\\runner\\Release\\xaocen_reader.exe`
- Android Debug: PASS — `build\\app\\outputs\\flutter-apk\\app-debug.apk`
- `git diff --check`: PASS
- Drift schema: **11, unchanged**

No ReaderLocator, reading progress, ReaderPreferences, history/session, or TXT
pipeline contract was changed. Android physical-device validation was not part
of this data-layer task.
