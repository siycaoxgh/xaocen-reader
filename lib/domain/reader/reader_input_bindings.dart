/// Pure domain contract for user-configurable Reader input bindings.
library;

enum ReaderInputPlatform { windows, android }

enum ReaderCommand {
  previousPage,
  nextPage,
  previousChapter,
  nextChapter,
  toggleReaderControls,
  openToc,
}

/// Stable persisted physical-input identifier.
///
/// The value is deliberately a string owned by the domain contract. It is not
/// a Flutter key object, Android keyCode, or any other runtime platform value.
final class PhysicalInputId {
  const PhysicalInputId(this.value);

  final String value;

  static const keyboardArrowLeft = PhysicalInputId('keyboard.arrowLeft');
  static const keyboardArrowRight = PhysicalInputId('keyboard.arrowRight');
  static const keyboardPageUp = PhysicalInputId('keyboard.pageUp');
  static const keyboardPageDown = PhysicalInputId('keyboard.pageDown');
  static const mouseWheelUp = PhysicalInputId('mouse.wheelUp');
  static const mouseWheelDown = PhysicalInputId('mouse.wheelDown');
  static const androidVolumeUp = PhysicalInputId('android.volumeUp');
  static const androidVolumeDown = PhysicalInputId('android.volumeDown');

  static const windowsInputs = <PhysicalInputId>[
    keyboardArrowLeft,
    keyboardArrowRight,
    keyboardPageUp,
    keyboardPageDown,
    mouseWheelUp,
    mouseWheelDown,
  ];

  static const androidInputs = <PhysicalInputId>[
    androidVolumeUp,
    androidVolumeDown,
  ];

  static const all = <PhysicalInputId>[...windowsInputs, ...androidInputs];

  static PhysicalInputId? parse(String value) {
    for (final input in all) {
      if (input.value == value) return input;
    }
    return null;
  }

  ReaderInputPlatform? get platform {
    if (windowsInputs.contains(this)) return ReaderInputPlatform.windows;
    if (androidInputs.contains(this)) return ReaderInputPlatform.android;
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is PhysicalInputId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

final class ReaderInputProfile {
  const ReaderInputProfile({
    required this.platform,
    required this.version,
    required this.bindings,
    required this.updatedAt,
  });

  static const currentVersion = 1;

  final ReaderInputPlatform platform;
  final int version;
  final Map<PhysicalInputId, ReaderCommand?> bindings;
  final DateTime updatedAt;

  factory ReaderInputProfile.defaults(
    ReaderInputPlatform platform, {
    DateTime? updatedAt,
  }) {
    final map = <PhysicalInputId, ReaderCommand?>{};
    if (platform == ReaderInputPlatform.windows) {
      map.addAll({
        PhysicalInputId.keyboardArrowLeft: ReaderCommand.previousPage,
        PhysicalInputId.keyboardArrowRight: ReaderCommand.nextPage,
        PhysicalInputId.keyboardPageUp: ReaderCommand.previousPage,
        PhysicalInputId.keyboardPageDown: ReaderCommand.nextPage,
        PhysicalInputId.mouseWheelUp: ReaderCommand.previousPage,
        PhysicalInputId.mouseWheelDown: ReaderCommand.nextPage,
      });
    } else {
      map.addAll({
        PhysicalInputId.androidVolumeUp: ReaderCommand.previousPage,
        PhysicalInputId.androidVolumeDown: ReaderCommand.nextPage,
      });
    }
    return ReaderInputProfile(
      platform: platform,
      version: currentVersion,
      bindings: Map.unmodifiable(map),
      updatedAt: updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  ReaderCommand? commandFor(PhysicalInputId input) => bindings[input];

  bool hasBinding(PhysicalInputId input) => bindings.containsKey(input);

  ReaderInputProfile copyWith({
    int? version,
    Map<PhysicalInputId, ReaderCommand?>? bindings,
    DateTime? updatedAt,
  }) => ReaderInputProfile(
    platform: platform,
    version: version ?? this.version,
    bindings: Map.unmodifiable(bindings ?? this.bindings),
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
