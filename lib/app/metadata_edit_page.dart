import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../domain/library/library_entities.dart';
import '../design/tokens/app_tokens.dart';
import 'library_page.dart';
import 'providers.dart';

/// Shared Windows/Android metadata editor. It only changes display metadata;
/// the source file, collection identity and reader state remain untouched.
class MetadataEditPage extends ConsumerStatefulWidget {
  const MetadataEditPage({super.key, required this.collection});

  final LibraryCollection collection;

  @override
  ConsumerState<MetadataEditPage> createState() => _MetadataEditPageState();
}

class _MetadataEditPageState extends ConsumerState<MetadataEditPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _authorController;
  late final TextEditingController _descriptionController;
  late final String _initialTitle;
  late final String _initialAuthor;
  late final String _initialDescription;
  bool _saving = false;
  String? _coverPath;

  @override
  void initState() {
    super.initState();
    _initialTitle = widget.collection.title;
    _initialAuthor = widget.collection.author ?? '';
    _initialDescription = widget.collection.description ?? '';
    _titleController = TextEditingController(text: _initialTitle);
    _authorController = TextEditingController(text: _initialAuthor);
    _descriptionController = TextEditingController(text: _initialDescription);
    _coverPath = widget.collection.coverPath;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collection = widget.collection;
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑书籍信息'),
        actions: [
          TextButton(
            key: const ValueKey('metadata-editor-save'),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 720;
          return Theme(
            data: _metadataEditorTheme(context),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildMetadataColumn(
                          collection,
                          includeReadOnly: true,
                        ),
                      ),
                      const SizedBox(width: 28),
                      SizedBox(
                        width: 220,
                        child: _buildCoverColumn(context, collection),
                      ),
                    ],
                  )
                else ...[
                  _buildMetadataColumn(collection),
                  const SizedBox(height: 22),
                  _buildCoverColumn(context, collection),
                  const SizedBox(height: 20),
                  _buildReadOnlyColumn(collection),
                ],
                const SizedBox(height: 20),
                _buildEditorActions(context),
              ],
            ),
          );
        },
      ),
    );
  }

  ThemeData _metadataEditorTheme(BuildContext context) {
    final base = Theme.of(context);
    final scheme = base.colorScheme;
    final radius = BorderRadius.circular(AppTokens.radiusSmall);
    final fillColor = Color.alphaBlend(
      scheme.surfaceContainerHighest.withValues(alpha: .38),
      scheme.surface,
    );
    OutlineInputBorder border(Color color, {double width = 1}) =>
        OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: color, width: width),
        );
    return base.copyWith(
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: fillColor,
        border: border(scheme.outline),
        enabledBorder: border(scheme.outline),
        focusedBorder: border(scheme.primary, width: 2),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        floatingLabelStyle: TextStyle(color: scheme.primary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildMetadataColumn(
    LibraryCollection collection, {
    bool includeReadOnly = false,
  }) {
    final fields = <Widget>[
      TextField(
        controller: _titleController,
        textInputAction: TextInputAction.next,
        decoration: const InputDecoration(labelText: '书名'),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: _authorController,
        textInputAction: TextInputAction.next,
        decoration: const InputDecoration(labelText: '作者（可选）'),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: _descriptionController,
        minLines: 3,
        maxLines: 6,
        decoration: const InputDecoration(
          labelText: '简介（可选）',
          alignLabelWithHint: true,
        ),
      ),
    ];
    if (includeReadOnly) {
      fields.addAll([
        const SizedBox(height: 22),
        _ReadOnlyMetadata(label: '原文件名', value: collection.fileName ?? '未知'),
        const SizedBox(height: 8),
        _ReadOnlyMetadata(label: '来源', value: collection.sourcePath ?? '未知'),
      ]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: fields,
    );
  }

  Widget _buildReadOnlyColumn(LibraryCollection collection) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReadOnlyMetadata(label: '原文件名', value: collection.fileName ?? '未知'),
        const SizedBox(height: 8),
        _ReadOnlyMetadata(label: '来源', value: collection.sourcePath ?? '未知'),
      ],
    );
  }

  Widget _buildCoverColumn(BuildContext context, LibraryCollection collection) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('封面', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: _CoverPreview(
            key: const ValueKey('metadata-cover-preview'),
            collection: collection,
            coverPath: _coverPath,
            width: 128,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _saving ? null : _chooseCover,
              icon: const Icon(Icons.image_outlined),
              label: const Text('选择本地图片'),
            ),
            TextButton(
              onPressed: _saving || _coverPath == null ? null : _removeCover,
              child: const Text('移除自定义封面'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditorActions(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: _saving ? null : _restoreAutomatic,
          icon: const Icon(Icons.refresh),
          label: const Text('恢复自动识别'),
        ),
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('书名不能为空，请恢复自动识别或保留原书名')));
      return;
    }
    setState(() => _saving = true);
    try {
      final updated = await ref
          .read(libraryRepositoryProvider)
          .updateManualMetadata(
            widget.collection.id,
            title: title,
            author: _authorController.text,
            description: _descriptionController.text,
            titleChanged: title != _initialTitle,
            authorChanged: _authorController.text != _initialAuthor,
            descriptionChanged:
                _descriptionController.text != _initialDescription,
          );
      if (!mounted) return;
      ref.invalidate(collectionsProvider);
      Navigator.of(context).pop(updated);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存失败：$error')));
    }
  }

  Future<void> _chooseCover() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    final repository = ref.read(localBookCoverRepositoryProvider);
    if (repository == null) return;
    setState(() => _saving = true);
    try {
      final pathInDataRoot = await repository.importCover(
        collectionId: widget.collection.id,
        source: File(path),
      );
      if (mounted) {
        setState(() {
          _coverPath = pathInDataRoot;
          _saving = false;
        });
        ref.invalidate(collectionsProvider);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('封面导入失败：$error')));
    }
  }

  Future<void> _removeCover() async {
    final repository = ref.read(localBookCoverRepositoryProvider);
    if (repository == null) return;
    setState(() => _saving = true);
    await repository.removeCover(widget.collection.id, _coverPath);
    if (mounted) {
      setState(() {
        _coverPath = null;
        _saving = false;
      });
      ref.invalidate(collectionsProvider);
    }
  }

  Future<void> _restoreAutomatic() async {
    setState(() => _saving = true);
    try {
      final updated = await ref
          .read(libraryRepositoryProvider)
          .restoreAutomaticMetadata(widget.collection.id);
      if (!mounted) return;
      ref.invalidate(collectionsProvider);
      Navigator.of(context).pop(updated);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('恢复失败：$error')));
    }
  }
}

class _CoverPreview extends ConsumerWidget {
  const _CoverPreview({
    super.key,
    required this.collection,
    required this.coverPath,
    this.width = 96,
  });
  final LibraryCollection collection;
  final String? coverPath;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final file = ref
        .watch(localBookCoverRepositoryProvider)
        ?.resolve(coverPath);
    if (file == null) {
      return SizedBox(
        width: width,
        child: AspectRatio(
          aspectRatio: 2 / 3,
          child: BookCoverPlaceholder(title: collection.title),
        ),
      );
    }
    return SizedBox(
      width: width,
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          child: Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                BookCoverPlaceholder(title: collection.title),
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyMetadata extends StatelessWidget {
  const _ReadOnlyMetadata({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }
}
