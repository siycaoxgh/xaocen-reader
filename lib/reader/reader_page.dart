/// ReaderPage —— 纵向滚动 Reader（M3 最小功能 UI）。
///
/// 结构：
/// - 顶部：返回 / 书名 / 目录
/// - 正文：SuperListView.builder（虚拟滚动）+ Scrollbar
/// - 目录：抽屉（卷 / 章，当前章高亮）
///
/// 恢复流程：open() → jumpToItem(targetBlock) → post-frame 确认可见范围
/// → finishRestore() 解冻写入。
/// 用户滚动：reportUserScroll（防抖 400ms）；生命周期 flush。
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

import '../data/repositories/reading_progress_repository.dart';
import '../domain/library/library_entities.dart';
import '../domain/reader/reader_locator.dart';
import '../domain/reader/reader_visible_range.dart';
import 'normalized_document_loader.dart';
import 'reader_controller.dart';
import 'reader_text_block.dart';

/// 打开 Reader 所需上下文（由书架页组装）。
class ReaderLaunchContext {
  const ReaderLaunchContext({
    required this.collection,
    required this.documents,
    required this.toc,
    required this.normalizedCharacterLength,
    required this.documentLoader,
    required this.progressRepository,
    this.repair,
  });

  final LibraryCollection collection;

  /// M2 documents（任取一个取其 storagePath；whole 或首章均可）。
  final List<LibraryDocument> documents;

  final List<LibraryTocEntry> toc;
  final int normalizedCharacterLength;
  final NormalizedDocumentLoader documentLoader;
  final ReadingProgressRepository progressRepository;

  /// 修复回调（由书架页注入）：返回 null 表示成功，否则返回错误信息。
  final Future<String?> Function()? repair;
}

/// 打开 Reader 的工厂（书架页调用）。
Future<void> openReader(BuildContext context, ReaderLaunchContext launch) {
  return Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => ReaderPage(launch: launch)));
}

class ReaderPage extends StatefulWidget {
  const ReaderPage({
    super.key,
    required this.launch,
    this.documentOverride,
    this.progressOverride,
  });

  final ReaderLaunchContext launch;

  /// 测试注入：跳过文件加载直接提供文档。
  final NormalizedDocument? documentOverride;

