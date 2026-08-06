import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/app/app.dart';
import 'package:xaocen_reader/app/constants.dart';
import 'package:xaocen_reader/app/providers.dart';
import 'package:xaocen_reader/app/router.dart';
import 'package:xaocen_reader/data/database/app_database.dart';
import 'package:xaocen_reader/data/repositories/library_file_manager.dart';

void main() {
  group('M0 骨架（M2 保留）', () {
    testWidgets('根路由注册', (tester) async {
      expect(AppRouter.root, '/');
      expect(AppRouter.routes.containsKey('/'), isTrue);
    });

    testWidgets('深色主题生效 + 根路由渲染书架', (tester) async {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          fileManagerProvider.overrideWithValue(
            LibraryFileManager(
              libraryRoot: Directory.systemTemp.createTempSync('xaocen_m0_lib'),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const XaocenApp(),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold).first);
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(find.text('本地书库'), findsOneWidget);
    });
  });

  group('版本与代际常量', () {
    test('应用版本为 0.1.0-dev.2+2', () {
      expect(appVersion, '0.1.0-dev.2+2');
      expect(appVersion.startsWith('0.1.0'), isTrue);
    });

    test('数据代际为 v4-local-1', () {
      expect(dataEpoch, 'v4-local-1');
    });

    test('根路由路径为 /', () {
      expect(AppRouter.root, '/');
      expect(AppRouter.routes.containsKey('/'), isTrue);
    });
  });
}
