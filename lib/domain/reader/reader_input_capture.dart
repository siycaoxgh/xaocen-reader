import 'reader_input_bindings.dart';

/// Domain-only capture state. A captured physical input is returned to the
/// caller and never interpreted as a ReaderCommand.
final class ReaderInputCapture {
  bool _active = false;
  ReaderInputGesture? _capturedGesture;

  bool get isActive => _active;
  PhysicalInputId? get captured => _capturedGesture?.primaryInput;
  ReaderInputGesture? get capturedGesture => _capturedGesture;

  void startCapture() {
    _capturedGesture = null;
    _active = true;
  }

  void cancelCapture() {
    _active = false;
    _capturedGesture = null;
  }

  bool handle(PhysicalInputId input) {
    return handleGesture(ReaderInputGesture.single(input));
  }

  bool handleGesture(ReaderInputGesture gesture) {
    if (!_active) return false;
    _capturedGesture = gesture;
    _active = false;
    return true;
  }
}