  /// 测试注入：跳过 DB 查询直接使用该进度。
  final ReaderLocator? progressOverride;

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> with WidgetsBindingObserver {
  late final ReaderController _controller;
  final ScrollController _scroll = ScrollController();
  final ListController _listController = ListController();
  late final TextStyle _bodyStyle;

  bool _restoreFinished = false;

  /// 当前可见范围缓存（供测试与诊断）。
  ReaderVisibleRange? lastVisibleRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bodyStyle = const TextStyle(
      fontSize: 17,
      height: 1.7,
      color: Color(0xFF222222),
    );
    _controller = ReaderController(
      collectionId: widget.launch.collection.id,
      documentLoader: widget.launch.documentLoader,
      progressRepository: widget.launch.progressRepository,
      progressOverride: widget.progressOverride,
    );
    final override = widget.documentOverride;
    if (override != null) {
      _controller.injectDocument(override);
    }
    final doc = widget.launch.documents.isNotEmpty
        ? widget.launch.documents.first
        : null;
    if (doc != null) {
      // 注意：不把 doc.contentHash 当作 expectedHash 传入。
      // M2 早期版本 content_documents.content_hash 误存 sourceHash；
      // normalizedHash 的唯一权威是 manifest（与文件原子写入）。
      // Loader 内部优先读 manifest.normalizedHash 校验落盘字节。
      _controller.setDocumentSource(
        storagePath: doc.storagePath,
        expectedLength: widget.launch.normalizedCharacterLength,
      );
    }
    _controller.visibleRangeProvider = _measureVisibleRange;
    _controller.blockLayoutResolver = (index) => _layoutByIndex(index);
    _controller.addListener(_onControllerChanged);

    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onControllerChanged);
    // 生命周期 flush：写最新已确认用户位置
    _controller.flush();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _controller.flush(source: ReaderPositionEventSource.lifecycleFlush);
    }
  }

  /// 修复并重试（§十：修复后重新打开 Reader）。
  bool _repairing = false;

  Future<void> _repairAndRetry() async {
    final repair = widget.launch.repair;
    if (repair == null || _repairing) return;
    _repairing = true;
    setState(() {});
    try {
      final err = await repair();
      if (!mounted) return;
      if (err == null) {
        // 修复成功：重新初始化控制器并打开
        _controller.removeListener(_onControllerChanged);
        _controller.dispose();
        _controller = ReaderController(
          collectionId: widget.launch.collection.id,
          documentLoader: widget.launch.documentLoader,
          progressRepository: widget.launch.progressRepository,
          progressOverride: widget.progressOverride,
        );
        final doc = widget.launch.documents.isNotEmpty
            ? widget.launch.documents.first
            : null;
        if (doc != null) {
          _controller.setDocumentSource(
            storagePath: doc.storagePath,
            expectedLength: widget.launch.normalizedCharacterLength,
          );
        }
        _controller.visibleRangeProvider = _measureVisibleRange;
        _controller.blockLayoutResolver = (index) => _layoutByIndex(index);
        _controller.addListener(_onControllerChanged);
        _restoreFinished = false;
        _repairing = false;
        _start();
      } else {
        _repairing = false;
        setState(() {});
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('修复失败: $err')));
      }
    } catch (e) {
      _repairing = false;
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('修复失败: $e')));
      }
    }
  }

  Future<void> _start() async {
    await _controller.open();
    if (!mounted) return;
    setState(() {});
    // 列表可能尚未 attach：post-frame 再尝试跳转
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scheduleJumpToPendingTarget();
      // 列表 attach 后需要再等一帧确保布局完成
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scheduleJumpToPendingTarget();
      });
    });
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  /// 目标标题行置于 viewport 顶部安全区下方的期望间距（§九：8~24px）。
  static const double _kTitleInset = 12.0;

  /// 二次对齐/验证重试计数（bounded frame state machine，§十）。
  int _alignRetries = 0;

  /// 本次跳转是否来自目录点击（决定完成后 finishTocJump 还是 finishRestore）。
  bool _tocJumpPending = false;

  // ---- 跳转诊断（供测试与 _DebugBar）----
  Rect? lastTitleLineRect; // 目标标题行 Rect（块局部坐标）
  double? lastTitleLineGlobalTop;
  double? lastViewportTop;
  double? lastViewportBottom;
  double? lastAlignError; // 标题行顶部 - viewport 顶部 - inset
  String? lastJumpError;

  /// 跳转目标块（阶段1）→ 块内字符二次对齐（阶段2）→ 真实可见验证（阶段3）。
  ///
  /// 阶段1：jumpToItem(block.index) 只把目标块带进视口；
  /// 阶段2：用 RenderReaderTextBlock 实际 TextPainter 求目标字符所在行 Rect，
  ///        再次 jumpToItem(rect) 把标题行对齐 viewport 顶部 + inset；
  /// 阶段3：测量真实可见范围，确认标题行与 viewport 相交，才完成恢复/保存。
  void _scheduleJumpToPendingTarget() {
    final block = _controller.pendingTargetBlock;
    if (block == null || !_listController.isAttached) {
      return;
    }
    _alignRetries = 0;
    lastJumpError = null;
    _listController.jumpToItem(
      index: block.index,
      scrollController: _scroll,
      alignment: 0.0,
    );
    // post-frame：等目标块布局完成后做块内字符对齐
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scheduleSecondStageAlign();
    });
  }

  void _scheduleSecondStageAlign() {
    final block = _controller.pendingTargetBlock;
    final target = _controller.requestedLocator?.absoluteCharacterOffset;
    if (block == null || target == null || !_listController.isAttached) {
      _alignFailed('目标块或目标偏移不可用');
      return;
    }
    final render = _renderObjects[block.index];
    if (render == null || !render.layoutCompleted) {
      _alignRetries++;
      if (_alignRetries > 5) {
        _alignFailed('目标块布局未完成（bounded retries 超限）');
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scheduleSecondStageAlign();
      });
      return;
    }
    final localOffset = target - block.startCharacterOffset;
    if (localOffset < 0 ||
        localOffset > block.endCharacterOffset - block.startCharacterOffset) {
      _alignFailed('目标偏移超出目标块范围');
      return;
    }
    final rect = render.rectForCharacterOffset(localOffset);
    if (rect == null) {
      _alignFailed('无法解析目标字符行 Rect');
      return;
    }
    lastTitleLineRect = rect;
    // 阶段2：目标行顶部对齐 viewport 顶部（rect 为块局部坐标）
    _listController.jumpToItem(
      index: block.index,
      scrollController: _scroll,
      alignment: 0.0,
      rect: Rect.fromLTWH(0, rect.top, 1, rect.height),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // 微调：标题行置于 viewport 顶部安全区下方（8~24px）
      final pos = _scroll.position;
      if (pos.pixels > _kTitleInset) {
        pos.jumpTo(pos.pixels - _kTitleInset);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _verifyTargetVisible();
      });
    });
  }

  void _verifyTargetVisible() {
    final block = _controller.pendingTargetBlock;
    final target = _controller.requestedLocator?.absoluteCharacterOffset;
    if (block == null || target == null) {
      _alignFailed('目标块或目标偏移不可用');
      return;
    }
    final render = _renderObjects[block.index];
    final viewportTop = _viewportGlobalTop();
    final viewportBottom = viewportTop + _scroll.position.viewportDimension;
    lastViewportTop = viewportTop;
    lastViewportBottom = viewportBottom;
    if (render == null || !render.layoutCompleted) {
      _alignRetries++;
      if (_alignRetries > 5) {
        _alignFailed('目标标题行不可见（布局未完成）');
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _verifyTargetVisible();
      });
      return;
    }
    final localOffset = target - block.startCharacterOffset;
    final rect = render.rectForCharacterOffset(localOffset);
    if (rect == null) {
      _alignFailed('标题行 Rect 不可用');
      return;
    }
    final titleTop = render.localToGlobal(Offset(0, rect.top)).dy;
    final titleBottom = titleTop + rect.height;
    lastTitleLineGlobalTop = titleTop;
    lastAlignError = titleTop - viewportTop - _kTitleInset;
    final intersects = titleBottom > viewportTop && titleTop < viewportBottom;
    if (!intersects) {
      _alignRetries++;
      if (_alignRetries > 5) {
        _alignFailed('目标标题行未进入 viewport（对齐失败）');
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _verifyTargetVisible();
      });
      return;
    }
    // 对齐成功：重新测量真实可见范围并完成恢复/保存
    final visible = _measureVisibleRange();
    _controller.visibleRangeProvider = () => visible;
    if (_tocJumpPending) {
      _tocJumpPending = false;
      _controller.finishTocJump().then((_) {
        if (!mounted) return;
        setState(() {});
      });
    } else {
      _finishRestore();
    }
  }

  double _viewportGlobalTop() {
    final pos = _scroll.position;
    // ScrollPosition.context 是与之关联的 ScrollableState（非空时可用）
    final ctx = pos.context as dynamic;
    final state = ctx?.notificationContext ?? ctx?.context;
    final ro = state?.findRenderObject();
    if (ro is RenderBox) return ro.localToGlobal(Offset.zero).dy;
    return 0;
  }

  void _alignFailed(String reason) {
    lastJumpError = reason;
    if (_tocJumpPending) {
      // 目录跳转失败：不保存，保持原状态，给出明确失败
      _tocJumpPending = false;
    }
    if (!_restoreFinished) {
      _controller.markRestoreFailed('跳转失败: $reason');
    }
    if (mounted) setState(() {});
  }

  void _finishRestore() {
    _controller.finishRestore().then((_) {
      if (!mounted) return;
      _restoreFinished = true;
      setState(() {});
    });
  }

  /// 测量真实可见范围（由 controller 调用）。
  ReaderVisibleRange _measureVisibleRange() {
    final viewport = _scroll.position.viewportDimension;
    final top = _scroll.position.pixels;
    final bottom = top + viewport;
    final range = _visibleRangeForScroll(top, bottom);
    lastVisibleRange = range;
    return range;
  }

  ReaderVisibleRange _visibleRangeForScroll(double top, double bottom) {
    final index = _controller.blockIndex;
    final doc = _controller.document;
    if (index == null || doc == null || index.blockCount == 0) {
      return ReaderVisibleRange(
        startCharacterOffset: 0,
        endCharacterOffset: 0,
        firstVisibleBlock: 0,
        lastVisibleBlock: 0,
        measuredAt: DateTime.now(),
      );
    }

    // 当前树中已布局的块（虚拟列表只构建可见区附近的块）。
    // 以「已布局块」的最小/最大 index 与 offset 作为可见范围。
    // 只统计 key 仍在树中的块（回收的块 currentContext 为 null）。
    final active = <int>[];
    _blockKeys.forEach((i, key) {
      if (key.currentContext != null) {
        active.add(i);
      }
    });
    active.sort();
    if (active.isEmpty) {
      // 尚未布局：退回首块
      final b0 = index.blocks.first;
      return ReaderVisibleRange(
        startCharacterOffset: b0.startCharacterOffset,
        endCharacterOffset: b0.endCharacterOffset,
        firstVisibleBlock: 0,
        lastVisibleBlock: 0,
        measuredAt: DateTime.now(),
      );
    }
    final firstBlock = active.first;
    final lastBlock = active.last;
    return ReaderVisibleRange(
      startCharacterOffset: index.blocks[firstBlock].startCharacterOffset,
      endCharacterOffset: index.blocks[lastBlock].endCharacterOffset,
      firstVisibleBlock: firstBlock,
      lastVisibleBlock: lastBlock,
      measuredAt: DateTime.now(),
    );
  }

  ReaderBlockLayout? _layoutByIndex(int index) {
    final render = _renderObjects[index];
    if (render == null) return null;
    return ReaderBlockLayout(
      height: render.size.height,
      layoutCompleted: render.layoutCompleted,
      textWidth: render.textWidth,
      styleVersion: render.currentStyleVersion,
      lineCount: render.lineCount,
    );
  }

  /// 已构建的 RenderReaderTextBlock（index -> render）。
  final Map<int, RenderReaderTextBlock> _renderObjects = {};

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    if (state == ReaderState.failed) {
      final err = _controller.error ?? '';
      // §十：hash_mismatch 等派生数据损坏显示修复入口（不显示长内部路径）
      final repairable =
          err.contains('hash_mismatch') ||
          err.contains('length_mismatch') ||
          err.contains('bom_present') ||
          err.contains('invalid_utf8') ||
          err.contains('file_missing');
      return Scaffold(
        appBar: AppBar(title: Text(widget.launch.collection.title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                if (repairable && widget.launch.repair != null) ...[
                  Text(
                    '书籍文件需要修复',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '应用保存的正文缓存校验失败，可以从已托管的原始文件重新生成，'
                    '不会修改您的外部 TXT。',
                    textAlign: TextAlign.center,
                  ),
                ] else
                  Text('加载失败: $err', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('返回书架'),
                    ),
                    if (repairable && widget.launch.repair != null) ...[
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _repairAndRetry,
                        child: const Text('修复并重试'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state == ReaderState.loadingDocument ||
        _controller.document == null ||
        _controller.blockIndex == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.launch.collection.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final index = _controller.blockIndex!;
    final doc = _controller.document!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.launch.collection.title,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: '目录',
            onPressed: _openToc,
          ),
        ],
      ),
      body: Column(
        children: [
          if (const bool.fromEnvironment('XAOCEN_READER_DEBUG'))
            _DebugBar(controller: _controller, page: this),
          Expanded(
            child: Scrollbar(
              controller: _scroll,
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  _onUserScroll(n);
                  return false;
                },
                child: SuperListView.builder(
                  controller: _scroll,
                  listController: _listController,
                  itemCount: index.blockCount,
                  itemBuilder: (context, i) {
                    final block = index.blocks[i];
                    final text = doc.text.substring(
                      block.startCharacterOffset,
                      block.endCharacterOffset,
                    );
                    final key = _blockKeys[i] ??= GlobalKey();
                    return ReaderTextBlock(
                      key: key,
                      text: text,
                      style: _bodyStyle,
                      styleVersion: 1,
                      textDirection: TextDirection.ltr,
                      maxWidth: MediaQuery.of(context).size.width - 32,
                      onLayout: (layout) {
                        final ro = key.currentContext?.findRenderObject();
                        if (ro is RenderReaderTextBlock) {
                          _renderObjects[i] = ro;
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  final Map<int, GlobalKey> _blockKeys = {};

  void _onUserScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification ||
        notification is ScrollEndNotification ||
        notification is OverscrollNotification) {
      final topOffset = _topVisibleCharacterOffset();
      _controller.reportUserScroll(
        topVisibleCharacterOffset: topOffset,
        source: _userSource(notification),
      );
      if (notification is ScrollEndNotification) {
        _controller.flush(source: ReaderPositionEventSource.userScrollbar);
      }
    }
  }

  ReaderPositionEventSource _userSource(ScrollNotification n) {
    // 简化：拖动/滚轮/滚动条都归为用户来源（UI 不细分设备）。
    return ReaderPositionEventSource.userDrag;
  }

  int _topVisibleCharacterOffset() {
    final top = _scroll.position.pixels;
    final bottom = top + _scroll.position.viewportDimension;
    final range = _visibleRangeForScroll(top, bottom);
    return range.startCharacterOffset;
  }

  void _openToc() {
    // 当前章节高亮基于真实可见范围顶部（§十一），非上次点击/恢复位置
    final currentTop = _topVisibleCharacterOffset();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _TocSheet(
        toc: widget.launch.toc,
        controller: _controller,
        currentTopOffset: currentTop,
        collectionTitle: widget.launch.collection.title,
        onJump: _jumpToChapter,
      ),
    );
  }

  Future<void> _jumpToChapter(LibraryTocEntry entry) async {
    Navigator.of(context).pop(); // close sheet
    _tocJumpPending = true;
    _alignRetries = 0;
    await _controller.jumpToOffset(
      entry.startCharacterOffset,
      itemIdHint: entry.itemId,
    );
    if (!mounted) return;
    setState(() {});
    _scheduleJumpToPendingTarget();
  }
}

class _TocSheet extends StatelessWidget {
  const _TocSheet({
    required this.toc,
    required this.controller,
    required this.currentTopOffset,
    required this.collectionTitle,
    required this.onJump,
  });

  final List<LibraryTocEntry> toc;
  final ReaderController controller;

  /// 当前真实可见范围顶部字符偏移（来自用户滚动/跳转后的实测，§十一）。
  final int currentTopOffset;

  final String collectionTitle;
  final ValueChanged<LibraryTocEntry> onJump;

  @override
  Widget build(BuildContext context) {
    final chapters = toc.where((e) => e.kind == 'chapter').toList();
    final hasChapters = chapters.isNotEmpty;

    // 当前章节：最后一个 startCharacterOffset <= topVisible 的 chapter（§十一）
    LibraryTocEntry? currentChapter;
    if (hasChapters) {
      for (final e in chapters) {
        if (e.startCharacterOffset <= currentTopOffset) {
          currentChapter = e;
        } else {
          break;
        }
      }
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '目录 — $collectionTitle',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: !hasChapters
                  ? ListTile(
                      leading: const Icon(Icons.menu_book),
                      title: const Text('全文'),
                      subtitle: Text(
                        '无章节文件 · ${controller.document?.text.length ?? 0} 字符',
                      ),
                      selected: true,
                      onTap: () => onJump(
                        LibraryTocEntry(
                          id: 'whole',
                          collectionId: controller.collectionId,
                          itemId: null,
                          parentId: null,
                          kind: 'chapter',
                          level: 1,
                          title: '全文',
                          displayTitle: '全文',
                          orderIndex: 0,
                          startCharacterOffset: 0,
                          endCharacterOffset:
                              controller.document?.text.length ?? 0,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: toc.length,
                      itemBuilder: (context, i) {
                        final e = toc[i];
                        if (e.kind == 'volume') {
                          // 卷：完整卷标题（§五），可点击跳卷首
                          return ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.collections_bookmark_outlined,
                              size: 20,
                            ),
                            title: Text(
                              e.displayTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onTap: () => onJump(e),
                          );
                        }
                        final selected =
                            currentChapter?.id == e.id ||
                            (currentChapter == null && e.orderIndex == 1);
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.only(
                            left: 32,
                            right: 16,
                          ),
                          title: Text(
                            e.displayTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          selected: selected,
                          onTap: () => onJump(e),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _DebugBar extends StatelessWidget {
  const _DebugBar({required this.controller, required this.page});

  final ReaderController controller;
  final _ReaderPageState page;

  @override
  Widget build(BuildContext context) {
    final requested = controller.requestedLocator;
    final confirmed = controller.confirmedLocator;
    final range = page.lastVisibleRange;
    return Container(
      width: double.infinity,
      color: const Color(0x22000000),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        'req=${requested?.absoluteCharacterOffset ?? '-'} '
        'conf=${confirmed?.absoluteCharacterOffset ?? '-'} '
        'visible=${range?.startCharacterOffset ?? '-'}..'
        '${range?.endCharacterOffset ?? '-'} '
        'phase=${controller.restorePhase.name} '
        'blocks=${controller.blockIndex?.blockCount ?? 0}',
        style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
      ),
    );
  }
}
