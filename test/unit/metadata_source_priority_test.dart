import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/library/metadata_source_priority.dart';

void main() {
  test('metadata precedence protects manual and online values', () {
    expect(
      MetadataSourcePriority.canReplace(
        currentSource: MetadataSourcePriority.manual,
        incomingSource: MetadataSourcePriority.autoDetected,
      ),
      isFalse,
    );
    expect(
      MetadataSourcePriority.canReplace(
        currentSource: MetadataSourcePriority.onlineConfirmed,
        incomingSource: MetadataSourcePriority.autoDetected,
      ),
      isFalse,
    );
    expect(
      MetadataSourcePriority.canReplace(
        currentSource: MetadataSourcePriority.fileName,
        incomingSource: MetadataSourcePriority.autoDetected,
      ),
      isTrue,
    );
  });

  test('cover precedence keeps manual cover above EPUB auto cover', () {
    expect(
      CoverSourcePriority.canReplace(
        currentSource: CoverSourcePriority.manual,
        incomingSource: CoverSourcePriority.autoDetected,
      ),
      isFalse,
    );
    expect(
      CoverSourcePriority.canReplace(
        currentSource: CoverSourcePriority.placeholder,
        incomingSource: CoverSourcePriority.autoDetected,
      ),
      isTrue,
    );
  });
}
