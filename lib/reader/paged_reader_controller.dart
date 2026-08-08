/// PagedReaderController —— 横向分页模式控制器（M4）。
///
/// 位置真源：ReaderLocator.absoluteCharacterOffset（UTF-16 码元偏移）。
/// Page / pageIndex / PageView index 只是派生状态，永不持久化。
///
/// 职责：
/// - open(anchor)：任意偏移 → pageContaining → 有限窗口；
/// - nextPage / previousPage：窗口扩展 + settle 后更新 confirmed locator
///   （§十九：用户主动翻页后 confirmed = 新页 page.start）+ 防抖保存；
/// - jumpToOffset：目录跳转，confirmed = **精确 target**（§二十四，
///   不被 page.start 覆盖）；
/// - relayout：resize / orientation，capture locator → invalidate →
///   pageContaining → 重建窗口，confirmed 保持不变（§三十一）；
/// - 防抖保存（400ms）+ flush（scroll end / lifecycle）；
/// - operation generation：拒绝过期异步结果（§二十一）。
// ignore_for_file: prefer_initializing_formals
library;

import 'dart:async';

import '../domain/reader/reader_progress_state.dart';
import '../domain/reader/reading_mode.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../data/repositories/reading_progress_repository.dart';
import '../domain/reader/paged_text_range.dart';
import '../domain/reader/reader_block.dart';
import '../domain/reader/reader_locator.dart';
import 'normalized_document_loader.dart';
import 'paged_layout_engine.dart';
import 'page_window.dart';

/// 翻页结果。
enum PageTurnResult {
  /// 翻页成功。
  ok,

  /// 已是文档第一页（previous 不可用）。
  startReached,

  /// 已是文档最后一页（next 不可用）。
  endReached,
}

/// 分页模式控制器。
class PagedReaderController extends ChangeNotifier {
  PagedReaderController({
    required this.collectionId,
    required NormalizedDocument document,
    required ReadingProgressRepository progressRepository,
    required ReaderBlockIndex blockIndex,
    required TextStyle style,
    required double width,
    required double height,
    this.horizontalPadding = 16,
    this.verticalPadding = 8,
    this.previousWindowPages = 2,
    this.nextWindowPages = 3,
  }) : _document = document,
       _progressRepository = progressRepository,
       _blockIndex = blockIndex,
       _style = style,
       _width = width,
       _height = height {
    _window = PageWindow(
      previousCount: previousWindowPages,
      nextCount: nextWindowPages,
    );
    _rebuildEngine();
  }

  final String collectionId;
  final NormalizedDocument _document;
  final ReadingProgressRepository _progressRepository;
  final ReaderBlockIndex _blockIndex;

  /// 显示与测量共用的正文样式（与纵向同一来源）。
  late TextStyle _style;
  late double _width;
  late double _height;
  late double horizontalPadding;
  late double verticalPadding;
  final int previousWindowPages;
  final int nextWindowPages;

  late PagedLayoutEngine _engine;
  late PageWindow _window;

  ReaderLocator? _confirmedLocator;
  ReaderLocator? get confirmedLocator => _confirmedLocator;

  /// 用户是否主动翻过页（§十八：仅切模式不丢 anchor）。
  bool _userTurnedPage = false;
  bool get userTurnedPage => _userTurnedPage;

  PageWindow get window => _window;
  PagedLayoutEngine get engine => _engine;
  NormalizedDocument get document => _document;
  ReaderBlockIndex get blockIndex => _blockIndex;

  bool _disposed = false;
  int _writeFreezeDepth = 0;

  bool get writesFrozen => _writeFreezeDepth > 0;

  void freezeWrites() {
    _writeFreezeDepth++;
    _generation++;
    _debounce?.cancel();
  }

  void unfreezeWrites() {
    if (_writeFreezeDepth > 0) _writeFreezeDepth--;
  }

  Timer? _debounce;
  static const Duration _debounceDuration = Duration(milliseconds: 400);

  /// 操作代数：open/relayout/jump 时递增；过期异步结果被拒绝。
  int _generation = 0;
  int get generation => _generation;

  // ---- 打开 / 定位 ----

  /// 以 [anchor] 打开分页模式（§十七：anchor 保持精确，不改成 page.start）。
  ///
  /// 返回当前页；页面开头可以早于 anchor。
  /// 窗口预填前后相邻页（§九：生成当前页 + 有限前后页，Reader 立即可用；
  /// PageView 需要窗口内有可滑动页）。
  PagedTextRange open(ReaderLocator anchor) {
    _generation++;
    final page = _engine.pageContaining(
      anchor.absoluteCharacterOffset,
      blockIndex: _blockIndex,
    )!;
    _window.reset(page, docLength: _document.text.length);
    _prefillWindow();
    // 程序化打开：confirmed = 精确 anchor（§十七，不覆盖为 page.start）。
    // 零写入：模式切换本身不改变阅读位置（§十八）。
    _confirmedLocator = anchor;
    _userTurnedPage = false;
    notifyListeners();
    return page;
  }

