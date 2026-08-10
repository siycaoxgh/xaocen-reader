/// ReaderController —— 纵向滚动 Reader 控制器。
///
/// 职责：
/// - 加载 NormalizedDocument（经 NormalizedDocumentLoader）；
/// - 构建 ReaderBlockIndex；
/// - 精确恢复状态机（loadingDocument → … → completed / failed）；
/// - 目录跳转（programmaticTocJump）；
/// - 用户滚动防抖保存（userDrag / userWheel / userScrollbar）；
/// - 生命周期 flush（route pop / inactive / paused / detached）。
///
/// 位置真源：UTF-16 码元偏移（absoluteCharacterOffset）。
/// 恢复完成前零写入数据库。
// ignore_for_file: prefer_initializing_formals
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../data/repositories/reading_progress_repository.dart';
import '../domain/reader/reader_block.dart';
import '../domain/reader/reader_locator.dart';
import '../domain/reader/reader_progress_state.dart';
import '../domain/reader/reading_mode.dart';
import '../domain/reader/reader_visible_range.dart';
import 'normalized_document_loader.dart';
import 'reader_text_block.dart';

/// 恢复结果。
class ReaderRestoreResult {
  const ReaderRestoreResult({
    required this.requested,
    required this.confirmed,
    required this.visibleRange,
    required this.phase,
  });

  final ReaderLocator requested;
  final ReaderLocator confirmed;
  final ReaderVisibleRange visibleRange;
  final ReaderRestorePhase phase;
}

/// Reader 状态。
enum ReaderState { idle, loadingDocument, ready, failed }

/// 可见范围回调。
typedef VisibleRangeCallback = ReaderVisibleRange Function();

/// 布局测量回调（注入：由 RenderObject 提供真实映射）。
typedef BlockLayoutResolver = ReaderBlockLayout? Function(int blockIndex);

/// Reader 控制器。
class ReaderController extends ChangeNotifier {
  ReaderController({
    required this.collectionId,
    required NormalizedDocumentLoader documentLoader,
    required ReadingProgressRepository progressRepository,
    this.targetBlockSize = 6144,
    this.progressOverride,
  }) : _documentLoader = documentLoader,
       _progressRepository = progressRepository;

  final String collectionId;
  final NormalizedDocumentLoader _documentLoader;
  final ReadingProgressRepository _progressRepository;
  final int targetBlockSize;

  /// 测试注入：跳过 DB 查询直接使用该进度（null = 无进度）。
  final ReaderLocator? progressOverride;

  NormalizedDocument? _document;
  ReaderBlockIndex? _blockIndex;

  /// 当前可见范围测量器（由 UI 注入）。
  VisibleRangeCallback? visibleRangeProvider;

  /// 块布局解析器（由 UI 注入，用于恢复定位）。
  BlockLayoutResolver? blockLayoutResolver;

  ReaderState _state = ReaderState.idle;
  ReaderState get state => _state;

  ReaderRestorePhase _restorePhase = ReaderRestorePhase.loadingDocument;
  ReaderRestorePhase get restorePhase => _restorePhase;

  String? _error;
  String? get error => _error;

  ReaderLocator? _confirmedLocator;
  ReaderLocator? get confirmedLocator => _confirmedLocator;

  ReaderLocator? _requestedLocator;
  ReaderLocator? get requestedLocator => _requestedLocator;

  NormalizedDocument? get document => _document;
  ReaderBlockIndex? get blockIndex => _blockIndex;

  Timer? _debounce;
  static const Duration _debounceDuration = Duration(milliseconds: 400);

  bool _restoreWriteUnlocked = false;

  /// 恢复完成后解冻用户位置写入。
  bool get restoreWriteUnlocked => _restoreWriteUnlocked;

  /// 模式切换期间的写入冻结深度（M4 §二十一）。
  /// 默认 0：M3 行为完全不变；切换期间 > 0 时跳过数据库写入
  /// （内存 confirmed 仍更新，只是不落库）。
  int _writeFreezeDepth = 0;

  /// 是否处于写入冻结（模式切换中）。
  bool get writesFrozen => _writeFreezeDepth > 0;

  /// 冻结写入（切换开始）。可嵌套。
  void freezeWrites() {
    _writeFreezeDepth++;
  }

  /// 解冻写入（切换完成）。
  void unfreezeWrites() {
    if (_writeFreezeDepth > 0) _writeFreezeDepth--;
  }

  /// 供测试注入的文档（跳过 loader）。
  void injectDocument(NormalizedDocument doc) {
    _document = doc;
    _blockIndex = ReaderBlockIndex.build(
      text: doc.text,
      targetBlockSize: targetBlockSize,
    );
    _state = ReaderState.ready;
    notifyListeners();
  }

