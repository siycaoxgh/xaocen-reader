import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/web_book_source_registry.dart';
import '../domain/library/library_import_models.dart';
import '../domain/remote/web_source_contracts.dart';
import '../sources/remote/web_book_runtime.dart';
import 'providers.dart';

/// Minimal WebBook product loop:
/// source registry → search → detail/TOC → snapshot into the existing shelf.
/// It deliberately does not add a second Reader or a source-specific progress
/// model. Adding a book fetches the selected ordered chapters into one local
/// normalized snapshot so the existing library/Reader path remains intact.
class WebBookPage extends ConsumerStatefulWidget {
  const WebBookPage({super.key});

  @override
  ConsumerState<WebBookPage> createState() => _WebBookPageState();
}

final class _WebBookSearchHit {
  const _WebBookSearchHit({required this.entry, required this.result});

  final WebBookSourceRegistryEntry entry;
  final WebBookSearchResult result;
}

class _WebBookPageState extends ConsumerState<WebBookPage> {
  final _queryController = TextEditingController();
  List<_WebBookSearchHit> _results = const [];
  _WebBookSearchHit? _selected;
  WebBookDetail? _detail;
  WebBookTableOfContents? _toc;
  bool _searching = false;
  bool _loadingDetail = false;
  bool _adding = false;
  int _addProgress = 0;
  int _addTotal = 0;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(webBookSourceEntriesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('在线书源'),
        actions: [
          IconButton(
            tooltip: '导入书源 JSON',
            onPressed: _adding ? null : _importSource,
            icon: const Icon(Icons.file_open_outlined),
          ),
        ],
      ),
      body: entries.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(message: '书源加载失败：$error'),
        data: (values) => _buildBody(context, values),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<WebBookSourceRegistryEntry> entries,
  ) {
    final enabled = entries.where((entry) => entry.enabled).toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final content = ListView(
          padding: EdgeInsets.fromLTRB(wide ? 32 : 16, 16, wide ? 32 : 16, 32),
          children: [
            _buildRegistryCard(context, entries),
            const SizedBox(height: 16),
            _buildSearchCard(context, enabled),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _InlineMessage(message: _error!, isError: true),
            ],
            if (_notice != null) ...[
              const SizedBox(height: 12),
              _InlineMessage(message: _notice!, isError: false),
            ],
            if (_searching) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
            if (!_searching && _results.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildResultsCard(context),
            ],
            if (_loadingDetail) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
            if (_selected != null && _detail != null && _toc != null) ...[
              const SizedBox(height: 16),
              _buildDetailCard(context),
            ],
            if (_adding) ...[
              const SizedBox(height: 16),
              _buildAddProgress(context),
            ],
          ],
        );
        return content;
      },
    );
  }

  Widget _buildRegistryCard(
    BuildContext context,
    List<WebBookSourceRegistryEntry> entries,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '书源管理',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton.icon(
                  onPressed: _adding ? null : _importSource,
                  icon: const Icon(Icons.add),
                  label: const Text('导入 JSON'),
                ),
              ],
            ),
            if (entries.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 4),
                child: Text('还没有书源。导入 XAOCEN WebBook JSON 后即可搜索。'),
              )
            else
              for (final entry in entries) _buildSourceRow(context, entry),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceRow(
    BuildContext context,
    WebBookSourceRegistryEntry entry,
  ) {
    final definition = entry.definition;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        entry.enabled ? Icons.public : Icons.public_off_outlined,
        color: entry.enabled
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(definition.name),
      subtitle: Text(
        '${definition.endpoint.host} · ${entry.enabled ? '已启用' : '已禁用'}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Wrap(
        spacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Switch(
            value: entry.enabled,
            onChanged: _adding
                ? null
                : (value) => _setSourceEnabled(entry.sourceId, value),
          ),
          if (definition.searchEndpoint == null)
            IconButton(
              tooltip: '打开默认书籍',
              onPressed: _adding ? null : () => _openConfiguredBook(entry),
              icon: const Icon(Icons.open_in_new),
            ),
          PopupMenuButton<String>(
            tooltip: '书源操作',
            onSelected: (value) {
              switch (value) {
                case 'export':
                  _exportSource(entry);
                case 'delete':
                  _deleteSource(entry);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'export', child: Text('导出书源')),
              PopupMenuItem(value: 'delete', child: Text('删除书源')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard(
    BuildContext context,
    List<WebBookSourceRegistryEntry> enabled,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '搜索在线书籍',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              enabled.isEmpty
                  ? '请先启用至少一个书源。'
                  : '将在 ${enabled.length} 个已启用书源中搜索。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    enabled: !_searching && !_adding && enabled.isNotEmpty,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(enabled),
                    decoration: const InputDecoration(
                      labelText: '书名或关键词',
                      hintText: '例如：青山',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: !_searching && !_adding && enabled.isNotEmpty
                      ? () => _search(enabled)
                      : null,
                  child: const Text('搜索'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '搜索结果（${_results.length}）',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            for (final hit in _results)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.menu_book_outlined),
                title: Text(hit.result.title),
                subtitle: Text(
                  '${hit.entry.definition.name}${hit.result.author == null ? '' : ' · ${hit.result.author}'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _adding ? null : () => _openDetail(hit),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context) {
    final detail = _detail!;
    final toc = _toc!;
    final selected = _selected!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.book_outlined, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (detail.author != null) Text('作者：${detail.author}'),
                      Text(
                        '${selected.entry.definition.name} · ${toc.entries.length} 章',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: _adding ? null : _addToLibrary,
                  icon: const Icon(Icons.library_add),
                  label: const Text('加入书架'),
                ),
              ],
            ),
            if (detail.description != null) ...[
              const SizedBox(height: 12),
              Text(detail.description!),
            ],
            const SizedBox(height: 14),
            Text('目录预览', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            SizedBox(
              height: 220,
              child: ListView.builder(
                itemCount: toc.entries.length,
                itemBuilder: (context, index) {
                  final entry = toc.entries[index];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text('${index + 1}'),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '加入书架时保存书籍信息与目录，并缓存少量章节；其余章节在阅读时按需加载。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddProgress(BuildContext context) {
    final fraction = _addTotal == 0 ? null : _addProgress / _addTotal;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('正在保存书籍…', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: fraction),
            const SizedBox(height: 6),
            Text('已获取 $_addProgress / $_addTotal 章'),
          ],
        ),
      ),
    );
  }

  Future<void> _search(List<WebBookSourceRegistryEntry> enabled) async {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _error = '请输入书名或关键词';
        _notice = null;
      });
      return;
    }
    setState(() {
      _searching = true;
      _error = null;
      _notice = null;
      _results = const [];
      _selected = null;
      _detail = null;
      _toc = null;
    });
    final hits = <_WebBookSearchHit>[];
    final failures = <String>[];
    for (final entry in enabled) {
      final runtime = WebBookHttpRuntime(
        transport: ref.read(webBookTransportProvider),
        rules: entry.definition.toExtractionRules(),
      );
      final result = await runtime.trySearch(
        source: entry.definition.toSource(),
        request: WebBookSearchRequest(query: query),
      );
      if (result.isSuccess) {
        hits.addAll(
          result.value!.map(
            (item) => _WebBookSearchHit(entry: entry, result: item),
          ),
        );
      } else if (result.failure != null) {
        failures.add('${entry.definition.name}：${result.failure!.message}');
      }
    }
    if (!mounted) return;
    setState(() {
      _searching = false;
      _results = hits;
      if (hits.isEmpty) {
        _error = failures.isEmpty ? '未找到匹配书籍' : failures.join('\n');
      } else if (failures.isNotEmpty) {
        _notice = '部分书源未返回结果：${failures.join('；')}';
      }
    });
  }

  Future<void> _openDetail(_WebBookSearchHit hit) async {
    setState(() {
      _loadingDetail = true;
      _error = null;
      _notice = null;
      _selected = hit;
      _detail = null;
      _toc = null;
    });
    final runtime = WebBookHttpRuntime(
      transport: ref.read(webBookTransportProvider),
      rules: hit.entry.definition.toExtractionRules(),
    );
    final detailResult = await runtime.tryOpenDetail(
      source: hit.entry.definition.toSource(),
      result: hit.result,
    );
    if (!detailResult.isSuccess) {
      if (!mounted) return;
      setState(() {
        _loadingDetail = false;
        _error = detailResult.failure?.message ?? '书籍详情加载失败';
      });
      return;
    }
    final detail = detailResult.value!;
    final tocResult = await runtime.tryLoadTableOfContents(
      source: hit.entry.definition.toSource(),
      detail: detail,
    );
    if (!mounted) return;
    setState(() {
      _loadingDetail = false;
      if (tocResult.isSuccess) {
        _detail = detail;
        _toc = tocResult.value;
      } else {
        _error = tocResult.failure?.message ?? '目录加载失败';
      }
    });
  }

  /// Some valid definitions intentionally describe one fixed book page and
  /// omit a search endpoint (for example a Sudugu fixture). Keep that case
  /// explicit in the UI instead of pretending it is a keyword search.
  Future<void> _openConfiguredBook(WebBookSourceRegistryEntry entry) {
    return _openDetail(
      _WebBookSearchHit(
        entry: entry,
        result: WebBookSearchResult(
          bookKey: entry.definition.bookKey,
          title: entry.definition.name,
          detailUri: entry.definition.endpoint,
        ),
      ),
    );
  }

  Future<void> _addToLibrary() async {
    final hit = _selected;
    final detail = _detail;
    final toc = _toc;
    if (hit == null || detail == null || toc == null || _adding) return;
    const initialCacheLimit = 3;
    final initialEntries = toc.entries.take(initialCacheLimit).toList();
    setState(() {
      _adding = true;
      _addProgress = 0;
      _addTotal = initialEntries.length;
      _error = null;
      _notice = null;
    });
    try {
      final runtime = WebBookHttpRuntime(
        transport: ref.read(webBookTransportProvider),
        rules: hit.entry.definition.toExtractionRules(),
      );
      final chapters = <WebBookChapter>[];
      final skipped = <String>[];
      for (final entry in initialEntries) {
        final result = await runtime.tryOpenChapter(
          source: hit.entry.definition.toSource(),
          detail: detail,
          entry: entry,
        );
        if (!result.isSuccess) {
          skipped.add(entry.title);
          if (mounted) setState(() => _addProgress++);
          continue;
        }
        chapters.add(result.value!);
        if (mounted) setState(() => _addProgress = chapters.length);
      }
      final projection = runtime.toReaderContent(
        source: hit.entry.definition.toSource(),
        detail: detail,
        chapters: chapters,
      );
      final result = await ref
          .read(libraryRepositoryProvider)
          .importWebBook(
            ImportWebBookRequest(
              source: hit.entry.definition.toSource(),
              detail: detail,
              projection: projection,
              sourceName: hit.entry.definition.name,
              catalogEntries: toc.entries,
            ),
          );
      ref.invalidate(collectionsProvider);
      if (!mounted) return;
      setState(() {
        _notice = result.alreadyImported
            ? '这本书已在书架中'
            : skipped.isEmpty
            ? '已加入书架；已缓存 ${chapters.length} 章，其余章节将在阅读时按需加载'
            : '已加入书架；已缓存 ${chapters.length} 章，${skipped.length} 章暂未缓存，可稍后按需加载';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '加入书架失败：$error');
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _importSource() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      dialogTitle: '选择 XAOCEN WebBook JSON',
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    try {
      final entry = await ref
          .read(webBookSourceRegistryProvider)
          .importJson(await File(path).readAsString());
      ref.invalidate(webBookSourceEntriesProvider);
      if (!mounted) return;
      setState(() {
        _error = null;
        _notice = '已导入书源：${entry.definition.name}';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '书源导入失败：$error');
    }
  }

  Future<void> _setSourceEnabled(String sourceId, bool enabled) async {
    try {
      await ref
          .read(webBookSourceRegistryProvider)
          .setEnabled(sourceId, enabled);
      ref.invalidate(webBookSourceEntriesProvider);
      if (!mounted) return;
      setState(() => _notice = enabled ? '书源已启用' : '书源已禁用');
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '更新书源失败：$error');
    }
  }

  Future<void> _exportSource(WebBookSourceRegistryEntry entry) async {
    try {
      final json = await ref
          .read(webBookSourceRegistryProvider)
          .exportJson(entry.sourceId);
      final path = await FilePicker.saveFile(
        dialogTitle: '导出 XAOCEN WebBook 书源',
        fileName: '${entry.sourceId}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (path == null || path.isEmpty) {
        await Clipboard.setData(ClipboardData(text: json));
        if (!mounted) return;
        setState(() => _notice = '未选择保存位置，书源 JSON 已复制到剪贴板');
        return;
      }
      await File(path).writeAsString(json, flush: true);
      if (!mounted) return;
      setState(() => _notice = '书源已导出');
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '书源导出失败：$error');
    }
  }

  Future<void> _deleteSource(WebBookSourceRegistryEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除“${entry.definition.name}”？'),
        content: const Text('只会删除本地书源注册，不会删除已经加入书架的书。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(webBookSourceRegistryProvider).remove(entry.sourceId);
      ref.invalidate(webBookSourceEntriesProvider);
      if (!mounted) return;
      setState(() => _notice = '书源已删除');
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '删除书源失败：$error');
    }
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isError ? scheme.errorContainer : scheme.primaryContainer)
            .withValues(alpha: .72),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isError ? scheme.onErrorContainer : scheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(child: Text(message));
}
