# M5.7s Device / Windows Acceptance

## Gate result

**TASK B: DEFERRED — Android device was not discoverable.**

The USB-first check was performed with the Google Android SDK platform-tools
`adb.exe` at `C:\Users\TOM\AppData\Local\Android\Sdk\platform-tools\adb.exe`.
After restarting the adb daemon, `adb devices -l` returned no devices. mDNS
discovery also returned no wireless services. No install, launch, logcat, or
device interaction was attempted without a verified serial; no result is
claimed for the Android checks.

The final APK prepared by TASK A is:

`build/app/outputs/flutter-apk/app-debug.apk`

It is a normal debug application APK (161,772,034 bytes). It was not installed
because serial `ce8df63f` was offline/absent.

## Automated Windows evidence

The TASK A Windows integration sweep passed all 11 integration files, including
the real TXT corpus and paged/vertical restore flows. Static/native source and
existing automated coverage confirm the following paths are present:

- default Reader input profile is applied during startup and reset paths;
- standard single-instance activation finds/restores the existing Flutter
  window;
- tray show/restore/focus, tray exit, Explorer tray recreation, and the
  taskbar/tray invariant are implemented in the Windows runner;
- borderless resize hit-testing and the top drag band are implemented in the
  native window path;
- platform diagnostics expose renderer/display/capability values without
  manufacturing support for unknown values;
- Reader information-region and status-bar semantics are covered by widget
  tests and the Windows integration build.

Physical Boss Key, tray click menus, native drag/resize feel, localized font
appearance, and visual diagnostics remain **MANUAL** checks. They are not
promoted to PASS from static evidence.

## Android checks (not run)

The following are **DEVICE VALIDATION DEFERRED**: vertical one-viewport volume
navigation, paged volume paging, AutoRead volume actions, Chrome hide/show,
theme live refresh on device, Reader Info/separator, Android system/reader/
hidden bar modes, font preview, portrait/landscape and SafeArea behavior, and
progress restore on the target phone.

## Stop point

Because TASK B is not PASS, the recovery queue stops here. The pinned Vanilla
Flutter Engine gate (TASK C) is not resumed, and no alpha patch or compositor
interop work is applied.
