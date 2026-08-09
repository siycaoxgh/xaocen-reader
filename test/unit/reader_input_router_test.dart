import 'package:flutter_test/flutter_test.dart';

import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/reader_input_bindings_repository.dart';
import 'package:xaocen_reader/domain/reader/reader_input_bindings.dart';
import 'package:xaocen_reader/reader/reader_input_router.dart';

void main() {
  late AppDatabase db;
  late ReaderInputBindingsRepository repository;

  setUp(() {
    db = AppDatabase.forTesting();
    repository = ReaderInputBindingsRepository(db: db);
  });

  tearDown(() => db.close());

  test('default Windows profile routes page inputs through commands', () async {
    var previous = 0;
    var next = 0;
    final router = ReaderInputRouter(
      platform: ReaderInputPlatform.windows,
      onPreviousPage: () => previous++,
      onNextPage: () => next++,
    );
    await router.start();

    expect(
      router.handlePhysicalInput(PhysicalInputId.keyboardArrowLeft),
      isTrue,
    );
    expect(router.handlePhysicalInput(PhysicalInputId.mouseWheelDown), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(previous, 1);
    expect(next, 1);
    await router.dispose();
  });

  test('custom profile hot reloads without restarting the router', () async {
    var toc = 0;
    var nextChapter = 0;
    final router = ReaderInputRouter(
      platform: ReaderInputPlatform.windows,
      repository: repository,
      onOpenToc: () => toc++,
      onNextChapter: () => nextChapter++,
    );
    await router.start();
    await repository.update(
      ReaderInputPlatform.windows,
      ReaderInputProfile(
        platform: ReaderInputPlatform.windows,
        version: ReaderInputProfile.currentVersion,
        bindings: {
          PhysicalInputId.keyboardArrowLeft: ReaderCommand.openToc,
          PhysicalInputId.keyboardArrowRight: ReaderCommand.nextChapter,
        },
        updatedAt: DateTime(2030, 8, 9, 1),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));

    router.handlePhysicalInput(PhysicalInputId.keyboardArrowLeft);
    router.handlePhysicalInput(PhysicalInputId.keyboardArrowRight);
    await Future<void>.delayed(Duration.zero);
    expect(toc, 1);
    expect(nextChapter, 1);
    expect(router.generation, greaterThan(1));
    await router.dispose();
  });

  test('explicit null does not execute a command', () async {
    var count = 0;
    final router = ReaderInputRouter(
      platform: ReaderInputPlatform.windows,
      repository: repository,
      onPreviousPage: () => count++,
    );
    await repository.update(
      ReaderInputPlatform.windows,
      ReaderInputProfile(
        platform: ReaderInputPlatform.windows,
        version: ReaderInputProfile.currentVersion,
        bindings: {PhysicalInputId.keyboardArrowLeft: null},
        updatedAt: DateTime(2030, 8, 9, 1),
      ),
    );
    await router.start();
    expect(
      router.handlePhysicalInput(PhysicalInputId.keyboardArrowLeft),
      isFalse,
    );
    expect(count, 0);
    await router.dispose();
  });

  test(
    'capture consumes first input and never dispatches its command',
    () async {
      var count = 0;
      final states = <bool>[];
      final router = ReaderInputRouter(
        platform: ReaderInputPlatform.android,
        onPreviousPage: () => count++,
        onHostStateChanged: ({required pagedActive, required captureActive}) {
          states.add(captureActive);
        },
      );
      await router.start();
      router.startCapture();
      expect(router.capture.isActive, isTrue);
      expect(
        router.handlePhysicalInput(PhysicalInputId.androidVolumeUp),
        isTrue,
      );
      expect(router.capture.captured, PhysicalInputId.androidVolumeUp);
      expect(router.capture.isActive, isFalse);
      expect(count, 0);
      expect(states, [true, false]);
      await router.dispose();
    },
  );

  test(
    'cancel capture clears input and dispose invalidates later events',
    () async {
      final router = ReaderInputRouter(platform: ReaderInputPlatform.android);
      await router.start();
      router.startCapture();
      router.cancelCapture();
      expect(router.capture.captured, isNull);
      expect(router.capture.isActive, isFalse);
      await router.dispose();
      expect(
        router.handlePhysicalInput(PhysicalInputId.androidVolumeDown),
        isFalse,
      );
    },
  );

  test('mode generation invalidates a queued physical action', () async {
    var count = 0;
    final router = ReaderInputRouter(
      platform: ReaderInputPlatform.windows,
      onNextPage: () => count++,
    );
    await router.start();
    router.handlePhysicalInput(PhysicalInputId.keyboardArrowRight);
    router.setPagedActive(true);
    await Future<void>.delayed(Duration.zero);
    expect(count, 0);
    await router.dispose();
  });
}
