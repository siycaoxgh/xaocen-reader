/// PagedReaderView —— 横向分页阅读视图（M4）。
///
/// - 容器：Flutter 内置 PageView + PageController（§十六）；
///   PageView index 只是**内存窗口索引**，不等同全书 pageIndex，不持久化；
/// - 每页：复用 M3 的 ReaderTextBlock（显示与测量同一 TextPainter 参数，
///   §八 合同）——正文样式与 PagedLayoutEngine 完全一致；
/// - Android：PageView 原生左右滑动（左滑下一页/右滑上一页/回弹/fling）；
/// - Windows：Left/Right/PageUp/PageDown 键盘翻页（§二十二）；
///   鼠标滚轮决策 A：不参与分页（避免滚一下连续翻页）；
/// - 边界：第一页 startReached / 最后一页 endReached（§二十七/§二十八）；
/// - 窗口变化（windowGeneration）：**不重建 PageView / 不重建 PageController**
///   （单一 controller 生命周期）；仅用 jumpToPage 跟随窗口 currentIndex，
///   保持当前视觉页无跳变。避免旧 RenderObject dispose 后仍参与 layout 的竞态。
// ignore_for_file: prefer_initializing_formals
library;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import 'normalized_document_loader.dart';
import 'page_window.dart';
import 'paged_reader_controller.dart';
import 'reader_appearance.dart';
import 'reader_text_block.dart';
import 'reader_input.dart';

/// 分页阅读视图。
class PagedReaderView extends StatefulWidget {
  const PagedReaderView({
    super.key,
    required this.controller,
    required this.appearance,
  });

  final PagedReaderController controller;
  final ReaderResolvedAppearance appearance;

  @override
  State<PagedReaderView> createState() => _PagedReaderViewState();
}

class _PagedReaderViewState extends State<PagedReaderView> {
  /// 单一 PageController：整个视图生命周期内只创建/释放一次，绝不重建。
  late PageController _pageController;
  final FocusNode _focusNode = FocusNode();
  final InputBinding _inputBinding = InputBinding.defaults;
  DateTime? _lastWheelTurn;

