import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/reader/reader_screen_awake.dart';

final class _FakeTimer implements ReaderScreenAwakeTimer {
  _FakeTimer(this.callback);
  final void Function() callback;
  bool cancelled = false;

  @override
  void cancel() => cancelled = true;
}

final class _FakeScheduler implements ReaderScreenAwakeScheduler {
  _FakeTimer? timer;

  @override
  ReaderScreenAwakeTimer schedule(Duration delay, void Function() callback) {
    timer = _FakeTimer(callback);
    return timer!;
  }

  void fire() => timer?.callback();
}

void main() {
  test('follow system never owns keep-screen-on', () {
    final changes = <bool>[];
    final controller = ReaderScreenAwakeController(
      setKeepScreenOn: (value) async => changes.add(value),
    );

    controller.enterReader();

    expect(controller.keepScreenOn, isFalse);
    expect(changes, isEmpty);
  });

  test('while reading owns the flag only while Reader is active', () {
    final changes = <bool>[];
    final controller =
        ReaderScreenAwakeController(
          setKeepScreenOn: (value) async => changes.add(value),
        )..updatePreferences(
          mode: ReaderScreenAwakeMode.whileReading,
          inactivityMinutes: 30,
        );

    controller.enterReader();
    expect(controller.keepScreenOn, isTrue);
    controller.setLifecycle(ReaderScreenAwakeLifecycle.background);
    expect(controller.keepScreenOn, isFalse);
    controller.leaveReader();
    expect(changes, [true, false]);
  });

  test('smart mode timeout releases and pauses AutoRead once', () {
    final changes = <bool>[];
    final scheduler = _FakeScheduler();
    var timeoutCount = 0;
    var now = DateTime(2026, 1, 1);
    final controller =
        ReaderScreenAwakeController(
          setKeepScreenOn: (value) async => changes.add(value),
          onSmartTimeout: () => timeoutCount++,
          now: () => now,
          scheduler: scheduler,
        )..updatePreferences(
          mode: ReaderScreenAwakeMode.smart,
          inactivityMinutes: 15,
        );

    controller.enterReader();
    expect(controller.keepScreenOn, isTrue);
    now = now.add(const Duration(minutes: 15));
    scheduler.fire();

    expect(controller.keepScreenOn, isFalse);
    expect(timeoutCount, 1);
    scheduler.fire();
    expect(timeoutCount, 1);
    expect(changes, [true, false]);
  });

  test('smart real activity resets timer; automatic activity does not', () {
    final scheduler = _FakeScheduler();
    var now = DateTime(2026, 1, 1);
    var timeoutCount = 0;
    final controller =
        ReaderScreenAwakeController(
          setKeepScreenOn: (_) async {},
          onSmartTimeout: () => timeoutCount++,
          now: () => now,
          scheduler: scheduler,
        )..updatePreferences(
          mode: ReaderScreenAwakeMode.smart,
          inactivityMinutes: 15,
        );

    controller.enterReader();
    now = now.add(const Duration(minutes: 10));
    controller.recordAutomaticActivity();
    now = now.add(const Duration(minutes: 5));
    scheduler.fire();
    expect(timeoutCount, 1);

    controller.recordUserActivity();
    expect(controller.keepScreenOn, isTrue);
    expect(controller.lastRealUserActivity, isNotNull);
  });

  test('invalid timeout falls back to 30 minutes', () {
    final preferences =
        ReaderScreenAwakeController(setKeepScreenOn: (_) async {})
          ..updatePreferences(
            mode: ReaderScreenAwakeMode.smart,
            inactivityMinutes: 99,
          );
    expect(preferences.inactivityMinutes, 30);
  });
}
