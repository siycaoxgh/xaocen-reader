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
  toggleAutoRead,
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
  static const keyboardArrowUp = PhysicalInputId('keyboard.arrowUp');
  static const keyboardArrowDown = PhysicalInputId('keyboard.arrowDown');
  static const keyboardPageUp = PhysicalInputId('keyboard.pageUp');
  static const keyboardPageDown = PhysicalInputId('keyboard.pageDown');
  static const keyboardHome = PhysicalInputId('keyboard.home');
  static const keyboardEnd = PhysicalInputId('keyboard.end');
  static const keyboardSpace = PhysicalInputId('keyboard.space');
  static const keyboardEnter = PhysicalInputId('keyboard.enter');
  static const mouseWheelUp = PhysicalInputId('mouse.wheelUp');
  static const mouseWheelDown = PhysicalInputId('mouse.wheelDown');
  static const androidVolumeUp = PhysicalInputId('android.volumeUp');
  static const androidVolumeDown = PhysicalInputId('android.volumeDown');

  static const keyboardKeyA = PhysicalInputId('keyboard.keyA');
  static const keyboardKeyB = PhysicalInputId('keyboard.keyB');
  static const keyboardKeyC = PhysicalInputId('keyboard.keyC');
  static const keyboardKeyD = PhysicalInputId('keyboard.keyD');
  static const keyboardKeyE = PhysicalInputId('keyboard.keyE');
  static const keyboardKeyF = PhysicalInputId('keyboard.keyF');
  static const keyboardKeyG = PhysicalInputId('keyboard.keyG');
  static const keyboardKeyH = PhysicalInputId('keyboard.keyH');
  static const keyboardKeyI = PhysicalInputId('keyboard.keyI');
  static const keyboardKeyJ = PhysicalInputId('keyboard.keyJ');
  static const keyboardKeyK = PhysicalInputId('keyboard.keyK');
  static const keyboardKeyL = PhysicalInputId('keyboard.keyL');
  static const keyboardKeyM = PhysicalInputId('keyboard.keyM');
  static const keyboardKeyN = PhysicalInputId('keyboard.keyN');
  static const keyboardKeyO = PhysicalInputId('keyboard.keyO');
  static const keyboardKeyP = PhysicalInputId('keyboard.keyP');
  static const keyboardKeyQ = PhysicalInputId('keyboard.keyQ');
  static const keyboardKeyR = PhysicalInputId('keyboard.keyR');
  static const keyboardKeyS = PhysicalInputId('keyboard.keyS');
  static const keyboardKeyT = PhysicalInputId('keyboard.keyT');
  static const keyboardKeyU = PhysicalInputId('keyboard.keyU');
  static const keyboardKeyV = PhysicalInputId('keyboard.keyV');
  static const keyboardKeyW = PhysicalInputId('keyboard.keyW');
  static const keyboardKeyX = PhysicalInputId('keyboard.keyX');
  static const keyboardKeyY = PhysicalInputId('keyboard.keyY');
  static const keyboardKeyZ = PhysicalInputId('keyboard.keyZ');

  static const keyboardDigit0 = PhysicalInputId('keyboard.digit0');
  static const keyboardDigit1 = PhysicalInputId('keyboard.digit1');
  static const keyboardDigit2 = PhysicalInputId('keyboard.digit2');
  static const keyboardDigit3 = PhysicalInputId('keyboard.digit3');
  static const keyboardDigit4 = PhysicalInputId('keyboard.digit4');
  static const keyboardDigit5 = PhysicalInputId('keyboard.digit5');
  static const keyboardDigit6 = PhysicalInputId('keyboard.digit6');
  static const keyboardDigit7 = PhysicalInputId('keyboard.digit7');
  static const keyboardDigit8 = PhysicalInputId('keyboard.digit8');
  static const keyboardDigit9 = PhysicalInputId('keyboard.digit9');

  static const keyboardLetters = <PhysicalInputId>[
    keyboardKeyA,
    keyboardKeyB,
    keyboardKeyC,
    keyboardKeyD,
    keyboardKeyE,
    keyboardKeyF,
    keyboardKeyG,
    keyboardKeyH,
    keyboardKeyI,
    keyboardKeyJ,
    keyboardKeyK,
    keyboardKeyL,
    keyboardKeyM,
    keyboardKeyN,
    keyboardKeyO,
    keyboardKeyP,
    keyboardKeyQ,
    keyboardKeyR,
    keyboardKeyS,
    keyboardKeyT,
    keyboardKeyU,
    keyboardKeyV,
    keyboardKeyW,
    keyboardKeyX,
    keyboardKeyY,
    keyboardKeyZ,
  ];

  static const keyboardDigits = <PhysicalInputId>[
    keyboardDigit0,
    keyboardDigit1,
    keyboardDigit2,
    keyboardDigit3,
    keyboardDigit4,
    keyboardDigit5,
    keyboardDigit6,
    keyboardDigit7,
    keyboardDigit8,
    keyboardDigit9,
  ];

  static const windowsInputs = <PhysicalInputId>[
    keyboardArrowLeft,
    keyboardArrowRight,
    keyboardArrowUp,
    keyboardArrowDown,
    keyboardPageUp,
    keyboardPageDown,
    keyboardHome,
    keyboardEnd,
    keyboardSpace,
    keyboardEnter,
    ...keyboardLetters,
    ...keyboardDigits,
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

enum ReaderInputModifier { ctrl, alt, shift }

/// Canonical physical gesture. Modifiers are ordered and deduplicated so the
/// persisted representation is stable across platforms and reloads.
final class ReaderInputGesture {
  ReaderInputGesture({
    required this.primaryInput,
    Iterable<ReaderInputModifier> modifiers = const [],
  }) : modifiers = Set.unmodifiable(
         ReaderInputModifier.values.where(modifiers.toSet().contains),
       );

  ReaderInputGesture.single(PhysicalInputId input) : this(primaryInput: input);

  final PhysicalInputId primaryInput;
  final Set<ReaderInputModifier> modifiers;

  String get canonicalKey =>
      '${modifiers.map((modifier) => modifier.name).join('+')}'
      '${modifiers.isEmpty ? '' : '+'}${primaryInput.value}';

  bool get isPlain => modifiers.isEmpty;

  static ReaderInputGesture? parse(Object? raw) {
    if (raw is! Map) return null;
    final primary = PhysicalInputId.parse(raw['primary'] as String? ?? '');
    final rawModifiers = raw['modifiers'];
    if (primary == null || rawModifiers is! List) return null;
    final modifiers = <ReaderInputModifier>[];
    for (final value in rawModifiers) {
      if (value is! String) return null;
      ReaderInputModifier? modifier;
      for (final item in ReaderInputModifier.values) {
        if (item.name == value) modifier = item;
      }
      if (modifier == null) return null;
      modifiers.add(modifier);
    }
    return ReaderInputGesture(primaryInput: primary, modifiers: modifiers);
  }

  @override
  bool operator ==(Object other) =>
      other is ReaderInputGesture && canonicalKey == other.canonicalKey;

  @override
  int get hashCode => canonicalKey.hashCode;
}

final class ReaderInputProfile {
  ReaderInputProfile({
    required this.platform,
    required this.version,
    required Map<ReaderInputGesture, ReaderCommand?> bindings,
    required this.updatedAt,
  }) : bindings = Map.unmodifiable(bindings);

  static const currentVersion = 2;

  /// Commands exposed by the first Android input contract. Android devices
  /// have only the two volume keys as stable physical inputs; chapter and UI
  /// actions remain available to Windows and to the domain router.
  static const androidSupportedCommands = <ReaderCommand>{
    ReaderCommand.previousPage,
    ReaderCommand.nextPage,
    ReaderCommand.toggleAutoRead,
  };

  static bool supportsCommand(
    ReaderInputPlatform platform,
    ReaderCommand command,
  ) =>
      platform == ReaderInputPlatform.windows ||
      androidSupportedCommands.contains(command);

  final ReaderInputPlatform platform;
  final int version;
  final Map<ReaderInputGesture, ReaderCommand?> bindings;
  final DateTime updatedAt;

  factory ReaderInputProfile.defaults(
    ReaderInputPlatform platform, {
    DateTime? updatedAt,
  }) {
    final map = <ReaderInputGesture, ReaderCommand?>{};
    if (platform == ReaderInputPlatform.windows) {
      map.addAll({
        ReaderInputGesture.single(PhysicalInputId.keyboardArrowLeft):
            ReaderCommand.previousPage,
        ReaderInputGesture.single(PhysicalInputId.keyboardArrowRight):
            ReaderCommand.nextPage,
        ReaderInputGesture.single(PhysicalInputId.keyboardPageUp):
            ReaderCommand.previousPage,
        ReaderInputGesture.single(PhysicalInputId.keyboardPageDown):
            ReaderCommand.nextPage,
        ReaderInputGesture.single(PhysicalInputId.mouseWheelUp):
            ReaderCommand.previousPage,
        ReaderInputGesture.single(PhysicalInputId.mouseWheelDown):
            ReaderCommand.nextPage,
      });
    } else {
      map.addAll({
        ReaderInputGesture.single(PhysicalInputId.androidVolumeUp):
            ReaderCommand.previousPage,
        ReaderInputGesture.single(PhysicalInputId.androidVolumeDown):
            ReaderCommand.nextPage,
      });
    }
    return ReaderInputProfile(
      platform: platform,
      version: currentVersion,
      bindings: Map.unmodifiable(map),
      updatedAt: updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  ReaderCommand? commandFor(Object input) {
    final gesture = _asGesture(input);
    return gesture == null ? null : bindings[gesture];
  }

  bool hasBinding(Object input) {
    final gesture = _asGesture(input);
    return gesture != null && bindings.containsKey(gesture);
  }

  ReaderInputProfile copyWith({
    int? version,
    Map<ReaderInputGesture, ReaderCommand?>? bindings,
    DateTime? updatedAt,
  }) => ReaderInputProfile(
    platform: platform,
    version: version ?? this.version,
    bindings: Map.unmodifiable(bindings ?? this.bindings),
    updatedAt: updatedAt ?? this.updatedAt,
  );

  static ReaderInputGesture? _asGesture(Object? input) => switch (input) {
    ReaderInputGesture gesture => gesture,
    PhysicalInputId id => ReaderInputGesture.single(id),
    _ => null,
  };
}
