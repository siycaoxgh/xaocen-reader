import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/library/library_entities.dart';
import '../domain/library/library_import_models.dart';
import '../domain/local_txt/large_file_policy.dart';
import '../domain/local_txt/pipeline_progress.dart';
import '../reader/reader_page.dart';
import 'providers.dart';

/// M2 最小书架 —— 本地书库（功能性界面，非 V3 统一 UI）。
class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  @override
  Widget build(BuildContext context) {
    final collections = ref.watch(collectionsProvider);
    final importState = ref.watch(importProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('XAOCEN Reader v4'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('本地书库', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                if (!importState.running)
                  FilledButton.icon(
                    onPressed: _pickAndImport,
                    icon: const Icon(Icons.add),
                    label: const Text('导入 TXT'),
                  )
                else
                  _ImportProgressPanel(state: importState),
                if (importState.error != null &&
                    importState.error == 'large_file_confirmation_required')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _LargeFileConfirmBar(onConfirm: _importConfirmed),
                  ),
                if (importState.error != null &&
                    importState.error != 'large_file_confirmation_required')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      importState.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (importState.done)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      importState.alreadyImported ? '该书已导入（未重复添加）' : '导入完成',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: collections.when(
              data: (list) => list.isEmpty
                  ? const Center(child: Text('书库为空，点击“导入 TXT”开始'))
                  : ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) =>
                          _CollectionTile(collection: list[i]),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndImport() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
      dialogTitle: '选择 TXT 文件',
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    final file = File(path);
    final size = await file.length();
    final fileClass = LargeFilePolicy.classify(size);
    if (fileClass == LargeFileClass.unsupported) {
      ref
          .read(importProgressProvider.notifier)
          .setError('文件超过 50MB，不支持导入（${_fmtSize(size)}）');
      return;
    }
    // 启动导入；>20MB 会抛 confirmation，UI 显示确认条
    ref
        .read(importProgressProvider.notifier)
        .start(ImportTxtRequest(externalFile: file, confirmLargeFile: false));
  }

  void _importConfirmed() {
    final notifier = ref.read(importProgressProvider.notifier);
    notifier.retryWithConfirmation();
  }

  String _fmtSize(int size) {
    if (size >= 1024 * 1024) {
      return '${(size / 1024 / 1024).toStringAsFixed(1)}MB';
    }
    return '${(size / 1024).toStringAsFixed(0)}KB';
  }
}

class _LargeFileConfirmBar extends ConsumerWidget {
  const _LargeFileConfirmBar({required this.onConfirm});
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const Icon(Icons.warning_amber, color: Colors.orange),
        const SizedBox(width: 8),
        const Expanded(child: Text('文件超过 20MB，处理需要较长时间，确认继续？')),
        TextButton(onPressed: onConfirm, child: const Text('确认导入')),
      ],
    );
  }
}

class _ImportProgressPanel extends ConsumerWidget {
  const _ImportProgressPanel({required this.state});
  final ImportProgressState state;

  static const _phaseLabels = {
    PipelinePhase.validatingFile: '校验文件',
    PipelinePhase.readingBytes: '读取文件',
    PipelinePhase.detectingEncoding: '检测编码',
    PipelinePhase.loadingEncodingTable: '加载编码表',
    PipelinePhase.decoding: '解码',
    PipelinePhase.normalizing: '规范化',
    PipelinePhase.scanningToc: '扫描卷章',
    PipelinePhase.writingCache: '保存索引',
    PipelinePhase.completed: '完成',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = state.progress;
    final label = p == null ? '准备中…' : _phaseLabels[p.phase] ?? p.phase.name;
    final percent = p?.percent ?? 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyLarge),
            const Spacer(),
            Text('${(percent * 100).toStringAsFixed(0)}%'),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: percent),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: () => ref.read(importProgressProvider.notifier).cancel(),
          icon: const Icon(Icons.close),
          label: const Text('取消'),
        ),
      ],
    );
  }
}

class _CollectionTile extends ConsumerWidget {
  const _CollectionTile({required this.collection});
  final LibraryCollection collection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(collection.title),
      subtitle: Text(
        '${collection.itemCount} 章 · ${collection.detectedEncoding.name} · '
        '${_fmtSize(collection.sourceSize)} · ${_fmtDate(collection.importedAt)}',
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: '删除',
        onPressed: () => _confirmDelete(context, ref),
      ),
      onTap: () => _openReader(context, ref),
    );
  }

  Future<void> _openReader(BuildContext context, WidgetRef ref) async {
    try {
      final repo = ref.read(libraryRepositoryProvider);
      final loader = ref.read(documentLoaderProvider);
      final progressRepo = ref.read(readingProgressRepositoryProvider);
      final docs = await repo.getDocuments(collection.id);
      final toc = await repo.getToc(collection.id);
      if (docs.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('该书没有可用文档')));
        return;
      }
      if (!context.mounted) return;
      await openReader(
        context,
        ReaderLaunchContext(
          collection: collection,
          documents: docs,
          toc: toc,
          normalizedCharacterLength: collection.normalizedCharacterLength,
          documentLoader: loader,
          progressRepository: progressRepo,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('打开失败: $e')));
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除这本书？'),
        content: const Text('将删除书库记录与应用管理副本，不影响外部原文件。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(libraryRepositoryProvider).removeCollection(collection.id);
      ref.invalidate(collectionsProvider);
    }
  }

  String _fmtSize(int size) {
    if (size >= 1024 * 1024) {
      return '${(size / 1024 / 1024).toStringAsFixed(1)}MB';
    }
    return '${(size / 1024).toStringAsFixed(0)}KB';
  }

  String _fmtDate(DateTime t) =>
      '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
}
