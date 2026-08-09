import 'dart:async';
import 'dart:isolate';

import '../domain/library/current_chapter_resolver.dart';
import '../domain/library/library_entities.dart';
import '../domain/reader/reader_search.dart';

class ReaderSearchCancelled implements Exception {
  const ReaderSearchCancelled();
}

/// Current-book ordinary substring search. The active request is cancellable
/// by killing its worker isolate; generation checks also protect the UI from
/// stale results that race with a newer query.
class ReaderSearchService {
  _ReaderSearchOperation? _active;
  int _generation = 0;

  Future<List<ReaderSearchResult>> search({
    required String text,
    required String query,
    required List<LibraryTocEntry> toc,
    int maxResults = 100,
    int contextBefore = 48,
    int contextAfter = 96,
  }) {
    final generation = ++_generation;
    _active?.cancel();
    if (query.isEmpty || maxResults <= 0) return Future.value(const []);
    final operation = _ReaderSearchOperation(
      generation: generation,
      text: text,
      query: query,
      maxResults: maxResults,
      contextBefore: contextBefore,
      contextAfter: contextAfter,
    );
    _active = operation;
    return operation.run().then((raw) {
      if (generation != _generation) {
        throw const ReaderSearchCancelled();
      }
      return raw
          .map(
            (result) => result.withChapterTitle(
              CurrentChapterResolver.resolve(
                    result.startOffset,
                    toc,
                  )?.displayTitle ??
                  '全文',
            ),
          )
          .toList(growable: false);
    });
  }

  void cancel() {
    _generation++;
    _active?.cancel();
    _active = null;
  }
}

class _ReaderSearchOperation {
  _ReaderSearchOperation({
    required this.generation,
    required this.text,
    required this.query,
    required this.maxResults,
    required this.contextBefore,
    required this.contextAfter,
  });

  final int generation;
  final String text;
  final String query;
  final int maxResults;
  final int contextBefore;
  final int contextAfter;

  Isolate? _isolate;
  ReceivePort? _port;
  StreamSubscription<Object?>? _subscription;
  final _completer = Completer<List<ReaderSearchResult>>();

  Future<List<ReaderSearchResult>> run() async {
    final port = ReceivePort();
    _port = port;
    _subscription = port.listen((message) {
      if (message is List) {
        _complete(
          message
              .cast<Map<Object?, Object?>>()
              .map(
                (row) => ReaderSearchResult(
                  startOffset: row['startOffset']! as int,
                  endOffset: row['endOffset']! as int,
                  contextStartOffset: row['contextStartOffset']! as int,
                  contextEndOffset: row['contextEndOffset']! as int,
                  snippet: row['snippet']! as String,
                  derivedChapterTitle: '',
                ),
              )
              .toList(growable: false),
        );
      } else if (message is Object && !_completer.isCompleted) {
        _completeError(StateError(message.toString()));
      }
    });
    try {
      _isolate = await Isolate.spawn<_ReaderSearchWorkerRequest>(
        _searchWorker,
        _ReaderSearchWorkerRequest(
          sendPort: port.sendPort,
          text: text,
          query: query,
          maxResults: maxResults,
          contextBefore: contextBefore,
          contextAfter: contextAfter,
        ),
      );
    } catch (error, stack) {
      _completeError(error, stack);
    }
    return _completer.future.then(
      (value) async {
        await _cleanup();
        return value;
      },
      onError: (Object error, StackTrace stack) async {
        await _cleanup();
        Error.throwWithStackTrace(error, stack);
      },
    );
  }

  void cancel() {
    _isolate?.kill(priority: Isolate.immediate);
    // Resolve the worker future normally; the public generation check turns
    // this into ReaderSearchCancelled on the stale request future. This avoids
    // an unobserved error on the internal cleanup future.
    _complete(const []);
    unawaited(_cleanup());
  }

  void _complete(List<ReaderSearchResult> result) {
    if (!_completer.isCompleted) _completer.complete(result);
  }

  void _completeError(Object error, [StackTrace? stack]) {
    if (!_completer.isCompleted) {
      _completer.completeError(error, stack);
    }
  }

  Future<void> _cleanup() async {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    await _subscription?.cancel();
    _subscription = null;
    _port?.close();
    _port = null;
  }
}

class _ReaderSearchWorkerRequest {
  const _ReaderSearchWorkerRequest({
    required this.sendPort,
    required this.text,
    required this.query,
    required this.maxResults,
    required this.contextBefore,
    required this.contextAfter,
  });

  final SendPort sendPort;
  final String text;
  final String query;
  final int maxResults;
  final int contextBefore;
  final int contextAfter;
}

void _searchWorker(_ReaderSearchWorkerRequest request) {
  try {
    final results = _scanSearch(
      request.text,
      request.query,
      maxResults: request.maxResults,
      contextBefore: request.contextBefore,
      contextAfter: request.contextAfter,
    );
    request.sendPort.send(
      results
          .map(
            (result) => <String, Object>{
              'startOffset': result.startOffset,
              'endOffset': result.endOffset,
              'contextStartOffset': result.contextStartOffset,
              'contextEndOffset': result.contextEndOffset,
              'snippet': result.snippet,
            },
          )
          .toList(growable: false),
    );
  } catch (error) {
    request.sendPort.send(error.toString());
  }
}

List<ReaderSearchResult> _scanSearch(
  String text,
  String query, {
  required int maxResults,
  required int contextBefore,
  required int contextAfter,
}) {
  if (query.isEmpty || text.isEmpty) return const [];
  final results = <ReaderSearchResult>[];
  final queryLength = query.length;
  for (
    var offset = 0;
    offset + queryLength <= text.length && results.length < maxResults;
    offset++
  ) {
    var matches = true;
    for (var i = 0; i < queryLength; i++) {
      if (_foldAscii(text.codeUnitAt(offset + i)) !=
          _foldAscii(query.codeUnitAt(i))) {
        matches = false;
        break;
      }
    }
    if (!matches) continue;
    final contextStart = _safeContextStart(
      text,
      (offset - contextBefore).clamp(0, text.length).toInt(),
    );
    final contextEnd = _safeContextEnd(
      text,
      (offset + queryLength + contextAfter).clamp(0, text.length).toInt(),
    );
    results.add(
      ReaderSearchResult(
        startOffset: offset,
        endOffset: offset + queryLength,
        contextStartOffset: contextStart,
        contextEndOffset: contextEnd,
        snippet: text.substring(contextStart, contextEnd),
        derivedChapterTitle: '',
      ),
    );
  }
  return results;
}

int _foldAscii(int codeUnit) =>
    codeUnit >= 0x41 && codeUnit <= 0x5A ? codeUnit + 0x20 : codeUnit;

int _safeContextStart(String text, int offset) {
  if (offset > 0 &&
      offset < text.length &&
      _isLowSurrogate(text.codeUnitAt(offset))) {
    return offset - 1;
  }
  return offset;
}

int _safeContextEnd(String text, int offset) {
  if (offset > 0 &&
      offset < text.length &&
      _isHighSurrogate(text.codeUnitAt(offset - 1))) {
    return offset + 1;
  }
  return offset;
}

bool _isHighSurrogate(int codeUnit) => codeUnit >= 0xD800 && codeUnit <= 0xDBFF;

bool _isLowSurrogate(int codeUnit) => codeUnit >= 0xDC00 && codeUnit <= 0xDFFF;
