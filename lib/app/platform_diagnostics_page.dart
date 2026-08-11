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
      appBar: AppBar(title: const Text('平台能力诊断')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('读取平台能力失败：$error')),
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
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('平台', style: theme.textTheme.titleMedium),
        _valueRow('platform', capabilities.platform),
        const SizedBox(height: 16),
        Text('显示', style: theme.textTheme.titleMedium),
        _valueRow('devicePixelRatio', _number(capabilities.display.devicePixelRatio)),
        _valueRow('resolution', capabilities.display.resolution?.toString() ?? 'unknown'),
        _valueRow('refreshRate', _hz(capabilities.display.refreshRate)),
        _statusRow('HDR', capabilities.display.hdr),
        _statusRow('Wide Color', capabilities.display.wideColor),
        const SizedBox(height: 16),
        Text('渲染', style: theme.textTheme.titleMedium),
        _valueRow('renderer', capabilities.rendering.renderer ?? 'unknown'),
        _valueRow('backend', capabilities.rendering.backend ?? 'unknown'),
        _statusRow('alpha surface', capabilities.rendering.alphaSurface),
        const SizedBox(height: 16),
        Text('窗口与输入', style: theme.textTheme.titleMedium),
        _statusRow('borderless', capabilities.desktopWindow.borderless),
        _statusRow('desktop transparency', capabilities.desktopWindow.desktopTransparency),
        _statusRow('tray', capabilities.desktopWindow.tray),
        _statusRow('taskbar/dock', capabilities.desktopWindow.taskbarOrDock),
        _statusRow('keyboard', capabilities.input.keyboard),
        _statusRow('mouse', capabilities.input.mouse),
        _statusRow('touch', capabilities.input.touch),
        _statusRow('volume keys', capabilities.input.volumeKeys),
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
  }

  Widget _valueRow(String label, String value) => ListTile(
    dense: true,
    title: Text(label),
    trailing: Text(value),
  );

  Widget _statusRow(String label, CapabilityStatus status) => ListTile(
    dense: true,
    title: Text(label),
    trailing: Text(
      status.fallbackReason == null
          ? status.diagnosticLabel
          : '${status.diagnosticLabel} · ${status.fallbackReason!.name}',
    ),
  );

  String _number(double? value) => value == null ? 'unknown' : value.toStringAsFixed(2);

  String _hz(double? value) => value == null ? 'unknown' : '${value.toStringAsFixed(1)} Hz';
}
