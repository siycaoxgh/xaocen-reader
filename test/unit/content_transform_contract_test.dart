import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/reader/content_transform.dart';

void main() {
  test('canonical content uses UTF-16 code-unit length', () {
    const canonical = CanonicalContent(
      contentId: 'book-1',
      sourceRevision: 'rev-1',
      text: '甲𠀀乙',
    );

    expect(canonical.utf16Length, 4);
  });

  test('identity transform preserves the canonical locator exactly', () {
    const canonical = CanonicalContent(
      contentId: 'book-1',
      sourceRevision: 'rev-1',
      text: '第一段\n正文',
    );
    final result = const IdentityContentTransform().apply(canonical);

    expect(result.text, canonical.text);
    expect(result.canPersistCanonicalLocator, isTrue);
    expect(result.positionMap.exactCanonicalOffsetForDerived(3), 3);
  });

  test('removed spans are explicit gaps and never become locator offsets', () {
    final map = ContentPositionMap(
      canonicalLength: 10,
      derivedLength: 6,
      anchors: <ContentPositionAnchor>[
        const ContentPositionAnchor(
          canonicalRange: ContentOffsetRange(0, 4),
          derivedRange: ContentOffsetRange(0, 4),
          quality: ContentMappingQuality.exact,
        ),
        const ContentPositionAnchor(
          canonicalRange: ContentOffsetRange(8, 10),
          derivedRange: ContentOffsetRange(4, 6),
          quality: ContentMappingQuality.exact,
        ),
      ],
    );

    expect(map.exactCanonicalOffsetForDerived(1), 1);
    expect(
      map.canonicalForDerivedOffset(4)?.targetRange,
      const ContentOffsetRange(8, 10),
    );
    expect(map.preservesCanonicalLocator, isFalse);
  });

  test(
    'replacement spans remain coarse instead of pretending exact offsets',
    () {
      final map = ContentPositionMap(
        canonicalLength: 5,
        derivedLength: 8,
        anchors: <ContentPositionAnchor>[
          const ContentPositionAnchor(
            canonicalRange: ContentOffsetRange(0, 5),
            derivedRange: ContentOffsetRange(0, 8),
            quality: ContentMappingQuality.coarse,
          ),
        ],
      );

      expect(
        map.canonicalForDerivedOffset(3)?.quality,
        ContentMappingQuality.coarse,
      );
      expect(map.exactCanonicalOffsetForDerived(3), isNull);
      expect(map.preservesCanonicalLocator, isFalse);
    },
  );

  test(
    'derived content retains canonical identity and transform provenance',
    () {
      const canonical = CanonicalContent(
        contentId: 'book-1',
        sourceRevision: 'rev-7',
        text: '正文',
      );
      final result = const IdentityContentTransform(
        transformId: 'sanitize-v1',
      ).apply(canonical);

      expect(result.canonical.contentId, 'book-1');
      expect(result.canonical.sourceRevision, 'rev-7');
      expect(result.transformId, 'sanitize-v1');
      expect(result.transformVersion, 1);
    },
  );

  test('position anchors reject overlapping derived ranges', () {
    expect(
      () => ContentPositionMap(
        canonicalLength: 4,
        derivedLength: 4,
        anchors: <ContentPositionAnchor>[
          const ContentPositionAnchor(
            canonicalRange: ContentOffsetRange(0, 2),
            derivedRange: ContentOffsetRange(0, 2),
            quality: ContentMappingQuality.exact,
          ),
          const ContentPositionAnchor(
            canonicalRange: ContentOffsetRange(2, 4),
            derivedRange: ContentOffsetRange(1, 4),
            quality: ContentMappingQuality.coarse,
          ),
        ],
      ),
      throwsArgumentError,
    );
  });
}
