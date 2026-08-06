import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/local_txt/large_file_policy.dart';

void main() {
  group('LargeFilePolicy 阈值', () {
    const mb = 1024 * 1024;

    test('≤20MB 正常', () {
      expect(LargeFilePolicy.classify(0), LargeFileClass.normal);
      expect(LargeFilePolicy.classify(20 * mb), LargeFileClass.normal);
    });

    test('20MB+1 需要确认', () {
      expect(
        LargeFilePolicy.classify(20 * mb + 1),
        LargeFileClass.requiresConfirmation,
      );
    });

    test('50MB 需要确认', () {
      expect(
        LargeFilePolicy.classify(50 * mb),
        LargeFileClass.requiresConfirmation,
      );
    });

    test('50MB+1 不支持', () {
      expect(LargeFilePolicy.classify(50 * mb + 1), LargeFileClass.unsupported);
    });
  });
}
