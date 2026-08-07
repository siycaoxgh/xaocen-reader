import '../../domain/local_txt/toc_entry.dart';
import 'txt_normalizer.dart';

/// 章节标题匹配规则（Spike 2 已验证的合同 + M1 扩展）：
///
/// - 行首「第X章/卷/部/节」（X=阿拉伯/中文数字，最多 12 位）+ 「卷X」形式
///   （卷一、卷二…）+ 楔子/序章/序言/前言/后记/尾声/番外/终章；
/// - 「章/卷/部/节」后必须跟 空白/全角空白/标点/换行/行尾，避免误匹配作者公告
///   （如「第五十二章被审核了」中"章"后是"被" → 不匹配）。
final RegExp tocTitlePattern = RegExp(
  r'^(?:第\s*[0-9〇零一二两三四五六七八九十百千万亿壹贰叁肆伍陆柒捌玖拾佰仟萬億]{1,12}\s*(?:章|卷|部|节)|卷\s*[0-9〇零一二两三四五六七八九十百千万亿壹贰叁肆伍陆柒捌玖拾佰仟萬億]{1,6}|楔子|序章|序言|前言|后记|尾声|番外|终章)(?=[ \u3000\t\n：:，,。.!！?？、]|$)',
);

/// 卷标题判定 —— 匹配「第X卷」或「卷X」。
final RegExp volumePattern = RegExp(
  r'^(?:第\s*[0-9〇零一二两三四五六七八九十百千万亿壹贰叁肆伍陆柒捌玖拾佰仟萬億]{1,12}\s*卷|卷\s*[0-9〇零一二两三四五六七八九十百千万亿壹贰叁肆伍陆柒捌玖拾佰仟萬億]{1,6})(?=[ \u3000\t\n：:，,。.!！?？、]|$)',
);

/// 章节命中（扫描中间结果）。
class TocHit {
  const TocHit({
    required this.lineIndex,
    required this.charOffset,
    required this.title,
    required this.displayTitle,
    required this.dedupeKey,
    this.chapterNumber,
    required this.isLineStart,
    required this.indentCount,
  });

  final int lineIndex;
  final int charOffset;

  /// 正则匹配片段（如「第31章」）——仅供内部过渡，不用于展示。
  final String title;

  /// 完整标题行（trim 首尾空白），用于目录/书架展示。
  final String displayTitle;

  /// 去重比较键（trim + 全/半角空格归一化 + 连续空白折叠）。
  final String dedupeKey;

  /// 章节/卷编号（如 "31" / "一" / "卷一"）。
  final String? chapterNumber;

  final bool isLineStart;
  final int indentCount;
}

/// 卷章扫描结果。
class TocScanResult {
  const TocScanResult({
    required this.entries,
    required this.volumeCount,
    required this.chapterCount,
    this.dedupeHitCount = 0,
  });

  final List<TocEntry> entries;
  final int volumeCount;
  final int chapterCount;

  /// 去重剔除的相邻重复数。
  final int dedupeHitCount;
}

/// 卷章扫描器 —— O(n) 单次顺序扫描，累计 UTF-16 offset。
///
/// 结构：
/// - 单次遍历规范化全文，逐行匹配（行边界由 [NormalizedText.lineStarts] 提供，
///   不 split、不重复 substring 前缀计算）；
/// - 标题匹配在行内进行（matchAsPrefix on trimmed），O(行长)；
/// - 相邻重复去重（行距 ≤3、标题相同、一个行首一个缩进 → 保留行首）；
/// - 远距同名/不同卷同名**不**全局去重；
/// - 目录层去重不删除规范化正文中的字符。
class TxtTocScanner {
  const TxtTocScanner();

  /// 扫描规范化文本，生成卷—章两级平铺目录。
  TocScanResult scan(NormalizedText normalized) {
    final hits = scanRaw(normalized);
    final deduped = _dedupe(hits);
    final tree = _buildTree(normalized, deduped);
    return TocScanResult(
      entries: tree.entries,
      volumeCount: tree.volumeCount,
      chapterCount: tree.chapterCount,
      dedupeHitCount: hits.length - deduped.length,
    );
  }

  /// 原始扫描（不去重）：返回所有标题命中。
  List<TocHit> scanRaw(NormalizedText normalized) {
    final text = normalized.text;
    final lineStarts = normalized.lineStarts;
    final lineCount = lineStarts.length;

    final hits = <TocHit>[];
    // 单次顺序扫描
    for (var line = 0; line < lineCount; line++) {
      final start = lineStarts[line];
      final end = (line + 1 < lineCount) ? lineStarts[line + 1] : text.length;
      // 行内容（不含行尾 LF，因为 lineStarts 定位到下一行起点）
      final lineEnd = (end > start && text.codeUnitAt(end - 1) == 0x0A)
          ? end - 1
          : end;
      final lineText = text.substring(start, lineEnd);

      final trimmedStart = _leadingWhitespaceCount(lineText);
      final trimmed = trimmedStart < lineText.length
          ? lineText.substring(trimmedStart)
          : '';
      final isLineStart = trimmedStart == 0 && lineText.isNotEmpty;

      final m = tocTitlePattern.matchAsPrefix(trimmed);
      if (m == null) continue;
      final matched = m.group(0)!;
      // M3.2 合同：displayTitle 取完整标题行（trim 首尾空白），
      // 保留「第X章/卷」与后面的具体标题；不得只存正则匹配片段。
      final displayTitle = trimmed.trim();
      hits.add(
        TocHit(
          lineIndex: line,
          charOffset: start,
          title: matched,
          displayTitle: displayTitle,
          dedupeKey: dedupeKeyFor(displayTitle),
          chapterNumber: chapterNumberFor(displayTitle),
          isLineStart: isLineStart,
          indentCount: trimmedStart,
        ),
      );
    }
    return hits;
  }