  static const _wheelThrottle = Duration(milliseconds: 140);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _pageController = PageController(
      initialPage: widget.controller.window.currentIndex,
    );
    // The Android host only reports volume keys while this paged subtree is
    // active. Mapping to previous/next remains a Dart concern.
    ReaderInputBridge.activatePaged(_onPhysicalInput);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _pageController.dispose();
    _focusNode.dispose();
    ReaderInputBridge.deactivatePaged();
    super.dispose();
  }

  /// 窗口变化（generation++ / select / extend）后保持视觉页：
  /// 不重建 controller、不重建 PageView；仅当显示页与窗口 currentIndex
  /// 不一致时 jumpToPage 跟随。jumpToPage 触发的 onPageChanged 会因
  /// rawIndex == currentIndex 而被忽略（见 _onPageChanged）。
  void _followWindow() {
    if (!_pageController.hasClients) return;
    final win = widget.controller.window;
    final shown = _pageController.page?.round();
    final target = win.currentIndex;
    if (shown != null && shown != target) {
      _pageController.jumpToPage(target);
    }
  }

  void _onControllerChanged() {
    if (!mounted) return;
    _followWindow();
    setState(() {});
  }

  /// PageView 完成一页切换（用户滑动 settle）。
  void _onPageChanged(int rawIndex) {
    final win = widget.controller.window;
    // attach/重建的 initialPage 回调 rawIndex == currentIndex：当前页未变，忽略。
    // 用户滑动后 rawIndex != currentIndex → 真实翻页，处理。
    if (rawIndex == win.currentIndex) return;
    final page = win.pageAt(rawIndex);
    if (page == null) return;

    // 边界扩展：当前页在窗口边界且仍有内容时，同步生成相邻页。
    var index = rawIndex;
    if (rawIndex == win.pageCount - 1 &&
        !widget.controller.engine.isDocumentEnd(page.endCharacterOffset)) {
      final next = widget.controller.engine.layoutForwardPage(
        page.endCharacterOffset,
      );
      if (next != null) win.extendTail(next);
    } else if (rawIndex == 0 && page.startCharacterOffset > 0) {
      final prev = widget.controller.engine.layoutPreviousPage(
        page.startCharacterOffset,
      );
      if (prev != null) {
        win.extendHead(prev);
        index = rawIndex + 1; // 头部加页后，原页索引后移
      }
    }

    win.select(index);
    // §十九：settle 后更新 confirmed + 防抖保存（只拖动一半不保存）。
    widget.controller.onPageSettled(win.current!);
    // select 可能触发窗口收缩（trim 删头部页、currentIndex 变化）：
    // 跟随窗口 currentIndex，保持显示页 = 用户所在页（防 itemCount 缩水越界）。
    _followWindow();
    if (mounted) setState(() {});
  }

  /// Windows 键盘翻页（§二十二）。
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final input = switch (key) {
      LogicalKeyboardKey.arrowRight => PhysicalInput.arrowRight,
      LogicalKeyboardKey.pageDown => PhysicalInput.pageDown,
      LogicalKeyboardKey.arrowLeft => PhysicalInput.arrowLeft,
      LogicalKeyboardKey.pageUp => PhysicalInput.pageUp,
      _ => null,
    };
    if (input != null && _dispatchInput(input)) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _onPhysicalInput(PhysicalInput input) {
    _dispatchInput(input);
  }

  bool _dispatchInput(PhysicalInput input) {
    final command = _inputBinding.commandFor(input);
    if (command == null) return false;
    switch (command) {
      case ReaderCommand.previousPage:
        _turnPage(forward: false);
      case ReaderCommand.nextPage:
        _turnPage(forward: true);
      case ReaderCommand.previousChapter:
      case ReaderCommand.nextChapter:
      case ReaderCommand.toggleReaderControls:
      case ReaderCommand.openToc:
        // M5.3a/b defines these commands but deliberately does not route
        // them into Reader actions yet.
        break;
    }
    return true;
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final dy = event.scrollDelta.dy;
    if (dy == 0) return;
    final now = DateTime.now();
    if (_lastWheelTurn != null &&
        now.difference(_lastWheelTurn!) < _wheelThrottle) {
      return;
    }
    _lastWheelTurn = now;
    _dispatchInput(dy < 0 ? PhysicalInput.wheelUp : PhysicalInput.wheelDown);
  }

  void _turnPage({required bool forward}) {
    final result = forward
        ? widget.controller.nextPage()
        : widget.controller.previousPage();
    if (result == PageTurnResult.ok) {
      _followWindow();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final win = widget.controller.window;
    final doc = widget.controller.document;
    final appearance = widget.appearance;

    if (win.pageCount == 0) {
      // 空文档 / 尚未定位：空状态（§二十九：不 crash、可预测）。
      return ColoredBox(
        color: appearance.backgroundColor,
        child: const Center(child: Text('（空文档）')),
      );
    }

    // LayoutBuilder 感知实际渲染尺寸：首次切换 / resize / orientation 时
    // 静默同步引擎（本帧即用新尺寸，无闪跳、无超约束；confirmed 不变）。
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        if (widget.controller.engine.width != w ||
            widget.controller.engine.height != h) {
          widget.controller.relayoutSilently(
            width: w,
            height: h,
            style: appearance.baseTextStyle,
          );
        }
        return _buildContent(context, win, doc, appearance);
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    PageWindow win,
    NormalizedDocument doc,
    ReaderResolvedAppearance appearance,
  ) {
    return Listener(
      onPointerSignal: _onPointerSignal,
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: PageView.builder(
          controller: _pageController,
          itemCount: win.pageCount,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, i) {
            final page = win.pageAt(i);
            if (page == null) return const SizedBox.shrink();
            final text = doc.text.substring(
              page.startCharacterOffset,
              page.endCharacterOffset,
            );
            return ColoredBox(
              color: appearance.backgroundColor,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  widget.controller.paddingLeft,
                  widget.controller.paddingTop,
                  widget.controller.paddingRight,
                  widget.controller.paddingBottom,
                ),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: ReaderTextBlock(
                    text: text,
                    style: appearance.baseTextStyle,
                    paragraphSpacing: widget.controller.paragraphSpacing,
                    firstLineIndent: widget.controller.firstLineIndent,
                    startsAtParagraphBoundary:
                        page.startCharacterOffset == 0 ||
                        widget.controller.document.text.codeUnitAt(
                              page.startCharacterOffset - 1,
                            ) ==
                            0x0A,
                    styleVersion: appearance.textColor.toARGB32(),
                    textDirection: TextDirection.ltr,
                    // §八：显示与测量同一宽度（引擎 contentWidth）。
                    maxWidth: widget.controller.engine.contentWidth,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
