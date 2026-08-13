import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/platform/windows_eyedropper_controller.dart';

const _channel = MethodChannel('xaocen/windows_eyedropper');

Map<Object?, Object?> _sample(int x) => <Object?, Object?>{
      'x': x,
      'y': 20,
      'r': 125,
      'g': 166,
      'b': 216,
      'hex': '#7DA6D8',
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  test('picking is single-entry and confirmation returns to idle', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
      expect(call.method, 'startPicking');
      return true;
    });
    final controller = WindowsEyedropperController(channel: _channel);

    expect(await controller.start(), isTrue);
    expect(controller.state, WindowsEyedropperState.picking);
    expect(await controller.start(), isFalse);

    await controller.handleNativeEvent('sampleUpdated', _sample(10));
    expect(controller.currentSample?.x, 10);
    await controller.handleNativeEvent('confirmed', _sample(11));
    expect(controller.confirmedSample?.x, 11);
    expect(controller.state, WindowsEyedropperState.idle);
    expect(controller.completedTransitions, 1);
    controller.dispose();
  });

  test('cancel returns to idle without changing confirmed sample', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
      return call.method == 'startPicking';
    });
    final controller = WindowsEyedropperController(channel: _channel);

    expect(await controller.start(), isTrue);
    await controller.handleNativeEvent('cancelled', null);
    expect(controller.state, WindowsEyedropperState.idle);
    expect(controller.confirmedSample, isNull);
    expect(controller.completedTransitions, 1);
    controller.dispose();
  });
}