  /// 窗口预填：current 前后各预生成 previous/nextWindowPages 页，
  /// 使 PageView 有可滑动页（§九：有限前后页面，非全文预分页）。
  void _prefillWindow() {
    // 向后预生成 next 页。
    var p = _window.current;
    for (var i = 0; p != null && i < nextWindowPages; i++) {
      if (_engine.isDocumentEnd(p.endCharacterOffset)) break;
      final next = _engine.layoutForwardPage(p.endCharacterOffset);
      if (next == null) break;
      _window.extendTail(next);
      p = next;
    }
    // 向前预生成 prev 页（extendHead 会移动 currentIndex，但 current 页不变）。
    var q = _window.current;
    for (var i = 0; q != null && i < previousWindowPages; i++) {
      if (q.startCharacterOffset <= 0) break;
      final prev = _engine.layoutPreviousPage(q.startCharacterOffset);
      if (prev == null) break;
      _window.extendHead(prev);
      q = prev;
    }
  }

  /// 目录 / 卷跳转（§二十四/§二十五）：
  /// pageContaining(target) → 显示；confirmed = **精确 target**。
  PagedTextRange jumpToOffset(int offset, {String? itemIdHint}) {
    _generation++;
    _debounce?.cancel();
    final clamped = clampLocatorOffset(
      requested: offset,
      normalizedLength: _document.text.length,
      text: _document.text,
    );
    final target = ReaderLocator(
      collectionId: collectionId,
      absoluteCharacterOffset: clamped.clamped,
      itemIdHint: itemIdHint,
    );
    final page = _engine.pageContaining(
      target.absoluteCharacterOffset,
      blockIndex: _blockIndex,
    )!;
    _window.reset(page, docLength: _document.text.length);
    _prefillWindow();
    // §二十四：目录明确跳转完成后 confirmed 保持精确 target，
    // 立即防抖保存（明确用户操作）；只有用户之后主动翻页才使用 page.start。
    _confirmedLocator = target;
    _userTurnedPage = false;
    _scheduleSave(target);
    notifyListeners();
    return page;
  }

  // ---- 翻页 ----

  /// 下一页（用户操作）。窗口扩展 + settle 后 confirmed = 新页 page.start。
  PageTurnResult nextPage() {
    final c = _window.current;
    if (c == null || _window.atDocumentEnd) {
      return PageTurnResult.endReached;
    }
    final next = _engine.layoutForwardPage(c.endCharacterOffset);
    if (next == null) {
      return PageTurnResult.endReached;
    }
    _window.extendTail(next);
    _window.select(_window.pageCount - 1); // 新页成为当前 + trim
    onPageSettled(next);
    return PageTurnResult.ok;
  }

  /// 上一页（用户操作）。
  PageTurnResult previousPage() {
    final c = _window.current;
    if (c == null || _window.atDocumentStart) {
      return PageTurnResult.startReached;
    }
    final prev = _engine.layoutPreviousPage(c.startCharacterOffset);
    if (prev == null) {
      return PageTurnResult.startReached;
    }
    _window.extendHead(prev);
    _window.select(0); // 新页成为当前 + trim
    onPageSettled(prev);
    return PageTurnResult.ok;
  }

  /// 页面 settle（用户翻页完成）：confirmed = page.start + 防抖保存
  /// （§十九：只拖动一半不保存；settle 且为新页才保存）。
  ///
  /// 由 UI 在 PageView onPageChanged（用户滑动完成）时调用；
  /// 键盘/按钮翻页在 nextPage/previousPage 内部自动调用。
  void onPageSettled(PagedTextRange page) {
    // 用户主动翻页：confirmed = 新页 page.start（§十九）。
    _userTurnedPage = true;
    final locator = ReaderLocator(
      collectionId: collectionId,
      absoluteCharacterOffset: page.startCharacterOffset,
    );
    _confirmedLocator = locator;
    _scheduleSave(locator);
  }

  /// 窗口内第 [index] 页（PageView itemBuilder 用）。
  PagedTextRange? pageAt(int index) => _window.pageAt(index);

  /// 当前页。
  PagedTextRange? get currentPage => _window.current;

  /// 当前页在窗口内索引。
  int get currentPageIndex => _window.currentIndex;

  // ---- resize / orientation（§三十一）----

