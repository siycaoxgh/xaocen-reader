import 'library_entities.dart';

/// 目录索引纯逻辑（M3.3：目录打开时定位当前章节）。
///
/// 不依赖 Flutter，可单元测试。
/// 坐标真源：UTF-16 码元偏移（startCharacterOffset）。
abstract final class TocIndexLogic {
  /// 当前章节：最后一个 startCharacterOffset <= topVisible 的 chapter。
  ///
  /// - 位置在第一章以前：返回 null（调用方回退到第一项或「全文」）；
  /// - 无章节：返回 null（调用方显示「全文」）。
  static LibraryTocEntry? currentChapterFor(
    int topVisibleOffset,
    List<LibraryTocEntry> toc,
  ) {
    LibraryTocEntry? current;
    for (final e in toc) {
      if (e.kind != 'chapter') continue;
      if (e.startCharacterOffset <= topVisibleOffset) {
        current = e;
      } else {
        break; // toc 按 offset 有序（volume 后紧跟 chapters）
      }
    }
    return current;
  }

  /// 当前 chapter 的所有父级 volume id（最近 → 最远）。
  static List<String> parentVolumeIdsOf(
    String? chapterId,
    List<LibraryTocEntry> toc,
  ) {
    if (chapterId == null) return const [];
    final byId = <String, LibraryTocEntry>{for (final e in toc) e.id: e};
    final out = <String>[];
    var current = byId[chapterId];
    var guard = 0;
    while (current?.parentId != null && guard < 16) {
      final pid = current!.parentId!;
      final parent = byId[pid];
      if (parent == null) break;
      out.add(pid);
      current = parent;
      guard++;
    }
    return out;
  }

  /// 根据折叠状态生成扁平可见目录列表。
  ///
  /// 折叠的 volume 本身仍显示（可再展开），其子章节隐藏。
  static List<LibraryTocEntry> visibleEntries(
    List<LibraryTocEntry> toc,
    Set<String> collapsedVolumeIds,
  ) {
    final out = <LibraryTocEntry>[];
    for (final e in toc) {
      if (e.kind == 'volume') {
        out.add(e);
      } else {
        final parentCollapsed =
            e.parentId != null && collapsedVolumeIds.contains(e.parentId);
        if (!parentCollapsed) out.add(e);
      }
    }
    return out;
  }

  /// 在可见列表中查找条目下标；未找到返回 null。
  static int? visibleIndexFor(String? entryId, List<LibraryTocEntry> visible) {
    if (entryId == null) return null;
    for (var i = 0; i < visible.length; i++) {
      if (visible[i].id == entryId) return i;
    }
    return null;
  }
}
