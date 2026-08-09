/// One valid foreground Reader session.
class ReadingSession {
  const ReadingSession({
    required this.id,
    required this.historyEntryId,
    required this.startedAt,
    required this.endedAt,
    required this.effectiveReadingSeconds,
    required this.platform,
    required this.deviceId,
  });

  final String id;
  final String historyEntryId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int effectiveReadingSeconds;
  final String? platform;
  final String? deviceId;

  bool get isOpen => endedAt == null;
}

class ReadingSessionAggregate {
  const ReadingSessionAggregate({
    required this.totalReadingSeconds,
    required this.sessionCount,
  });

  final int totalReadingSeconds;
  final int sessionCount;
}
