/// Global AutoRead pacing preferences.
///
/// These values describe how AutoRead should drive a Reader in the future;
/// they do not contain running state or any position coordinate.
library;

enum VerticalSpeedPreset { slow, slower, standard, faster, fast }

extension VerticalSpeedPresetValues on VerticalSpeedPreset {
  /// Initial pixels-per-second mapping for the vertical ticker.
  ///
  /// The mapping is deliberately runtime-derived. It is not persisted as a
  /// second source of truth alongside the preset.
  double get velocityPixelsPerSecond => switch (this) {
    VerticalSpeedPreset.slow => 18,
    VerticalSpeedPreset.slower => 28,
    VerticalSpeedPreset.standard => 40,
    VerticalSpeedPreset.faster => 56,
    VerticalSpeedPreset.fast => 76,
  };
}

final class AutoReadPreferences {
  AutoReadPreferences._({
    required this.verticalSpeedPreset,
    required this.pagedIntervalSeconds,
    required this.version,
    required this.updatedAt,
  });

  static const int currentVersion = 1;
  static const VerticalSpeedPreset defaultVerticalSpeedPreset =
      VerticalSpeedPreset.standard;
  static const int defaultPagedIntervalSeconds = 5;
  static const Set<int> supportedPagedIntervals = {3, 5, 8, 10, 15};

  static AutoReadPreferences get defaults => AutoReadPreferences._(
    verticalSpeedPreset: defaultVerticalSpeedPreset,
    pagedIntervalSeconds: defaultPagedIntervalSeconds,
    version: currentVersion,
    updatedAt: DateTime.now().toUtc(),
  );

  factory AutoReadPreferences({
    VerticalSpeedPreset verticalSpeedPreset = defaultVerticalSpeedPreset,
    int pagedIntervalSeconds = defaultPagedIntervalSeconds,
    int version = currentVersion,
    DateTime? updatedAt,
  }) => AutoReadPreferences._(
    verticalSpeedPreset: verticalSpeedPreset,
    pagedIntervalSeconds: supportedPagedIntervals.contains(pagedIntervalSeconds)
        ? pagedIntervalSeconds
        : defaultPagedIntervalSeconds,
    // A persisted model always emits the current canonical version. Older
    // inputs are migrated on read; future inputs are rejected by the
    // repository before they reach this constructor.
    version: currentVersion,
    updatedAt: (updatedAt ?? DateTime.now()).toUtc(),
  );

  final VerticalSpeedPreset verticalSpeedPreset;
  final int pagedIntervalSeconds;
  final int version;
  final DateTime updatedAt;

  double get verticalVelocityPixelsPerSecond =>
      verticalSpeedPreset.velocityPixelsPerSecond;

  AutoReadPreferences copyWith({
    VerticalSpeedPreset? verticalSpeedPreset,
    int? pagedIntervalSeconds,
    int? version,
    DateTime? updatedAt,
  }) => AutoReadPreferences(
    verticalSpeedPreset: verticalSpeedPreset ?? this.verticalSpeedPreset,
    pagedIntervalSeconds: pagedIntervalSeconds ?? this.pagedIntervalSeconds,
    version: version ?? this.version,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  bool operator ==(Object other) =>
      other is AutoReadPreferences &&
      other.verticalSpeedPreset == verticalSpeedPreset &&
      other.pagedIntervalSeconds == pagedIntervalSeconds &&
      other.version == version &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
    verticalSpeedPreset,
    pagedIntervalSeconds,
    version,
    updatedAt,
  );
}
