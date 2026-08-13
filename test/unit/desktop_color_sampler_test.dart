import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/platform/desktop_color_sampler.dart';

void main() {
  test('ColorSample preserves physical coordinates and RGB/HEX output', () {
    final sample = ColorSample.fromMap(<Object?, Object?>{
      'x': -1920,
      'y': 144,
      'r': 125,
      'g': 166,
      'b': 216,
      'hex': '#7DA6D8',
    });

    expect(sample.x, -1920);
    expect(sample.y, 144);
    expect(sample.r, 125);
    expect(sample.g, 166);
    expect(sample.b, 216);
    expect(sample.hex, '#7DA6D8');
  });
}
