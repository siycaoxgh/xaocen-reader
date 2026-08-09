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

import '../design/theme/app_theme.dart';
import '../data/repositories/reading_progress_repository.dart';
import '../data/repositories/reader_preferences_repository.dart';
import '../domain/library/library_entities.dart';
import '../domain/library/toc_index.dart';
import '../domain/reader/reader_locator.dart';
import '../domain/reader/paged_text_range.dart';
import '../domain/reader/reader_block.dart';
import '../domain/reader/reader_preferences.dart';
import '../domain/reader/reader_visible_range.dart';
import 'normalized_document_loader.dart';
import 'paged_reader_controller.dart';
import 'paged_reader_view.dart';
import 'reader_appearance.dart';
import 'reader_chrome.dart';
import 'reader_controller.dart';
import 'reader_mode.dart';
import 'reader_metrics_signature.dart';
import '../domain/reader/reader_progress_state.dart';
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
    this.preferencesRepository,
    this.repair,
  });

  final LibraryCollection collection;

  /// M2 documents（任取一个取其 storagePath；whole 或首章均可）。
  final List<LibraryDocument> documents;

  final List<LibraryTocEntry> toc;
  final int normalizedCharacterLength;
  final NormalizedDocumentLoader documentLoader;
  final ReadingProgressRepository progressRepository;
  final ReaderPreferencesRepository? preferencesRepository;

  /// 修复回调（由书架页注入）：返回 null 表示成功，否则返回错误信息。
  final Future<String?> Function()? repair;
}

/// 打开 Reader 的工厂（书架页调用）。
Future<void> openReader(BuildContext context, ReaderLaunchContext launch) {
  return Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => ReaderPage(launch: launch)));
}

@immutable
class ReaderModeRestoreReport {
  const ReaderModeRestoreReport({
    required this.generation,
    required this.target,
    required this.confirmed,
    required this.visibleRange,
  });

  final int generation;
  final ReaderLocator target;
  final ReaderLocator confirmed;
  final ReaderVisibleRange visibleRange;
}

class ReaderPage extends StatefulWidget {
  const ReaderPage({
    super.key,
    required this.launch,
    this.documentOverride,
    this.progressOverride,
    this.initialStateOverride,
    this.preferencesOverride,
    this.onMetricsRelayout,
    this.onModeRestore,
  });

  final ReaderLaunchContext launch;

  /// 测试注入：跳过文件加载直接提供文档。
  final NormalizedDocument? documentOverride;

  /// 测试注入：跳过 DB 查询直接使用该进度。
  final ReaderLocator? progressOverride;

  /// 测试注入：含 readingMode 的初始状态（跳过 DB 查询）。
  /// 用于 widget 测试验证“重开恢复模式 + 位置”。
  final ReaderProgressState? initialStateOverride;

