/// 目录条目 —— 卷—章两级目录的平铺实体。
///
/// 坐标约定：
/// - 所有 offset 均为**规范化全文的 UTF-16 码元坐标**（唯一持久位置真源）；
/// - 卷与章使用同一坐标系；
/// - 不保存页码、滚动像素或 chunkIndex（均为派生渲染结果）。
library;

enum TocEntryKind { volume, chapter }

class TocEntry {
  const TocEntry({
    required this.id,
    required this.parentId,
    required this.kind,
    required this.level,
    required this.title,
    required this.order,
    required this.startCharacterOffset,
    required this.endCharacterOffset,
    String? displayTitle,
    String? dedupeKey,
    this.chapterNumber,
  }) : displayTitle = displayTitle ?? title,
       dedupeKey = dedupeKey ?? title;

  /// 稳定 ID（扫描阶段生成，卷/章平铺唯一）。
  final String id;

  /// 父条目 ID；卷的 parentId 为空，卷前章节的 parentId 为空。
  final String? parentId;

  final TocEntryKind kind;

  /// 层级：卷=1，章=2。
  final int level;

  /// 兼容旧字段：新数据下与 [displayTitle] 相同。
  final String title;

  /// 完整标题（M3.2 合同）：取完整标题行，仅移除行首/行尾空白。
  /// 用于目录与书架展示。
  final String displayTitle;

  /// 去重比较键（仅用于相邻重复标题判断，禁止用于 UI 显示）。
  /// trim + 全/半角空格归一化 + 连续空白折叠。
  final String dedupeKey;

  /// 章节/卷编号（如 "31" / "一" / "卷一"），单独解析，仅诊断/排序用。
  final String? chapterNumber;

  /// 卷内/全局顺序（从 1 开始）。
  final int order;

  /// 条目起始字符偏移（UTF-16 码元，规范化全文坐标）。
  final int startCharacterOffset;

  /// 条目结束字符偏移（独占；卷=卷内最后一章结束，章=下一章开始或全文末尾）。
  final int endCharacterOffset;

  bool get isVolume => kind == TocEntryKind.volume;
  bool get isChapter => kind == TocEntryKind.chapter;

  Map<String, dynamic> toJson() => {
    'id': id,
    'parentId': parentId,
    'kind': kind.name,
    'level': level,
    'title': title,
    'displayTitle': displayTitle,
    'dedupeKey': dedupeKey,
    'chapterNumber': chapterNumber,
    'order': order,
    'startCharacterOffset': startCharacterOffset,
    'endCharacterOffset': endCharacterOffset,
  };

  factory TocEntry.fromJson(Map<String, dynamic> json) => TocEntry(
    id: json['id'] as String,
    parentId: json['parentId'] as String?,
    kind: TocEntryKind.values.byName(json['kind'] as String),
    level: json['level'] as int,
    title: json['title'] as String,
    displayTitle: (json['displayTitle'] as String?) ?? json['title'] as String,
    dedupeKey: (json['dedupeKey'] as String?) ?? json['title'] as String,
    chapterNumber: json['chapterNumber'] as String?,
    order: json['order'] as int,
    startCharacterOffset: json['startCharacterOffset'] as int,
    endCharacterOffset: json['endCharacterOffset'] as int,
  );
}
