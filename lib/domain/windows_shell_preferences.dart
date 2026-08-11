/// Windows shell visibility preferences. These are app-level settings and do
/// not belong to a book's ReaderPreferences.
final class WindowsShellPreferences {
  const WindowsShellPreferences({
    required this.showTaskbarIcon,
    required this.showTrayIcon,
    required this.updatedAt,
    this.version = currentVersion,
  });

  static const int currentVersion = 1;

  /// The taskbar entry is the recovery fallback when no tray entry exists.
  static final WindowsShellPreferences defaults = WindowsShellPreferences(
    showTaskbarIcon: true,
    showTrayIcon: false,
    updatedAt: _defaultUpdatedAt,
  );

  // Repositories replace this sentinel with the current timestamp when
  // persisting a real update.
  static final DateTime _defaultUpdatedAt = DateTime.utc(1970, 1, 1);

  final bool showTaskbarIcon;
  final bool showTrayIcon;
  final int version;
  final DateTime updatedAt;

  bool get hasRecoveryEntry => showTaskbarIcon || showTrayIcon;

  WindowsShellPreferences copyWith({
    bool? showTaskbarIcon,
    bool? showTrayIcon,
    int? version,
    DateTime? updatedAt,
  }) {
    return WindowsShellPreferences(
      showTaskbarIcon: showTaskbarIcon ?? this.showTaskbarIcon,
      showTrayIcon: showTrayIcon ?? this.showTrayIcon,
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WindowsShellPreferences &&
      other.showTaskbarIcon == showTaskbarIcon &&
      other.showTrayIcon == showTrayIcon &&
      other.version == version &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode =>
      Object.hash(showTaskbarIcon, showTrayIcon, version, updatedAt);
}

/// Strongly typed app-local gesture contract. The native runner never
/// installs a global hook; Flutter only recognizes this while its window is
/// focused.
enum WindowsShellGesture { leftAndRightMouseChord }

final class WindowsShellVisibilityException implements Exception {
  const WindowsShellVisibilityException();

  @override
  String toString() =>
      'At least one Windows shell recovery entry must remain enabled.';
}
