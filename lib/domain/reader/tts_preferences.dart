/// App-level TTS preferences.  These settings are independent of a book's
/// Locator and are safe to reuse for future readable sources.
final class TtsPreferences {
  const TtsPreferences({
    this.speechRate = 1.0,
    this.voiceName,
    this.voiceLocale,
    this.voiceIdentifier,
    this.version = currentVersion,
  });

  static const int currentVersion = 1;
  static const double defaultSpeechRate = 1.0;
  static const double minSpeechRate = 0.5;
  static const double maxSpeechRate = 2.0;

  final double speechRate;
  final String? voiceName;
  final String? voiceLocale;
  final String? voiceIdentifier;
  final int version;

  TtsPreferences copyWith({
    double? speechRate,
    Object? voiceName = _unset,
    Object? voiceLocale = _unset,
    Object? voiceIdentifier = _unset,
    int? version,
  }) => TtsPreferences(
    speechRate: _clampRate(speechRate ?? this.speechRate),
    voiceName: voiceName == _unset ? this.voiceName : voiceName as String?,
    voiceLocale: voiceLocale == _unset
        ? this.voiceLocale
        : voiceLocale as String?,
    voiceIdentifier: voiceIdentifier == _unset
        ? this.voiceIdentifier
        : voiceIdentifier as String?,
    version: version ?? this.version,
  );

  static const Object _unset = Object();

  static double _clampRate(double value) =>
      value.isFinite ? value.clamp(minSpeechRate, maxSpeechRate).toDouble() : 1;
}
