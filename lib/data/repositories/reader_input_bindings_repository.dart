import 'dart:convert';

import '../../domain/reader/reader_input_bindings.dart';
import '../database/app_database.dart';

/// Strongly typed boundary for platform-level Reader input bindings.
///
/// The app_settings key and JSON representation are intentionally private to
/// this repository. UI and Reader code consume only [ReaderInputProfile].
final class ReaderInputBindingsRepository {
  ReaderInputBindingsRepository({required this._db});

  final AppDatabase _db;

  Future<ReaderInputProfile> load(ReaderInputPlatform platform) async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((t) => t.key.equals(_key(platform)))).getSingleOrNull();
    return _decode(row?.value, platform);
  }

  Stream<ReaderInputProfile> watch(ReaderInputPlatform platform) =>
      (_db.select(_db.appSettings)..where((t) => t.key.equals(_key(platform))))
          .watchSingleOrNull()
          .map((row) => _decode(row?.value, platform));

  Future<void> bind(
    ReaderInputPlatform platform,
    Object input,
    ReaderCommand command,
  ) async {
    final gesture = _gestureOf(input);
    if (gesture == null || gesture.primaryInput.platform != platform) return;
    if (!ReaderInputProfile.supportsCommand(platform, command)) return;
    final current = await load(platform);
    await update(
      platform,
      current.copyWith(
        bindings: {...current.bindings, gesture: command},
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> unbind(ReaderInputPlatform platform, Object input) async {
    final gesture = _gestureOf(input);
    if (gesture == null || gesture.primaryInput.platform != platform) return;
    final current = await load(platform);
    await update(
      platform,
      current.copyWith(
        bindings: {...current.bindings, gesture: null},
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> update(
    ReaderInputPlatform platform,
    ReaderInputProfile profile,
  ) async {
    if (profile.platform != platform) {
      throw ArgumentError.value(profile.platform, 'profile.platform');
    }
    final normalized = _normalize(profile, platform);
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: _key(platform),
            value: jsonEncode(_encode(normalized)),
            updatedAt: normalized.updatedAt,
          ),
        );
  }

  Future<void> setAndroidAutoReadAction(
    PhysicalInputId input,
    AndroidAutoReadVolumeAction action,
  ) async {
    if (input.platform != ReaderInputPlatform.android) return;
    final current = await load(ReaderInputPlatform.android);
    await update(
      ReaderInputPlatform.android,
      current.copyWith(
        autoReadVolumeActions: {
          ...current.autoReadVolumeActions,
          input: action,
        },
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> resetToDefaults(ReaderInputPlatform platform) async {
    await (_db.delete(
      _db.appSettings,
    )..where((t) => t.key.equals(_key(platform)))).go();
  }

  String _key(ReaderInputPlatform platform) =>
      'reader.inputBindings.${platform.name}.v1';

  Map<String, Object?> _encode(ReaderInputProfile profile) => {
    'version': profile.version,
    'platform': profile.platform.name,
    'updatedAt': profile.updatedAt.toUtc().toIso8601String(),
    'bindings': [
      for (final entry in profile.bindings.entries)
        {
          'primary': entry.key.primaryInput.value,
          'modifiers': entry.key.modifiers.map((item) => item.name).toList(),
          'command': entry.value?.name,
        },
    ],
    'autoReadVolumeActions': {
      for (final entry in profile.autoReadVolumeActions.entries)
        entry.key.value: entry.value.name,
    },
  };

  ReaderInputProfile _decode(String? raw, ReaderInputPlatform platform) {
    final defaults = ReaderInputProfile.defaults(
      platform,
      updatedAt: DateTime.now(),
    );
    if (raw == null || raw.isEmpty) return defaults;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return defaults;
      final version = decoded['version'];
      final storedPlatform = decoded['platform'];
      final rawBindings = decoded['bindings'];
      if (version is! int || storedPlatform != platform.name) {
        return defaults;
      }
      final merged = <ReaderInputGesture, ReaderCommand?>{...defaults.bindings};
      final autoReadActions = <PhysicalInputId,
          AndroidAutoReadVolumeAction>{...defaults.autoReadVolumeActions};
      final rawAutoReadActions = decoded['autoReadVolumeActions'];
      if (rawAutoReadActions is Map && platform == ReaderInputPlatform.android) {
        for (final entry in rawAutoReadActions.entries) {
          final input = PhysicalInputId.parse(entry.key.toString());
          final action = _parseAutoReadAction(entry.value);
          if (input != null && action != null &&
              input.platform == ReaderInputPlatform.android) {
            autoReadActions[input] = action;
          }
        }
      }
      if (rawBindings is Map) {
        // Version 1 stored a map keyed by the plain PhysicalInputId string.
        for (final entry in rawBindings.entries) {
          if (entry.key is! String) continue;
          final input = PhysicalInputId.parse(entry.key as String);
          if (input == null || input.platform != platform) continue;
          final command = _parseNullableCommand(entry.value);
          if (entry.value == null) {
            merged[ReaderInputGesture.single(input)] = command;
          } else if (command != null &&
              ReaderInputProfile.supportsCommand(platform, command)) {
            merged[ReaderInputGesture.single(input)] = command;
          }
        }
      } else if (rawBindings is List) {
        for (final rawEntry in rawBindings) {
          if (rawEntry is! Map) continue;
          final gesture = ReaderInputGesture.parse(rawEntry);
          if (gesture == null || gesture.primaryInput.platform != platform) {
            continue;
          }
          final command = _parseNullableCommand(rawEntry['command']);
          if (rawEntry['command'] == null) {
            merged[gesture] = command;
          } else if (command != null &&
              ReaderInputProfile.supportsCommand(platform, command)) {
            merged[gesture] = command;
          }
        }
      } else {
        return defaults;
      }
      final migrated = version < ReaderInputProfile.currentVersion
          ? ReaderInputProfile.currentVersion
          : version;
      final timestamp = _parseDate(decoded['updatedAt']) ?? defaults.updatedAt;
      return ReaderInputProfile(
        platform: platform,
        version: migrated,
        bindings: Map.unmodifiable(merged),
        autoReadVolumeActions: Map.unmodifiable(autoReadActions),
        updatedAt: timestamp,
      );
    } catch (_) {
      return defaults;
    }
  }

  ReaderInputProfile _normalize(
    ReaderInputProfile profile,
    ReaderInputPlatform platform,
  ) {
    final defaults = ReaderInputProfile.defaults(platform);
    final bindings = <ReaderInputGesture, ReaderCommand?>{...defaults.bindings};
    for (final entry in profile.bindings.entries) {
      if (entry.key.primaryInput.platform == platform &&
          (entry.value == null ||
              ReaderInputProfile.supportsCommand(platform, entry.value!))) {
        bindings[entry.key] = entry.value;
      }
    }
    return ReaderInputProfile(
      platform: platform,
      version: ReaderInputProfile.currentVersion,
      bindings: Map.unmodifiable(bindings),
      autoReadVolumeActions: profile.autoReadVolumeActions,
      updatedAt: profile.updatedAt,
    );
  }

  ReaderCommand? _parseNullableCommand(Object? value) {
    if (value is! String) return null;
    for (final command in ReaderCommand.values) {
      if (command.name == value) return command;
    }
    return null;
  }

  AndroidAutoReadVolumeAction? _parseAutoReadAction(Object? value) {
    if (value is! String) return null;
    for (final action in AndroidAutoReadVolumeAction.values) {
      if (action.name == value) return action;
    }
    return null;
  }

  DateTime? _parseDate(Object? value) => switch (value) {
    String value => DateTime.tryParse(value),
    _ => null,
  };

  ReaderInputGesture? _gestureOf(Object input) => switch (input) {
    ReaderInputGesture gesture => gesture,
    PhysicalInputId id => ReaderInputGesture.single(id),
    _ => null,
  };
}
