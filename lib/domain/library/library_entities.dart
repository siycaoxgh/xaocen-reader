import '../local_txt/text_encoding.dart';

/// 书库集合（领域实体，非 Drift 表实体）。
class LibraryCollection {
  const LibraryCollection({
    required this.id,
    required this.sourceId,
    required this.title,
    required this.subtitle,
    required this.itemCount,
    required this.normalizedCharacterLength,
    required this.detectedEncoding,
    required this.sourceSize,
    required this.importedAt,
    this.author,
    this.description,
    this.metadataSource = 'legacy',
    this.titleSource = 'legacy',
    this.authorSource = 'unknown',
    this.fileName,
    this.sourcePath,
    this.coverPath,
    this.coverSource = 'placeholder',
  });

  final String id;
  final String sourceId;
  final String title;
  final String? subtitle;

  /// 章节 item 数（volume 不计入）。
  final int itemCount;
  final int normalizedCharacterLength;
  final TextEncoding detectedEncoding;
  final int sourceSize;
  final DateTime importedAt;
  final String? author;
  final String? description;
  final String metadataSource;
  final String titleSource;
  final String authorSource;
  final String? fileName;
  final String? sourcePath;
  final String? coverPath;
  final String coverSource;
}

/// 书库条目（领域实体）。
class LibraryItem {
  const LibraryItem({
    required this.id,
    required this.collectionId,
    required this.kind,
    required this.title,
    required this.orderIndex,
    required this.startCharacterOffset,
    required this.endCharacterOffset,
  });

  final String id;
  final String collectionId;

  /// chapter / whole。
  final String kind;
  final String title;
  final int orderIndex;
  final int startCharacterOffset;
  final int endCharacterOffset;
}

/// 目录条目（领域实体；volume 不计入 itemCount）。
class LibraryTocEntry {
  const LibraryTocEntry({
    required this.id,
    required this.collectionId,
    required this.itemId,
    required this.parentId,
    required this.kind,
    required this.level,
    required this.title,
    required this.orderIndex,
    required this.startCharacterOffset,
    required this.endCharacterOffset,
    String? displayTitle,
  }) : displayTitle = displayTitle ?? title;

  final String id;
  final String collectionId;
  final String? itemId;
  final String? parentId;

  /// volume / chapter。
  final String kind;
  final int level;

  /// Drift 标题（完整标题）。
  final String title;

  /// 完整展示标题（与 [title] 相同，供 UI 直接使用）。
  final String displayTitle;

  final int orderIndex;
  final int startCharacterOffset;
  final int endCharacterOffset;
}

/// 文档（领域实体）。
class LibraryDocument {
  const LibraryDocument({
    required this.id,
    required this.itemId,
    required this.storagePath,
    required this.mediaType,
    required this.startCharacterOffset,
    required this.endCharacterOffset,
    required this.contentHash,
    required this.normalizationVersion,
  });

  final String id;
  final String itemId;
  final String storagePath;
  final String mediaType;
  final int startCharacterOffset;
  final int endCharacterOffset;
  final String contentHash;
  final String normalizationVersion;
}
