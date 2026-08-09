/// Aggregate history for a book that has been read at least once.
///
/// Reading duration and session count are intentionally not stored here;
/// callers derive them from [ReadingSession] rows.
class ReadingHistoryEntry {
  const ReadingHistoryEntry({
    required this.id,
    required this.collectionId,
    required this.bookTitleSnapshot,
    required this.authorSnapshot,
    required this.normalizedHashSnapshot,
    required this.firstReadAt,
    required this.lastReadAt,
    required this.lastChapterTitleSnapshot,
    required this.lastProgressSnapshot,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? collectionId;
  final String bookTitleSnapshot;
  final String? authorSnapshot;
  final String? normalizedHashSnapshot;
  final DateTime firstReadAt;
  final DateTime lastReadAt;
  final String? lastChapterTitleSnapshot;
  final String? lastProgressSnapshot;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isCurrentlyInLibrary => collectionId != null;
}
