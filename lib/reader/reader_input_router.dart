import 'dart:async';

import '../data/repositories/reader_input_bindings_repository.dart';
import '../domain/reader/reader_input_bindings.dart';
import '../domain/reader/reader_input_capture.dart';

typedef ReaderInputAction = FutureOr<void> Function();

/// The single semantic boundary between physical input and Reader actions.
/// It owns the current platform profile and rejects stale profile events.
final class ReaderInputRouter {
  ReaderInputRouter({
    required this.platform,
    this.repository,
    this.onPreviousPage,
    this.onNextPage,
    this.onPreviousChapter,
    this.onNextChapter,
    this.onToggleReaderControls,
    this.onOpenToc,
    this.onHostStateChanged,
  }) : _profile = ReaderInputProfile.defaults(platform);

  final ReaderInputPlatform platform;
  final ReaderInputBindingsRepository? repository;
  final ReaderInputAction? onPreviousPage;
  final ReaderInputAction? onNextPage;
  final ReaderInputAction? onPreviousChapter;
  final ReaderInputAction? onNextChapter;
  final ReaderInputAction? onToggleReaderControls;
  final ReaderInputAction? onOpenToc;
  final void Function({required bool pagedActive, required bool captureActive})?
  onHostStateChanged;

  final ReaderInputCapture capture = ReaderInputCapture();
  ReaderInputProfile _profile;
  StreamSubscription<ReaderInputProfile>? _subscription;
  DateTime? _latestProfileTimestamp;
  int _generation = 0;
  bool _disposed = false;
  bool _pagedActive = false;

  ReaderInputProfile get profile => _profile;
  int get generation => _generation;
  bool get pagedActive => _pagedActive;

  /// Invalidates events already queued by a previous Reader mode/lifecycle
  /// generation without changing the active profile.
  void invalidatePendingInput() {
    if (!_disposed) _generation++;
  }

  Future<void> start() async {
    if (_disposed) return;
    final loaded = repository == null
        ? ReaderInputProfile.defaults(platform)
        : await repository!.load(platform);
    if (_disposed) return;
    _acceptProfile(loaded);
    await _subscription?.cancel();
    if (repository != null && !_disposed) {
      _subscription = repository!.watch(platform).listen(_acceptProfile);
    }
  }

  void setPagedActive(bool active) {
    if (_disposed || _pagedActive == active) return;
    _pagedActive = active;
    _generation++;
    _notifyHostState();
  }

  void startCapture() {
    if (_disposed) return;
    capture.startCapture();
    _generation++;
    _notifyHostState();
  }

  void cancelCapture() {
    if (_disposed) return;
    capture.cancelCapture();
    _generation++;
    _notifyHostState();
  }

  /// Returns true when the input was consumed either by capture or by a
  /// command binding. During capture, no Reader action is dispatched.
  bool handlePhysicalInput(PhysicalInputId input) {
    if (_disposed) return false;
    if (capture.handle(input)) {
      _notifyHostState();
      return true;
    }
    final command = _profile.commandFor(input);
    if (command == null) return false;
    final action = switch (command) {
      ReaderCommand.previousPage => onPreviousPage,
      ReaderCommand.nextPage => onNextPage,
      ReaderCommand.previousChapter => onPreviousChapter,
      ReaderCommand.nextChapter => onNextChapter,
      ReaderCommand.toggleReaderControls => onToggleReaderControls,
      ReaderCommand.openToc => onOpenToc,
    };
    if (action == null) return false;
    final eventGeneration = _generation;
    unawaited(
      Future<void>.microtask(() async {
        if (_disposed || eventGeneration != _generation) return;
        await action();
      }),
    );
    return true;
  }

  void _acceptProfile(ReaderInputProfile next) {
    if (_disposed || next.platform != platform) return;
    final timestamp = next.updatedAt;
    if (_latestProfileTimestamp != null &&
        timestamp.isBefore(_latestProfileTimestamp!)) {
      return;
    }
    _latestProfileTimestamp = timestamp;
    _profile = next;
    _generation++;
  }

  void _notifyHostState() {
    onHostStateChanged?.call(
      pagedActive: _pagedActive,
      captureActive: capture.isActive,
    );
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    capture.cancelCapture();
    await _subscription?.cancel();
    _subscription = null;
    onHostStateChanged?.call(pagedActive: false, captureActive: false);
  }
}