  int _leadingWhitespaceCount(String s) {
    var i = 0;
    while (i < s.length) {
      final c = s.codeUnitAt(i);
      if (c == 0x20 || c == 0x09 || c == 0x3000) {
        i++;
      } else {
        break;
      }
    }
    return i;
  }

  /// 去重比较键：trim + 全/半角空格归一化 + 连续空白折叠。
  static String dedupeKeyFor(String title) {
    final s = title.trim().replaceAll('\u3000', ' ');
    final sb = StringBuffer();
    var prevSpace = false;
    for (var i = 0; i < s.length; i++) {
      final ch = s[i];
      if (ch == ' ' || ch == '\t') {
        if (!prevSpace) sb.write(' ');
        prevSpace = true;
      } else {
        sb.write(ch);
        prevSpace = false;
      }
    }
    return sb.toString().trim();
  }

  /// 从标题解析编号（如「第31章」→ "31"；「卷一」→ "一"；「楔子」→ null）。
  static String? chapterNumberFor(String displayTitle) {
    final m = RegExp(
      r'^(?:第\s*([0-9〇零一二两三四五六七八九十百千万亿壹贰叁肆伍陆柒捌玖拾佰仟萬億]{1,12})\s*(?:章|卷|部|节)|卷\s*([0-9〇零一二两三四五六七八九十百千万亿壹贰叁肆伍陆柒捌玖拾佰仟萬億]{1,6}))',
    ).firstMatch(displayTitle);
    if (m == null) return null;
    return m.group(1) ?? m.group(2);
  }

  /// 相邻结构重复去重（保留行首版本）。
  ///
  /// 判据：行距 ≤3 + 一个真行首一个缩进 + （dedupeKey 相同 或 章节编号相同）。
  /// 章节编号相同即视为重复：真实小说中缩进重复行常是正文对标题的引用
  /// （可能带错别字，如「第468章 这特么」vs「　第468章 这特码」），
  /// 此时应保留行首版并剔除正文引用行（M3.2 真实文件回归：473 章不得变 486）。
  List<TocHit> _dedupe(List<TocHit> hits) {
    final result = <TocHit>[];
    var i = 0;
    while (i < hits.length) {
      final cur = hits[i];
      if (i + 1 < hits.length) {
        final next = hits[i + 1];
        final sameNumber =
            cur.chapterNumber != null &&
            cur.chapterNumber == next.chapterNumber;
        final isAdjacentDup =
            (next.lineIndex - cur.lineIndex) <= 3 &&
            (cur.dedupeKey == next.dedupeKey || sameNumber) &&
            cur.isLineStart &&
            !next.isLineStart;
        if (isAdjacentDup) {
          result.add(cur);
          i += 2;
          continue;
        }
      }
      result.add(cur);
      i++;
    }
    return result;
  }

  /// 构建卷—章树（平铺实体，parentId/level 稳定）。
  TocScanResult _buildTree(NormalizedText normalized, List<TocHit> hits) {
    final textLength = normalized.text.length;
    final entries = <TocEntry>[];
    String? currentVolumeId;
    var volumeOrder = 0;
    var chapterOrderInVolume = 0;
    var globalChapterOrder = 0;

    // 预计算每个条目的 end offset（下一同类型条目起点或全文末尾）
    // 简化：章的 end = 下一个章起点 或 全文末尾；卷的 end = 卷内最后一章 end。
    for (var i = 0; i < hits.length; i++) {
      final hit = hits[i];
      final isVolume = volumePattern.hasMatch(hit.title);
      final endOffset = i + 1 < hits.length
          ? hits[i + 1].charOffset
          : textLength;

      if (isVolume) {
        volumeOrder++;
        chapterOrderInVolume = 0;
        currentVolumeId = 'v$volumeOrder';
        entries.add(
          TocEntry(
            id: currentVolumeId,
            parentId: null,
            kind: TocEntryKind.volume,
            level: 1,
            title: hit.displayTitle,
            displayTitle: hit.displayTitle,
            dedupeKey: hit.dedupeKey,
            chapterNumber: hit.chapterNumber,
            order: volumeOrder,
            startCharacterOffset: hit.charOffset,
            endCharacterOffset: endOffset,
          ),
        );
      } else {
        globalChapterOrder++;
        chapterOrderInVolume++;
        final parentId = currentVolumeId;
        entries.add(
          TocEntry(
            id: 'c$globalChapterOrder',
            parentId: parentId,
            kind: TocEntryKind.chapter,
            level: 2,
            title: hit.displayTitle,
            displayTitle: hit.displayTitle,
            dedupeKey: hit.dedupeKey,
            chapterNumber: hit.chapterNumber,
            order: chapterOrderInVolume,
            startCharacterOffset: hit.charOffset,
            endCharacterOffset: endOffset,
          ),
        );
      }
    }

    // 修正卷的 end：卷的 end 应为卷内最后一章的 end（若卷后无内容则全文末尾）。
    // 简化处理：卷的 endOffset 已由下一 hit 起点计算；若卷内最后一章在卷后，
    // 卷的 end 会延伸到下一卷起点 —— 这符合"点击卷标题跳转到卷首"的语义
    // （卷标题跳转只看 startCharacterOffset）。
    return TocScanResult(
      entries: entries,
      volumeCount: volumeOrder,
      chapterCount: globalChapterOrder,
    );
  }
}
