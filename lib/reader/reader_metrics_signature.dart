import '../domain/reader/paged_text_range.dart';
import '../domain/reader/reader_locator.dart';
import '../domain/reader/reader_preferences.dart';
import '../domain/reader/reader_visible_range.dart';

final class ReaderMetricsSignature {
  const ReaderMetricsSignature({
    required this.fontId,
    required this.fontSize,
    required this.letterSpacing,
    required this.lineHeight,
    required this.paragraphSpacing,
    required this.firstLineIndent,
    required this.paddingTop,
    required this.paddingBottom,
    required this.paddingLeft,
    required this.paddingRight,
  });

  factory ReaderMetricsSignature.fromPreferences(ReaderPreferences value) =>
      ReaderMetricsSignature(
        fontId: value.fontId,
        fontSize: value.fontSize,
        letterSpacing: value.letterSpacing,
        lineHeight: value.lineHeight,
        paragraphSpacing: value.paragraphSpacing,
        firstLineIndent: value.firstLineIndent,
        paddingTop: value.paddingTop,
        paddingBottom: value.paddingBottom,
        paddingLeft: value.paddingLeft,
        paddingRight: value.paddingRight,
      );

  final String? fontId;
  final double fontSize;
  final double letterSpacing;
  final double lineHeight;
  final double paragraphSpacing;
  final double firstLineIndent;
  final double paddingTop;
  final double paddingBottom;
  final double paddingLeft;
  final double paddingRight;

  @override
  bool operator ==(Object other) =>
      other is ReaderMetricsSignature &&
      fontId == other.fontId &&
      fontSize == other.fontSize &&
      letterSpacing == other.letterSpacing &&
      lineHeight == other.lineHeight &&
      paragraphSpacing == other.paragraphSpacing &&
      firstLineIndent == other.firstLineIndent &&
      paddingTop == other.paddingTop &&
      paddingBottom == other.paddingBottom &&
      paddingLeft == other.paddingLeft &&
      paddingRight == other.paddingRight;

  @override
  int get hashCode => Object.hash(
    fontId,
    fontSize,
    letterSpacing,
    lineHeight,
    paragraphSpacing,
    firstLineIndent,
    paddingTop,
    paddingBottom,
    paddingLeft,
    paddingRight,
  );
}

final class ReaderMetricsRelayoutReport {
  const ReaderMetricsRelayoutReport({
    required this.generation,
    required this.locatorBefore,
    required this.locatorAfter,
    required this.signature,
    this.visibleBefore,
    this.visibleAfter,
    this.pageBefore,
    this.pageAfter,
  });
  final int generation;
  final ReaderLocator locatorBefore;
  final ReaderLocator locatorAfter;
  final ReaderMetricsSignature signature;
  final ReaderVisibleRange? visibleBefore;
  final ReaderVisibleRange? visibleAfter;
  final PagedTextRange? pageBefore;
  final PagedTextRange? pageAfter;
  int get logicalError =>
      (locatorAfter.absoluteCharacterOffset -
              locatorBefore.absoluteCharacterOffset)
          .abs();
}
