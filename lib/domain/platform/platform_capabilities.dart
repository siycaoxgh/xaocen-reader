/// Whether a platform capability is available to the current application.
enum CapabilitySupport { supported, unsupported, unknown }

/// Why a capability is not currently available.
enum CapabilityFallbackReason {
  unsupportedPlatform,
  backendUnavailable,
  standardWindow,
  rendererUnsupported,
  displayUnsupported,
  unknown,
}

/// A capability value with an explicit fallback reason.
///
/// `unknown` is intentionally different from `unsupported`: adapters must not
/// claim support when the platform has not been measured yet.
final class CapabilityStatus {
  const CapabilityStatus._(this.support, this.fallbackReason);

  const CapabilityStatus.supported()
    : this._(CapabilitySupport.supported, null);

  const CapabilityStatus.unsupported(CapabilityFallbackReason reason)
    : this._(CapabilitySupport.unsupported, reason);

  const CapabilityStatus.unknown([
    CapabilityFallbackReason reason = CapabilityFallbackReason.unknown,
  ]) : this._(CapabilitySupport.unknown, reason);

  final CapabilitySupport support;
  final CapabilityFallbackReason? fallbackReason;

  bool get isSupported => support == CapabilitySupport.supported;
  bool get isUnknown => support == CapabilitySupport.unknown;

  String get diagnosticLabel => switch (support) {
    CapabilitySupport.supported => 'supported',
    CapabilitySupport.unsupported => 'unsupported',
    CapabilitySupport.unknown => 'unknown',
  };
}

/// A display resolution expressed in physical pixels.
final class DisplayResolution {
  const DisplayResolution({required this.width, required this.height});

  final double width;
  final double height;

  @override
  String toString() => '${width.round()} × ${height.round()} px';
}

final class DisplayCapabilities {
  const DisplayCapabilities({
    this.devicePixelRatio,
    this.resolution,
    this.refreshRate,
    this.hdr = const CapabilityStatus.unknown(),
    this.wideColor = const CapabilityStatus.unknown(),
  });

  final double? devicePixelRatio;
  final DisplayResolution? resolution;
  final double? refreshRate;
  final CapabilityStatus hdr;
  final CapabilityStatus wideColor;
}

final class RenderingCapabilities {
  const RenderingCapabilities({
    this.renderer,
    this.backend,
    this.alphaSurface = const CapabilityStatus.unknown(),
  });

  final String? renderer;
  final String? backend;
  final CapabilityStatus alphaSurface;
}

final class DesktopWindowCapabilities {
  const DesktopWindowCapabilities({
    this.borderless = const CapabilityStatus.unknown(),
    this.desktopTransparency = const CapabilityStatus.unknown(),
    this.tray = const CapabilityStatus.unknown(),
    this.taskbarOrDock = const CapabilityStatus.unknown(),
  });

  final CapabilityStatus borderless;
  final CapabilityStatus desktopTransparency;
  final CapabilityStatus tray;
  final CapabilityStatus taskbarOrDock;
}

final class InputCapabilities {
  const InputCapabilities({
    this.keyboard = const CapabilityStatus.unknown(),
    this.mouse = const CapabilityStatus.unknown(),
    this.touch = const CapabilityStatus.unknown(),
    this.volumeKeys = const CapabilityStatus.unknown(),
  });

  final CapabilityStatus keyboard;
  final CapabilityStatus mouse;
  final CapabilityStatus touch;
  final CapabilityStatus volumeKeys;
}

/// Platform facts consumed by application features.
///
/// This model deliberately contains no platform API types. Native details
/// belong in a platform adapter; Reader and other core code consume only this
/// contract.
final class PlatformCapabilities {
  const PlatformCapabilities({
    required this.platform,
    required this.display,
    required this.rendering,
    required this.desktopWindow,
    required this.input,
  });

  final String platform;
  final DisplayCapabilities display;
  final RenderingCapabilities rendering;
  final DesktopWindowCapabilities desktopWindow;
  final InputCapabilities input;

  bool get supportsDesktopReaderTransparency =>
      desktopWindow.desktopTransparency.isSupported;

  CapabilityFallbackReason get desktopTransparencyFallbackReason =>
      desktopWindow.desktopTransparency.fallbackReason ??
      CapabilityFallbackReason.unknown;

  bool get isMobile => platform == 'android' || platform == 'ios';

  factory PlatformCapabilities.unknown({required String platform}) {
    return PlatformCapabilities(
      platform: platform,
      display: const DisplayCapabilities(),
      rendering: const RenderingCapabilities(),
      desktopWindow: const DesktopWindowCapabilities(),
      input: const InputCapabilities(),
    );
  }
}
