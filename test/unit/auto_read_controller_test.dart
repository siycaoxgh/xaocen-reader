import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/reader/auto_read_controller.dart';
import 'package:xaocen_reader/domain/reader/auto_read_preferences.dart';

void main() {
  test('state machine follows the idempotent AutoRead contract', () {
    final controller = AutoReadController();
    expect(controller.state, AutoReadState.idle);
    expect(controller.generation, 0);

    controller.start();
    expect(controller.state, AutoReadState.running);
    expect(controller.generation, 1);

    controller.start();
    expect(controller.generation, 1);
    controller.pause(AutoReadPauseReason.manualNavigation);
    expect(controller.state, AutoReadState.paused);
    expect(controller.generation, 2);

    controller.pause(AutoReadPauseReason.toc);
    expect(controller.generation, 2);
    controller.resume();
    expect(controller.state, AutoReadState.running);
    expect(controller.generation, 3);
    controller.stop();
    expect(controller.state, AutoReadState.idle);
    expect(controller.generation, 4);

    controller.stop();
    expect(controller.generation, 4);
    controller.dispose();
  });

  test('EOF state can be stopped and started again without persistence', () {
    final controller = AutoReadController();
    controller.start();
    controller.stopAtEnd();
    expect(controller.state, AutoReadState.stoppedAtEnd);
    controller.stop();
    expect(controller.state, AutoReadState.idle);
    controller.start();
    expect(controller.state, AutoReadState.running);
    controller.dispose();
  });

  test(
    'generation token invalidates stale work on transitions and preferences',
    () {
      final controller = AutoReadController();
      final initial = controller.captureGeneration();
      expect(controller.isCurrentGeneration(initial), isTrue);

      controller.start();
      expect(controller.isCurrentGeneration(initial), isFalse);
      final running = controller.captureGeneration();
      controller.updatePreferences(
        AutoReadPreferences(
          verticalSpeedPreset: VerticalSpeedPreset.fast,
          pagedIntervalSeconds: 15,
        ),
      );
      expect(controller.isCurrentGeneration(running), isFalse);
      final updated = controller.captureGeneration();
      controller.invalidate(AutoReadPauseReason.modeSwitch);
      expect(controller.isCurrentGeneration(updated), isFalse);
      final invalidated = controller.captureGeneration();
      controller.pause(AutoReadPauseReason.relayout);
      expect(controller.isCurrentGeneration(invalidated), isFalse);
      controller.dispose();
      expect(controller.isCurrentGeneration(controller.generation), isFalse);
    },
  );

  test('events are typed and include pause reason', () async {
    final controller = AutoReadController();
    final events = <AutoReadEvent>[];
    final subscription = controller.events.listen(events.add);
    controller.start();
    controller.pause(AutoReadPauseReason.settingsPanel);
    controller.updatePreferences(AutoReadPreferences(pagedIntervalSeconds: 10));
    expect(events, hasLength(3));
    expect(events[0].kind, AutoReadEventKind.stateChanged);
    expect(events[1].pauseReason, AutoReadPauseReason.settingsPanel);
    expect(events[2].kind, AutoReadEventKind.preferencesChanged);
    await subscription.cancel();
    controller.dispose();
  });

  test('dispose is idempotent and prevents future transitions', () {
    final controller = AutoReadController();
    controller.dispose();
    controller.dispose();
    controller.start();
    controller.updatePreferences(AutoReadPreferences(pagedIntervalSeconds: 5));
    expect(controller.state, AutoReadState.idle);
    expect(controller.generation, 1);
  });

  test('a new controller starts idle even when preferences are restored', () {
    final first = AutoReadController(
      preferences: AutoReadPreferences(pagedIntervalSeconds: 10),
    );
    first.start();
    final restoredPreferences = first.preferences;
    first.dispose();

    final restarted = AutoReadController(preferences: restoredPreferences);
    expect(restarted.state, AutoReadState.idle);
    expect(restarted.preferences.pagedIntervalSeconds, 10);
    restarted.dispose();
  });

  test('metadata timestamp does not invalidate effective preferences', () {
    final controller = AutoReadController();
    final generation = controller.generation;
    controller.updatePreferences(
      AutoReadPreferences(
        updatedAt: DateTime.now().add(const Duration(days: 1)),
      ),
    );
    expect(controller.generation, generation);
    controller.dispose();
  });
}
