import 'library_entities.dart';

/// 目录索引纯逻辑（M3.3：目录打开时定位当前章节；M3.4：平铺展示）。
///
/// 不依赖 Flutter，可单元测试。
/// 坐标真源：UTF-16 码元偏移（startCharacterOffset）。
///
/// TOC hierarchy is advisory; source order is authoritative.
/// 层级（parentId/kind/level）仅用于视觉与语义，不参与可见性过滤。
abstract final class TocIndexLogic {
  /// 当前章节：最后一个 startCharacterOffset <= topVisible 的 chapter。
  ///
  /// - volume 不能作为「当前章节」；
  /// - 位置在第一章以前：返回 null（调用方回退到第一项或「全文」）；
  /// - 无章节：返回 null（调用方显示「全文」）；
  /// - 遍历全表取最后一个满足条件的 chapter（异常 TXT 中 offset 可能
  ///   不严格递增，不提前 break，保证容错且不崩溃）。
  static LibraryTocEntry? currentChapterFor(
    int topVisibleOffset,
    List<LibraryTocEntry> toc,
  ) {
    LibraryTocEntry? current;
    for (final e in toc) {
      if (e.kind != 'chapter') continue;
      if (e.startCharacterOffset <= topVisibleOffset) {
        current = e;
      }
    }
    return current;
  }

  /// 平铺目录列表中的条目下标；未找到返回 null。
  ///
  /// M3.4：目录始终平铺显示（无折叠），displayIndex == 条目在原始
  /// 有序列表中的位置（orderIndex 排序，与正文 startCharacterOffset
  /// 顺序一致）。
  static int? displayIndexFor(String? entryId, List<LibraryTocEntry> flat) {
    if (entryId == null) return null;
    for (var i = 0; i < flat.length; i++) {
      if (flat[i].id == entryId) return i;
    }
    return null;
  }
}
