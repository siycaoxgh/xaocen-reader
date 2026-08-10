import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/reading_progress_repository.dart';
import 'package:xaocen_reader/domain/reader/auto_read_controller.dart';
import 'package:xaocen_reader/domain/reader/auto_read_preferences.dart';
import 'package:xaocen_reader/domain/reader/reader_block.dart';
import 'package:xaocen_reader/domain/reader/reader_locator.dart';
import 'package:xaocen_reader/reader/normalized_document_loader.dart';
import 'package:xaocen_reader/reader/paged_auto_read_driver.dart';
import 'package:xaocen_reader/reader/paged_reader_controller.dart';

void main() {
  late AppDatabase db;
  late ReadingProgressRepository progressRepository;

  setUp(() async {
    db = AppDatabase.forTesting();
    progressRepository = ReadingProgressRepository(db: db);
    final now = DateTime.now();
    await db
        .into(db.contentSources)
        .insert(
          ContentSourcesCompanion.insert(
            id: 'auto-read-source',
            type: 'localTxt',
            displayName: 'AutoRead test source',
            contentHash: 'auto-read',
            managedSourcePath: 'library/auto-read/source.txt',
            sourceSize: 1,
            detectedEncoding: 'utf8',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db
        .into(db.contentCollections)
        .insert(
          ContentCollectionsCompanion.insert(
            id: 'auto-read-book',
            sourceId: 'auto-read-source',
            title: 'AutoRead test book',
            itemCount: 1,
            normalizedCharacterLength: 1000000,
            importedAt: now,
            updatedAt: now,
          ),
        );
  });

  tearDown(() => db.close());

  PagedReaderController makeReader({int characters = 60000}) {
    final text = ('一段用于分页自动阅读验证的正文。' * characters);
    final document = NormalizedDocument(
      text: text,
      normalizedHash: 'auto-read',
      normalizationVersion: 'v1',
      parserVersion: 'v1',
      indexFormatVersion: 'v1',
      sourceFileName: 'auto-read.txt',
    );
    final blockIndex = ReaderBlockIndex.build(
      text: text,
      targetBlockSize: 6144,
    );
    final reader = PagedReaderController(
      collectionId: 'auto-read-book',
      document: document,
      progressRepository: progressRepository,
      blockIndex: blockIndex,
      style: const TextStyle(fontSize: 10, height: 1),
      width: 400,
      height: 600,
      previousWindowPages: 2,
      nextWindowPages: 3,
    );
    reader.open(
      const ReaderLocator(
        collectionId: 'auto-read-book',
        absoluteCharacterOffset: 0,
      ),
    );
    return reader;
  }

  testWidgets(
    'paged driver advances through bounded window and pauses safely',
    (tester) async {
      final reader = makeReader();
      final controller = AutoReadController(
        preferences: AutoReadPreferences(pagedIntervalSeconds: 3),
      );
      var confirmations = 0;
      final driver = PagedAutoReadDriver(
        readerController: reader,
        controller: controller,
        intervalOverride: const Duration(milliseconds: 10),
        canDrive: () => true,
        confirmPosition: () async => confirmations++,
      );
      addTearDown(() {
        driver.dispose();
        reader.dispose();
        controller.dispose();
      });

      final first = reader.currentPage!.startCharacterOffset;
      driver.start();
      await tester.pump(const Duration(milliseconds: 11));
      await tester.pump();
      expect(reader.currentPage!.startCharacterOffset, greaterThan(first));
      expect(controller.state, AutoReadState.running);
      expect(reader.window.pageCount, lessThanOrEqualTo(6));

      driver.pauseForManualNavigation();
      await tester.pump();
      final pausedAt = reader.currentPage!.startCharacterOffset;
      await tester.pump(const Duration(seconds: 1));
      expect(reader.currentPage!.startCharacterOffset, pausedAt);
      expect(controller.state, AutoReadState.paused);
      expect(confirmations, greaterThanOrEqualTo(2));
    },
  );

  testWidgets('preference generation replaces stale interval timer', (
    tester,
  ) async {
    final reader = makeReader();
    final controller = AutoReadController(
      preferences: AutoReadPreferences(pagedIntervalSeconds: 3),
    );
    final driver = PagedAutoReadDriver(
      readerController: reader,
      controller: controller,
      intervalOverride: null,
      canDrive: () => true,
      confirmPosition: () async {},
    );
    addTearDown(() {
      driver.dispose();
      reader.dispose();
      controller.dispose();
    });

    driver.start();
    controller.updatePreferences(AutoReadPreferences(pagedIntervalSeconds: 15));
    await tester.pump(const Duration(seconds: 3));
    expect(reader.currentPage!.startCharacterOffset, 0);
    await tester.pump(const Duration(seconds: 12));
    await tester.pump();
    expect(reader.currentPage!.startCharacterOffset, greaterThan(0));
    driver.stop();
    await tester.pump();
    await reader.flush();
  });

  testWidgets('pause, resume, and stop keep one paged auto-read run', (
    tester,
  ) async {
    final reader = makeReader();
    final controller = AutoReadController();
    final driver = PagedAutoReadDriver(
      readerController: reader,
      controller: controller,
      intervalOverride: const Duration(milliseconds: 10),
      canDrive: () => true,
      confirmPosition: () async {},
    );
    addTearDown(() {
      driver.dispose();
      reader.dispose();
      controller.dispose();
    });

    driver.start();
    await tester.pump(const Duration(milliseconds: 11));
    final afterStart = reader.currentPage!.startCharacterOffset;
    expect(controller.state, AutoReadState.running);

    driver.pauseForManualNavigation();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.state, AutoReadState.paused);
    expect(reader.currentPage!.startCharacterOffset, afterStart);

    driver.resume();
    await tester.pump(const Duration(milliseconds: 11));
    expect(controller.state, AutoReadState.running);
    expect(reader.currentPage!.startCharacterOffset, greaterThan(afterStart));

    driver.stop();
    await tester.pump(const Duration(seconds: 1));
    expect(controller.state, AutoReadState.idle);
    await reader.flush();
  });

  testWidgets('interrupt pauses and invalidates pending paged ticks', (
    tester,
  ) async {
    final reader = makeReader();
    final controller = AutoReadController();
    final driver = PagedAutoReadDriver(
      readerController: reader,
      controller: controller,
      intervalOverride: const Duration(milliseconds: 10),
      canDrive: () => true,
      confirmPosition: () async {},
    );
    addTearDown(() {
      driver.dispose();
      reader.dispose();
      controller.dispose();
    });

    driver.start();
    final generation = controller.generation;
    driver.interrupt(AutoReadPauseReason.modeSwitch);
    await tester.pump(const Duration(seconds: 1));
    expect(controller.state, AutoReadState.paused);
    expect(controller.generation, greaterThan(generation));
    expect(reader.currentPage!.startCharacterOffset, 0);
    await reader.flush();
  });

  testWidgets(
    'navigation operation is serialized while confirmation is pending',
    (tester) async {
      final reader = makeReader();
      final controller = AutoReadController();
      final confirmationGate = Completer<void>();
      var confirmationCount = 0;
      final driver = PagedAutoReadDriver(
        readerController: reader,
        controller: controller,
        intervalOverride: const Duration(milliseconds: 10),
        canDrive: () => true,
        confirmPosition: () async {
          confirmationCount++;
          if (confirmationCount == 1) await confirmationGate.future;
        },
      );
      addTearDown(() {
        driver.dispose();
        reader.dispose();
        controller.dispose();
      });

      driver.start();
      await tester.pump(const Duration(milliseconds: 11));
      final firstTurn = reader.currentPage!.startCharacterOffset;
      expect(driver.isNavigationInFlight, isTrue);
      await tester.pump(const Duration(milliseconds: 100));
      expect(reader.currentPage!.startCharacterOffset, firstTurn);
      expect(confirmationCount, 1);

      confirmationGate.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 11));
      expect(confirmationCount, greaterThanOrEqualTo(2));
      driver.stop();
      await tester.pump();
      await reader.flush();
    },
  );

  testWidgets('real document EOF transitions to stoppedAtEnd without looping', (
    tester,
  ) async {
    final reader = makeReader(characters: 4000);
    final controller = AutoReadController();
    final driver = PagedAutoReadDriver(
      readerController: reader,
      controller: controller,
      intervalOverride: const Duration(milliseconds: 1),
      canDrive: () => true,
      confirmPosition: () async {},
    );
    addTearDown(() {
      driver.dispose();
      reader.dispose();
      controller.dispose();
    });

    driver.start();
    for (var i = 0; i < 200 && controller.state == AutoReadState.running; i++) {
      await tester.pump(const Duration(milliseconds: 2));
    }
    expect(controller.state, AutoReadState.stoppedAtEnd);
    final atEnd = reader.currentPage!.startCharacterOffset;
    await tester.pump(const Duration(seconds: 1));
    expect(reader.currentPage!.startCharacterOffset, atEnd);
  });
}
