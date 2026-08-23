import 'dart:convert';
import 'dart:io';

/// Conservative metadata inferred from a local TXT file.
///
/// This deliberately distinguishes a title taken from explicit text from a
/// title cleaned from the file name. It never treats an arbitrary first line
/// or a short second line as author metadata.
final class LocalTxtMetadata {
  const LocalTxtMetadata({
    required this.title,
    required this.author,
    required this.description,
    required this.metadataSource,
    required this.titleSource,
    required this.authorSource,
  });

  final String title;
  final String? author;
  final String? description;
  final String metadataSource;
  final String titleSource;
  final String authorSource;
}

final class LocalTxtMetadataInferer {
  static LocalTxtMetadata fromText(String text, String fileName) {
    final lines = text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .take(40)
        .toList(growable: false);
    String? title;
    var titleSource = 'fileName';
    String? author;
    var authorSource = 'unknown';

    for (final line in lines) {
      final markedTitle = RegExp(r'^书名\s*[:：]\s*(.+?)\s*$').firstMatch(line);
      if (markedTitle != null) {
        title = _clean(markedTitle.group(1));
        titleSource = 'explicitText';
        break;
      }
      final quotedTitle = RegExp(r'^《(.+?)》$').firstMatch(line);
      if (quotedTitle != null) {
        title = _clean(quotedTitle.group(1));
        titleSource = 'explicitText';
        break;
      }
    }

    for (final line in lines) {
      final match = RegExp(r'^作者\s*[:：]\s*(.+?)\s*$').firstMatch(line);
      if (match != null) {
        final value = _clean(match.group(1));
        if (value != null) {
          author = value;
          authorSource = 'explicitText';
        }
        break;
      }
    }

    title ??= cleanFileName(fileName);
    return LocalTxtMetadata(
      title: title,
      author: author,
      description: null,
      metadataSource: 'localInference',
      titleSource: titleSource,
      authorSource: authorSource,
    );
  }

  static Future<LocalTxtMetadata> fromFile(File file) async {
    // Metadata only needs a small prefix. UTF-8 is used as a best-effort
    // fallback; decoded normalized text is preferred by the import pipeline.
    final bytes = await file
        .openRead(0, 128 * 1024)
        .fold<List<int>>(<int>[], (all, chunk) => all..addAll(chunk));
    return fromText(
      utf8.decode(bytes, allowMalformed: true),
      file.uri.pathSegments.last,
    );
  }

  static String cleanFileName(String fileName) {
    var value = fileName.trim();
    value = value.replaceFirst(RegExp(r'\.txt$', caseSensitive: false), '');
    // Only strip an explicit chapter range that includes the 章 marker.
    value = value.replaceFirst(
      RegExp(r'''\s*[\(（\[【]\s*\d+\s*[-~—至到]\s*\d+\s*章\s*[\)）\]】]\s*$'''),
      '',
    );
    return value.trim().isEmpty ? fileName.trim() : value.trim();
  }

  static String? _clean(String? value) {
    final cleaned = value?.trim();
    return cleaned == null || cleaned.isEmpty ? null : cleaned;
  }
}
