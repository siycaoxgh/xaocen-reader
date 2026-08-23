import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/reader/reader_epub_image.dart';

void main() {
  test('paged EPUB image height reserves per-image spacing', () {
    expect(pagedEpubImageMaxHeight(availableHeight: 400, imageCount: 2), 188);
  });

  test('paged EPUB image height clamps when no room remains', () {
    expect(pagedEpubImageMaxHeight(availableHeight: 12, imageCount: 2), 0);
    expect(pagedEpubImageMaxHeight(availableHeight: 100, imageCount: 0), 0);
  });
}
