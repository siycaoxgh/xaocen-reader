class ReaderSearchResult {
  const ReaderSearchResult({
    required this.startOffset,
    required this.endOffset,
    required this.contextStartOffset,
    required this.contextEndOffset,
    required this.snippet,
    required this.derivedChapterTitle,
  });

  final int startOffset;
  final int endOffset;
  final int contextStartOffset;
  final int contextEndOffset;
  final String snippet;
  final String derivedChapterTitle;

  ReaderSearchResult withChapterTitle(String title) => ReaderSearchResult(
    startOffset: startOffset,
    endOffset: endOffset,
    contextStartOffset: contextStartOffset,
    contextEndOffset: contextEndOffset,
    snippet: snippet,
    derivedChapterTitle: title,
  );
}
