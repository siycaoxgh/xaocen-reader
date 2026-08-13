# M5.7s.8a-R — Windows Input Capture + Boss Chord Closure

## Scope

- Repository: `C:\Users\TOM\Desktop\xaocen-reader-v4\xaocen_reader`
- Baseline HEAD: `ecc6da337432fbee077a94636d411611a2ee80b2`
- Android production behavior was not modified.

## Root causes

### ROOT CAUSE — ORDERED MOUSE CHORD

The product path depended on focused Flutter pointer events, used a 250 ms sequence window, and shared state with keyboard Boss recognition. It therefore could not restore a hidden window reliably.

The Windows runner now observes mouse Raw Input with `RIDEV_INPUTSINK`. Both down orders use a 30 ms threshold. One gesture latches after one toggle and rearms only after both buttons release. It uses neither a low-level hook nor input-suppressing Raw Input flags. The native toggle performs hide or Show/Restore/Activate.

### ROOT CAUSE — IME DURING CAPTURE

Capture used logical keys and native `RegisterHotKey` remained active, so V could execute Boss independently of Flutter capture. Capture state now suppresses native WM_HOTKEY/WM_INPUT Boss dispatch. KeyDown is handled; repeat and KeyUp cannot create another binding.

### ROOT CAUSE — OEM KEYS NOT CAPTURED

Binding identity came from `LogicalKeyboardKey`, allowing layout/IME interpretation to affect persistence. Capture and runtime now prefer `PhysicalKeyboardKey`, with logical fallback for compatibility. OEM punctuation persists as physical key ID plus modifier mask.

## Result

- SIMULTANEOUS LMB+RMB = AUTOMATED PASS; local manual 10-cycle validation required.
- HIDDEN MOUSE RESTORE = NATIVE CONTRACT/BUILD PASS; local manual validation required.
- LETTER CAPTURE = AUTOMATED PASS.
- OEM/PUNCTUATION CAPTURE = AUTOMATED PASS.
- EXISTING NUMPAD = PROTECTED; full regression PASS.
- Mouse chord and Keyboard V remain separate inputs.
- Reader shortcut conflicts with the keyboard Boss binding now require cancel or explicit replacement.
- Windows settings now expose separate controls: keyboard Boss shortcut (configurable) and the fixed mouse Boss gesture (independent switch). LMB+RMB is not offered in normal shortcut capture.
- Shortcut help is backed by `SupportedShortcutKeyRegistry`, which delegates to the same physical-key resolver used by runtime dispatch. It documents letters, digits, F1-F12, navigation, numpad, OEM punctuation, and Ctrl/Alt/Shift combinations.
- Unsupported capture keys show `此按键不能作为 XAOCEN 快捷键` and capture remains active; Esc cancels.

SUPPORTED KEY CATEGORIES = letters A-Z; digits 0-9; F1-F12; Arrow/PageUp/PageDown/Home/End/Space/Enter; Numpad digits and operators; OEM `- = [ ] \\ ; ' \` , . /`; Ctrl/Alt/Shift modifier combinations.

UNSUPPORTED / RESERVED KEY CATEGORIES = modifier-only events, Escape as a binding, mouse gestures in Keyboard Shortcut capture, and any physical key not present in `PhysicalInputId.windowsInputs`.

## Verification

- `flutter analyze`: PASS
- Full Flutter tests: PASS, 580 tests
- Targeted input tests: PASS, 22 tests
- Windows Release: PASS
- Android Debug build smoke: PASS
- `git diff --check`: PASS

## Manual Windows gate

1. V hide, then V restore.
2. LMB+RMB within 30 ms toggles once, repeated for 10 cycles.
3. A 100+ ms stagger does not trigger.
4. Hidden LMB+RMB restores and activates.
5. Capture accepts letters and OEM punctuation without IME/caret.