  /// 开始加载文档并恢复位置。
  Future<ReaderRestoreResult?> open({ReaderLocator? initialLocator}) async {
    _state = ReaderState.loadingDocument;
    _restorePhase = ReaderRestorePhase.loadingDocument;
    _error = null;
    notifyListeners();

    try {
      // 加载文档（由 UI 层提供 storagePath；这里用可注入的 loader 回调）
      if (_document == null) {
        await _loadDocument();
      }
      _restorePhase = ReaderRestorePhase.buildingBlockIndex;
      _blockIndex = ReaderBlockIndex.build(
        text: _document!.text,
        targetBlockSize: targetBlockSize,
      );
      notifyListeners();

      // 读取进度（progressOverride 供测试跳过 DB）
      // getProgress 返回 ReaderProgressState（含 mode），取位置真源部分。
      final saved =
          initialLocator ??
          progressOverride ??
          (await _progressRepository.getProgress(collectionId))?.toLocator();

      final requested =
          saved ??
          ReaderLocator(collectionId: collectionId, absoluteCharacterOffset: 0);

      // clamp
      final clamped = clampLocatorOffset(
        requested: requested.absoluteCharacterOffset,
        normalizedLength: _document!.text.length,
        text: _document!.text,
      );
      _requestedLocator = requested.copyWith(
        absoluteCharacterOffset: clamped.clamped,
      );
      _restorePhase = ReaderRestorePhase.locatingTargetBlock;
      notifyListeners();

      // 定位目标块
      final targetBlock = _blockIndex!.blockForOffset(
        _requestedLocator!.absoluteCharacterOffset,
      );
      if (targetBlock == null) {
        _restorePhase = ReaderRestorePhase.failed;
        _error = '无法定位目标块';
        _state = ReaderState.failed;
        notifyListeners();
        return null;
      }

      // 通知 UI 跳到目标块（返回目标块信息，由 UI 执行跳转）
      _restorePhase = ReaderRestorePhase.jumpingToBlock;
      _pendingTargetBlock = targetBlock;
      _lastTopVisibleOffset = _requestedLocator!.absoluteCharacterOffset;
      // 文档已就绪：正文可渲染（finishRestore 负责确认可见范围 + 解冻写入）
      _state = ReaderState.ready;
      notifyListeners();

      return null; // UI 完成布局后调用 finishRestore
    } catch (e) {
      _restorePhase = ReaderRestorePhase.failed;
      _error = '恢复失败: $e';
      _state = ReaderState.failed;
      notifyListeners();
      return null;
    }
  }

  /// 待跳转目标块（UI 消费）。
  ReaderBlock? _pendingTargetBlock;
  ReaderBlock? get pendingTargetBlock => _pendingTargetBlock;

  /// UI 完成目标块跳转与布局后调用：确认可见范围、解冻写入。
  Future<ReaderRestoreResult?> finishRestore() async {
    if (_requestedLocator == null || _document == null) return null;
    _restorePhase = ReaderRestorePhase.resolvingTargetCharacter;

    final visible = visibleRangeProvider?.call();
    if (visible == null) {
      _restorePhase = ReaderRestorePhase.failed;
      _error = '可见范围不可用';
      _state = ReaderState.failed;
      notifyListeners();
      return null;
    }

    _restorePhase = ReaderRestorePhase.confirmingVisibleRange;
    final requestedOffset = _requestedLocator!.absoluteCharacterOffset;

    // 逻辑误差：requested 与 confirmed 必须一致（confirmed 由真实可见范围得出）
    final confirmedOffset = visible.contains(requestedOffset)
        ? requestedOffset
        : _nearestVisibleOffset(requestedOffset, visible);

    _confirmedLocator = ReaderLocator(
      collectionId: collectionId,
      absoluteCharacterOffset: confirmedOffset,
      itemIdHint: _requestedLocator!.itemIdHint,
    );

    // 恢复完成：解冻用户写入（此处不写库——programmaticRestore 零写入）
    _restoreWriteUnlocked = true;
    _restorePhase = ReaderRestorePhase.completed;
    _state = ReaderState.ready;
    notifyListeners();

    return ReaderRestoreResult(
      requested: _requestedLocator!,
      confirmed: _confirmedLocator!,
      visibleRange: visible,
      phase: _restorePhase,
    );
  }

  int _nearestVisibleOffset(int requested, ReaderVisibleRange visible) {
    if (requested < visible.startCharacterOffset) {
      return visible.startCharacterOffset;
    }
    return visible.endCharacterOffset - 1 < requested
        ? visible.endCharacterOffset - 1
        : requested;
  }

  Future<void> _loadDocument() async {
    // UI 层通过 setDocumentSource 提供 storagePath / hash / length
    if (_documentSource == null) {
      throw const NormalizedDocumentException('no_source', '未设置文档来源');
    }
    final src = _documentSource!;
    _document = await _documentLoader.load(
      storagePath: src.storagePath,
      expectedHash: src.expectedHash,
      expectedLength: src.expectedLength,
    );
  }

  _DocumentSource? _documentSource;

