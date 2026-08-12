import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/platform/platform_capabilities.dart';
import 'providers.dart';

class PlatformDiagnosticsPage extends ConsumerWidget {
  const PlatformDiagnosticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(platformCapabilitiesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('\u5e73\u53f0\u80fd\u529b\u8bca\u65ad')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('\u8bfb\u53d6\u5e73\u53f0\u80fd\u529b\u5931\u8d25\uff1a$error'),
        ),
        data: (capabilities) => _CapabilitiesView(capabilities: capabilities),
      ),
    );
  }
}

class _CapabilitiesView extends StatelessWidget {
  const _CapabilitiesView({required this.capabilities});

  final PlatformCapabilities capabilities;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 840;
        final sections = [
          _section('\u5e73\u53f0', [
            _valueRow('\u64cd\u4f5c\u7cfb\u7edf / platform', capabilities.platform),
          ]),
          _section('\u663e\u793a', [
            _valueRow('devicePixelRatio', _number(capabilities.display.devicePixelRatio)),
            _valueRow('\u5206\u8fa8\u7387', capabilities.display.resolution?.toString() ?? 'unknown'),
            _valueRow('\u5237\u65b0\u7387', _hz(capabilities.display.refreshRate)),
            _statusRow('HDR', capabilities.display.hdr),
            _statusRow('Wide Color', capabilities.display.wideColor),
          ]),
          _section('\u6e32\u67d3', [
            _valueRow('renderer', capabilities.rendering.renderer ?? 'unknown'),
            _valueRow('backend', capabilities.rendering.backend ?? 'unknown'),
            _statusRow('alpha surface', capabilities.rendering.alphaSurface),
          ]),
          _section('\u7a97\u53e3\u4e0e\u8f93\u5165', [
            _statusRow('borderless', capabilities.desktopWindow.borderless),
            _statusRow('desktop transparency', capabilities.desktopWindow.desktopTransparency),
            _statusRow('tray', capabilities.desktopWindow.tray),
            _statusRow('taskbar/dock', capabilities.desktopWindow.taskbarOrDock),
            _statusRow('keyboard', capabilities.input.keyboard),
            _statusRow('mouse', capabilities.input.mouse),
            _statusRow('touch', capabilities.input.touch),
            _statusRow('volume keys', capabilities.input.volumeKeys),
          ]),
        ];
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < sections.length; i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: i == sections.length - 1 ? 0 : 12,
                        ),
                        child: sections[i],
                      ),
                    ),
                ],
              )
            else
              ...sections,
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                title: const Text('supportsDesktopReaderTransparency'),
                subtitle: Text(
                  capabilities.supportsDesktopReaderTransparency
                      ? 'supported'
                      : 'not supported (${capabilities.desktopTransparencyFallbackReason.name})',
                ),
                leading: Icon(
                  capabilities.supportsDesktopReaderTransparency
                      ? Icons.check_circle_outline
                      : Icons.info_outline,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _section(String title, List<Widget> children) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    ),
  );

  Widget _valueRow(String label, String value) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    trailing: SizedBox(
      width: 170,
      child: Text(value, textAlign: TextAlign.right, overflow: TextOverflow.ellipsis),
    ),
  );

  Widget _statusRow(String label, CapabilityStatus status) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    trailing: Text(
      status.fallbackReason == null
          ? status.diagnosticLabel
          : '${status.diagnosticLabel} \u00b7 ${status.fallbackReason!.name}',
    ),
  );

  String _number(double? value) =>
      value == null ? 'unknown' : value.toStringAsFixed(2);

  String _hz(double? value) =>
      value == null ? 'unknown' : '${value.toStringAsFixed(1)} Hz';
}
