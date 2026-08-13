import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/reader/reader_preferences.dart';
import 'package:xaocen_reader/reader/android_reader_window.dart';

void main() {
  DisplayFeature cutout(Rect bounds) => DisplayFeature(
    bounds: bounds,
    type: DisplayFeatureType.cutout,
    state: DisplayFeatureState.unknown,
  );

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

  test('foreground inset follows a centered top cutout bounds', () {
    final media = MediaQueryData(
      size: const Size(1080, 2400),
      padding: EdgeInsets.zero,
      viewPadding: EdgeInsets.zero,
      displayFeatures: [cutout(const Rect.fromLTWH(480, 0, 120, 52))],
    );
    final insets = AndroidReaderWindow.foregroundInsetsForData(
      media,
      extendIntoDisplayCutout: true,
      hideNavigationBar: true,
    );
    expect(insets.top, 56);
    expect(insets.left, 0);
    expect(insets.right, 0);
  });

  test('top slot padding uses side space around a centered cutout', () {
    final media = MediaQueryData(
      size: const Size(1080, 2400),
      displayFeatures: [cutout(const Rect.fromLTWH(480, 0, 120, 52))],
    );
    expect(
      AndroidReaderWindow.topSlotPaddingForData(
        media,
        slot: ReaderInfoSlot.topLeft,
      ),
      EdgeInsets.zero,
    );
    expect(
      AndroidReaderWindow.topSlotPaddingForData(
        media,
        slot: ReaderInfoSlot.topCenter,
      ).top,
      56,
    );
    expect(
      AndroidReaderWindow.topSlotPaddingForData(
        media,
        slot: ReaderInfoSlot.topRight,
      ),
      EdgeInsets.zero,
    );
  });

  test('foreground inset follows left and right cutouts in landscape', () {
    final media = MediaQueryData(
      size: const Size(2400, 1080),
      padding: EdgeInsets.zero,
      viewPadding: EdgeInsets.zero,
      displayFeatures: [
        cutout(const Rect.fromLTWH(0, 380, 52, 320)),
        cutout(const Rect.fromLTWH(2348, 380, 52, 320)),
      ],
    );
    final insets = AndroidReaderWindow.foregroundInsetsForData(
      media,
      extendIntoDisplayCutout: true,
      hideNavigationBar: true,
    );
    expect(insets.left, 56);
    expect(insets.right, 56);
    expect(insets.top, 0);
    expect(insets.bottom, 0);
  });

  test('non-cutout display features do not consume foreground space', () {
    final media = MediaQueryData(
      size: const Size(1080, 2400),
      padding: EdgeInsets.zero,
      viewPadding: EdgeInsets.zero,
      displayFeatures: [
        const DisplayFeature(
          bounds: Rect.fromLTWH(0, 1200, 1080, 2),
          type: DisplayFeatureType.fold,
          state: DisplayFeatureState.postureFlat,
        ),
      ],
    );
    expect(
      AndroidReaderWindow.foregroundInsetsForData(
        media,
        extendIntoDisplayCutout: true,
        hideNavigationBar: true,
      ),
      EdgeInsets.zero,
    );
  });
}