  /// 尺寸/字体度量变化：capture locator → 新引擎 → pageContaining →
  /// 重建窗口；confirmed 保持不变（不改成 page.start）。
  ///
  /// 仅当布局签名变化时才真正重建（§十五/§三十二：纯颜色变化
  /// 不改变签名 → 不重分页）。
  bool relayout({
    required double width,
    required double height,
    required TextStyle style,
    double? horizontalPadding,
    double? verticalPadding,
  }) {
    final nextHorizontalPadding = horizontalPadding ?? this.horizontalPadding;
    final nextVerticalPadding = verticalPadding ?? this.verticalPadding;
    final nextMetricsKey = textStyleMetricsKey(style);
    final metricsUnchanged =
        width == _width &&
        height == _height &&
        nextMetricsKey == textStyleMetricsKey(_style) &&
        nextHorizontalPadding == this.horizontalPadding &&
        nextVerticalPadding == this.verticalPadding;
    if (metricsUnchanged) {
      if (style == _style) return false;
      _style = style;
      notifyListeners();
      return true;
    }
    final locator = _confirmedLocator;
    if (locator == null) return false;

    _generation++;
    _debounce?.cancel();
    _width = width;
    _height = height;
    _style = style;
    this.horizontalPadding = nextHorizontalPadding;
    this.verticalPadding = nextVerticalPadding;
    _engine.dispose();
    _rebuildEngine();

    final page = _engine.pageContaining(
      locator.absoluteCharacterOffset,
      blockIndex: _blockIndex,
    )!;
    _window.reset(page, docLength: _document.text.length);
    _prefillWindow();
    // §三十一：resize 是程序化重建，confirmed 保持 locator。
    _confirmedLocator = locator;
    notifyListeners();
    return true;
  }

  /// 静默 relayout（不 notifyListeners）：供 PagedReaderView 在 build 中
  /// 同步引擎尺寸与渲染约束（首次切换 / resize / orientation）。
  ///
  /// 本帧即用新尺寸渲染——避免「先渲染旧尺寸一帧 → 超约束」以及
  /// build 中 notifyListeners → setState 的非法调用。confirmed 保持不变
  /// （§三十一：resize 不改变阅读位置）。
  bool relayoutSilently({
    required double width,
    required double height,
    required TextStyle style,
    double? horizontalPadding,
    double? verticalPadding,
  }) {
    final nextHorizontalPadding = horizontalPadding ?? this.horizontalPadding;
    final nextVerticalPadding = verticalPadding ?? this.verticalPadding;
    final nextMetricsKey = textStyleMetricsKey(style);
    final metricsUnchanged =
        width == _width &&
        height == _height &&
        nextMetricsKey == textStyleMetricsKey(_style) &&
        nextHorizontalPadding == this.horizontalPadding &&
        nextVerticalPadding == this.verticalPadding;
    if (metricsUnchanged) {
      if (style == _style) return false;
      _style = style;
      return true;
    }
    final locator = _confirmedLocator;
    if (locator == null) return false;

    _generation++;
    _debounce?.cancel();
    _width = width;
    _height = height;
    _style = style;
    this.horizontalPadding = nextHorizontalPadding;
    this.verticalPadding = nextVerticalPadding;
    _engine.dispose();
    _rebuildEngine();

    final page = _engine.pageContaining(
      locator.absoluteCharacterOffset,
      blockIndex: _blockIndex,
    )!;
    _window.reset(page, docLength: _document.text.length);
    _prefillWindow();
    _confirmedLocator = locator;
    return true;
  }

  void _rebuildEngine() {
    _engine = PagedLayoutEngine(
      text: _document.text,
      style: _style,
      textDirection: TextDirection.ltr,
      width: _width,
      height: _height,
      horizontalPadding: horizontalPadding,
      verticalPadding: verticalPadding,
    );
  }

  /// 最近一次布局签名（诊断 / 测试）。
  PagedLayoutSignature get lastSignature => _engine.signature;

  // ---- 保存 ----

  void _scheduleSave(ReaderLocator locator) {
    if (_disposed) return;
    _debounce?.cancel();
    final gen = _generation;
    _debounce = Timer(_debounceDuration, () async {
      // 过期异步结果拒绝（§二十一）：代数变化后不再写旧代位置。
      if (gen != _generation) return;
      if (_disposed) return;
      if (writesFrozen) return;
      await _progressRepository.saveProgress(
        ReaderProgressState(
          collectionId: collectionId,
          absoluteCharacterOffset: locator.absoluteCharacterOffset,
          readingMode: ReadingMode.paged,
          itemIdHint: locator.itemIdHint,
        ),
      );
    });
  }

  /// 立即 flush 最新已确认位置（生命周期 / 退出分页模式）。
  Future<void> flush() async {
    _debounce?.cancel();
    _debounce = null;
    final locator = _confirmedLocator;
    if (locator == null || _disposed || writesFrozen) return;
    await _progressRepository.saveProgress(
      ReaderProgressState(
        collectionId: collectionId,
        absoluteCharacterOffset: locator.absoluteCharacterOffset,
        readingMode: ReadingMode.paged,
        itemIdHint: locator.itemIdHint,
      ),
    );
  }

  /// 测试注入：跳过防抖立即返回当前 confirmed。
  ReaderLocator? get debugConfirmed => _confirmedLocator;

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    _engine.dispose();
    super.dispose();
  }
}
