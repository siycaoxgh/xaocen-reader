import 'reader_input_bindings.dart';

/// Domain-only capture state. A captured physical input is returned to the
/// caller and never interpreted as a ReaderCommand.
final class ReaderInputCapture {
  bool _active = false;
  PhysicalInputId? _captured;

  bool get isActive => _active;
  PhysicalInputId? get captured => _captured;

  void startCapture() {
    _captured = null;
    _active = true;
  }

  void cancelCapture() {
    _active = false;
    _captured = null;
  }

  bool handle(PhysicalInputId input) {
    if (!_active) return false;
    _captured = input;
    _active = false;
    return true;
  }
}
