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
  });

  final LibraryCollection collection;

  /// M2 documents（任取一个取其 storagePath；whole 或首章均可）。
  final List<LibraryDocument> documents;

  final List<LibraryTocEntry> toc;
  final int normalizedCharacterLength;
  final NormalizedDocumentLoader documentLoader;
  final ReadingProgressRepository progressRepository;
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

  Timer? _postJumpTimer;
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
      _controller.setDocumentSource(
        storagePath: doc.storagePath,
        expectedHash: doc.contentHash.isEmpty ? null : doc.contentHash,
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
    _postJumpTimer?.cancel();
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

  /// 跳转到待处理目标块。
  void _scheduleJumpToPendingTarget() {
    final block = _controller.pendingTargetBlock;
    if (block == null || !_listController.isAttached) {
      return;
    }
    _listController.jumpToItem(
      index: block.index,
      scrollController: _scroll,
      alignment: 0.0,
    );
    // post-frame 确认
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_restoreFinished) {
        _finishRestore();
      }
    });
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
                Text('加载失败: ${_controller.error}', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('返回书架'),
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
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _TocSheet(
        toc: widget.launch.toc,
        controller: _controller,
        collectionTitle: widget.launch.collection.title,
        onJump: _jumpToChapter,
      ),
    );
  }

  Future<void> _jumpToChapter(LibraryTocEntry entry) async {
    Navigator.of(context).pop(); // close sheet
    await _controller.jumpToOffset(
      entry.startCharacterOffset,
      itemIdHint: entry.itemId,
    );
    if (!mounted) return;
    setState(() {});
    _scheduleJumpToPendingTarget();
    // 目录跳转完成确认后立即保存
    _postJumpTimer?.cancel();
    _postJumpTimer = Timer(const Duration(milliseconds: 100), () {
      _controller.finishTocJump();
    });
  }
}

class _TocSheet extends StatelessWidget {
  const _TocSheet({
    required this.toc,
    required this.controller,
    required this.collectionTitle,
    required this.onJump,
  });

  final List<LibraryTocEntry> toc;
  final ReaderController controller;
  final String collectionTitle;
  final ValueChanged<LibraryTocEntry> onJump;

  @override
  Widget build(BuildContext context) {
    final chapters = toc.where((e) => e.kind == 'chapter').toList();
    final volumes = toc.where((e) => e.kind == 'volume').toList();
    final currentOffset =
        controller.confirmedLocator?.absoluteCharacterOffset ?? 0;

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
              child: chapters.isEmpty
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
                          orderIndex: 0,
                          startCharacterOffset: 0,
                          endCharacterOffset:
                              controller.document?.text.length ?? 0,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: chapters.length,
                      itemBuilder: (context, i) {
                        final e = chapters[i];
                        final selected =
                            currentOffset >= e.startCharacterOffset &&
                            currentOffset < e.endCharacterOffset;
                        return ListTile(
                          dense: true,
                          title: Text(
                            e.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          selected: selected,
                          trailing: volumes.isEmpty
                              ? null
                              : Text(
                                  '${e.orderIndex + 1}',
                                  style: const TextStyle(fontSize: 12),
                                ),
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
