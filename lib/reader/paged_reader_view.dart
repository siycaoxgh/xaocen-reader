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
import 'reader_input_router.dart';

/// 分页阅读视图。
class PagedReaderView extends StatefulWidget {
  const PagedReaderView({
    super.key,
    required this.controller,
    required this.appearance,
    this.inputRouter,
    this.onUserNavigation,
    this.focusNode,
  });

  final PagedReaderController controller;
  final ReaderResolvedAppearance appearance;
  final ReaderInputRouter? inputRouter;
  final VoidCallback? onUserNavigation;

  /// Optional route-owned focus node.  ReaderPage uses this to restore
  /// shortcut focus after Aa/TOC (or another modal) closes.
  final FocusNode? focusNode;

  @override
  State<PagedReaderView> createState() => _PagedReaderViewState();
}

class _PagedReaderViewState extends State<PagedReaderView> {
  /// 单一 PageController：整个视图生命周期内只创建/释放一次，绝不重建。
  late PageController _pageController;
  late FocusNode _focusNode;
  bool _ownsFocusNode = false;
  final InputBinding _inputBinding = InputBinding.defaults;
  DateTime? _lastWheelTurn;
  bool _userGestureActive = false;
  bool _navigationNotified = false;
  int? _gestureWindowGeneration;
  int? _programmaticTargetIndex;
  int? _edgeFallbackGeneration;
  Offset? _pointerDownPosition;

  static const _wheelThrottle = Duration(milliseconds: 140);

