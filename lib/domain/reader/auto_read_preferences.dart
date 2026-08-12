/// Global AutoRead pacing preferences.
///
/// Running state and position coordinates are deliberately not part of this
/// model. Vertical speed is stored as one canonical integer value; presets are
/// only convenient UI mappings to that value.
library;

/// Stable names are retained for JSON/source compatibility; labels are
/// localized as 极慢/慢/中/快/极快 in the UI.
enum VerticalSpeedPreset { slow, slower, standard, faster, fast }

extension VerticalSpeedPresetValues on VerticalSpeedPreset {
  int get velocityPixelsPerSecond => switch (this) {
    VerticalSpeedPreset.slow => 2,
    VerticalSpeedPreset.slower => 10,
    VerticalSpeedPreset.standard => 25,
    VerticalSpeedPreset.faster => 50,
    VerticalSpeedPreset.fast => 100,
  };

  static VerticalSpeedPreset? fromVelocity(int velocity) {
    for (final preset in VerticalSpeedPreset.values) {
      if (preset.velocityPixelsPerSecond == velocity) return preset;
    }
    return null;
  }
}

final class AutoReadPreferences {
  AutoReadPreferences._({
    required this.verticalVelocityPixelsPerSecond,
    required this.pagedIntervalSeconds,
    required this.version,
    required this.updatedAt,
  });

  static const int currentVersion = 2;
  static const int minVerticalVelocityPixelsPerSecond = 2;
  static const int maxVerticalVelocityPixelsPerSecond = 100;
  static const int defaultVerticalVelocityPixelsPerSecond = 25;
  static const VerticalSpeedPreset defaultVerticalSpeedPreset =
      VerticalSpeedPreset.standard;
  static const int defaultPagedIntervalSeconds = 5;
  static const int minPagedIntervalSeconds = 5;
  static const int maxPagedIntervalSeconds = 120;
  static const Set<int> supportedPagedIntervals = {120, 60, 30, 15, 5};

  static AutoReadPreferences get defaults => AutoReadPreferences._(
    verticalVelocityPixelsPerSecond: defaultVerticalVelocityPixelsPerSecond,
    pagedIntervalSeconds: defaultPagedIntervalSeconds,
    version: currentVersion,
    updatedAt: DateTime.now().toUtc(),
  );

  factory AutoReadPreferences({
    int? verticalVelocityPixelsPerSecond,
    // Kept as a source-compatible migration convenience for existing callers;
    // it is immediately converted to the canonical velocity value.
    VerticalSpeedPreset? verticalSpeedPreset,
    int pagedIntervalSeconds = defaultPagedIntervalSeconds,
    int version = currentVersion,
    DateTime? updatedAt,
  }) {
    final requested =
        verticalVelocityPixelsPerSecond ??
        verticalSpeedPreset?.velocityPixelsPerSecond ??
        defaultVerticalVelocityPixelsPerSecond;
    final velocity =
        requested >= minVerticalVelocityPixelsPerSecond &&
            requested <= maxVerticalVelocityPixelsPerSecond
        ? requested
        : defaultVerticalVelocityPixelsPerSecond;
    return AutoReadPreferences._(
      verticalVelocityPixelsPerSecond: velocity,
      pagedIntervalSeconds:
          pagedIntervalSeconds >= minPagedIntervalSeconds &&
              pagedIntervalSeconds <= maxPagedIntervalSeconds
          ? pagedIntervalSeconds
          : defaultPagedIntervalSeconds,
      version: currentVersion,
      updatedAt: (updatedAt ?? DateTime.now()).toUtc(),
    );
  }

  final int verticalVelocityPixelsPerSecond;
  final int pagedIntervalSeconds;
  final int version;
  final DateTime updatedAt;

  double get verticalVelocity => verticalVelocityPixelsPerSecond.toDouble();

  /// Returns a preset only when the canonical value exactly matches one.
  VerticalSpeedPreset? get verticalSpeedPreset =>
      VerticalSpeedPresetValues.fromVelocity(verticalVelocityPixelsPerSecond);

  AutoReadPreferences copyWith({
    int? verticalVelocityPixelsPerSecond,
    VerticalSpeedPreset? verticalSpeedPreset,
    int? pagedIntervalSeconds,
    int? version,
    DateTime? updatedAt,
  }) => AutoReadPreferences(
    verticalVelocityPixelsPerSecond:
        verticalVelocityPixelsPerSecond ??
        verticalSpeedPreset?.velocityPixelsPerSecond ??
        this.verticalVelocityPixelsPerSecond,
    pagedIntervalSeconds: pagedIntervalSeconds ?? this.pagedIntervalSeconds,
    version: version ?? this.version,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  bool operator ==(Object other) =>
      other is AutoReadPreferences &&
      other.verticalVelocityPixelsPerSecond ==
          verticalVelocityPixelsPerSecond &&
      other.pagedIntervalSeconds == pagedIntervalSeconds &&
      other.version == version;

  @override
  int get hashCode => Object.hash(
    verticalVelocityPixelsPerSecond,
    pagedIntervalSeconds,
    version,
  );
}
