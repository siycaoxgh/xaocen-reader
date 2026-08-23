import 'package:flutter/foundation.dart';

/// User-visible product names. Android intentionally uses the Chinese name;
/// desktop builds retain the official English product name.
const String productNameEnglish = 'XAOCEN Reader';
const String productNameChinese = '晓枨阅读';

String productNameForPlatform([TargetPlatform? platform]) {
  final target = platform ?? defaultTargetPlatform;
  return target == TargetPlatform.android
      ? productNameChinese
      : productNameEnglish;
}
