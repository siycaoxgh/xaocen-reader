/// A bookmark anchored to a normalized.txt UTF-16 code-unit offset.
class ReaderBookmark {
  const ReaderBookmark({
    required this.id,
    required this.collectionId,
    required this.absoluteCharacterOffset,
    required this.normalizedHashAtCreation,
    required this.bookTitleSnapshot,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? collectionId;
  final int absoluteCharacterOffset;
  final String? normalizedHashAtCreation;
  final String bookTitleSnapshot;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
}

enum ReaderBookmarkOrphanReason {
  collectionRemoved,
  normalizedHashMismatch,
  offsetOutOfBounds,
}

/// Orphan state is deliberately derived, never persisted.
class ReaderBookmarkStatus {
  const ReaderBookmarkStatus({this.reason});

  final ReaderBookmarkOrphanReason? reason;

  bool get isOrphan => reason != null;
}

ReaderBookmarkStatus deriveReaderBookmarkStatus(
  ReaderBookmark bookmark, {
  required String? currentNormalizedHash,
  required int? normalizedCharacterLength,
}) {
  if (bookmark.collectionId == null) {
    return const ReaderBookmarkStatus(
      reason: ReaderBookmarkOrphanReason.collectionRemoved,
    );
  }
  if (normalizedCharacterLength != null &&
      (bookmark.absoluteCharacterOffset < 0 ||
          bookmark.absoluteCharacterOffset > normalizedCharacterLength)) {
    return const ReaderBookmarkStatus(
      reason: ReaderBookmarkOrphanReason.offsetOutOfBounds,
    );
  }
  if (bookmark.normalizedHashAtCreation != null &&
      currentNormalizedHash != null &&
      bookmark.normalizedHashAtCreation != currentNormalizedHash) {
    return const ReaderBookmarkStatus(
      reason: ReaderBookmarkOrphanReason.normalizedHashMismatch,
    );
  }
  return const ReaderBookmarkStatus();
}