  /// 设置文档来源（由 UI 从 M2 Document / manifest 读取）。
  void setDocumentSource({
    required String storagePath,
    String? expectedHash,
    int? expectedLength,
  }) {
    _documentSource = _DocumentSource(
      storagePath: storagePath,
      expectedHash: expectedHash,
      expectedLength: expectedLength,
    );
  }

  /// 目录跳转（programmaticTocJump）：保存明确目标 offset。
  Future<void> jumpToOffset(int offset, {String? itemIdHint}) async {
    if (_document == null || _blockIndex == null) return;
    final clamped = clampLocatorOffset(
      requested: offset,
      normalizedLength: _document!.text.length,
      text: _document!.text,
    );
    final target = ReaderLocator(
      collectionId: collectionId,
      absoluteCharacterOffset: clamped.clamped,
      itemIdHint: itemIdHint,
    );
    _requestedLocator = target;
    _lastTopVisibleOffset = target.absoluteCharacterOffset;
    final block = _blockIndex!.blockForOffset(target.absoluteCharacterOffset);
    if (block == null) return;
    _pendingTargetBlock = block;
    _restorePhase = ReaderRestorePhase.jumpingToBlock;
    notifyListeners();
  }

  /// 目录跳转完成确认：可见范围确认后立即保存（明确用户操作）。
  Future<void> finishTocJump({bool persist = true}) async {
    final visible = visibleRangeProvider?.call();
    if (visible == null || _requestedLocator == null) return;
    final requestedOffset = _requestedLocator!.absoluteCharacterOffset;
    final confirmedOffset = visible.contains(requestedOffset)
        ? requestedOffset
        : _nearestVisibleOffset(requestedOffset, visible);
    _confirmedLocator = ReaderLocator(
      collectionId: collectionId,
      absoluteCharacterOffset: confirmedOffset,
      itemIdHint: _requestedLocator!.itemIdHint,
    );
    _restorePhase = ReaderRestorePhase.completed;
    notifyListeners();
    if (persist) {
      await _progressRepository.saveProgress(
        ReaderProgressState(
          collectionId: collectionId,
          absoluteCharacterOffset: _confirmedLocator!.absoluteCharacterOffset,
          readingMode: ReadingMode.vertical,
          itemIdHint: _confirmedLocator!.itemIdHint,
        ),
      );
    }
  }

  /// 用户滚动上报（userDrag / userWheel / userScrollbar）。
  /// 跳转失败标记（§十：bounded 重试后明确失败，不宣称成功）。
  Future<void> markRestoreFailed(String reason) async {
    if (_restoreWriteUnlocked) return; // 已解冻写入的不再回退
    _restorePhase = ReaderRestorePhase.failed;
    _error = reason;
    _state = ReaderState.failed;
    notifyListeners();
  }

  /// 最近一次真实可见范围顶部偏移（目录当前章节高亮用，§十一）。
  int _lastTopVisibleOffset = 0;
  int get lastTopVisibleOffset => _lastTopVisibleOffset;

  void reportUserScroll({
    required int topVisibleCharacterOffset,
    ReaderPositionEventSource source = ReaderPositionEventSource.userDrag,
  }) {
    _lastTopVisibleOffset = topVisibleCharacterOffset;
    if (!_restoreWriteUnlocked) return; // 恢复完成前零写入
    if (_document == null) return;
    final clamped = clampLocatorOffset(
      requested: topVisibleCharacterOffset,
      normalizedLength: _document!.text.length,
      text: _document!.text,
    );
    final locator = ReaderLocator(
      collectionId: collectionId,
      absoluteCharacterOffset: clamped.clamped,
    );
    _confirmedLocator = locator;
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () async {
      if (writesFrozen) return; // 切换中不落库（§二十一）
      await _progressRepository.saveProgress(
        ReaderProgressState(
          collectionId: collectionId,
          absoluteCharacterOffset: locator.absoluteCharacterOffset,
          readingMode: ReadingMode.vertical,
          itemIdHint: locator.itemIdHint,
        ),
      );
    });
  }

  /// 立即 flush 最新已确认位置（scroll end / 生命周期）。
  Future<void> flush({
    ReaderPositionEventSource source = ReaderPositionEventSource.lifecycleFlush,
  }) async {
    if (!_restoreWriteUnlocked) return;
    if (writesFrozen) return; // 模式切换中：不落库（§二十一）
    _debounce?.cancel();
    _debounce = null;
    final locator = _confirmedLocator;
    if (locator == null) return;
    await _progressRepository.saveProgress(
      ReaderProgressState(
        collectionId: collectionId,
        absoluteCharacterOffset: locator.absoluteCharacterOffset,
        readingMode: ReadingMode.vertical,
        itemIdHint: locator.itemIdHint,
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

class _DocumentSource {
  const _DocumentSource({
    required this.storagePath,
    this.expectedHash,
    this.expectedLength,
  });

  final String storagePath;
  final String? expectedHash;
  final int? expectedLength;
}
