import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/database/app_database.dart';
import '../data/repositories/library_file_manager.dart';
import 'app.dart';
import 'providers.dart';

/// 启动入口 —— 初始化数据库与文件管理，然后挂载应用。
///
/// M2：数据库在 support 目录；library 根在
/// `<support>/library`（见 [LibraryFileManager] 布局）。
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 数据库（正式文件库）
  final db = await AppDatabase.open();
  // 文件管理（library 根）
  final supportDir = await getApplicationSupportDirectory();
  final libraryRoot = Directory(p.join(supportDir.path, 'library'));
  final fileManager = LibraryFileManager(libraryRoot: libraryRoot);
  // 启动时清理未完成导入 job（半成品不显示在书架）
  await fileManager.cleanupStaleImportingJobs();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        fileManagerProvider.overrideWithValue(fileManager),
      ],
      child: const XaocenApp(),
    ),
  );
}
