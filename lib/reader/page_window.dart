/// PageWindow —— 有限内存分页窗口（§九/§十四/§十五）。
///
/// 窗口永远只保留 current 及其附近有限页（如 prev 2 + next 3），
/// 翻页时向对应方向扩展、淘汰远离当前页的 PageRange。
///
/// **Page 对象数量与全文总页数无关**（红线 §四十九-7）。
/// 窗口内容只存 offset 范围，正文引用 NormalizedDocument（不复制大 String）。
library;

import 'dart:math' as math;

import '../domain/reader/paged_text_range.dart';

/// 分页窗口。
class PageWindow {
  PageWindow({this.previousCount = 2, this.nextCount = 3})
    : assert(previousCount >= 0 && nextCount >= 0);

  /// 当前页之前保留的最大页数。
  final int previousCount;

  /// 当前页之后保留的最大页数。
  final int nextCount;

  final List<PagedTextRange> _pages = [];
  int _currentIndex = 0;
  int _maxObserved = 0;
  int _windowGeneration = 0;
  int _documentLength = 0;

  /// 连续页序列（旧 → 新，窗口内）。
  List<PagedTextRange> get pages => List.unmodifiable(_pages);

  /// 当前页。
  PagedTextRange? get current =>
      _currentIndex >= 0 && _currentIndex < _pages.length
      ? _pages[_currentIndex]
      : null;

  /// 当前页在窗口内的索引（PageView initialPage 用）。
  int get currentIndex => _currentIndex;

  /// 窗口页数。
  int get pageCount => _pages.length;

  /// 历史最大窗口页数（§九：M4_RESULT 记录用）。
  int get maxObserved => _maxObserved;

  /// 窗口重建计数（UI 用：PageView key 变化触发重建）。
  int get windowGeneration => _windowGeneration;

  /// 当前页是否已是文档第一页（无上一页可生成）。
  bool get atDocumentStart {
    final c = current;
    return c == null || c.startCharacterOffset <= 0;
  }

  /// 当前页是否已是文档最后一页（无下一页可生成）。
  bool get atDocumentEnd {
    final c = current;
    return c == null || c.endCharacterOffset >= _documentLength;
  }

  /// 重置窗口：以 [page] 为当前页（打开 / 定位 / resize 重建）。
  void reset(PagedTextRange page, {required int docLength}) {
    _documentLength = docLength;
    _pages
      ..clear()
      ..add(page);
    _currentIndex = 0;
    _windowGeneration++;
    _trackMax();
  }

  /// 窗口内切换当前页（用户滑到窗口内已有页，未触发扩展）。
  void select(int index) {
    if (index < 0 || index >= _pages.length) return;
    _currentIndex = index;
    _windowGeneration++;
    _trim();
  }

  /// 尾部扩展一页（当前页不变；[next] 必须与当前窗口尾页相邻）。
  /// 不立即 trim——由调用方随后 select() 统一 trim（避免误删刚加的页）。
  void extendTail(PagedTextRange next) {
    _pages.add(next);
    _windowGeneration++;
    _trackMax(); // 记录扩展瞬间峰值
  }

  /// 头部扩展一页（当前页不变；[previous] 必须与当前窗口首页相邻）。
  /// 不立即 trim——由调用方随后 select() 统一 trim。
  void extendHead(PagedTextRange previous) {
    _pages.insert(0, previous);
    _currentIndex++;
    _windowGeneration++;
    _trackMax(); // 记录扩展瞬间峰值
  }

  /// 翻到下一页（键盘/按钮便捷方法）：扩展窗口尾 + 新页成为当前。
  bool goNext(PagedTextRange next) {
    if (atDocumentEnd) return false;
    extendTail(next);
    _currentIndex = _pages.length - 1;
    _windowGeneration++;
    _trackMax();
    _trim();
    return true;
  }

  /// 翻到上一页：扩展窗口头 + 新页成为当前。
  bool goPrevious(PagedTextRange previous) {
    if (atDocumentStart) return false;
    _pages.insert(0, previous);
    _currentIndex = 0;
    _windowGeneration++;
    _trackMax();
    _trim();
    return true;
  }

  /// 窗口内第 [index] 页（PageView itemBuilder 用）。
  PagedTextRange? pageAt(int index) =>
      index >= 0 && index < _pages.length ? _pages[index] : null;

  /// 淘汰远离当前页的页：窗口保持
  /// [currentIndex - previousCount, currentIndex + nextCount]。
  void _trim() {
    while (_currentIndex > previousCount) {
      _pages.removeAt(0);
      _currentIndex--;
    }
    while (_pages.length - 1 - _currentIndex > nextCount) {
      _pages.removeLast();
    }
    _trackMax();
  }

  void _trackMax() {
    _maxObserved = math.max(_maxObserved, _pages.length);
  }

  /// 清空窗口（dispose / 失效）。
  void clear() {
    _pages.clear();
    _currentIndex = 0;
    _windowGeneration++;
  }
}
