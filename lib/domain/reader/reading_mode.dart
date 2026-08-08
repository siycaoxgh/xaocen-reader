/// 阅读模式（持久化）—— 表现状态，绝不是位置真源。
///
/// 唯一位置真源始终是 `ReaderLocator.absoluteCharacterOffset`
/// （normalized.txt → Dart String → UTF-16 code unit offset）。
/// readingMode 只描述「一本书上次以什么模式阅读」，用于重开时恢复表现，
/// 绝不能替代 Locator / 参与位置计算。
library;

/// 阅读模式。
enum ReadingMode {
  /// 纵向虚拟滚动（M3 基线，默认）。
  vertical,

  /// 横向分页（M4）。
  paged;

  /// 序列化名（Drift 存储值）。
  String get storageName => name;

  /// 从存储值解析；未知值回退 vertical。
  static ReadingMode fromStorage(String? value) {
    for (final m in ReadingMode.values) {
      if (m.storageName == value) return m;
    }
    return ReadingMode.vertical;
  }
}
