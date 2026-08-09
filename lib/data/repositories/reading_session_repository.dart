import 'package:drift/drift.dart';

import '../../domain/reader/reading_session.dart' as domain;
import '../database/app_database.dart';

class ReadingSessionRepository {
  // ignore: prefer_initializing_formals
  ReadingSessionRepository({required AppDatabase db}) : _db = db;

  final AppDatabase _db;

  Future<domain.ReadingSession> start({
    required String historyEntryId,
    DateTime? startedAt,
    String? platform,
    String? deviceId,
  }) async {
    final timestamp = startedAt ?? DateTime.now();
    final id = 'session-${timestamp.microsecondsSinceEpoch}';
    await _db.into(_db.readingSessions).insert(
      ReadingSessionsCompanion.insert(
        id: id,
        historyEntryId: historyEntryId,
        startedAt: timestamp,
        effectiveReadingSeconds: 0,
        platform: Value(platform),
        deviceId: Value(deviceId),
      ),
    );
    return (await get(id))!;
  }

  Future<domain.ReadingSession?> get(String id) async {
    final row = await (_db.select(_db.readingSessions)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _map(row);
  }

  Future<void> addEffectiveSeconds(String id, int seconds) async {
    if (seconds <= 0) return;
    await _db.customStatement(
      'UPDATE reading_sessions '
      'SET effective_reading_seconds = effective_reading_seconds + ? '
      'WHERE id = ?',
      [seconds, id],
    );
  }

  Future<void> finish(String id, DateTime endedAt) async {
    await (_db.update(_db.readingSessions)..where((t) => t.id.equals(id))).write(
      ReadingSessionsCompanion(endedAt: Value(endedAt)),
    );
  }

  Future<domain.ReadingSessionAggregate> aggregate(String historyEntryId) async {
    final row = await _db.customSelect(
      'SELECT COALESCE(SUM(effective_reading_seconds), 0) AS total_seconds, '
      'COUNT(*) AS session_count FROM reading_sessions '
      'WHERE history_entry_id = ?',
      variables: [Variable<String>(historyEntryId)],
    ).getSingle();
    return domain.ReadingSessionAggregate(
      totalReadingSeconds: row.read<int>('total_seconds'),
      sessionCount: row.read<int>('session_count'),
    );
  }

  Future<List<domain.ReadingSession>> loadForHistory(String historyEntryId) async {
    final rows = await (_db.select(_db.readingSessions)
          ..where((t) => t.historyEntryId.equals(historyEntryId))
          ..orderBy([(t) => OrderingTerm.asc(t.startedAt)]))
        .get();
    return rows.map(_map).toList(growable: false);
  }

  domain.ReadingSession _map(ReadingSession row) => domain.ReadingSession(
    id: row.id,
    historyEntryId: row.historyEntryId,
    startedAt: row.startedAt,
    endedAt: row.endedAt,
    effectiveReadingSeconds: row.effectiveReadingSeconds,
    platform: row.platform,
    deviceId: row.deviceId,
  );
}

/// In-memory lifecycle contract for one Reader route.
///
/// The session starts only after the first visible/page confirmation.  Pause
/// and resume only affect the effective duration; no idle timeout is used.
class ReadingSessionLifecycle {
  ReadingSessionLifecycle({
    required this.repository,
    required this.historyEntryId,
    DateTime Function()? clock,
    this.platform,
    this.deviceId,
  }) : _clock = clock ?? DateTime.now;

  final ReadingSessionRepository repository;
  final String historyEntryId;
  final DateTime Function() _clock;
  final String? platform;
  final String? deviceId;

  String? _sessionId;
  DateTime? _resumedAt;

  bool get hasStarted => _sessionId != null;
  bool get isActive => _resumedAt != null;

  Future<void> startAfterVisibleConfirm() async {
    if (hasStarted) return;
    final now = _clock();
    final session = await repository.start(
      historyEntryId: historyEntryId,
      startedAt: now,
      platform: platform,
      deviceId: deviceId,
    );
    _sessionId = session.id;
    _resumedAt = now;
  }

  Future<void> pause() async {
    final resumedAt = _resumedAt;
    final sessionId = _sessionId;
    if (resumedAt == null || sessionId == null) return;
    final seconds = _clock().difference(resumedAt).inSeconds;
    await repository.addEffectiveSeconds(sessionId, seconds);
    _resumedAt = null;
  }

  Future<void> resume() async {
    if (!hasStarted || isActive) return;
    _resumedAt = _clock();
  }

  Future<void> end() async {
    final sessionId = _sessionId;
    if (sessionId == null) return;
    await pause();
    await repository.finish(sessionId, _clock());
    _sessionId = null;
    _resumedAt = null;
  }
}
