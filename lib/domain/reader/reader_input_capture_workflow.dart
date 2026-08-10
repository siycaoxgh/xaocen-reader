import 'reader_input_bindings.dart';

enum ReaderInputCaptureStage { idle, capturing, candidate }

/// UI-independent capture state machine. Persistence is deliberately outside
/// this class: a candidate is only committed after the user confirms it.
final class ReaderInputCaptureWorkflow {
  ReaderInputCaptureStage _stage = ReaderInputCaptureStage.idle;
  PhysicalInputId? _candidate;

  ReaderInputCaptureStage get stage => _stage;
  PhysicalInputId? get candidate => _candidate;

  void start() {
    _candidate = null;
    _stage = ReaderInputCaptureStage.capturing;
  }

  bool capture(PhysicalInputId input) {
    if (_stage != ReaderInputCaptureStage.capturing) return false;
    _candidate = input;
    _stage = ReaderInputCaptureStage.candidate;
    return true;
  }

  void retry() {
    _candidate = null;
    _stage = ReaderInputCaptureStage.capturing;
  }

  PhysicalInputId? confirm() {
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
