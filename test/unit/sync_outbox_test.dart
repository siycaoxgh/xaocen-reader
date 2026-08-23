import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:xaocen_reader/data/data_root.dart';
import 'package:xaocen_reader/data/sync/sync_outbox.dart';

void main() {
  test('outbox persists metadata operations and completes them', () async {
    final directory = await Directory.systemTemp.createTemp(
      'xaocen-sync-outbox-',
    );
    addTearDown(() => directory.delete(recursive: true));

    final root = await DataRoot.forDirectory(directory);
    final outbox = SyncOutbox(root: root);
    final created = await outbox.enqueue(
      entityType: 'readingProgress',
      entityId: 'book-1',
      operation: 'upsert',
      payload: const {
        'absoluteCharacterOffset': 128,
        'readingMode': 'vertical',
      },
    );

    final pending = await outbox.pending();
    expect(pending, hasLength(1));
    expect(pending.single.id, created.id);
    expect(pending.single.profileId, root.profileId);
    expect(pending.single.payload['absoluteCharacterOffset'], 128);

    await outbox.recordFailure(created.id);
    expect((await outbox.pending()).single.retryCount, 1);

    await outbox.markCompleted(created.id);
    expect(await outbox.pending(), isEmpty);
    expect((await outbox.completed()).single.isCompleted, isTrue);
  });

  test(
    'outbox survives a new service instance without network state',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'xaocen-sync-outbox-reopen-',
      );
      addTearDown(() => directory.delete(recursive: true));

      final root = await DataRoot.forDirectory(directory);
      await SyncOutbox(root: root).enqueue(
        entityType: 'bookmark',
        entityId: 'bookmark-1',
        operation: 'delete',
      );

      final reopened = SyncOutbox(root: await DataRoot.forDirectory(directory));
      final entries = await reopened.pending();
      expect(entries, hasLength(1));
      expect(entries.single.operation, 'delete');
      expect(entries.single.entityType, 'bookmark');
    },
  );

  test('outbox rejects empty identity fields and unsafe ids', () async {
    final directory = await Directory.systemTemp.createTemp(
      'xaocen-sync-outbox-validation-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final root = await DataRoot.forDirectory(directory);
    final outbox = SyncOutbox(root: root);

    expect(
      () =>
          outbox.enqueue(entityType: '', entityId: 'book', operation: 'upsert'),
      throwsA(isA<DataRootException>()),
    );
    expect(
      () => outbox.remove('../outside'),
      throwsA(isA<DataRootException>()),
    );
  });
}
