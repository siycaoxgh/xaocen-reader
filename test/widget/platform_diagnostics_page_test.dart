import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xaocen_reader/app/platform_diagnostics_page.dart';
import 'package:xaocen_reader/app/providers.dart';
import 'package:xaocen_reader/domain/platform/platform_capabilities.dart';

void main() {
  testWidgets('diagnostics never renders unknown as supported', (tester) async {
    const capabilities = PlatformCapabilities(
      platform: 'android',
      display: DisplayCapabilities(
        devicePixelRatio: 3,
        resolution: DisplayResolution(width: 1080, height: 2400),
        refreshRate: 90,
      ),
      rendering: RenderingCapabilities(
        renderer: 'Flutter runtime renderer',
        backend: 'runtime-selected',
      ),
      desktopWindow: DesktopWindowCapabilities(
        desktopTransparency: CapabilityStatus.unsupported(
          CapabilityFallbackReason.unsupportedPlatform,
        ),
      ),
      input: InputCapabilities(touch: CapabilityStatus.supported()),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          platformCapabilitiesProvider.overrideWith(
            (ref) async => capabilities,
          ),
        ],
        child: const MaterialApp(home: PlatformDiagnosticsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('android'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pump();
    expect(find.textContaining('当前平台不支持'), findsAtLeastNWidgets(1));
    expect(find.text('支持'), findsOneWidget);
    expect(find.text('桌面阅读透明能力'), findsOneWidget);
  });
}
