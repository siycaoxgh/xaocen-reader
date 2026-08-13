import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/reader/reader_preferences.dart';
import 'package:xaocen_reader/reader/android_reader_window.dart';

void main() {
  test('safe inset policy uses cutout and navigation insets dynamically', () {
    const media = MediaQueryData(
      padding: EdgeInsets.fromLTRB(7, 31, 9, 23),
      viewPadding: EdgeInsets.fromLTRB(11, 47, 13, 29),
      devicePixelRatio: 3,
    );
    expect(
      AndroidReaderWindow.safeInsetsForData(
        media,
        extendIntoDisplayCutout: false,
        hideNavigationBar: false,
      ),
      const EdgeInsets.fromLTRB(0, 47, 0, 29),
    );
    expect(
      AndroidReaderWindow.safeInsetsForData(
        media,
        extendIntoDisplayCutout: true,
        hideNavigationBar: true,
      ),
      EdgeInsets.zero,
    );
  });

  test('cutout is normalized off while system status bar is visible', () {
    final visible = ReaderPreferences.defaults.copyWith(
      showSystemStatusBar: true,
      extendIntoDisplayCutout: true,
    );
    expect(visible.extendIntoDisplayCutout, isFalse);
    final hidden = visible.copyWith(
      showSystemStatusBar: false,
      extendIntoDisplayCutout: true,
    );
    expect(hidden.extendIntoDisplayCutout, isTrue);
  });
}
