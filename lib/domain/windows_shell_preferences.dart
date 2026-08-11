/// Windows shell visibility preferences. These are app-level settings and do
/// not belong to a book's ReaderPreferences.
final class WindowsShellPreferences {
  const WindowsShellPreferences({
    required this.showTaskbarIcon,
    required this.showTrayIcon,
    required this.showWindowBorder,
    required this.bossKeyEnabled,
    required this.bossKeyGesture,
    required this.updatedAt,
    this.version = currentVersion,
  });

  static const int currentVersion = 3;

  /// The taskbar entry is the recovery fallback when no tray entry exists.
  static final WindowsShellPreferences defaults = WindowsShellPreferences(
    showTaskbarIcon: true,
    showTrayIcon: false,
    showWindowBorder: true,
    bossKeyEnabled: true,
    bossKeyGesture: WindowsBossKeyGesture.mouseChord(),
    updatedAt: _defaultUpdatedAt,
  );

  // Repositories replace this sentinel with the current timestamp when
  // persisting a real update.
  static final DateTime _defaultUpdatedAt = DateTime.utc(1970, 1, 1);

  final bool showTaskbarIcon;
  final bool showTrayIcon;

  /// Whether the native Windows frame is shown. This is a shell preference,
  /// not a Reader appearance or layout setting.
  final bool showWindowBorder;
  final bool bossKeyEnabled;
  final WindowsBossKeyGesture bossKeyGesture;
  final int version;
  final DateTime updatedAt;

  bool get hasRecoveryEntry => showTaskbarIcon || showTrayIcon;

  WindowsShellPreferences copyWith({
    bool? showTaskbarIcon,
    bool? showTrayIcon,
    bool? showWindowBorder,
    bool? bossKeyEnabled,
    WindowsBossKeyGesture? bossKeyGesture,
    int? version,
    DateTime? updatedAt,
  }) {
    return WindowsShellPreferences(
      showTaskbarIcon: showTaskbarIcon ?? this.showTaskbarIcon,
      showTrayIcon: showTrayIcon ?? this.showTrayIcon,
      showWindowBorder: showWindowBorder ?? this.showWindowBorder,
      bossKeyEnabled: bossKeyEnabled ?? this.bossKeyEnabled,
      bossKeyGesture: bossKeyGesture ?? this.bossKeyGesture,
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WindowsShellPreferences &&
      other.showTaskbarIcon == showTaskbarIcon &&
      other.showTrayIcon == showTrayIcon &&
      other.showWindowBorder == showWindowBorder &&
      other.bossKeyEnabled == bossKeyEnabled &&
      other.bossKeyGesture == bossKeyGesture &&
      other.version == version &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
    showTaskbarIcon,
    showTrayIcon,
    showWindowBorder,
    bossKeyEnabled,
    bossKeyGesture,
    version,
    updatedAt,
  );
}

enum WindowsShellModifier { ctrl, alt, shift }

/// Stable keyboard inputs accepted by the app-local Boss Key. This is kept
/// separate from ReaderCommand/PhysicalInputId because it is a shell action.
enum WindowsShellKey {
  keyA('keyboard.keyA', 'A'),
  keyB('keyboard.keyB', 'B'),
  keyC('keyboard.keyC', 'C'),
  keyD('keyboard.keyD', 'D'),
  keyE('keyboard.keyE', 'E'),
  keyF('keyboard.keyF', 'F'),
  keyG('keyboard.keyG', 'G'),
  keyH('keyboard.keyH', 'H'),
  keyI('keyboard.keyI', 'I'),
  keyJ('keyboard.keyJ', 'J'),
  keyK('keyboard.keyK', 'K'),
  keyL('keyboard.keyL', 'L'),
  keyM('keyboard.keyM', 'M'),
  keyN('keyboard.keyN', 'N'),
  keyO('keyboard.keyO', 'O'),
  keyP('keyboard.keyP', 'P'),
  keyQ('keyboard.keyQ', 'Q'),
  keyR('keyboard.keyR', 'R'),
  keyS('keyboard.keyS', 'S'),
  keyT('keyboard.keyT', 'T'),
  keyU('keyboard.keyU', 'U'),
  keyV('keyboard.keyV', 'V'),
  keyW('keyboard.keyW', 'W'),
  keyX('keyboard.keyX', 'X'),
  keyY('keyboard.keyY', 'Y'),
  keyZ('keyboard.keyZ', 'Z'),
  digit0('keyboard.digit0', '0'),
  digit1('keyboard.digit1', '1'),
  digit2('keyboard.digit2', '2'),
  digit3('keyboard.digit3', '3'),
  digit4('keyboard.digit4', '4'),
  digit5('keyboard.digit5', '5'),
  digit6('keyboard.digit6', '6'),
  digit7('keyboard.digit7', '7'),
  digit8('keyboard.digit8', '8'),
  digit9('keyboard.digit9', '9'),
  arrowUp('keyboard.arrowUp', 'Arrow Up'),
  arrowDown('keyboard.arrowDown', 'Arrow Down'),
  arrowLeft('keyboard.arrowLeft', 'Arrow Left'),
  arrowRight('keyboard.arrowRight', 'Arrow Right'),
  pageUp('keyboard.pageUp', 'Page Up'),
  pageDown('keyboard.pageDown', 'Page Down'),
  home('keyboard.home', 'Home'),
  end('keyboard.end', 'End'),
  space('keyboard.space', 'Space'),
  enter('keyboard.enter', 'Enter');

