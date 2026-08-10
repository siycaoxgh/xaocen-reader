import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/reader_input_bindings_repository.dart';
import '../reader/reader_input.dart';
import '../reader/reader_input_router.dart';
import 'providers.dart';

class ReaderSettingsPage extends StatelessWidget {
  const ReaderSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('阅读设置')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          ListTile(
            leading: const Icon(Icons.keyboard_alt_outlined),
            title: const Text('按键与操作'),
            subtitle: const Text('自定义翻页、章节、控制区和目录输入'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ReaderInputSettingsPage(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReaderInputSettingsPage extends ConsumerStatefulWidget {
  const ReaderInputSettingsPage({super.key});

  @override
  ConsumerState<ReaderInputSettingsPage> createState() =>
      _ReaderInputSettingsPageState();
}

class _ReaderInputSettingsPageState
    extends ConsumerState<ReaderInputSettingsPage> {
  late final ReaderInputPlatform _platform =
      defaultTargetPlatform == TargetPlatform.android
      ? ReaderInputPlatform.android
      : ReaderInputPlatform.windows;
  late final ReaderInputBindingsRepository _repository = ref.read(
    readerInputBindingsRepositoryProvider,
  );
  late final ReaderInputRouter _router = ReaderInputRouter(
    platform: _platform,
    repository: _repository,
    onProfileChanged: _onProfileChanged,
    onHostStateChanged: _onHostStateChanged,
  );
  ReaderInputProfile? _profile;
  ReaderCommand? _captureCommand;
  bool _captureDialogOpen = false;
  bool _resetting = false;

  @override
  void initState() {
    super.initState();
    unawaited(_router.start());
    if (Platform.isAndroid) {
      unawaited(
        ReaderInputBridge.activate(
          pagedActive: false,
          inputCaptureActive: false,
          onInput: _router.handlePhysicalInput,
        ),
      );
    }
  }

  @override
  void dispose() {
    unawaited(_router.dispose());
    if (Platform.isAndroid) {
      unawaited(ReaderInputBridge.deactivate());
    }
    super.dispose();
  }

  void _onProfileChanged(ReaderInputProfile next) {
    if (!mounted) return;
    setState(() => _profile = next);
  }

  void _onHostStateChanged({
    required bool pagedActive,
    required bool captureActive,
  }) {
    if (Platform.isAndroid) {
      unawaited(
        ReaderInputBridge.setActiveState(
          pagedActive: pagedActive,
          inputCaptureActive: captureActive,
        ),
      );
    }
    if (mounted) setState(() {});
    final captured = _router.capture.captured;
    if (!captureActive && captured != null && !_captureDialogOpen) {
      _captureDialogOpen = true;
      unawaited(_finishCapture(captured));
    }
  }

  void _startCapture(ReaderCommand command) {
    if (_captureDialogOpen) return;
    setState(() => _captureCommand = command);
    _router.startCapture();
  }

  void _cancelCapture() {
    _captureCommand = null;
    _router.cancelCapture();
    if (mounted) setState(() {});
  }

  Future<void> _finishCapture(PhysicalInputId input) async {
    final command = _captureCommand;
    _captureCommand = null;
    if (!mounted || command == null) {
      _captureDialogOpen = false;
      return;
    }
    if (input.platform != _platform) {
      _captureDialogOpen = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前平台不支持该输入')),
      );
      if (mounted) setState(() {});
      return;
    }
    final current = _profile ?? _router.profile;
    final existing = current.commandFor(input);
    var replace = true;
    if (existing != null && existing != command) {
      replace =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('按键冲突'),
              content: Text(
                '${inputLabel(input)} 当前用于“${commandLabel(existing)}”，是否改为“${commandLabel(command)}”？',
              ),
              actions: [
                TextButton(
                  key: const ValueKey('reader-input-conflict-cancel'),
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('取消'),
                ),
                FilledButton(
                  key: const ValueKey('reader-input-conflict-replace'),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('替换'),
                ),
              ],
            ),
          ) ??
          false;
    }
    if (replace && mounted) {
      await _repository.bind(_platform, input, command);
      final latest = await _repository.load(_platform);
      if (mounted) setState(() => _profile = latest);
    }
    _captureDialogOpen = false;
    if (mounted) setState(() {});
  }

  Future<void> _clearBinding(PhysicalInputId input) async {
    await _repository.unbind(_platform, input);
    final latest = await _repository.load(_platform);
    if (mounted) setState(() => _profile = latest);
  }

  Future<void> _resetDefaults() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('恢复默认按键？'),
            content: Text('仅恢复 ${platformLabel(_platform)} 当前平台的默认按键。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              FilledButton(
                key: const ValueKey('reader-input-reset-confirm'),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('恢复默认'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || _resetting) return;
    setState(() => _resetting = true);
    await _repository.resetToDefaults(_platform);
    final latest = await _repository.load(_platform);
    if (mounted) {
      setState(() {
        _profile = latest;
        _resetting = false;
      });
    }
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        !_router.capture.isActive ||
        _platform != ReaderInputPlatform.windows) {
      return KeyEventResult.ignored;
    }
    final input = physicalInputIdForKey(event.logicalKey);
    if (input == null) return KeyEventResult.ignored;
    _router.handlePhysicalInput(input);
    return KeyEventResult.handled;
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (_platform != ReaderInputPlatform.windows ||
        !_router.capture.isActive ||
        event is! PointerScrollEvent) {
      return;
    }
    final dy = event.scrollDelta.dy;
    if (dy == 0) return;
    _router.handlePhysicalInput(
      dy < 0 ? PhysicalInputId.mouseWheelUp : PhysicalInputId.mouseWheelDown,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile ?? _router.profile;
    final isDesktop = MediaQuery.sizeOf(context).width >= 720;
    return Scaffold(
      appBar: AppBar(title: const Text('按键与操作')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Listener(
            onPointerSignal: _onPointerSignal,
            child: Focus(
              autofocus: true,
              onKeyEvent: _onKeyEvent,
              child: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 680 : double.infinity,
                    ),
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        isDesktop ? 24 : 16,
                        12,
                        isDesktop ? 24 : 16,
                        32,
                      ),
                      children: [
                        _PlatformHeader(platform: _platform),
                        const SizedBox(height: 12),
                        for (final command in ReaderCommand.values)
                          _CommandSection(
                            command: command,
                            inputs: profile.bindings.entries
                                .where((entry) => entry.value == command)
                                .map((entry) => entry.key)
                                .toList(),
                            onAdd: () => _startCapture(command),
                            onClear: _clearBinding,
                          ),
                        _DisabledSection(
                          inputs: profile.bindings.entries
                              .where((entry) => entry.value == null)
                              .map((entry) => entry.key)
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          key: const ValueKey('reader-input-reset'),
                          onPressed: _resetting ? null : _resetDefaults,
                          icon: const Icon(Icons.restore),
                          label: const Text('恢复当前平台默认按键'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_router.capture.isActive)
            _CaptureOverlay(
              onCancel: _cancelCapture,
              onPointerSignal: _onPointerSignal,
            ),
        ],
      ),
    );
  }
}

class _PlatformHeader extends StatelessWidget {
  const _PlatformHeader({required this.platform});
  final ReaderInputPlatform platform;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          platform == ReaderInputPlatform.android
              ? Icons.phone_android
              : Icons.desktop_windows,
        ),
        title: Text(platformLabel(platform)),
        subtitle: const Text('仅显示当前平台支持的物理输入'),
      ),
    );
  }
}

