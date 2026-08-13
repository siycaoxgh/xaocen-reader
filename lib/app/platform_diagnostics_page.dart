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
          child: Text(
            '\u8bfb\u53d6\u5e73\u53f0\u80fd\u529b\u5931\u8d25\uff1a$error',
          ),
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
            _valueRow('\u64cd\u4f5c\u7cfb\u7edf / 平台', capabilities.platform),
          ]),
          _section('\u663e\u793a', [
            _valueRow('设备像素比', _number(capabilities.display.devicePixelRatio)),
            _valueRow(
              '分辨率',
              capabilities.display.resolution?.toString() ?? '未知',
            ),
            _valueRow('刷新率', _hz(capabilities.display.refreshRate)),
            _statusRow('HDR', capabilities.display.hdr),
            _statusRow('宽色域', capabilities.display.wideColor),
          ]),
          _section('\u6e32\u67d3', [
            _valueRow('渲染器', capabilities.rendering.renderer ?? '未知'),
            _valueRow('图形后端', capabilities.rendering.backend ?? '未知'),
            _statusRow('Alpha 透明表面', capabilities.rendering.alphaSurface),
          ]),
          _section('\u7a97\u53e3\u4e0e\u8f93\u5165', [
            _statusRow('无边框窗口', capabilities.desktopWindow.borderless),
            _statusRow(
              '桌面阅读透明',
              capabilities.desktopWindow.desktopTransparency,
            ),
            _statusRow('系统托盘', capabilities.desktopWindow.tray),
            _statusRow('任务栏 / Dock', capabilities.desktopWindow.taskbarOrDock),
            _statusRow('键盘', capabilities.input.keyboard),
            _statusRow('鼠标', capabilities.input.mouse),
            _statusRow('触控', capabilities.input.touch),
            _statusRow('音量键', capabilities.input.volumeKeys),
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
                title: const Text('桌面阅读透明能力'),
                subtitle: Text(
                  capabilities.supportsDesktopReaderTransparency
                      ? '支持'
                      : '不支持 · ${_reason(capabilities.desktopTransparencyFallbackReason)}',
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
      child: Text(
        value,
        textAlign: TextAlign.right,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  );

  Widget _statusRow(String label, CapabilityStatus status) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    trailing: Text(
      status.fallbackReason == null
          ? _support(status)
          : '${_support(status)} · ${_reason(status.fallbackReason!)}',
    ),
  );

  String _number(double? value) =>
      value == null ? '未知' : value.toStringAsFixed(2);

  String _hz(double? value) =>
      value == null ? '未知' : '${value.toStringAsFixed(1)} Hz';

  String _support(CapabilityStatus status) => switch (status.support) {
    CapabilitySupport.supported => '支持',
    CapabilitySupport.unsupported => '不支持',
    CapabilitySupport.unknown => '未知',
  };

  String _reason(CapabilityFallbackReason reason) => switch (reason) {
    CapabilityFallbackReason.unsupportedPlatform => '当前平台不支持',
    CapabilityFallbackReason.backendUnavailable => '图形后端不可用',
    CapabilityFallbackReason.standardWindow => '标准窗口模式',
    CapabilityFallbackReason.rendererUnsupported => '当前渲染器不支持',
    CapabilityFallbackReason.displayUnsupported => '当前显示设备不支持',
    CapabilityFallbackReason.unknown => '未知原因',
  };
}