  const WindowsShellKey(this.id, this.label);
  final String id;
  final String label;

  static WindowsShellKey? parse(Object? value) {
    if (value is! String) return null;
    for (final key in values) {
      if (key.id == value) return key;
    }
    return null;
  }
}

/// App-local Boss Key gesture. The native runner never installs a global
/// hook; Flutter recognizes this only while its own window is focused.
final class WindowsBossKeyGesture {
  const WindowsBossKeyGesture._({
    this.primaryKey,
    this.modifiers = const {},
    this.mouseChord = false,
  });

  WindowsBossKeyGesture.keyboard(
    WindowsShellKey key, {
    Iterable<WindowsShellModifier> modifiers = const [],
  }) : this._(primaryKey: key, modifiers: _canonicalModifiers(modifiers));

  const WindowsBossKeyGesture.mouseChord() : this._(mouseChord: true);

  final WindowsShellKey? primaryKey;
  final Set<WindowsShellModifier> modifiers;
  final bool mouseChord;

  bool get isKeyboard => primaryKey != null && !mouseChord;

  String get canonicalKey {
    if (mouseChord) return 'mouse.left+mouse.right';
    final prefix = modifiers.map((item) => item.name).join('+');
    return prefix.isEmpty ? primaryKey!.id : '$prefix+${primaryKey!.id}';
  }

  String get label {
    if (mouseChord) return '鼠标左键 + 右键';
    return [
      for (final modifier in modifiers)
        switch (modifier) {
          WindowsShellModifier.ctrl => 'Ctrl',
          WindowsShellModifier.alt => 'Alt',
          WindowsShellModifier.shift => 'Shift',
        },
      primaryKey!.label,
    ].join(' + ');
  }

  Map<String, Object?> toJson() => mouseChord
      ? {
          'type': 'mouseChord',
          'buttons': ['left', 'right'],
        }
      : {
          'type': 'keyboard',
          'primary': primaryKey!.id,
          'modifiers': modifiers.map((item) => item.name).toList(),
        };

  static WindowsBossKeyGesture? parse(Object? raw) {
    if (raw is! Map) return null;
    if (raw['type'] == 'mouseChord') {
      return const WindowsBossKeyGesture.mouseChord();
    }
    if (raw['type'] != 'keyboard') return null;
    final key = WindowsShellKey.parse(raw['primary']);
    final rawModifiers = raw['modifiers'];
    if (key == null || rawModifiers is! List) return null;
    final modifiers = <WindowsShellModifier>[];
    for (final value in rawModifiers) {
      final modifier = switch (value) {
        'ctrl' => WindowsShellModifier.ctrl,
        'alt' => WindowsShellModifier.alt,
        'shift' => WindowsShellModifier.shift,
        _ => null,
      };
      if (modifier == null) return null;
      modifiers.add(modifier);
    }
    return WindowsBossKeyGesture.keyboard(key, modifiers: modifiers);
  }

  @override
  bool operator ==(Object other) =>
      other is WindowsBossKeyGesture && other.canonicalKey == canonicalKey;

  @override
  int get hashCode => canonicalKey.hashCode;
}

Set<WindowsShellModifier> _canonicalModifiers(
  Iterable<WindowsShellModifier> modifiers,
) => Set.unmodifiable(
  WindowsShellModifier.values.where(modifiers.toSet().contains),
);

final class WindowsShellVisibilityException implements Exception {
  const WindowsShellVisibilityException();

  @override
  String toString() =>
      'At least one Windows shell recovery entry must remain enabled.';
}
