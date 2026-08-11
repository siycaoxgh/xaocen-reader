import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/data/repositories/library_file_manager.dart';
import 'package:xaocen_reader/data/repositories/reader_appearance_asset_repository.dart';

void main() {
  test(
    'import copies image into managed storage independent of source',
    () async {
      final root = await Directory.systemTemp.createTemp('m55e-assets');
      final source = File('${root.path}${Platform.pathSeparator}source.png');
      await source.writeAsBytes(const [0x89, 0x50, 0x4e, 0x47]);
      final repository = ReaderAppearanceAssetRepository(
        fileManager: LibraryFileManager(
          libraryRoot: Directory(
            '${root.path}${Platform.pathSeparator}library',
          ),
        ),
      );

      final relative = await repository.importBackground(
        collectionId: 'local-txt:book-a',
        source: source,
      );
      final managed = repository.resolve(relative);
      expect(
        relative,
        startsWith(ReaderAppearanceAssetRepository.managedPrefix),
      );
      expect(await managed.readAsBytes(), const [0x89, 0x50, 0x4e, 0x47]);

      await source.delete();
      expect(await managed.exists(), isTrue);
      await repository.deleteIfManaged(relative);
      expect(await managed.exists(), isFalse);
      await root.delete(recursive: true);
    },
  );

  test('rejects paths outside managed Reader backgrounds', () async {
    final root = await Directory.systemTemp.createTemp('m55e-assets-safe');
    final repository = ReaderAppearanceAssetRepository(
      fileManager: LibraryFileManager(libraryRoot: root),
    );
    expect(
      () => repository.resolve('library/local_txt/book/normalized.txt'),
      throwsA(isA<ReaderAppearanceAssetException>()),
    );
    await root.delete(recursive: true);
  });
}
