import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:xaocen_reader/data/data_root.dart';
import 'package:xaocen_reader/data/data_root_backup.dart';

void main() {
  test('standard root uses a stable product key and default profile', () async {
    final support = await Directory.systemTemp.createTemp(
      'xaocen-data-root-stable-',
    );
    addTearDown(() => support.delete(recursive: true));

    final root = await DataRoot.standard(supportDirectory: support);

    expect(root.mode, DataRootMode.standard);
    expect(root.profileId, DataRoot.defaultProfileId);
    expect(
      root.rootDirectory.path,
      p.join(
        support.path,
        DataRoot.stableCompanyDirectory,
        DataRoot.stableProductDirectory,
        DataRoot.profilesDirectoryName,
        DataRoot.defaultProfileId,
      ),
    );
  });

  test(
    'portable root is separate from Flutter runtime data directory',
    () async {
      final executable = await Directory.systemTemp.createTemp(
        'xaocen-portable-executable-',
      );
      addTearDown(() => executable.delete(recursive: true));

      final root = await DataRoot.portable(executableDirectory: executable);

      expect(root.mode, DataRootMode.portable);
      expect(
        root.rootDirectory.path,
        p.join(
          executable.path,
          DataRoot.portableUserDataDirectoryName,
          DataRoot.profilesDirectoryName,
          DataRoot.defaultProfileId,
        ),
      );
      expect(root.rootDirectory.path, isNot(p.join(executable.path, 'data')));
    },
  );

  test('portable mode requires an explicit argument or marker', () async {
    final executable = await Directory.systemTemp.createTemp(
      'xaocen-portable-resolver-',
    );
    final support = await Directory.systemTemp.createTemp(
      'xaocen-standard-resolver-',
    );
    addTearDown(() async {
      await executable.delete(recursive: true);
      await support.delete(recursive: true);
    });

    final portable = await DataRoot.resolve(
      arguments: const [DataRoot.portableArgument],
      executableDirectory: executable,
    );
    expect(portable.mode, DataRootMode.portable);

    final marker = File(
      p.join(executable.path, DataRoot.portableMarkerFileName),
    );
    await marker.writeAsString('portable');
    final marked = await DataRoot.resolve(executableDirectory: executable);
    expect(marked.mode, DataRootMode.portable);

    final standard = await DataRoot.standard(supportDirectory: support);
    expect(standard.mode, DataRootMode.standard);
  });

  test('active profile selection is persisted for the next startup', () async {
    final executable = await Directory.systemTemp.createTemp(
      'xaocen-active-profile-',
    );
    addTearDown(() => executable.delete(recursive: true));

    await DataRoot.setActiveProfile(
      profileId: 'reader_2',
      mode: DataRootMode.portable,
      executableDirectory: executable,
    );
    final resolved = await DataRoot.resolve(
      arguments: const [DataRoot.portableArgument],
      executableDirectory: executable,
    );
    expect(resolved.profileId, 'reader_2');

    final defaultProfile = await DataRoot.portable(
      executableDirectory: executable,
    );
    expect(await defaultProfile.listProfileIds(), ['default', 'reader_2']);
  });

  test(
    'standard root migrates legacy database and library without absolute paths',
    () async {
      final support = await Directory.systemTemp.createTemp(
        'xaocen-data-root-legacy-',
      );
      addTearDown(() => support.delete(recursive: true));
      final legacyLibrary = Directory(
        p.join(support.path, 'library', 'local_txt', 'book'),
      );
      await legacyLibrary.create(recursive: true);
      await File(
        p.join(legacyLibrary.path, 'normalized.txt'),
      ).writeAsString('正文');
      await File(
        p.join(support.path, 'xaocen_v4_local.sqlite'),
      ).writeAsString('sqlite-placeholder');

      final root = await DataRoot.standard(supportDirectory: support);
      expect(root.mode, DataRootMode.standard);
      expect(root.rootId, hasLength(32));
      expect(await root.databaseFile.exists(), isTrue);
      expect(
        await File(
          p.join(
            root.booksDirectory.path,
            'local_txt',
            'book',
            'normalized.txt',
          ),
        ).readAsString(),
        '正文',
      );
      expect(p.isAbsolute('library/local_txt/book/normalized.txt'), isFalse);
      expect(await root.metadataFile.exists(), isTrue);
    },
  );

  test(
    'portable roots have independent identity and an exclusive lease',
    () async {
      final firstDir = await Directory.systemTemp.createTemp(
        'xaocen-data-root-one-',
      );
      final secondDir = await Directory.systemTemp.createTemp(
        'xaocen-data-root-two-',
      );
      addTearDown(() async {
        await firstDir.delete(recursive: true);
        await secondDir.delete(recursive: true);
      });
      final first = await DataRoot.forDirectory(firstDir);
      final second = await DataRoot.forDirectory(secondDir);
      expect(first.rootId, isNot(second.rootId));

      final lease = await first.acquireLease();
      addTearDown(lease.release);
      expect(() => first.acquireLease(), throwsA(isA<DataRootException>()));
      final secondLease = await second.acquireLease();
      await secondLease.release();
    },
  );

  test(
    'backup manifest hashes files and restore swaps through a staged root',
    () async {
      final sourceDir = await Directory.systemTemp.createTemp(
        'xaocen-data-root-source-',
      );
      final targetDir = await Directory.systemTemp.createTemp(
        'xaocen-data-root-target-',
      );
      final bundleDir = await Directory.systemTemp.createTemp(
        'xaocen-data-root-bundle-',
      );
      addTearDown(() async {
        await sourceDir.delete(recursive: true);
        await targetDir.delete(recursive: true);
        await bundleDir.delete(recursive: true);
      });
      final source = await DataRoot.forDirectory(sourceDir);
      final target = await DataRoot.forDirectory(targetDir);
      await File(
        p.join(
          source.booksDirectory.path,
          'local_txt',
          'book',
          'normalized.txt',
        ),
      ).create(recursive: true);
      await File(
        p.join(
          source.booksDirectory.path,
          'local_txt',
          'book',
          'normalized.txt',
        ),
      ).writeAsString('original');
      final service = const DataRootBackupService();
      final manifest = await service.createBackup(
        root: source,
        destination: bundleDir,
      );
      expect(manifest.files, isNotEmpty);
      expect(manifest.sourceProfileId, source.profileId);
      expect(await service.verifyBundle(bundle: bundleDir), isNotNull);

      final targetFile = File(
        p.join(
          target.booksDirectory.path,
          'local_txt',
          'book',
          'normalized.txt',
        ),
      );
      await targetFile.create(recursive: true);
      await targetFile.writeAsString('changed');
      await service.importProfile(target: target, bundle: bundleDir);
      final restored = File(
        p.join(targetDir.path, 'books', 'local_txt', 'book', 'normalized.txt'),
      );
      expect(await restored.readAsString(), 'original');
    },
  );

  test('tampered backup is rejected before restore', () async {
    final rootDir = await Directory.systemTemp.createTemp(
      'xaocen-data-root-tamper-root-',
    );
    final bundleDir = await Directory.systemTemp.createTemp(
      'xaocen-data-root-tamper-bundle-',
    );
    addTearDown(() async {
      await rootDir.delete(recursive: true);
      await bundleDir.delete(recursive: true);
    });
    final root = await DataRoot.forDirectory(rootDir);
    final file = File(p.join(root.settingsDirectory.path, 'settings.json'));
    await file.writeAsString('{"ok":true}');
    final service = const DataRootBackupService();
    await service.createBackup(root: root, destination: bundleDir);
    await File(
      p.join(bundleDir.path, 'payload', 'settings', 'settings.json'),
    ).writeAsString('tampered');
    expect(
      () => service.verifyBundle(bundle: bundleDir),
      throwsA(isA<DataRootException>()),
    );
  });

  test(
    'all current real TXT files survive DataRoot export and restore',
    () async {
      final corpus = Directory(r'C:\Users\TOM\Desktop\测试');
      if (!await corpus.exists()) {
        markTestSkipped('real corpus is not available on this machine');
        return;
      }
      final files =
          (await corpus.list().where((entry) => entry is File).toList())
              .where((entry) => p.extension(entry.path).toLowerCase() == '.txt')
              .cast<File>()
              .toList();
      expect(files.length, 4);
      final sourceDir = await Directory.systemTemp.createTemp(
        'xaocen-data-root-real-source-',
      );
      final targetDir = await Directory.systemTemp.createTemp(
        'xaocen-data-root-real-target-',
      );
      final bundleDir = await Directory.systemTemp.createTemp(
        'xaocen-data-root-real-bundle-',
      );
      addTearDown(() async {
        await sourceDir.delete(recursive: true);
        await targetDir.delete(recursive: true);
        await bundleDir.delete(recursive: true);
      });
      final source = await DataRoot.forDirectory(sourceDir);
      final target = await DataRoot.forDirectory(targetDir);
      final realRoot = Directory(
        p.join(source.booksDirectory.path, 'local_txt', 'real'),
      );
      await realRoot.create(recursive: true);
      for (final file in files) {
        await file.copy(p.join(realRoot.path, p.basename(file.path)));
      }
      final service = const DataRootBackupService();
      final manifest = await service.createBackup(
        root: source,
        destination: bundleDir,
      );
      expect(
        manifest.files.where((entry) => entry.path.contains('/real/')).length,
        4,
      );
      await service.restoreBundle(root: target, bundle: bundleDir);
      for (final file in files) {
        final restored = File(
          p.join(
            targetDir.path,
            'books',
            'local_txt',
            'real',
            p.basename(file.path),
          ),
        );
        expect(await restored.length(), await file.length());
      }
    },
  );
}
