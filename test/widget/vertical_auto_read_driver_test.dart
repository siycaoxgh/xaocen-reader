import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/reader/auto_read_controller.dart';
import 'package:xaocen_reader/domain/reader/auto_read_preferences.dart';
import 'package:xaocen_reader/reader/vertical_auto_read_driver.dart';

void main() {
  testWidgets('ticker scrolls smoothly and auto frames do not self-pause', (
    tester,
  ) async {
    final key = GlobalKey<_AutoReadHarnessState>();
    await tester.pumpWidget(
      MaterialApp(
        home: _AutoReadHarness(
          key: key,
          preferences: AutoReadPreferences(
            verticalSpeedPreset: VerticalSpeedPreset.standard,
          ),
        ),
      ),
    );
    await tester.pump();

    final state = key.currentState!;
    state.driver.start();
    await tester.pump(const Duration(milliseconds: 100));
    final first = state.scroll.position.pixels;
    await tester.pump(const Duration(milliseconds: 100));
    final second = state.scroll.position.pixels;

    expect(first, 0);
    expect(second, greaterThan(first));
    expect(state.controller.state, AutoReadState.running);
    expect(state.autoFrames, greaterThan(0));
    expect(state.framesObservedAsGuarded, state.autoFrames);
  });

  testWidgets('pause and stop perform a final position confirmation', (
    tester,
  ) async {
    final key = GlobalKey<_AutoReadHarnessState>();
    await tester.pumpWidget(MaterialApp(home: _AutoReadHarness(key: key)));
    await tester.pump();
    final state = key.currentState!;

    state.driver.start();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    state.driver.pause(AutoReadPauseReason.manualNavigation);
    await tester.pump();
    expect(state.controller.state, AutoReadState.paused);
    expect(state.confirmations, greaterThanOrEqualTo(1));

    state.driver.stop();
    await tester.pump();
    expect(state.controller.state, AutoReadState.idle);
    expect(state.confirmations, greaterThanOrEqualTo(2));
  });

  testWidgets('interrupt pauses and invalidates stale ticker work', (
    tester,
  ) async {
    final key = GlobalKey<_AutoReadHarnessState>();
    await tester.pumpWidget(MaterialApp(home: _AutoReadHarness(key: key)));
    await tester.pump();
    final state = key.currentState!;
    state.driver.start();
    await tester.pump(const Duration(milliseconds: 100));
    final generation = state.controller.generation;
    state.driver.interrupt(AutoReadPauseReason.modeSwitch);
    await tester.pump();
    expect(state.controller.state, AutoReadState.paused);
    expect(state.controller.generation, greaterThan(generation));
    expect(state.driver.isTicking, isFalse);
  });

  testWidgets('real scroll extent reaches stoppedAtEnd without looping', (
    tester,
  ) async {
    final key = GlobalKey<_AutoReadHarnessState>();
    await tester.pumpWidget(
      MaterialApp(
        home: _AutoReadHarness(
          key: key,
          itemCount: 8,
          itemExtent: 40,
          preferences: AutoReadPreferences(
            verticalSpeedPreset: VerticalSpeedPreset.fast,
          ),
        ),
      ),
    );
    await tester.pump();
    final state = key.currentState!;
    state.driver.start();
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (state.controller.state == AutoReadState.stoppedAtEnd) break;
    }
    expect(state.controller.state, AutoReadState.stoppedAtEnd);
    final atEnd = state.scroll.position.pixels;
    await tester.pump(const Duration(seconds: 1));
    expect(state.scroll.position.pixels, atEnd);
  });
}

class _AutoReadHarness extends StatefulWidget {
  const _AutoReadHarness({
    super.key,
    this.itemCount = 100,
    this.itemExtent = 80,
    this.preferences,
  });

  final int itemCount;
  final double itemExtent;
  final AutoReadPreferences? preferences;

  @override
  State<_AutoReadHarness> createState() => _AutoReadHarnessState();
}

class _AutoReadHarnessState extends State<_AutoReadHarness>
    with SingleTickerProviderStateMixin {
  late final ScrollController scroll = ScrollController();
  late final AutoReadController controller = AutoReadController(
    preferences: widget.preferences,
  );
  late final VerticalAutoReadDriver driver = VerticalAutoReadDriver(
    vsync: this,
    scrollController: scroll,
    controller: controller,
    canDrive: () => mounted,
    confirmPosition: () async {
      confirmations++;
    },
    onFrame: () {
      autoFrames++;
      if (driver.isApplyingAutoScroll) framesObservedAsGuarded++;
    },
  );

  int confirmations = 0;
  int autoFrames = 0;
  int framesObservedAsGuarded = 0;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 200,
    child: ListView.builder(
      controller: scroll,
      itemCount: widget.itemCount,
      itemExtent: widget.itemExtent,
      itemBuilder: (_, index) => Text('line $index'),
    ),
  );

  @override
  void dispose() {
    driver.dispose();
    controller.dispose();
    scroll.dispose();
    super.dispose();
  }
}
