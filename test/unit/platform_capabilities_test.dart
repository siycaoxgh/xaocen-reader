import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/domain/platform/platform_capabilities.dart';

void main() {
  test('desktop transparency is supported only when explicitly reported', () {
    const supported = PlatformCapabilities(
      platform: 'windows',
      display: DisplayCapabilities(),
      rendering: RenderingCapabilities(),
      desktopWindow: DesktopWindowCapabilities(
        desktopTransparency: CapabilityStatus.supported(),
      ),
      input: InputCapabilities(),
    );
    const unknown = PlatformCapabilities(
      platform: 'linux',
      display: DisplayCapabilities(),
      rendering: RenderingCapabilities(),
      desktopWindow: DesktopWindowCapabilities(),
      input: InputCapabilities(),
    );

    expect(supported.supportsDesktopReaderTransparency, isTrue);
    expect(unknown.supportsDesktopReaderTransparency, isFalse);
    expect(
      unknown.desktopTransparencyFallbackReason,
      CapabilityFallbackReason.unknown,
    );
  });

  test('mobile desktop transparency reports unsupported platform', () {
    const capabilities = PlatformCapabilities(
      platform: 'android',
      display: DisplayCapabilities(),
      rendering: RenderingCapabilities(),
      desktopWindow: DesktopWindowCapabilities(
        desktopTransparency: CapabilityStatus.unsupported(
          CapabilityFallbackReason.unsupportedPlatform,
        ),
      ),
      input: InputCapabilities(
        touch: CapabilityStatus.supported(),
        volumeKeys: CapabilityStatus.supported(),
      ),
    );

    expect(capabilities.isMobile, isTrue);
    expect(capabilities.supportsDesktopReaderTransparency, isFalse);
    expect(
      capabilities.desktopTransparencyFallbackReason,
      CapabilityFallbackReason.unsupportedPlatform,
    );
  });

  test('display measurements and diagnostic status remain strongly typed', () {
    const display = DisplayCapabilities(
      devicePixelRatio: 2,
      resolution: DisplayResolution(width: 2560, height: 1440),
      refreshRate: 120,
      hdr: CapabilityStatus.unsupported(
        CapabilityFallbackReason.displayUnsupported,
      ),
      wideColor: CapabilityStatus.unknown(),
    );

    expect(display.devicePixelRatio, 2);
    expect(display.resolution.toString(), '2560 × 1440 px');
    expect(display.refreshRate, 120);
    expect(display.hdr.diagnosticLabel, 'unsupported');
    expect(display.wideColor.isUnknown, isTrue);
  });
}