class _CommandSection extends StatelessWidget {
  const _CommandSection({
    required this.command,
    required this.inputs,
    required this.onAdd,
    required this.onClear,
  });

  final ReaderCommand command;
  final List<PhysicalInputId> inputs;
  final VoidCallback onAdd;
  final Future<void> Function(PhysicalInputId input) onClear;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('reader-input-command-${command.name}'),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              commandLabel(command),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (inputs.isEmpty)
              Text(
                '未绑定',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final input in inputs)
                    InputChip(
                      key: ValueKey('reader-input-binding-${input.value}'),
                      label: Text(inputLabel(input)),
                      deleteIcon: Icon(
                        Icons.clear,
                        key: ValueKey('reader-input-delete-${input.value}'),
                      ),
                      onDeleted: () => unawaited(onClear(input)),
                    ),
                ],
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: ValueKey('reader-input-add-${command.name}'),
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('添加按键'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisabledSection extends StatelessWidget {
  const _DisabledSection({required this.inputs});
  final List<PhysicalInputId> inputs;

  @override
  Widget build(BuildContext context) {
    if (inputs.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('已禁用输入', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(inputs.map(inputLabel).join('、')),
            const SizedBox(height: 4),
            Text(
              '如需重新启用，请在对应操作下添加按键。',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureOverlay extends StatelessWidget {
  const _CaptureOverlay({
    required this.onCancel,
    required this.onPointerSignal,
  });

  final VoidCallback onCancel;
  final void Function(PointerSignalEvent event) onPointerSignal;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Listener(
        onPointerSignal: onPointerSignal,
        child: SafeArea(
          child: Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  const Icon(Icons.touch_app_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '请按下一个按键或滚动鼠标',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TextButton(onPressed: onCancel, child: const Text('取消')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String platformLabel(ReaderInputPlatform platform) =>
    platform == ReaderInputPlatform.android ? 'Android' : 'Windows';

String commandLabel(ReaderCommand command) => switch (command) {
  ReaderCommand.previousPage => '上一页',
  ReaderCommand.nextPage => '下一页',
  ReaderCommand.previousChapter => '上一章',
  ReaderCommand.nextChapter => '下一章',
  ReaderCommand.toggleReaderControls => '显示/隐藏阅读控制',
  ReaderCommand.openToc => '打开目录',
};

String inputLabel(PhysicalInputId input) => switch (input) {
  PhysicalInputId.keyboardArrowLeft => '键盘 ←',
  PhysicalInputId.keyboardArrowRight => '键盘 →',
  PhysicalInputId.keyboardPageUp => 'PageUp',
  PhysicalInputId.keyboardPageDown => 'PageDown',
  PhysicalInputId.mouseWheelUp => '鼠标滚轮 ↑',
  PhysicalInputId.mouseWheelDown => '鼠标滚轮 ↓',
  PhysicalInputId.androidVolumeUp => '音量 +',
  PhysicalInputId.androidVolumeDown => '音量 −',
  _ => input.value,
};
