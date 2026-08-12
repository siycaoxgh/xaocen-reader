// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_engine_spike_test_app/main.dart';

void main() {
  testWidgets('alpha fixture renders opaque text and controls',
      (WidgetTester tester) async {
    await tester.pumpWidget(const AlphaSurfaceFixture());
    expect(find.text('Opaque Flutter text / transparent background'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });
}
