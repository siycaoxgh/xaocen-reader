import 'reader_input_bindings.dart';

enum ReaderInputCaptureStage { idle, capturing, candidate }

/// UI-independent capture state machine. Persistence is deliberately outside
/// this class: a candidate is only committed after the user confirms it.
final class ReaderInputCaptureWorkflow {
  ReaderInputCaptureStage _stage = ReaderInputCaptureStage.idle;
  ReaderInputGesture? _candidate;

  ReaderInputCaptureStage get stage => _stage;
  ReaderInputGesture? get candidate => _candidate;

  void start() {
    _candidate = null;
    _stage = ReaderInputCaptureStage.capturing;
  }

  bool capture(Object input) {
    if (_stage != ReaderInputCaptureStage.capturing) return false;
    _candidate = switch (input) {
      ReaderInputGesture gesture => gesture,
      PhysicalInputId id => ReaderInputGesture.single(id),
      _ => null,
    };
    if (_candidate == null) return false;
    _stage = ReaderInputCaptureStage.candidate;
    return true;
  }

  void retry() {
    _candidate = null;
    _stage = ReaderInputCaptureStage.capturing;
  }

  ReaderInputGesture? confirm() {
    if (_stage != ReaderInputCaptureStage.candidate) return null;
    final value = _candidate;
    _candidate = null;
    _stage = ReaderInputCaptureStage.idle;
    return value;
  }

  void cancel() {
    _candidate = null;
    _stage = ReaderInputCaptureStage.idle;
  }
}