  @override
  void initState() {
    super.initState();
    _focusNode =
        widget.focusNode ?? FocusNode(debugLabel: 'paged-reader-input');
    _ownsFocusNode = widget.focusNode == null;
    widget.controller.addListener(_onControllerChanged);
    _pageController = PageController(
      initialPage: widget.controller.window.currentIndex,
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _pageController.dispose();
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PagedReaderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode == widget.focusNode) return;
    if (_ownsFocusNode) _focusNode.dispose();
    _focusNode =
        widget.focusNode ?? FocusNode(debugLabel: 'paged-reader-input');
    _ownsFocusNode = widget.focusNode == null;
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
      _programmaticTargetIndex = target;
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
    if (_programmaticTargetIndex == rawIndex) {
      _programmaticTargetIndex = null;
      return;
    }
    if (!_userGestureActive && _programmaticTargetIndex != null) return;
    final gestureWindowGeneration = _gestureWindowGeneration;
    if (gestureWindowGeneration != null &&
        gestureWindowGeneration != win.windowGeneration) {
      return;
    }
    if (rawIndex == win.currentIndex) return;
    final generation = widget.controller.layoutGeneration;
    if (!widget.controller.settleGestureAtWindowIndex(
      rawIndex,
      generation: generation,
    )) {
      return;
    }
    _followWindow();
    if (mounted) setState(() {});
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      // A ScrollStart can be emitted for a tap on some platforms. Defer the
      // navigation signal until a real drag update so center taps never alter
      // Reader chrome or AutoRead state.
      _userGestureActive = true;
      _navigationNotified = false;
      _programmaticTargetIndex = null;
      _gestureWindowGeneration = widget.controller.window.windowGeneration;
      _edgeFallbackGeneration = null;
    } else if (notification is ScrollUpdateNotification &&
        notification.dragDetails != null &&
        _userGestureActive &&
        !_navigationNotified) {
      _navigationNotified = true;
      widget.onUserNavigation?.call();
    } else if (notification is OverscrollNotification && _userGestureActive) {
      final metrics = notification.metrics;
      final atEnd = metrics.pixels >= metrics.maxScrollExtent;
      final atStart = metrics.pixels <= metrics.minScrollExtent;
      if (atEnd) {
        _fallbackAtEdge(forward: true);
      } else if (atStart) {
        _fallbackAtEdge(forward: false);
      }
    } else if (notification is ScrollEndNotification) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _userGestureActive = false;
        _navigationNotified = false;
        _gestureWindowGeneration = null;
      });
    }
    return false;
  }

  void _fallbackAtEdge({required bool forward}) {
    final generation = widget.controller.layoutGeneration;
    if (_edgeFallbackGeneration == generation) return;
    final result = forward
        ? widget.controller.nextPage()
        : widget.controller.previousPage();
    if (result != PageTurnResult.ok) return;
    _edgeFallbackGeneration = generation;
    _followWindow();
    if (mounted) setState(() {});
  }

  void _onPointerDown(PointerDownEvent event) {
    // Mouse middle is a physical input, not a page drag. Route it through
    // the same binding/capture boundary as keyboard and wheel input.
    if (event.kind == PointerDeviceKind.mouse &&
        event.buttons & kMiddleMouseButton != 0) {
      widget.inputRouter?.handlePhysicalInput(
        PhysicalInputId.mouseMiddleButton,
      );
      return;
    }
    // Keep keyboard shortcuts owned by the Reader after a panel/control has
    // previously taken focus.  PageView itself does not reliably request this
    // node on a pointer tap, so without an explicit request the next
    // PageUp/PageDown/arrow event can be consumed by the former control (or
    // by Scrollable's default actions) instead of reaching ReaderInputRouter.
    _focusNode.requestFocus();
    _pointerDownPosition = event.position;
    _userGestureActive = true;
    _gestureWindowGeneration = widget.controller.window.windowGeneration;
    _edgeFallbackGeneration = null;
  }

  void _onPointerUp(PointerUpEvent event) {
    final start = _pointerDownPosition;
    if (start != null && _userGestureActive) {
      final deltaX = event.position.dx - start.dx;
      if (deltaX.abs() >= 24) {
        final win = widget.controller.window;
        if (deltaX < 0 &&
            win.currentIndex >= win.pageCount - 1 &&
            win.tailHasPotentialNext) {
          _fallbackAtEdge(forward: true);
        } else if (deltaX > 0 &&
            win.currentIndex <= 0 &&
            !win.atDocumentStart) {
          _fallbackAtEdge(forward: false);
        }
      }
    }
    _pointerDownPosition = null;
    _userGestureActive = false;
    _navigationNotified = false;
    _gestureWindowGeneration = null;
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _pointerDownPosition = null;
    _userGestureActive = false;
    _navigationNotified = false;
    _gestureWindowGeneration = null;
  }

  /// Windows 键盘翻页（§二十二）。
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final router = widget.inputRouter;
    if (router != null) {
      final input = readerInputGestureForEvent(
        event,
        control: HardwareKeyboard.instance.isControlPressed,
        alt: HardwareKeyboard.instance.isAltPressed,
        shift: HardwareKeyboard.instance.isShiftPressed,
      );
      if (input != null && router.handlePhysicalGesture(input)) {
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
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

  bool _dispatchInput(PhysicalInput input) {
    final router = widget.inputRouter;
    if (router != null) {
      final id = switch (input) {
        PhysicalInput.arrowLeft => PhysicalInputId.keyboardArrowLeft,
        PhysicalInput.arrowRight => PhysicalInputId.keyboardArrowRight,
        PhysicalInput.pageUp => PhysicalInputId.keyboardPageUp,
        PhysicalInput.pageDown => PhysicalInputId.keyboardPageDown,
        PhysicalInput.wheelUp => PhysicalInputId.mouseWheelUp,
        PhysicalInput.wheelDown => PhysicalInputId.mouseWheelDown,
        PhysicalInput.volumeUp => PhysicalInputId.androidVolumeUp,
        PhysicalInput.volumeDown => PhysicalInputId.androidVolumeDown,
      };
      return router.handlePhysicalInput(id);
    }
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
      case ReaderCommand.toggleAutoRead:
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
    widget.onUserNavigation?.call();
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
            textAlign: widget.controller.textAlign,
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
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      onPointerSignal: _onPointerSignal,
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScrollNotification,
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
                color: appearance.hasBackgroundImage
                    ? Colors.transparent
                    : appearance.backgroundColor,
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
                      textAlign: widget.controller.textAlign,
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
      ),
    );
  }
}
