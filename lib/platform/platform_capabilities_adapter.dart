import 'dart:io';
import 'dart:ui' as ui;

import '../domain/platform/platform_capabilities.dart';

abstract interface class PlatformCapabilitiesAdapter {
  Future<PlatformCapabilities> load();
}

/// Reads capabilities that are available from the Flutter view and the
/// platform runner. Unsupported/undetected values remain explicit instead of
/// being inferred as supported.
final class DefaultPlatformCapabilitiesAdapter
    implements PlatformCapabilitiesAdapter {
  @override
  Future<PlatformCapabilities> load() async {
    final platform = _platformName();
    final display = _displayCapabilities();

    if (Platform.isWindows) {
      return PlatformCapabilities(
        platform: platform,
        display: display,
        rendering: const RenderingCapabilities(
          renderer: 'Skia',
          backend: 'ANGLE / D3D11',
          alphaSurface: CapabilityStatus.unsupported(
            CapabilityFallbackReason.rendererUnsupported,
          ),
        ),
        desktopWindow: const DesktopWindowCapabilities(
          borderless: CapabilityStatus.supported(),
          // The current Flutter Windows EGL child surface is opaque. This is
          // a measured limitation, not a claim about future compositors.
          desktopTransparency: CapabilityStatus.unsupported(
            CapabilityFallbackReason.rendererUnsupported,
          ),
          tray: CapabilityStatus.supported(),
          taskbarOrDock: CapabilityStatus.supported(),
        ),
        input: const InputCapabilities(
          keyboard: CapabilityStatus.supported(),
          mouse: CapabilityStatus.supported(),
          touch: CapabilityStatus.unknown(),
          volumeKeys: CapabilityStatus.unsupported(
            CapabilityFallbackReason.unsupportedPlatform,
          ),
        ),
      );
    }

    if (Platform.isAndroid) {
      return PlatformCapabilities(
        platform: platform,
        display: display,
        rendering: const RenderingCapabilities(
          renderer: 'Flutter runtime renderer',
          backend: 'runtime-selected (Vulkan/OpenGL)',
          alphaSurface: CapabilityStatus.unknown(
            CapabilityFallbackReason.backendUnavailable,
          ),
        ),
        desktopWindow: const DesktopWindowCapabilities(
          borderless: CapabilityStatus.unsupported(
            CapabilityFallbackReason.unsupportedPlatform,
          ),
          desktopTransparency: CapabilityStatus.unsupported(
            CapabilityFallbackReason.unsupportedPlatform,
          ),
          tray: CapabilityStatus.unsupported(
            CapabilityFallbackReason.unsupportedPlatform,
          ),
          taskbarOrDock: CapabilityStatus.unsupported(
            CapabilityFallbackReason.unsupportedPlatform,
          ),
        ),
        input: const InputCapabilities(
          keyboard: CapabilityStatus.unknown(),
          mouse: CapabilityStatus.unknown(),
          touch: CapabilityStatus.supported(),
          volumeKeys: CapabilityStatus.supported(),
        ),
      );
    }

    // macOS/Linux/iOS/HarmonyOS adapters are intentionally conservative
    // stubs. A future native adapter must prove support before exposing it.
    return PlatformCapabilities.unknown(platform: platform);
  }

  String _platformName() {
    if (Platform.isWindows) return 'windows';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return Platform.operatingSystem;
  }

  DisplayCapabilities _displayCapabilities() {
    try {
      final views = ui.PlatformDispatcher.instance.views;
      if (views.isEmpty) return const DisplayCapabilities();
      final display = views.first.display;
      return DisplayCapabilities(
        devicePixelRatio: display.devicePixelRatio,
        resolution: DisplayResolution(
          width: display.size.width,
          height: display.size.height,
        ),
        refreshRate: display.refreshRate > 0 ? display.refreshRate : null,
      );
    } on Object {
      return const DisplayCapabilities();
    }
  }
}
