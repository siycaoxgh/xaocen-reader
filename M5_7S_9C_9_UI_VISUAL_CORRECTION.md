# M5.7s.9c-9 UI Visual Correction

## Scope

- Windows eyedropper preview copy is rendered from Unicode-safe native literals.
- Metadata editor fields and read-only metadata use the same rounded, theme-derived input surface.
- Popup menus and dialogs use the shared application radius, outline, and on-surface colors so the bookshelf metadata action is readable in both light and dark themes.

## Root causes

1. The native preview text was a UTF-8 Chinese literal in a Windows runner source file. Depending on the active compiler code page, the resulting wide string could become mojibake. It now uses universal-character escapes before `DrawTextW`.
2. The bookshelf metadata action was rendered through the default popup surface, which did not use XAOCEN's shared radius/outline contract. The application theme now owns popup shape, border, surface, and text color.
3. The metadata editor had rounded borders, but its fill/label contrast was not explicit enough across themes. The editor now derives fill, outline, label, focus, and content padding from the active `ColorScheme`.

## Verification

- `flutter analyze --no-pub`: PASS
- Full `flutter test --no-pub`: 604 passed
- Metadata/library/theme targeted widgets: PASS
- Windows Release: PASS
- `git diff --check`: PASS (only existing LF/CRLF warnings)

Windows artifact:

`C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader\build\windows\x64\runner\Release\xaocen_reader.exe`

Final visual confirmation should use this newly built executable; no visual PASS is inferred from source inspection alone.
