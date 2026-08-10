import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/reader/reader_input_bindings.dart';
import 'package:xaocen_reader/domain/reader/reader_input_capture_workflow.dart';

void main() {
  test('candidate is held until confirm', () {
    final workflow = ReaderInputCaptureWorkflow();
    workflow.start();
    expect(workflow.stage, ReaderInputCaptureStage.capturing);
    expect(workflow.capture(PhysicalInputId.keyboardKeyA), isTrue);
    expect(workflow.stage, ReaderInputCaptureStage.candidate);
    expect(
      workflow.confirm(),
      ReaderInputGesture.single(PhysicalInputId.keyboardKeyA),
    );
    expect(workflow.stage, ReaderInputCaptureStage.idle);
  });

  test('retry discards old candidate and cancel never commits it', () {
    final workflow = ReaderInputCaptureWorkflow();
    workflow.start();
    workflow.capture(PhysicalInputId.keyboardSpace);
    workflow.retry();
    expect(workflow.candidate, isNull);
    expect(workflow.stage, ReaderInputCaptureStage.capturing);
    workflow.capture(PhysicalInputId.keyboardEnter);
    workflow.cancel();
    expect(workflow.confirm(), isNull);
    expect(workflow.stage, ReaderInputCaptureStage.idle);
  });

  test('input outside candidate stage is ignored', () {
    final workflow = ReaderInputCaptureWorkflow();
    expect(workflow.capture(PhysicalInputId.mouseWheelUp), isFalse);
    workflow.start();
    expect(workflow.capture(PhysicalInputId.mouseWheelUp), isTrue);
    expect(workflow.capture(PhysicalInputId.mouseWheelDown), isFalse);
    expect(
      workflow.candidate,
      ReaderInputGesture.single(PhysicalInputId.mouseWheelUp),
    );
  });
}