  /// 测试注入：绕过 storage，直接驱动强类型设置流。
  final Stream<ReaderPreferences>? preferencesOverride;
  final ValueChanged<ReaderMetricsRelayoutReport>? onMetricsRelayout;
  final ValueChanged<ReaderModeRestoreReport>? onModeRestore;

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> with WidgetsBindingObserver {
  late final ReaderController _controller;
  final ScrollController _scroll = ScrollController();
  final ListController _listController = ListController();
  late TextStyle _bodyStyle;
  ReaderPreferences _preferences = ReaderPreferences.defaults;
  late ReaderMetricsSignature _metricsSignature =
      ReaderMetricsSignature.fromPreferences(_preferences);
  StreamSubscription<ReaderPreferences>? _preferencesSubscription;
  int _metricsGeneration = 0;
  ReaderLocator? _metricsAnchor;
  bool _metricsWritesFrozen = false;
  ReaderVisibleRange? _metricsVisibleBefore;
  PagedTextRange? _metricsPageBefore;
  bool _preferencesReady = false;
  ReaderPreferences? _pendingPreferencesWrite;
  bool _pendingPreferencesReset = false;
  bool _preferencesWriteInFlight = false;

  /// Reader 视觉合同（P1：从 Theme 解析，禁止正文硬编码颜色）。
  late ReaderResolvedAppearance _appearance;

  /// 上次应用的主题（didChangeDependencies 检测切换）。
  ThemeData? _lastTheme;

  bool _restoreFinished = false;

  /// 当前可见范围缓存（供测试与诊断）。
  ReaderVisibleRange? lastVisibleRange;

  // ---- M4：双模式 ----

  /// 初始状态（重开时从库读取，含 readingMode）。
  ReaderProgressState? _initialState;

  /// 当前阅读模式（纵向 M3 / 横向分页 M4）。
  ReaderMode _mode = ReaderMode.vertical;

  /// 模式切换状态机（§二十一）。
  ReaderModeTransitionState _transition = ReaderModeTransitionState.idle;

  /// 分页模式控制器（首次切换到分页时创建）。
  PagedReaderController? _pagedController;

  /// 模式切换代数：切换时递增，过期异步结果被拒绝（§二十一）。
  int _modeGeneration = 0;
  ReaderLocator? _modeRestoreAnchor;
  int? _modeRestoreGeneration;
  bool _suppressProgrammaticScrollNotifications = false;
  bool _chromeVisible = true;

  void _toggleChrome() {
    setState(() => _chromeVisible = !_chromeVisible);
  }

  void _showChrome() {
    if (_chromeVisible) return;
    setState(() => _chromeVisible = true);
  }

  void _traceModeTransition(
    String event, {
    ReaderLocator? confirmed,
    ReaderLocator? target,
    int? generation,
  }) {
    assert(() {
      debugPrint(
        'reader-mode collection=${widget.launch.collection.id} '
        'event=$event activeMode=${_mode.name} '
        'confirmedLocator=${confirmed?.absoluteCharacterOffset ?? '-'} '
        'persistedLocator=${_initialState?.absoluteCharacterOffset ?? '-'} '
        'targetLocator=${target?.absoluteCharacterOffset ?? '-'} '
        'generation=${generation ?? _modeGeneration} '
        'timestamp=${DateTime.now().toIso8601String()}',
      );
      return true;
    }());
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_initializePreferencesAndStart());
    });
  }

  Future<void> _initializePreferencesAndStart() async {
    final repository = widget.launch.preferencesRepository;
    final collectionId = widget.launch.collection.id;
    if (widget.preferencesOverride case final override?) {
      _preferencesSubscription = override.listen(_onPreferencesChanged);
    } else if (repository != null) {
      final saved = await repository.load(collectionId);
      if (!mounted) return;
      _preferences = saved;
      _metricsSignature = ReaderMetricsSignature.fromPreferences(saved);
      _preferencesSubscription = repository
          .watch(collectionId)
          .listen(_onPreferencesChanged);
    }
    if (!mounted) return;
    _preferencesReady = true;
    _resolveAppearance();
    setState(() {});
    await _start();
  }

  ThemeData _effectiveReaderTheme() => switch (_preferences.themeMode) {
    ReaderThemeMode.system => Theme.of(context),
    ReaderThemeMode.light => AppTheme.light(),
    ReaderThemeMode.dark => AppTheme.dark(),
  };

  void _resolveAppearance() {
    final scheme = _effectiveReaderTheme().colorScheme;
    _appearance = ReaderResolvedAppearance(
      backgroundColor: scheme.surface,
      textColor: scheme.onSurface,
      secondaryTextColor: scheme.onSurfaceVariant,
      headingColor: scheme.onSurface,
      selectionColor: scheme.primaryContainer,
      baseTextStyle: TextStyle(
        fontSize: _preferences.fontSize,
        height: _preferences.lineHeight,
        letterSpacing: _preferences.letterSpacing,
        color: scheme.onSurface,
      ),
    );
    _bodyStyle = _appearance.baseTextStyle;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = Theme.of(context);
    if (theme != _lastTheme) {
      _lastTheme = theme;
      // P1：主题切换 → 解析新外观。颜色变化只触发重绘
      // （RenderReaderTextBlock.style setter 区分度量/颜色），
      // 不重建 block 索引、不写进度、阅读 offset 保持不变。
      _resolveAppearance();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _modeGeneration++;
    _modeRestoreAnchor = null;
    _modeRestoreGeneration = null;
    _metricsGeneration++;
    _preferencesSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onControllerChanged);
    final paged = _pagedController;
    if (paged != null) {
      paged.removeListener(_onPagedControllerChanged);
    }
    // M4 P1：只有“当前激活的 Reader 模式”允许提交位置。
    // inactive/disposed 的 VerticalReader 或 PagedReader 不得
    // 在 route pop / lifecycle / dispose 时覆盖当前模式的新进度。
    if (_mode == ReaderMode.paged) {
      paged?.flush(); // active = 分页：保存 paged confirmed
    } else {
      _controller.flush(); // active = 纵向：保存纵向 confirmed
    }
    paged?.dispose();
    _pagedController = null;
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (_modeRestoreAnchor != null) {
        _cancelModeRestore(revertToPaged: true);
        return;
      }
      // M4 P1：只 flush 当前激活模式，
      // 避免 inactive 纵向覆盖分页新位置。
      if (_mode == ReaderMode.paged) {
        _pagedController?.flush();
      } else {
        _controller.flush(source: ReaderPositionEventSource.lifecycleFlush);
      }
    }
  }

  void _onPreferencesChanged(ReaderPreferences next) {
    if (!mounted) return;
    final previous = _preferences;
    final nextSignature = ReaderMetricsSignature.fromPreferences(next);
    _preferences = next;
    if (nextSignature == _metricsSignature) {
      if (next.themeMode != previous.themeMode) {
        _resolveAppearance();
        setState(() {});
      }
      return;
    }
    _metricsSignature = nextSignature;
    _beginMetricsRelayout(next);
  }

  void _commitPreferences(ReaderPreferences next) {
    _onPreferencesChanged(next);
    final repository = widget.launch.preferencesRepository;
    if (repository == null) return;
    _pendingPreferencesReset = false;
    _pendingPreferencesWrite = next;
    if (!_preferencesWriteInFlight) unawaited(_drainPreferencesWrites());
  }

  Future<void> _drainPreferencesWrites() async {
    final repository = widget.launch.preferencesRepository;
    if (repository == null || _preferencesWriteInFlight) return;
    _preferencesWriteInFlight = true;
    try {
      while (_pendingPreferencesReset || _pendingPreferencesWrite != null) {
        if (_pendingPreferencesReset) {
          _pendingPreferencesReset = false;
          await repository.resetToDefaults(widget.launch.collection.id);
        } else if (_pendingPreferencesWrite case final next?) {
          _pendingPreferencesWrite = null;
          await repository.update(widget.launch.collection.id, next);
        }
      }
    } finally {
      _preferencesWriteInFlight = false;
    }
  }

  void _resetPreferences() {
    _onPreferencesChanged(ReaderPreferences.defaults);
    _pendingPreferencesWrite = null;
    _pendingPreferencesReset = true;
    final repository = widget.launch.preferencesRepository;
    if (repository != null && !_preferencesWriteInFlight) {
      unawaited(_drainPreferencesWrites());
    }
  }

  void _freezeMetricsWrites() {
    if (_metricsWritesFrozen) {
      _controller.unfreezeWrites();
      _pagedController?.unfreezeWrites();
    }
    _controller.freezeWrites();
    _pagedController?.freezeWrites();
    _metricsWritesFrozen = true;
  }

  void _unfreezeMetricsWrites() {
    if (!_metricsWritesFrozen) return;
    _controller.unfreezeWrites();
    _pagedController?.unfreezeWrites();
    _metricsWritesFrozen = false;
  }

  void _cancelMetricsRelayout() {
    _metricsGeneration++;
    _metricsAnchor = null;
    _metricsVisibleBefore = null;
    _metricsPageBefore = null;
    _unfreezeMetricsWrites();
  }

  void _beginMetricsRelayout(ReaderPreferences next) {
    _cancelModeRestore();
    final activeLocator = _mode == ReaderMode.paged
        ? _pagedController?.confirmedLocator
        : _controller.confirmedLocator;
    if (activeLocator == null) {
      _resolveAppearance();
      setState(() {});
      return;
    }

    final generation = ++_metricsGeneration;
    _metricsAnchor = activeLocator;
    _metricsVisibleBefore = _mode == ReaderMode.vertical
        ? lastVisibleRange
        : null;
    _metricsPageBefore = _mode == ReaderMode.paged
        ? _pagedController?.currentPage
        : null;
    _freezeMetricsWrites();
    _resolveAppearance();

    if (_mode == ReaderMode.paged) {
      final paged = _pagedController;
      if (paged == null) {
        _cancelMetricsRelayout();
        return;
      }
      final size = _pagedViewportSize;
      paged.relayout(
        width: size.width > 0 ? size.width : paged.engine.width,
        height: size.height > 0 ? size.height : paged.engine.height,
        style: _bodyStyle,
        paddingTop: next.paddingTop,
        paddingBottom: next.paddingBottom,
        paddingLeft: next.paddingLeft,
        paddingRight: next.paddingRight,
        paragraphSpacing: next.paragraphSpacing,
        firstLineIndent: next.firstLineIndent,
      );
      if (generation != _metricsGeneration || !mounted) return;
      final page = paged.currentPage;
      assert(
        page != null && page.contains(activeLocator.absoluteCharacterOffset),
      );
      assert(paged.confirmedLocator == activeLocator);
      widget.onMetricsRelayout?.call(
        ReaderMetricsRelayoutReport(
          generation: generation,
          locatorBefore: activeLocator,
          locatorAfter: paged.confirmedLocator!,
          signature: _metricsSignature,
          pageBefore: _metricsPageBefore,
          pageAfter: page,
        ),
      );
      _metricsAnchor = null;
      _metricsPageBefore = null;
      _unfreezeMetricsWrites();
      setState(() {});
      return;
    }

    _renderObjects.clear();
    _restoreFinished = false;
    _controller
        .jumpToOffset(
          activeLocator.absoluteCharacterOffset,
          itemIdHint: activeLocator.itemIdHint,
        )
        .then((_) {
          if (!mounted || generation != _metricsGeneration) return;
          setState(() {});
          _scheduleJumpToPendingTarget();
        });
    setState(() {});
  }

  /// 分页控制器变化（窗口重建/翻页后）→ setState。
  void _onPagedControllerChanged() {
    if (mounted) setState(() {});
  }

  // ---- M4：模式切换（§十七~§二十一）----

  /// 当前分页模式正文样式（与纵向同一外观）。
  TextStyle get _pagedBodyStyle => _appearance.baseTextStyle;

  /// 分页模式内容区尺寸（由 body 布局提供；切换前用屏幕估算）。
  Size _pagedViewportSize = const Size(0, 0);

  /// 纵向 → 分页（§十七）：
  /// freeze → 取真实可见范围顶部 anchor → pageContaining(anchor) →
  /// 验证 anchor 在页内 → 显示 → unfreeze。
  /// 页面开头可以早于 anchor；anchor 不被改成 page.start。
  void _switchToPaged() {
    if (_transition != ReaderModeTransitionState.idle) return;
    if (_controller.document == null || _controller.blockIndex == null) {
      return;
    }
    final gen = ++_modeGeneration;
    _transition = ReaderModeTransitionState.verticalToPaged;
    _controller.freezeWrites();
    setState(() {});

    // 取真实可见范围顶部作为切换锚点（§十七 switchAnchor）。
    final anchor =
        _controller.confirmedLocator ??
        ReaderLocator(
          collectionId: _controller.collectionId,
          absoluteCharacterOffset: _controller.lastTopVisibleOffset,
        );
    final anchorOffset = anchor.absoluteCharacterOffset;

    final size = _pagedViewportSize;
    final width = size.width > 0
        ? size.width
        : MediaQuery.of(context).size.width;
    final height = size.height > 0
        ? size.height
        : MediaQuery.of(context).size.height - kToolbarHeight;

    final paged = PagedReaderController(
      collectionId: _controller.collectionId,
      document: _controller.document!,
      progressRepository: widget.launch.progressRepository,
      blockIndex: _controller.blockIndex!,
      style: _pagedBodyStyle,
      width: width,
      height: height,
      paddingTop: _preferences.paddingTop,
      paddingBottom: _preferences.paddingBottom,
      paddingLeft: _preferences.paddingLeft,
      paddingRight: _preferences.paddingRight,
      paragraphSpacing: _preferences.paragraphSpacing,
      firstLineIndent: _preferences.firstLineIndent,
    );
    paged.addListener(_onPagedControllerChanged);
    final page = paged.open(anchor);
    // 验证 anchor 在页内（§十七：switchAnchor inside page）。
    assert(page.contains(anchorOffset), '切换锚点必须在页面范围内');
    _pagedController = paged;
    _mode = ReaderMode.paged;
    _transition = ReaderModeTransitionState.idle;
    _controller.unfreezeWrites();
    if (gen != _modeGeneration) return; // 切换期间又切换：丢弃旧代
    // M4 P1：切换本身零写入（§二十一）。
    // mode=paged 的持久化由退出时的 paged.flush()
    // （dispose/lifecycle 只 flush active 模式）自然落盘。
    setState(() {});
  }

  /// 分页 → 纵向（§二十）：
  /// freeze → 取最新 confirmed locator → 精确 M3 restore →
  /// 验证 locator 在真实可见范围内 → 完成 → unfreeze。
  /// 未翻页时 confirmed 仍是原精确 anchor（§十八：切模式不丢位置）。
  void _switchToVertical() {
    if (_transition != ReaderModeTransitionState.idle) return;
    final paged = _pagedController;
    if (paged == null) return;
    final locator = paged.confirmedLocator;
    if (locator == null) return;

    final gen = ++_modeGeneration;
    _transition = ReaderModeTransitionState.pagedToVertical;
    _controller.freezeWrites();
    // Activate the target subtree before scheduling its two-stage restore.
    _mode = ReaderMode.vertical;
    _modeRestoreAnchor = locator;
    _modeRestoreGeneration = gen;
    _suppressProgrammaticScrollNotifications = true;
    _restoreFinished = false;
    _traceModeTransition(
      'modeSwitchStart',
      confirmed: locator,
      target: locator,
      generation: gen,
    );
    // §二十一：切换本身零写入。翻页进度由防抖 Timer（400ms）自然落盘；
    // 退出 Reader 时由 dispose flush 落盘。
    setState(() {});

    // 精确 M3 restore：jumpToOffset 走既有两阶段对齐链。
    _tocJumpPending = false;
    _controller
        .jumpToOffset(
          locator.absoluteCharacterOffset,
          itemIdHint: locator.itemIdHint,
        )
        .then((_) {
          if (!mounted || gen != _modeGeneration) return;
          setState(() {});
          _traceModeTransition(
            'verticalRestore',
            target: locator,
            generation: gen,
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || gen != _modeGeneration) return;
            _scheduleJumpToPendingTarget();
          });
        });
  }

  void _cancelModeRestore({bool revertToPaged = false}) {
    if (_modeRestoreAnchor == null) return;
    _modeGeneration++;
    _modeRestoreAnchor = null;
    _modeRestoreGeneration = null;
    _transition = ReaderModeTransitionState.idle;
    if (revertToPaged) _mode = ReaderMode.paged;
    _suppressProgrammaticScrollNotifications = false;
    _controller.unfreezeWrites();
    _traceModeTransition('modeRestoreCancelled');
  }

  /// 模式切换入口（AppBar 菜单）。
  void _selectMode(ReaderMode mode) {
    if (mode == _mode && _transition == ReaderModeTransitionState.idle) return;
    _cancelModeRestore();
    if (mode == _mode) return;
    _cancelMetricsRelayout();
    if (mode == ReaderMode.paged) {
      _switchToPaged();
    } else {
      _switchToVertical();
    }
  }

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
    // 读初始状态（含 readingMode）：重开时恢复
    // “上次的阅读模式 + 最后 confirmed Locator”。
    // 测试注入 progressOverride 时跳过 DB 查询
    // （widget 测试 FakeAsync 不推真实 IO）。
    if (widget.initialStateOverride != null) {
      _initialState = widget.initialStateOverride;
    } else if (widget.progressOverride == null) {
      _initialState = await widget.launch.progressRepository.getProgress(
        widget.launch.collection.id,
      );
    }
    await _controller.open(initialLocator: _initialState?.toLocator());
    if (!mounted) return;
    setState(() {});
    // 列表可能尚未 attach：post-frame 再尝试跳转
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // M4 P1：重开时若上次是分页模式，自动切回分页
      // （anchor = 恢复的位置，切换不改变 offset）。
      // 先于纵向跳转执行，避免跳转异常中断切换。
      if (_initialState?.readingMode == ReadingMode.paged) {
        try {
          _switchToPaged();
        } catch (e) {
          // 自动切分页失败不应阻断后续流程：保持纵向，由用户手动切换。
        }
      }
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
    // M4 P1：分页模式下纵向跳转/对齐跳过（纵向已让位给 paged）。
    if (_mode == ReaderMode.paged) {
      _restoreFinished = true;
      return;
    }
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
    // M4 P1：分页模式下纵向对齐失败不标记恢复失败（纵向已让位给 paged）。
    if (_mode == ReaderMode.paged) {
      _restoreFinished = true;
      if (mounted) setState(() {});
      return;
    }
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
    // M4 P1：分页模式下不执行纵向恢复确认
    // （纵向已让位给 paged，可见范围测量无法在 paged 下返回，
    // 避免误设 state=failed）。
    if (_mode == ReaderMode.paged) {
      _restoreFinished = true;
      return;
    }
    final metricsGeneration = _metricsGeneration;
    final metricsAnchor = _metricsAnchor;
    final modeGeneration = _modeRestoreGeneration;
    final modeAnchor = _modeRestoreAnchor;
    _controller.finishRestore().then((result) {
      if (!mounted) return;
      if (modeAnchor != null) {
        if (modeGeneration != _modeGeneration ||
            modeGeneration != _modeRestoreGeneration) {
          return;
        }
        final range = result?.visibleRange;
        final confirmed = result?.confirmed;
        final containsTarget =
            range != null && range.contains(modeAnchor.absoluteCharacterOffset);
        if (confirmed != modeAnchor || !containsTarget) {
          _traceModeTransition(
            'modeRestoreRejected',
            confirmed: confirmed,
            target: modeAnchor,
            generation: modeGeneration,
          );
          return;
        }
        _modeRestoreAnchor = null;
        _modeRestoreGeneration = null;
        _transition = ReaderModeTransitionState.idle;
        _restoreFinished = true;
        _traceModeTransition(
          'modeSwitchComplete',
          confirmed: confirmed,
          target: modeAnchor,
          generation: modeGeneration,
        );
        widget.onModeRestore?.call(
          ReaderModeRestoreReport(
            generation: modeGeneration!,
            target: modeAnchor,
            confirmed: confirmed!,
            visibleRange: range,
          ),
        );
        setState(() {});
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || modeGeneration != _modeGeneration) return;
          _suppressProgrammaticScrollNotifications = false;
          _controller.unfreezeWrites();
        });
        return;
      }
      if (metricsAnchor != null) {
        if (metricsGeneration != _metricsGeneration) return;
        final range = result?.visibleRange;
        assert(result?.confirmed == metricsAnchor);
        assert(
          range != null &&
              range.contains(metricsAnchor.absoluteCharacterOffset),
        );
        widget.onMetricsRelayout?.call(
          ReaderMetricsRelayoutReport(
            generation: metricsGeneration,
            locatorBefore: metricsAnchor,
            locatorAfter: result!.confirmed,
            signature: _metricsSignature,
            visibleBefore: _metricsVisibleBefore,
            visibleAfter: range,
          ),
        );
        _metricsAnchor = null;
        _metricsVisibleBefore = null;
        _unfreezeMetricsWrites();
      }
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
    final active = <int>[];
    _blockKeys.forEach((i, key) {
      if (key.currentContext != null) {
        active.add(i);
      }
    });
    active.sort();
    if (active.isEmpty) {
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

    // 布局进行中（例如 SuperListView 布局帧内派发滚动通知）：
    // 禁止访问 RenderBox.size（box.dart 断言），回退 block 级近似。
    if (RenderObject.debugActiveLayout != null) {
      return ReaderVisibleRange(
        startCharacterOffset: index.blocks[firstBlock].startCharacterOffset,
        endCharacterOffset: index.blocks[lastBlock].endCharacterOffset,
        firstVisibleBlock: firstBlock,
        lastVisibleBlock: lastBlock,
        measuredAt: DateTime.now(),
      );
    }

    // M3.3：块内真实顶部/底部字符（不再用 block 起始近似）。
    // 视口顶/底与块全局坐标比对 → RenderReaderTextBlock.characterOffsetAtLocalY。
    final viewportGlobalTop = _viewportGlobalTop();
    final viewportDim = _scroll.position.viewportDimension;
    final viewportGlobalBottom = viewportGlobalTop + viewportDim;
    int? preciseTop;
    int? preciseBottom;
    for (final i in active) {
      final ro = _renderObjects[i];
      if (ro == null || !ro.layoutCompleted || !ro.attached) continue;
      final gTop = ro.localToGlobal(Offset.zero).dy;
      final gBottom = gTop + ro.size.height;
      final blockStart = index.blocks[i].startCharacterOffset;
      if (preciseTop == null &&
          gTop <= viewportGlobalTop &&
          gBottom > viewportGlobalTop) {
        final rel = (viewportGlobalTop - gTop).clamp(0.0, ro.size.height);
        final localChar = ro.characterOffsetAtLocalY(rel);
        preciseTop = blockStart + localChar;
      }
      if (preciseBottom == null &&
          gTop <= viewportGlobalBottom &&
          gBottom > viewportGlobalBottom) {
        final rel = (viewportGlobalBottom - gTop).clamp(0.0, ro.size.height);
        preciseBottom = blockStart + ro.characterOffsetAtLocalY(rel);
      }
      if (preciseTop != null && preciseBottom != null) break;
    }

    return ReaderVisibleRange(
      startCharacterOffset:
          preciseTop ?? index.blocks[firstBlock].startCharacterOffset,
      endCharacterOffset:
          preciseBottom ?? index.blocks[lastBlock].endCharacterOffset,
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
    return Theme(
      data: _effectiveReaderTheme(),
      child: Builder(builder: _buildReader),
    );
  }

  Widget _buildReader(BuildContext context) {
    if (!_preferencesReady) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.launch.collection.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
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
        backgroundColor: _appearance.backgroundColor,
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
        backgroundColor: _appearance.backgroundColor,
        appBar: AppBar(title: Text(widget.launch.collection.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final index = _controller.blockIndex!;
    final doc = _controller.document!;

    final readerContent = _mode == ReaderMode.paged && _pagedController != null
        ? _buildPagedBody(context)
        : _buildVerticalBody(context, index, doc);
    return Scaffold(
      backgroundColor: _appearance.backgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            key: readerChromeToggleKey,
            behavior: HitTestBehavior.translucent,
            onTap: _toggleChrome,
            child: readerContent,
          ),
          ReaderChrome(
            visible: _chromeVisible,
            title: widget.launch.collection.title,
            mode: _mode,
            onBack: () => Navigator.of(context).pop(),
            onToc: () {
              _showChrome();
              _openToc();
            },
            onAppearance: () {
              _showChrome();
              showReaderSettings(
                context,
                preferences: _preferences,
                mode: _mode,
                onPreferencesCommitted: _commitPreferences,
                onModeSelected: _selectMode,
                onResetPreferences: _resetPreferences,
              );
            },
            onMore: () {
              _showChrome();
              showReaderMorePreview(context);
            },
            onModeSelected: (mode) {
              _showChrome();
              _selectMode(mode);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalBody(
    BuildContext context,
    ReaderBlockIndex index,
    NormalizedDocument doc,
  ) {
    return Column(
      children: [
        if (const bool.fromEnvironment('XAOCEN_READER_DEBUG'))
          _DebugBar(controller: _controller, page: this),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              _preferences.paddingLeft,
              _preferences.paddingTop,
              _preferences.paddingRight,
              _preferences.paddingBottom,
            ),
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
                      styleVersion: _appearance.textColor.toARGB32(),
                      textDirection: TextDirection.ltr,
                      paragraphSpacing: _preferences.paragraphSpacing,
                      firstLineIndent: _preferences.firstLineIndent,
                      startsAtParagraphBoundary:
                          block.startCharacterOffset == 0 ||
                          doc.text.codeUnitAt(block.startCharacterOffset - 1) ==
                              0x0A,
                      maxWidth:
                          MediaQuery.of(context).size.width -
                          _preferences.paddingLeft -
                          _preferences.paddingRight,
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
        ),
      ],
    );
  }

  /// M4：分页模式 body。
  ///
  /// 记录视口尺寸（供切换锚点用）；引擎尺寸与渲染约束的同步由
  /// PagedReaderView 内部的 LayoutBuilder 静默处理（§三十一 resize/
  /// orientation：capture locator → 重建窗口 → confirmed 保持）。
  Widget _buildPagedBody(BuildContext context) {
    final paged = _pagedController!;
    return LayoutBuilder(
      builder: (context, constraints) {
        _pagedViewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        return PagedReaderView(controller: paged, appearance: _appearance);
      },
    );
  }

  final Map<int, GlobalKey> _blockKeys = {};

  void _onUserScroll(ScrollNotification notification) {
    if (_suppressProgrammaticScrollNotifications) return;
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
    // 当前章节高亮基于真实可见范围顶部（§十一），非上次点击/恢复位置。
    // M4：分页模式基于 confirmed locator（精确 anchor / 翻页后 page.start）。
    final currentTop = _mode == ReaderMode.paged
        ? (_pagedController?.confirmedLocator?.absoluteCharacterOffset ?? 0)
        : _topVisibleCharacterOffset();
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
    // M4：分页模式目录跳转（§二十四：confirmed = 精确 target offset）。
    if (_mode == ReaderMode.paged) {
      final paged = _pagedController;
      if (paged == null) return;
      paged.jumpToOffset(entry.startCharacterOffset, itemIdHint: entry.itemId);
      if (mounted) setState(() {});
      return;
    }
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

class _TocSheet extends StatefulWidget {
  const _TocSheet({
    required this.toc,
    required this.controller,
    required this.currentTopOffset,
    required this.collectionTitle,
    required this.onJump,
  });

  final List<LibraryTocEntry> toc;
  final ReaderController controller;

  /// 当前真实可见范围顶部字符偏移（用户滚动/跳转后的实测，§六）。
  final int currentTopOffset;

  final String collectionTitle;
  final ValueChanged<LibraryTocEntry> onJump;

  @override
  State<_TocSheet> createState() => _TocSheetState();
}

/// 平铺目录（M3.4）：所有 TocEntry 按正文顺序始终显示，无折叠。
///
/// TOC hierarchy is advisory; source order is authoritative.
/// 层级仅影响视觉表现，不影响目录项是否可见。
class _TocSheetState extends State<_TocSheet> {
  /// 当前章节（目录打开时计算一次，§四：真实可见范围顶部）。
  String? _currentChapterId;

  /// 本次打开是否已自动定位（§六：每次打开最多一次）。
  bool _autoLocated = false;

  /// extent 未稳定时自动定位的 bounded 重试计数（§七：禁止无限重试）。
  int _locateRetries = 0;

  /// 用户是否已手动滚动目录（显示「定位当前章节」按钮）。
  bool _userScrolled = false;

  /// DraggableScrollableSheet 提供的滚动控制器（builder 首次构建后可用）。
  ScrollController? _sheetScroll;

  final Map<int, GlobalKey> _itemKeys = {};

  /// dense ListTile 估算行高（阶段一索引级估算，阶段二 ensureVisible 修正）。
  static const double _kItemExtent = 40.0;

  /// 目标行期望位于视口约 35% 处（§六：30%~40%）。
  static const double _kTargetAlignment = 0.35;

  List<LibraryTocEntry> get _chapters =>
      widget.toc.where((e) => e.kind == 'chapter').toList();

  bool get _hasChapters => _chapters.isNotEmpty;

  /// 平铺目录：collection 所有真实 TocEntry，保持原顺序（orderIndex，
  /// 与正文 startCharacterOffset 顺序一致）。层级不隐藏任何条目。
  List<LibraryTocEntry> get _flatEntries => widget.toc;

  @override
  void initState() {
    super.initState();
    // §四：当前章节 = 最后一个 startCharacterOffset <= 顶部可见 的 chapter。
    _currentChapterId = TocIndexLogic.currentChapterFor(
      widget.currentTopOffset,
      widget.toc,
    )?.id;
    // 等列表首次构建后执行自动定位（一次）。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _autoLocate();
    });
  }

  /// 阶段一：索引级跳转 + 阶段二：行级精确对齐。
  void _locateToCurrent() {
    final scroll = _sheetScroll;
    if (scroll == null || !scroll.hasClients) {
      // 打开动画早期 scroll 尚未 attach：bounded 重试（§七：禁止无限重试）
      if (_locateRetries < 10) {
        _locateRetries++;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _locateToCurrent();
        });
      }
      return;
    }
    final idx = TocIndexLogic.displayIndexFor(_currentChapterId, _flatEntries);
    if (idx == null) {
      return;
    }
    final viewport = scroll.position.viewportDimension;
    final max = scroll.position.maxScrollExtent;
    // extent 未稳定时（打开动画早期 max=0）bounded 重试
    if (max <= 0 && _locateRetries < 10) {
      _locateRetries++;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _locateToCurrent();
      });
      return;
    }
    final targetPixels = idx * _kItemExtent - viewport * _kTargetAlignment;
    scroll.jumpTo(targetPixels.clamp(0.0, max).toDouble());
    // 阶段二：目标行布局完成后 ensureVisible 对齐到 35%。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _alignItem(idx, retries: 0);
    });
  }

  /// 从当前已构建的目录项实测单行高度（dense ListTile 在不同主题/字体
  /// 下高度不同，估算不可靠；实测后一次到位）。
  double? _measuredItemExtent() {
    for (final key in _itemKeys.values) {
      final ctx = key.currentContext;
      if (ctx != null) {
        final ro = ctx.findRenderObject();
        if (ro is RenderBox && ro.size.height > 0) {
          return ro.size.height;
        }
      }
    }
    return null;
  }

  void _alignItem(int idx, {required int retries}) {
    final ctx = _itemKeys[idx]?.currentContext;
    if (ctx == null) {
      // bounded frame retry（§七：不允许无限重试）。
      if (retries < 8) {
        final sp = _sheetScroll?.position;
        if (sp != null && sp.hasContentDimensions) {
          // 用实测行高重算目标位置（估算值可能偏差导致目标不在构建区）
          final extent = _measuredItemExtent() ?? _kItemExtent;
          final targetPixels =
              idx * extent - sp.viewportDimension * _kTargetAlignment;
          sp.jumpTo(targetPixels.clamp(0.0, sp.maxScrollExtent).toDouble());
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _alignItem(idx, retries: retries + 1);
        });
      }
      return;
    }
    Scrollable.ensureVisible(
      ctx,
      alignment: _kTargetAlignment,
      duration: Duration.zero,
    );
  }

  void _autoLocate() {
    if (_autoLocated) return;
    _autoLocated = true;
    _locateToCurrent();
  }

  /// 「定位当前章节」按钮（§六：仅用户滚离后提供）。
  void _locatePressed() {
    setState(() {
      _userScrolled = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _locateToCurrent();
    });
  }

  void _onScrollNotification(ScrollNotification n) {
    // 用户拖动（dragDetails 非空）才算用户滚动；程序 jumpTo 不算。
    if (n is ScrollStartNotification && n.dragDetails != null) {
      _markUserScrolled();
    }
    if (n is ScrollUpdateNotification && n.dragDetails != null) {
      _markUserScrolled();
    }
  }

  void _markUserScrolled() {
    if (_userScrolled) return;
    setState(() {
      _userScrolled = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentChapter = _currentChapterId == null
        ? null
        : _chapters.where((e) => e.id == _currentChapterId).firstOrNull;
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        _sheetScroll = scrollController;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '目录 — ${widget.collectionTitle}',
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // §六：用户滚离当前章节后提供「定位当前章节」入口。
                  if (_userScrolled)
                    TextButton.icon(
                      onPressed: _locatePressed,
                      icon: const Icon(Icons.my_location, size: 16),
                      label: const Text('定位当前章节'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: !_hasChapters
                  ? ListTile(
                      leading: const Icon(Icons.menu_book),
                      title: const Text('全文'),
                      subtitle: Text(
                        '无章节文件 · ${widget.controller.document?.text.length ?? 0} 字符',
                      ),
                      selected: true,
                      onTap: () => widget.onJump(
                        LibraryTocEntry(
                          id: 'whole',
                          collectionId: widget.controller.collectionId,
                          itemId: null,
                          parentId: null,
                          kind: 'chapter',
                          level: 1,
                          title: '全文',
                          displayTitle: '全文',
                          orderIndex: 0,
                          startCharacterOffset: 0,
                          endCharacterOffset:
                              widget.controller.document?.text.length ?? 0,
                        ),
                      ),
                    )
                  : NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        _onScrollNotification(n);
                        return false;
                      },
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: _flatEntries.length,
                        itemBuilder: (context, i) {
                          final e = _flatEntries[i];
                          if (e.kind == 'volume') {
                            // §五：volume 平铺显示 — 稍高字重 + 轻量「卷」标识 +
                            // 上方间距；不显示展开箭头；点击跳转卷首。
                            return Padding(
                              key: _itemKeys[i] ??= GlobalKey(),
                              padding: const EdgeInsets.only(top: 14),
                              child: ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                ),
                                leading: Container(
                                  width: 22,
                                  height: 22,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '卷',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme
                                          .colorScheme
                                          .onSecondaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  e.displayTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onTap: () => widget.onJump(e),
                              ),
                            );
                          }
                          final selected =
                              currentChapter?.id == e.id ||
                              (currentChapter == null && e.orderIndex == 1);
                          return ListTile(
                            key: _itemKeys[i] ??= GlobalKey(),
                            dense: true,
                            // §五：chapter 轻微一级缩进，不按 parentId 多层加深。
                            contentPadding: const EdgeInsets.only(
                              left: 28,
                              right: 16,
                            ),
                            title: Text(
                              e.displayTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            selected: selected,
                            onTap: () => widget.onJump(e),
                          );
                        },
                      ),
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
