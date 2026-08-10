import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/app/reading_history_page.dart';
import 'package:xaocen_reader/domain/reader/reading_history.dart';
import 'package:xaocen_reader/domain/reader/reading_session.dart';

void main() {
  ReadingHistoryEntry entry({String? chapter, String? progress}) {
    final time = DateTime(2026, 8, 10);
    return ReadingHistoryEntry(
      id: 'history-a',
      collectionId: 'book-a',
      bookTitleSnapshot: 'Book A',
      authorSnapshot: null,
      normalizedHashSnapshot: 'hash',
      firstReadAt: time,
      lastReadAt: time,
      lastChapterTitleSnapshot: chapter,
      lastProgressSnapshot: progress,
      createdAt: time,
      updatedAt: time,
    );
  }

  const aggregate = ReadingSessionAggregate(
    totalReadingSeconds: 125,
    sessionCount: 3,
  );

  test('history displays values, never object interpolation', () {
    final lines = readingHistoryDetailLines(
      entry(chapter: '第十章', progress: '42.5%'),
      aggregate,
      isInLibrary: true,
    );
    expect(lines, contains('阅读 2 分钟 · 3 次会话'));
    expect(lines, contains('最后章节：第十章'));
    expect(lines, contains('进度快照：42.5%'));
    expect(lines.join('\n'), isNot(contains('Instance of')));
    expect(lines.join('\n'), isNot(contains('null')));
  });

  test('null and empty snapshots are omitted', () {
    final lines = readingHistoryDetailLines(
      entry(chapter: '  ', progress: null),
      aggregate,
      isInLibrary: false,
    );
    expect(lines.where((line) => line.startsWith('最后章节')), isEmpty);
    expect(lines.where((line) => line.startsWith('进度快照')), isEmpty);
    expect(lines, contains('已移出书架'));
  });
}
