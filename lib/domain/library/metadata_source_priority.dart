/// Shared source precedence for display metadata and future source adapters.
///
/// The database stores the source string next to each value.  This small
/// contract keeps future EPUB/RSS/online refreshes from overwriting a manual
/// value without adding another schema column or a second metadata truth.
abstract final class MetadataSourcePriority {
  static const manual = 'manual';
  static const onlineConfirmed = 'onlineConfirmed';
  static const autoDetected = 'autoDetected';
  static const fileName = 'fileName';

  static bool canReplace({
    required String currentSource,
    required String incomingSource,
  }) {
    return rank(incomingSource) >= rank(currentSource);
  }

  static int rank(String source) {
    switch (source.trim().toLowerCase()) {
      case 'manual':
        return 400;
      case 'onlineconfirmed':
      case 'online':
      case 'cloud':
        return 300;
      case 'autodetected':
      case 'epubpackage':
      case 'localinference':
      case 'explicittext':
        return 200;
      case 'filename':
        return 100;
      default:
        return 0;
    }
  }
}

/// Cover source precedence mirrors metadata while keeping the current
/// `coverSource` column compatible with manual/placeholder values.
abstract final class CoverSourcePriority {
  static const manual = 'manual';
  static const online = 'online';
  static const autoDetected = 'autoDetected';
  static const placeholder = 'placeholder';

  static bool canReplace({
    required String currentSource,
    required String incomingSource,
  }) {
    return rank(incomingSource) >= rank(currentSource);
  }

  static int rank(String source) {
    switch (source.trim().toLowerCase()) {
      case 'manual':
        return 400;
      case 'online':
      case 'onlineconfirmed':
      case 'cloud':
        return 300;
      case 'autodetected':
      case 'epubpackage':
        return 200;
      case 'placeholder':
        return 0;
      default:
        return 0;
    }
  }
}
