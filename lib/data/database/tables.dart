import 'package:drift/drift.dart';

/// content_sources —— 内容来源（首版仅 localTxt）。
class ContentSources extends Table {
  /// 稳定 ID：`local-txt-source:<contentHash>`（确定性，非 UUID）。
  TextColumn get id => text()();

  /// 来源类型：首版仅 localTxt。
  TextColumn get type => text()();

  /// 展示名（原始文件名，去除 .txt 扩展）。
  TextColumn get displayName => text()();

  /// 内容 SHA-256（稳定内容身份）。
  TextColumn get contentHash => text().unique()();

  /// 应用管理目录下的原始文件副本路径。
  TextColumn get managedSourcePath => text()();

  /// 源文件字节大小。
  IntColumn get sourceSize => integer()();

  /// 检测到的编码名（TextEncoding.name）。
  TextColumn get detectedEncoding => text()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// content_collections —— 一本书。
class ContentCollections extends Table {
  /// 稳定 ID：`local-txt:<contentHash>`。
  TextColumn get id => text()();

  TextColumn get sourceId => text().references(ContentSources, #id)();

  TextColumn get title => text()();

  TextColumn get subtitle => text().nullable()();

  /// 章节 item 数（volume 不计入）。
  IntColumn get itemCount => integer()();

  IntColumn get normalizedCharacterLength => integer()();

  DateTimeColumn get importedAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// content_items —— 章节或 whole 文档项。
class ContentItems extends Table {
  /// 稳定 ID：`local-txt:<hash>:chapter:<startOffset>` 或 `local-txt:<hash>:whole`。
  TextColumn get id => text()();

  TextColumn get collectionId => text().references(ContentCollections, #id)();

  /// chapter / whole。
  TextColumn get kind => text()();

  TextColumn get title => text()();

  IntColumn get orderIndex => integer()();

  /// 规范化 UTF-16 偏移（唯一位置真源）。
  IntColumn get startCharacterOffset => integer()();

  IntColumn get endCharacterOffset => integer()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// content_documents —— item 对应的文档范围（引用同一 normalized.txt）。
class ContentDocuments extends Table {
  /// 稳定 ID：`local-txt:<hash>:document:<startOffset>`。
  TextColumn get id => text()();

  TextColumn get itemId => text().references(ContentItems, #id)();

  /// 应用管理目录下 normalized.txt 的路径。
  TextColumn get storagePath => text()();

  TextColumn get mediaType => text()();

  IntColumn get startCharacterOffset => integer()();

  IntColumn get endCharacterOffset => integer()();

  /// 文档范围内容 hash（用于校验派生数据）。
  TextColumn get contentHash => text()();

  TextColumn get normalizationVersion => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// toc_entries —— 卷—章层级（volume 不计入 itemCount）。
class TocEntries extends Table {
  /// 稳定 ID（与 TxtIndex tocEntries id 一致）。
  TextColumn get id => text()();

  TextColumn get collectionId => text().references(ContentCollections, #id)();

  /// volume 为 null；chapter 指向 content_items。
  TextColumn get itemId => text().nullable().references(ContentItems, #id)();

  TextColumn get parentId => text().nullable()();

  /// volume / chapter。
  TextColumn get kind => text()();

  IntColumn get level => integer()();

  TextColumn get title => text()();

  IntColumn get orderIndex => integer()();

  IntColumn get startCharacterOffset => integer()();

  IntColumn get endCharacterOffset => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// import_records —— 导入状态与诊断。
class ImportRecords extends Table {
  /// 稳定 ID：`import:<sourceHash>:<startedAtEpochMs>`。
  TextColumn get id => text()();

  TextColumn get sourceHash => text()();

  /// preparing / copying / indexing / writingFiles / writingDatabase /
  /// completed / failed / cancelled。
  TextColumn get state => text()();

  DateTimeColumn get startedAt => dateTime()();

  DateTimeColumn get completedAt => dateTime().nullable()();

  TextColumn get errorCode => text().nullable()();

  TextColumn get errorMessage => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
