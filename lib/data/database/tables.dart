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

/// reading_progress —— 每本书一条当前阅读进度（schema 2 新增；schema 3 加 readingMode）。
///
/// 唯一位置真源：absoluteCharacterOffset（normalized.txt 的 UTF-16 码元偏移）。
/// readingMode 是阅读表现状态（vertical/paged），绝不是位置真源。
/// 禁止保存页码 / scroll pixels / blockIndex / 章节百分比。
class ReadingProgress extends Table {
  /// collection ID（`local-txt:<hash>`，主键 + 外键（级联删除））。
  TextColumn get collectionId => text().customConstraint(
    'REFERENCES content_collections (id) ON DELETE CASCADE',
  )();

  /// 唯一位置真源：normalized.txt UTF-16 码元偏移。
  IntColumn get absoluteCharacterOffset => integer()();

  /// 阅读表现状态：'vertical' / 'paged'（schema 3 新增，旧数据默认 vertical）。
  TextColumn get readingMode =>
      text().withDefault(const Constant('vertical'))();

  /// 快速识别章节的提示（非位置真源），可空。
  TextColumn get itemIdHint => text().nullable()();

  DateTimeColumn get updatedAt => dateTime()();

  /// ReaderLocator 版本（区分未来 locator 语义）。
  IntColumn get locatorVersion => integer()();

  /// M1 normalization 版本（normalizationVersion）。
  TextColumn get normalizationVersion => text()();

  @override
  Set<Column> get primaryKey => {collectionId};
}

/// app_settings —— 应用级设置键值存储（schema 4 新增）。
///
/// 字符串 key/value 是 storage 细节，只允许 Repository 解释；
/// UI、Controller、Reader 只能使用强类型设置模型。
class AppSettings extends Table {
  TextColumn get key => text()();

  TextColumn get value => text()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}

/// reader_preferences —— per-collection Reader appearance (schema 5).
class ReaderPreferencesRows extends Table {
  @override
  String get tableName => 'reader_preferences';

  TextColumn get collectionId => text().customConstraint(
    'NOT NULL REFERENCES content_collections (id) ON DELETE CASCADE',
  )();
  RealColumn get fontSize => real()();
  RealColumn get letterSpacing => real()();
  RealColumn get lineHeight => real()();
  RealColumn get paragraphSpacing => real()();
  RealColumn get firstLineIndent => real()();
  RealColumn get paddingTop => real()();
  RealColumn get paddingBottom => real()();
  RealColumn get paddingLeft => real()();
  RealColumn get paddingRight => real()();
  TextColumn get themeMode => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {collectionId};
}

/// Bookmarks are anchored by the normalized UTF-16 offset.  The collection
/// relation is nullable so a removed book can leave an orphaned bookmark for
/// the user to inspect or delete.
class ReaderBookmarks extends Table {
  TextColumn get id => text()();

  TextColumn get collectionId => text().nullable().customConstraint(
    'REFERENCES content_collections (id) ON DELETE SET NULL',
  )();

  IntColumn get absoluteCharacterOffset => integer()();

  TextColumn get normalizedHashAtCreation => text().nullable()();

  TextColumn get bookTitleSnapshot => text()();

  TextColumn get note => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One aggregate row per book ever opened in Reader.  It deliberately does
/// not duplicate locator, duration or session count state.
class ReadingHistory extends Table {
  TextColumn get id => text()();

  TextColumn get collectionId => text().nullable().customConstraint(
    'REFERENCES content_collections (id) ON DELETE SET NULL',
  )();

  TextColumn get bookTitleSnapshot => text()();

  TextColumn get authorSnapshot => text().nullable()();

  TextColumn get normalizedHashSnapshot => text().nullable()();

  DateTimeColumn get firstReadAt => dateTime()();

  DateTimeColumn get lastReadAt => dateTime()();

  TextColumn get lastChapterTitleSnapshot => text().nullable()();

  TextColumn get lastProgressSnapshot => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A single valid foreground Reader session.  Aggregate duration and count
/// are derived from this table, never maintained as duplicate columns on
/// [ReadingHistory].
class ReadingSessions extends Table {
  TextColumn get id => text()();

  TextColumn get historyEntryId => text().customConstraint(
    'NOT NULL REFERENCES reading_history (id) ON DELETE CASCADE',
  )();

  DateTimeColumn get startedAt => dateTime()();

  DateTimeColumn get endedAt => dateTime().nullable()();

  IntColumn get effectiveReadingSeconds => integer()();

  TextColumn get platform => text().nullable()();

  TextColumn get deviceId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
