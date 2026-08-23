import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/data/data_root.dart';
import 'package:xaocen_reader/data/repositories/web_book_source_registry.dart';
import 'package:xaocen_reader/sources/remote/xaocen_web_book_source_definition.dart';

Map<String, Object?> _definition(
  Uri endpoint, {
  String id = 'fixture-source',
}) => <String, Object?>{
  'schema': XaocenWebBookSourceDefinition.schema,
  'version': XaocenWebBookSourceDefinition.schemaVersion,
  'sourceId': id,
  'name': '本地规则测试源',
  'endpoint': endpoint.toString(),
  'searchEndpoint': null,
  'bookKey': 'book-1',
  'ruleVersion': 1,
  'rules': <String, Object?>{
    'search': <String, Object?>{
      'itemSelector': '#results article',
      'title': <String, Object?>{'selector': '.title'},
      'linkSelector': '.title',
      'keyAttribute': 'data-book-key',
    },
    'detail': <String, Object?>{
      'selector': '#book',
      'title': <String, Object?>{'selector': 'h1'},
    },
    'toc': <String, Object?>{
      'entrySelector': '#toc a',
      'title': <String, Object?>{},
    },
    'chapter': <String, Object?>{'bodySelector': '#content'},
  },
};

void main() {
  late Directory temporary;
  late DataRoot root;
  late Uri endpoint;

  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('xaocen-webbook-reg-');
    root = await DataRoot.forDirectory(temporary, profileId: 'reader_user');
    endpoint = Uri.parse('https://example.test/books/1');
  });

  tearDown(() => temporary.delete(recursive: true));

  test('imports, persists, exports and reloads one source', () async {
    final registry = WebBookSourceRegistry(root);
    final json = jsonEncode(_definition(endpoint));
    final imported = await registry.importJson(json);

    expect(imported.sourceId, 'fixture-source');
    expect(imported.enabled, isTrue);
    expect(imported.definition.toSource().bookKey, 'book-1');
    expect(await registry.storageFile.exists(), isTrue);

    final exported = await registry.exportJson('fixture-source');
    final exportedDefinition = XaocenWebBookSourceDefinition.fromJsonString(
      exported,
    );
    expect(exportedDefinition.sourceId, 'fixture-source');
    expect(exportedDefinition.rules.chapterBodySelector, '#content');

    final reopened = WebBookSourceRegistry(
      await DataRoot.forDirectory(temporary, profileId: 'reader_user'),
    );
    expect((await reopened.list()).single.sourceId, 'fixture-source');
  });

  test(
    'enable/disable is local registry state and re-import preserves it',
    () async {
      final registry = WebBookSourceRegistry(root);
      await registry.importJson(jsonEncode(_definition(endpoint)));
      final disabled = await registry.setEnabled('fixture-source', false);
      expect(disabled.enabled, isFalse);

      final changed = _definition(endpoint);
      changed['name'] = '更新后的规则名称';
      final reimported = await registry.importJson(jsonEncode(changed));
      expect(reimported.enabled, isFalse);
      expect(reimported.definition.name, '更新后的规则名称');

      expect(await registry.remove('fixture-source'), isTrue);
      expect(await registry.list(), isEmpty);
      expect(await registry.remove('fixture-source'), isFalse);
    },
  );

  test('rejects invalid import and keeps profile/DataRoot isolation', () async {
    final registry = WebBookSourceRegistry(root);
    expect(
      () => registry.importJson('{"schema":"unknown"}'),
      throwsA(isA<DataRootException>()),
    );
    expect(await registry.list(), isEmpty);

    await registry.importJson(jsonEncode(_definition(endpoint)));
    final otherDirectory = await Directory.systemTemp.createTemp(
      'xaocen-webbook-other-',
    );
    addTearDown(() => otherDirectory.delete(recursive: true));
    final otherRoot = await DataRoot.forDirectory(
      otherDirectory,
      profileId: 'other_user',
    );
    final otherRegistry = WebBookSourceRegistry(otherRoot);
    await registry.storageFile.copy(otherRegistry.storageFile.path);
    await expectLater(otherRegistry.list(), throwsA(isA<DataRootException>()));
  });
}
