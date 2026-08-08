import '../domain/reader/reader_preferences.dart';
import '../domain/reader/reader_locator.dart';
import '../domain/reader/reader_visible_range.dart';
import '../domain/reader/paged_text_range.dart';

/// Reader metrics 的稳定签名。只包含会改变排版的参数；themeMode 不参与。
final class ReaderMetricsSignature {
  const ReaderMetricsSignature({
    required this.fontSize,
    required this.lineHeight,
    required this.horizontalPadding,
    required this.verticalPadding,
  });

  factory ReaderMetricsSignature.fromPreferences(ReaderPreferences value) {
    return ReaderMetricsSignature(
      fontSize: value.fontSize,
      lineHeight: value.lineHeight,
      horizontalPadding: value.horizontalPadding,
      verticalPadding: value.verticalPadding,
    );
  }

  final double fontSize;
  final double lineHeight;
  final double horizontalPadding;
  final double verticalPadding;

  @override
  bool operator ==(Object other) =>
      other is ReaderMetricsSignature &&
      fontSize == other.fontSize &&
      lineHeight == other.lineHeight &&
      horizontalPadding == other.horizontalPadding &&
      verticalPadding == other.verticalPadding;

  @override
  int get hashCode =>
      Object.hash(fontSize, lineHeight, horizontalPadding, verticalPadding);
}

/// 一次 metrics 保位重排的可验证结果。
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
