import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/reader_input_bindings_repository.dart';
import '../data/repositories/windows_shell_preferences_repository.dart';
import '../domain/reader/reader_input_capture_workflow.dart';
import '../domain/windows_shell_preferences.dart';
import '../reader/reader_input.dart';
import '../reader/reader_input_router.dart';
import '../reader/supported_shortcut_key_registry.dart';
import 'windows_shell.dart';
import 'providers.dart';
import 'router.dart';

class ReaderSettingsPage extends StatelessWidget {
  const ReaderSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 720;
    return Scaffold(
      appBar: AppBar(title: const Text('阅读设置')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: desktop ? 760 : double.infinity,
          ),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              desktop ? 32 : 16,
              20,
              desktop ? 32 : 16,
              32,
            ),
            children: [
              Text('应用设置', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                '按键配置属于应用级设置；每本书的排版与主题仍在 Reader 的 Aa 面板中独立保存。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              if (kDebugMode || Platform.isWindows || Platform.isAndroid) ...[
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.analytics_outlined),
                    title: const Text('平台能力诊断'),
                    subtitle: const Text('查看当前平台、渲染器、显示与窗口能力'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(
                      context,
                    ).pushNamed(AppRouter.platformDiagnostics),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              _SettingsSectionLabel(label: '输入与操作'),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.keyboard_alt_outlined),
                  title: const Text('按键与操作'),
                  subtitle: const Text('自定义翻页、章节、阅读控制和目录输入'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ReaderInputSettingsPage(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _SettingsSectionLabel(label: '阅读外观'),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.text_fields_outlined),
                  title: const Text('排版与主题'),
                  subtitle: const Text('请在打开的书籍中点击 Aa，设置字号、间距、边距和主题'),
                  trailing: const Icon(Icons.info_outline),
                ),
              ),
              if (Platform.isWindows) ...[
                const SizedBox(height: 20),
                _SettingsSectionLabel(label: 'Windows 专属设置'),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.desktop_windows_outlined),
                    title: const Text('窗口与托盘'),
                    subtitle: const Text('任务栏、托盘和关闭窗口行为'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const WindowsShellSettingsPage(),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class LegacyWindowsShellSettingsPage extends ConsumerStatefulWidget {
  const LegacyWindowsShellSettingsPage({super.key});

  @override
  ConsumerState<LegacyWindowsShellSettingsPage> createState() =>
      _LegacyWindowsShellSettingsPageState();
}

class _LegacyWindowsShellSettingsPageState
    extends ConsumerState<LegacyWindowsShellSettingsPage> {
  late final WindowsShellPreferencesRepository _repository = ref.read(
    windowsShellPreferencesRepositoryProvider,
  );
  WindowsShellPreferences _preferences = WindowsShellPreferences.defaults;
  StreamSubscription<WindowsShellPreferences>? _subscription;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    _subscription = _repository.watch().listen((value) {
      if (mounted) setState(() => _preferences = value);
      unawaited(WindowsShellBridge.apply(value));
    });
  }

  Future<void> _load() async {
    final value = await _repository.load();
    if (!mounted) return;
    setState(() => _preferences = value);
    unawaited(WindowsShellBridge.apply(value));
  }

  @override
  void dispose() {
    final subscription = _subscription;
    if (subscription != null) unawaited(subscription.cancel());
    super.dispose();
  }

  Future<void> _set({bool? taskbar, bool? tray}) async {
    final nextTaskbar = taskbar ?? _preferences.showTaskbarIcon;
    final nextTray = tray ?? _preferences.showTrayIcon;
    try {
      final value = await _repository.update(
        showTaskbarIcon: nextTaskbar,
        showTrayIcon: nextTray,
      );
      if (mounted) setState(() => _preferences = value);
      await WindowsShellBridge.apply(value);
    } on WindowsShellVisibilityException {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('任务栏图标和托盘图标至少保留一个')));
    }
  }

  Future<void> _reset() async {
    final value = await _repository.resetToDefaults();
    if (!mounted) return;
    setState(() => _preferences = value);
    await WindowsShellBridge.apply(value);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已恢复 Windows 默认窗口入口')));
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 720;
    return Scaffold(
      appBar: AppBar(title: const Text('窗口与托盘')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: desktop ? 720 : double.infinity,
          ),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              desktop ? 32 : 16,
              20,
              desktop ? 32 : 16,
              32,
            ),
            children: [
              Text(
                'Windows 窗口入口',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '至少保留一个入口，避免隐藏窗口后无法找回。启用托盘后，关闭窗口会隐藏到托盘。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      title: const Text('显示任务栏图标'),
                      subtitle: const Text('在 Windows 任务栏中显示应用入口'),
                      value: _preferences.showTaskbarIcon,
                      onChanged: (value) => unawaited(_set(taskbar: value)),
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      title: const Text('显示托盘图标'),
                      subtitle: const Text('从系统托盘显示/隐藏窗口或退出应用'),
                      value: _preferences.showTrayIcon,
                      onChanged: (value) => unawaited(_set(tray: value)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.keyboard_double_arrow_left),
                  title: const Text('Boss Key'),
                  subtitle: Text(
                    _preferences.showTrayIcon
                        ? '鼠标左键 + 右键同时按下即可隐藏窗口，再从托盘恢复'
                        : '需要先启用托盘图标，才能安全隐藏窗口',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => unawaited(_reset()),
                icon: const Icon(Icons.restore),
                label: const Text('恢复 Windows 默认'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WindowsShellSettingsPage extends ConsumerStatefulWidget {
  const WindowsShellSettingsPage({super.key});

  @override
  ConsumerState<WindowsShellSettingsPage> createState() =>
      _WindowsShellSettingsPageState();
}

class _WindowsShellSettingsPageState
    extends ConsumerState<WindowsShellSettingsPage> {
  late final WindowsShellPreferencesRepository _repository = ref.read(
    windowsShellPreferencesRepositoryProvider,
  );
  WindowsShellPreferences _preferences = WindowsShellPreferences.defaults;
  StreamSubscription<WindowsShellPreferences>? _subscription;
  late final FocusNode _captureFocus = FocusNode(
    debugLabel: 'boss-key-capture',
  );
  bool _capturing = false;
  WindowsBossKeyGesture? _candidate;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    _subscription = _repository.watch().listen((value) {
      if (mounted) setState(() => _preferences = value);
      unawaited(WindowsShellBridge.apply(value));
    });
  }

  Future<void> _load() async {
    final value = await _repository.load();
    if (!mounted) return;
    setState(() => _preferences = value);
    unawaited(WindowsShellBridge.apply(value));
  }

  @override
  void dispose() {
    final subscription = _subscription;
    if (subscription != null) unawaited(subscription.cancel());
    WindowsShellBridge.setCaptureActive(false);
    _captureFocus.dispose();
    super.dispose();
  }

  Future<void> _setVisibility({bool? taskbar, bool? tray}) async {
    final nextTaskbar = taskbar ?? _preferences.showTaskbarIcon;
    final nextTray = tray ?? _preferences.showTrayIcon;
    try {
      final value = await _repository.update(
        showTaskbarIcon: nextTaskbar,
        showTrayIcon: nextTray,
      );
      if (mounted) setState(() => _preferences = value);
      await WindowsShellBridge.apply(value);
    } on WindowsShellVisibilityException {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('至少保留任务栏或托盘中的一个入口。')));
    }
  }

  Future<void> _setWindowBorder(bool show) async {
    final value = await _repository.updateWindowBorder(show);
    if (!mounted) return;
    setState(() => _preferences = value);
    await WindowsShellBridge.apply(value);
  }

  Future<void> _setBossEnabled(bool enabled) async {
    final value = await _repository.updateBossKey(
      enabled: enabled,
      gesture: _preferences.bossKeyGesture,
    );
    if (!mounted) return;
    setState(() => _preferences = value);
    await WindowsShellBridge.apply(value);
  }

  Future<void> _setMouseBossEnabled(bool enabled) async {
    final value = await _repository.updateMouseBoss(enabled);
    if (!mounted) return;
    setState(() => _preferences = value);
    await WindowsShellBridge.apply(value);
  }

  void _startCapture() {
    setState(() {
      _capturing = true;
      _candidate = null;
    });
    WindowsShellBridge.setCaptureActive(true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _capturing) _captureFocus.requestFocus();
    });
  }

  void _cancelCapture() {
    WindowsShellBridge.setCaptureActive(false);
    if (!mounted) return;
    setState(() {
      _capturing = false;
      _candidate = null;
    });
  }

  void _retryCapture() {
    if (!mounted) return;
    setState(() => _candidate = null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _capturing) _captureFocus.requestFocus();
    });
  }

  KeyEventResult _captureKey(FocusNode node, KeyEvent event) {
    if (!_capturing) return KeyEventResult.ignored;
    if (event is KeyUpEvent) {
      return KeyEventResult.handled;
    }
    if (event is KeyRepeatEvent) {
      return KeyEventResult.handled;
    }
    if (event is! KeyDownEvent) return KeyEventResult.handled;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _cancelCapture();
      return KeyEventResult.handled;
    }
    final input =
        SupportedShortcutKeyRegistry.inputFor(event.physicalKey) ??
        physicalInputIdForKey(event.logicalKey);
    final key = input == null ? null : WindowsShellKey.parse(input.value);
    if (key == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('此按键不能作为 XAOCEN 快捷键')));
      return KeyEventResult.handled;
    }
    final modifiers = <WindowsShellModifier>{
      if (HardwareKeyboard.instance.isControlPressed) WindowsShellModifier.ctrl,
      if (HardwareKeyboard.instance.isAltPressed) WindowsShellModifier.alt,
      if (HardwareKeyboard.instance.isShiftPressed) WindowsShellModifier.shift,
    };
    setState(
      () => _candidate = WindowsBossKeyGesture.keyboard(
        key,
        modifiers: modifiers,
      ),
    );
    return KeyEventResult.handled;
  }

  Future<void> _confirmCapture() async {
    final candidate = _candidate;
    if (candidate == null) return;
    if (candidate.isKeyboard && candidate.primaryKey != null) {
      final input = PhysicalInputId.parse(candidate.primaryKey!.id);
      if (input != null) {
        final profile = await ref
            .read(readerInputBindingsRepositoryProvider)
            .load(ReaderInputPlatform.windows);
        final readerGesture = ReaderInputGesture(
          primaryInput: input,
          modifiers: candidate.modifiers.map(
            (modifier) => switch (modifier) {
              WindowsShellModifier.ctrl => ReaderInputModifier.ctrl,
              WindowsShellModifier.alt => ReaderInputModifier.alt,
              WindowsShellModifier.shift => ReaderInputModifier.shift,
            },
          ),
        );
        final conflicting = profile.commandFor(readerGesture);
        if (conflicting != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('该按键已绑定阅读操作：${commandLabel(conflicting)}'),
              ),
            );
          }
          return;
        }
      }
    }
    final value = await _repository.updateBossKey(
      enabled: true,
      gesture: candidate,
    );
    if (!mounted) return;
    setState(() => _preferences = value);
    await WindowsShellBridge.apply(value);
    _cancelCapture();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('\u2713 老板键已保存：${candidate.label}')));
  }

  Future<void> _reset() async {
    final value = await _repository.resetToDefaults();
    if (!mounted) return;
    setState(() => _preferences = value);
    await WindowsShellBridge.apply(value);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已恢复 Windows 默认设置。')));
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 720;
    return Scaffold(
      appBar: AppBar(title: const Text('窗口、托盘与老板键')),
      body: Focus(
        focusNode: _captureFocus,
        onKeyEvent: _captureKey,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: desktop ? 720 : double.infinity,
            ),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                desktop ? 32 : 16,
                20,
                desktop ? 32 : 16,
                32,
              ),
              children: [
                Text(
                  'Windows 窗口入口',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '至少保留任务栏或托盘中的一个入口，避免隐藏窗口后无法找回。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        title: const Text('显示任务栏图标'),
                        value: _preferences.showTaskbarIcon,
                        onChanged: (value) =>
                            unawaited(_setVisibility(taskbar: value)),
                      ),
                      const Divider(height: 1),
                      SwitchListTile.adaptive(
                        title: const Text('显示托盘图标'),
                        subtitle: const Text('关闭窗口时可隐藏到托盘'),
                        value: _preferences.showTrayIcon,
                        onChanged: (value) =>
                            unawaited(_setVisibility(tray: value)),
                      ),
                      const Divider(height: 1),
                      SwitchListTile.adaptive(
                        title: const Text('显示窗口边框'),
                        subtitle: const Text('关闭后进入可拖动、可调整大小的无边框阅读模式'),
                        value: _preferences.showWindowBorder,
                        onChanged: (value) =>
                            unawaited(_setWindowBorder(value)),
                      ),
                      const Divider(height: 1),
                      const ListTile(
                        title: Text('阅读背景/窗口透明度'),
                        subtitle: Text(
                          '当前 Flutter Windows surface 尚不支持安全的原生透明；功能 deferred。',
                        ),
                        trailing: Icon(Icons.info_outline),
                      ),
                      const Divider(height: 1),
                      const ListTile(
                        title: Text('正文文字透明度'),
                        subtitle: Text('独立文字 alpha 需要透明渲染合成；当前未启用，不会偷偷改变正文颜色。'),
                        trailing: Icon(Icons.info_outline),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.keyboard_alt_outlined),
                        title: const Text('键盘老板键'),
                        subtitle: Text(
                          _preferences.bossKeyGesture.isKeyboard
                              ? '老板键快捷键：${_preferences.bossKeyGesture.label}'
                              : '老板键快捷键：未设置',
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Switch.adaptive(
                              value:
                                  _preferences.bossKeyEnabled &&
                                  _preferences.bossKeyGesture.isKeyboard,
                              onChanged: _preferences.bossKeyGesture.isKeyboard
                                  ? (value) => unawaited(_setBossEnabled(value))
                                  : null,
                            ),
                            OutlinedButton(
                              onPressed: _capturing ? null : _startCapture,
                              child: const Text('修改'),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile.adaptive(
                        title: const Text('鼠标老板手势'),
                        subtitle: const Text(
                          '左右键同时按下显示/隐藏窗口。鼠标左右键为固定手势，不参与普通快捷键录入。',
                        ),
                        value: _preferences.mouseBossEnabled,
                        onChanged: (value) =>
                            unawaited(_setMouseBossEnabled(value)),
                      ),
                      if (_capturing)
                        _BossKeyCapturePanel(
                          candidate: _candidate,
                          onConfirm: _confirmCapture,
                          onRetry: _retryCapture,
                          onCancel: _cancelCapture,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => unawaited(_reset()),
                  icon: const Icon(Icons.restore),
                  label: const Text('恢复 Windows 默认设置'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BossKeyCapturePanel extends StatelessWidget {
  const _BossKeyCapturePanel({
    required this.candidate,
    required this.onConfirm,
    required this.onRetry,
    required this.onCancel,
  });
  final WindowsBossKeyGesture? candidate;
  final VoidCallback onConfirm;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final waiting = candidate == null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              waiting ? '正在等待输入……' : '检测到：${candidate!.label}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(waiting ? '请按一个键或同时按下鼠标左右键。Esc 取消。' : '确认后才会保存老板键绑定。'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                if (!waiting)
                  FilledButton(onPressed: onConfirm, child: const Text('确认绑定')),
                OutlinedButton(onPressed: onRetry, child: const Text('重新输入')),
                TextButton(onPressed: onCancel, child: const Text('取消')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSectionLabel extends StatelessWidget {
  const _SettingsSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
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
  late final FocusNode _captureFocusNode = FocusNode(
    debugLabel: 'reader-input-capture',
  );
  late final ReaderInputRouter _router = ReaderInputRouter(
    platform: _platform,
    repository: _repository,
    onProfileChanged: _onProfileChanged,
    onHostStateChanged: _onHostStateChanged,
  );
  final ReaderInputCaptureWorkflow _captureWorkflow =
      ReaderInputCaptureWorkflow();

  ReaderInputProfile? _profile;
  ReaderCommand? _captureCommand;
  ReaderInputGesture? _candidate;
  bool _resetting = false;

  @override
  void initState() {
    super.initState();
    unawaited(_router.start());
    // Android volume keys use the physical-input selector below. Capture is
    // intentionally a Windows-only interaction; the Reader route owns the
    // Android bridge lifecycle.
  }

  @override
  void dispose() {
    WindowsShellBridge.setCaptureActive(false);
    unawaited(_router.dispose());
    _captureFocusNode.dispose();
    if (Platform.isAndroid) unawaited(ReaderInputBridge.deactivate());
    super.dispose();
  }

  void _onProfileChanged(ReaderInputProfile profile) {
    if (mounted) setState(() => _profile = profile);
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
    final captured = _router.capture.capturedGesture;
    if (!captureActive &&
        captured != null &&
        _captureCommand != null &&
        _captureWorkflow.capture(captured)) {
      WindowsShellBridge.setCaptureActive(false);
      if (mounted) setState(() => _candidate = captured);
    } else if (mounted) {
      setState(() {});
    }
  }

  void _startCapture(ReaderCommand command) {
    if (_platform != ReaderInputPlatform.windows) return;
    setState(() {
      _captureCommand = command;
      _candidate = null;
    });
    _captureWorkflow.start();
    _router.startCapture();
    WindowsShellBridge.setCaptureActive(true);
    _captureFocusNode.requestFocus();
  }

  void _retryCapture() {
    if (_captureCommand == null) return;
    _captureWorkflow.retry();
    setState(() => _candidate = null);
    _router.startCapture();
    WindowsShellBridge.setCaptureActive(true);
    _captureFocusNode.requestFocus();
  }

  void _cancelCapture() {
    WindowsShellBridge.setCaptureActive(false);
    _router.cancelCapture();
    _captureWorkflow.cancel();
    setState(() {
      _captureCommand = null;
      _candidate = null;
    });
  }

  Future<void> _confirmCandidate() async {
    final gesture = _candidate;
    final command = _captureCommand;
    if (gesture == null || command == null) return;
    if (_platform == ReaderInputPlatform.windows) {
      final shellRepository = ref.read(
        windowsShellPreferencesRepositoryProvider,
      );
      final shell = await shellRepository.load();
      if (!mounted) return;
      final bossGesture = shell.bossKeyGesture;
      final shellInput = bossGesture.primaryKey == null
          ? null
          : PhysicalInputId.parse(bossGesture.primaryKey!.id);
      final sameModifiers =
          bossGesture.modifiers.length == gesture.modifiers.length &&
          bossGesture.modifiers.every(
            (modifier) => gesture.modifiers.contains(switch (modifier) {
              WindowsShellModifier.ctrl => ReaderInputModifier.ctrl,
              WindowsShellModifier.alt => ReaderInputModifier.alt,
              WindowsShellModifier.shift => ReaderInputModifier.shift,
            }),
          );
      if (shell.bossKeyEnabled &&
          bossGesture.isKeyboard &&
          shellInput == gesture.primaryInput &&
          sameModifiers) {
        final replace =
            await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('快捷键冲突'),
                content: Text(
                  '${gestureLabel(gesture)} 已用于 显示/隐藏窗口。是否替换为当前阅读操作？',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('取消'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('确认替换'),
                  ),
                ],
              ),
            ) ??
            false;
        if (!replace || !mounted) return;
        final updated = await shellRepository.updateBossKey(
          enabled: true,
          gesture: const WindowsBossKeyGesture.mouseChord(),
        );
        await WindowsShellBridge.apply(updated);
      }
    }
    await _repository.bind(_platform, gesture, command);
    WindowsShellBridge.setCaptureActive(false);
    final latest = await _repository.load(_platform);
    if (!mounted) return;
    _captureWorkflow.confirm();
    setState(() {
      _profile = latest;
      _captureCommand = null;
      _candidate = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✓ 已保存\n${gestureLabel(gesture)} → ${commandLabel(command)}',
        ),
      ),
    );
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (_platform != ReaderInputPlatform.windows || !_router.capture.isActive) {
      return KeyEventResult.ignored;
    }
    if (event is! KeyDownEvent) return KeyEventResult.handled;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _cancelCapture();
      return KeyEventResult.handled;
    }
    final gesture = readerInputGestureForEvent(
      event,
      control: HardwareKeyboard.instance.isControlPressed,
      alt: HardwareKeyboard.instance.isAltPressed,
      shift: HardwareKeyboard.instance.isShiftPressed,
    );
    // A modifier on its own is deliberately not a complete gesture.
    if (gesture == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('此按键不能作为 XAOCEN 快捷键')));
      return KeyEventResult.handled;
    }
    _router.handlePhysicalGesture(gesture);
    return KeyEventResult.handled;
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (_platform != ReaderInputPlatform.windows ||
        !_router.capture.isActive ||
        event is! PointerScrollEvent ||
        event.scrollDelta.dy == 0) {
      return;
    }
    _router.handlePhysicalGesture(
      ReaderInputGesture.single(
        event.scrollDelta.dy < 0
            ? PhysicalInputId.mouseWheelUp
            : PhysicalInputId.mouseWheelDown,
      ),
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_platform != ReaderInputPlatform.windows ||
        !_router.capture.isActive ||
        event.kind != PointerDeviceKind.mouse ||
        event.buttons & kMiddleMouseButton == 0) {
      return;
    }
    _router.handlePhysicalGesture(
      ReaderInputGesture.single(PhysicalInputId.mouseMiddleButton),
    );
  }

  Future<void> _clearBinding(ReaderInputGesture gesture) async {
    await _repository.unbind(_platform, gesture);
    final latest = await _repository.load(_platform);
    if (mounted) setState(() => _profile = latest);
  }

  Future<void> _selectAndroidBinding(
    PhysicalInputId input,
    ReaderCommand? command,
  ) async {
    if (_platform != ReaderInputPlatform.android) return;
    if (command == null) {
      await _repository.unbind(_platform, ReaderInputGesture.single(input));
    } else {
      await _repository.bind(
        _platform,
        ReaderInputGesture.single(input),
        command,
      );
    }
    final latest = await _repository.load(_platform);
    if (mounted) setState(() => _profile = latest);
  }

  Future<void> _resetDefaults() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('恢复默认按键'),
            content: Text('只恢复 ${platformLabel(_platform)} 当前平台的默认按键。'),
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

  @override
  Widget build(BuildContext context) {
    final profile = _profile ?? _router.profile;
    final desktop = MediaQuery.sizeOf(context).width >= 720;
    return Scaffold(
      appBar: AppBar(title: const Text('按键与操作')),
      body: Focus(
        focusNode: _captureFocusNode,
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Listener(
              onPointerDown: _onPointerDown,
              onPointerSignal: _onPointerSignal,
              child: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: desktop ? 680 : double.infinity,
                    ),
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        desktop ? 24 : 16,
                        12,
                        desktop ? 24 : 16,
                        32,
                      ),
                      children: [
                        _PlatformHeader(platform: _platform),
                        const SizedBox(height: 12),
                        if (_platform == ReaderInputPlatform.windows)
                          Card(
                            child: ListTile(
                              leading: const Icon(
                                Icons.visibility_off_outlined,
                              ),
                              title: const Text('老板键'),
                              subtitle: const Text('窗口与托盘设置中的应用内隐藏窗口快捷键'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const WindowsShellSettingsPage(),
                                ),
                              ),
                            ),
                          ),
                        if (_platform == ReaderInputPlatform.windows)
                          const SizedBox(height: 8),
                        if (_platform == ReaderInputPlatform.android)
                          for (final input in PhysicalInputId.androidInputs)
                            _AndroidInputSection(
                              input: input,
                              command: profile.commandFor(input),
                              autoReadAction:
                                  profile.autoReadVolumeActions[input] ??
                                  AndroidAutoReadVolumeAction.followNormal,
                              onChanged: (command) =>
                                  _selectAndroidBinding(input, command),
                              onAutoReadChanged: (action) async {
                                await _repository.setAndroidAutoReadAction(
                                  input,
                                  action,
                                );
                                final latest = await _repository.load(
                                  _platform,
                                );
                                if (mounted) setState(() => _profile = latest);
                              },
                            )
                        else ...[
                          const _SupportedShortcutHelp(),
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
                        ],
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
            if (_captureCommand != null)
              _CaptureOverlay(
                candidate: _candidate,
                existing: _candidate == null
                    ? null
                    : profile.commandFor(_candidate!),
                target: _captureCommand!,
                onConfirm: _confirmCandidate,
                onRetry: _retryCapture,
                onCancel: _cancelCapture,
                onPointerDown: _onPointerDown,
                onPointerSignal: _onPointerSignal,
              ),
          ],
        ),
      ),
    );
  }
}

class _PlatformHeader extends StatelessWidget {
  const _PlatformHeader({required this.platform});
  final ReaderInputPlatform platform;

  @override
  Widget build(BuildContext context) => Card(
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

class _SupportedShortcutHelp extends StatelessWidget {
  const _SupportedShortcutHelp();

  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      leading: const Icon(Icons.keyboard_alt_outlined),
      title: const Text('查看支持的按键'),
      subtitle: const Text('支持字母、数字、功能键、导航键、小键盘、常用符号键及 Ctrl / Alt / Shift 组合。'),
      children: [
        for (final entry in SupportedShortcutKeyRegistry.categories.entries)
          ListTile(
            dense: true,
            title: Text(entry.key),
            subtitle: Text(
              entry.value
                  .map(SupportedShortcutKeyRegistry.displayName)
                  .join('、'),
            ),
          ),
        const ListTile(
          dense: true,
          title: Text('修饰键'),
          subtitle: Text(SupportedShortcutKeyRegistry.modifierDescription),
        ),
        const ListTile(
          dense: true,
          title: Text('鼠标手势'),
          subtitle: Text(
            '${SupportedShortcutKeyRegistry.mouseGestureDescription}。属于 Mouse Gesture，不参与普通 Keyboard Shortcut 捕获。',
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text('部分系统保留键不能作为 XAOCEN 快捷键。'),
        ),
      ],
    ),
  );
}

class _AndroidInputSection extends StatelessWidget {
  const _AndroidInputSection({
    required this.input,
    required this.command,
    required this.autoReadAction,
    required this.onChanged,
    required this.onAutoReadChanged,
  });

  final PhysicalInputId input;
  final ReaderCommand? command;
  final AndroidAutoReadVolumeAction autoReadAction;
  final ValueChanged<ReaderCommand?> onChanged;
  final ValueChanged<AndroidAutoReadVolumeAction> onAutoReadChanged;

  @override
  Widget build(BuildContext context) => Card(
    key: ValueKey('reader-input-android-${input.value}'),
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              input == PhysicalInputId.androidVolumeUp
                  ? Icons.volume_up_outlined
                  : Icons.volume_down_outlined,
            ),
            title: Text(inputLabel(input)),
            subtitle: Text(
              '当前操作：${command == null ? '不使用' : commandLabel(command!)}',
            ),
            trailing: DropdownButtonHideUnderline(
              child: DropdownButton<ReaderCommand?>(
                key: ValueKey('reader-input-android-select-${input.value}'),
                value: command,
                hint: const Text('选择操作'),
                onChanged: onChanged,
                items: const [
                  DropdownMenuItem<ReaderCommand?>(
                    value: ReaderCommand.previousPage,
                    child: Text('上一页'),
                  ),
                  DropdownMenuItem<ReaderCommand?>(
                    value: ReaderCommand.nextPage,
                    child: Text('下一页'),
                  ),
                  DropdownMenuItem<ReaderCommand?>(
                    value: ReaderCommand.toggleAutoRead,
                    child: Text('自动阅读'),
                  ),
                  DropdownMenuItem<ReaderCommand?>(
                    value: null,
                    child: Text('不使用'),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            dense: true,
            title: const Text('自动阅读运行时'),
            subtitle: const Text('自动阅读运行中按下此键时的操作'),
            trailing: DropdownButton<AndroidAutoReadVolumeAction>(
              value: autoReadAction,
              onChanged: (value) {
                if (value != null) onAutoReadChanged(value);
              },
              items: const [
                DropdownMenuItem(
                  value: AndroidAutoReadVolumeAction.followNormal,
                  child: Text('沿用普通阅读'),
                ),
                DropdownMenuItem(
                  value: AndroidAutoReadVolumeAction.previousPage,
                  child: Text('上一页'),
                ),
                DropdownMenuItem(
                  value: AndroidAutoReadVolumeAction.nextPage,
                  child: Text('下一页'),
                ),
                DropdownMenuItem(
                  value: AndroidAutoReadVolumeAction.toggleAutoRead,
                  child: Text('暂停/继续自动阅读'),
                ),
                DropdownMenuItem(
                  value: AndroidAutoReadVolumeAction.systemVolume,
                  child: Text('系统音量'),
                ),
                DropdownMenuItem(
                  value: AndroidAutoReadVolumeAction.disabled,
                  child: Text('禁用'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _CommandSection extends StatelessWidget {
  const _CommandSection({
    required this.command,
    required this.inputs,
    required this.onAdd,
    required this.onClear,
  });

  final ReaderCommand command;
  final List<ReaderInputGesture> inputs;
  final VoidCallback onAdd;
  final Future<void> Function(ReaderInputGesture gesture) onClear;

  @override
  Widget build(BuildContext context) => Card(
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
                for (final gesture in inputs)
                  InputChip(
                    key: ValueKey(
                      'reader-input-binding-${gesture.canonicalKey}',
                    ),
                    label: Text(gestureLabel(gesture)),
                    deleteIcon: Icon(
                      Icons.clear,
                      key: ValueKey(
                        'reader-input-delete-${gesture.canonicalKey}',
                      ),
                    ),
                    onDeleted: () => unawaited(onClear(gesture)),
                  ),
              ],
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: ValueKey('reader-input-add-${command.name}'),
              onPressed: onAdd,
              icon: const Icon(Icons.keyboard),
              label: const Text('点击这里，然后按下快捷键'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _DisabledSection extends StatelessWidget {
  const _DisabledSection({required this.inputs});
  final List<ReaderInputGesture> inputs;

  @override
  Widget build(BuildContext context) {
    if (inputs.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('已禁用输入：${inputs.map(gestureLabel).join('、')}'),
      ),
    );
  }
}

class _CaptureOverlay extends StatelessWidget {
  const _CaptureOverlay({
    required this.candidate,
    required this.existing,
    required this.target,
    required this.onConfirm,
    required this.onRetry,
    required this.onCancel,
    required this.onPointerSignal,
    required this.onPointerDown,
  });

  final ReaderInputGesture? candidate;
  final ReaderCommand? existing;
  final ReaderCommand target;
  final VoidCallback onConfirm;
  final VoidCallback onRetry;
  final VoidCallback onCancel;
  final void Function(PointerSignalEvent event) onPointerSignal;
  final void Function(PointerDownEvent event) onPointerDown;

  @override
  Widget build(BuildContext context) {
    final waiting = candidate == null;
    final conflict = !waiting && existing != null && existing != target;
    return Material(
      color: Colors.black45,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onCancel,
            ),
          ),
          SafeArea(
            child: Center(
              child: Listener(
                onPointerDown: onPointerDown,
                onPointerSignal: onPointerSignal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: AnimatedContainer(
                    key: const ValueKey('reader-input-capture'),
                    duration: const Duration(milliseconds: 120),
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(blurRadius: 16, color: Colors.black38),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          waiting
                              ? '● 正在等待输入……'
                              : '检测到：${gestureLabel(candidate!)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          waiting
                              ? '请按快捷键或滚动鼠标\nEsc 可取消'
                              : conflict
                              ? '当前：${gestureLabel(candidate!)} → ${commandLabel(existing!)}\n'
                                    '准备修改为：${gestureLabel(candidate!)} → ${commandLabel(target)}'
                              : '准备绑定到：${commandLabel(target)}',
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (!waiting)
                              FilledButton(
                                key: ValueKey(
                                  conflict
                                      ? 'reader-input-conflict-replace'
                                      : 'reader-input-confirm',
                                ),
                                onPressed: onConfirm,
                                child: Text(conflict ? '确认替换' : '确认绑定'),
                              ),
                            if (!waiting)
                              OutlinedButton(
                                key: const ValueKey('reader-input-retry'),
                                onPressed: onRetry,
                                child: const Text('重新输入'),
                              ),
                            TextButton(
                              key: const ValueKey('reader-input-cancel'),
                              onPressed: onCancel,
                              child: const Text('取消'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
  ReaderCommand.toggleAutoRead => '切换自动阅读',
};

String gestureLabel(ReaderInputGesture gesture) {
  final parts = <String>[
    if (gesture.modifiers.contains(ReaderInputModifier.ctrl)) 'Ctrl',
    if (gesture.modifiers.contains(ReaderInputModifier.alt)) 'Alt',
    if (gesture.modifiers.contains(ReaderInputModifier.shift)) 'Shift',
    inputLabel(gesture.primaryInput),
  ];
  return parts.join(' + ');
}

String inputLabel(PhysicalInputId input) {
  final value = input.value;
  if (value.startsWith('keyboard.key')) {
    return value.substring('keyboard.key'.length);
  }
  if (value.startsWith('keyboard.digit')) {
    return value.substring('keyboard.digit'.length);
  }
  if (value.startsWith('keyboard.numpad')) {
    final suffix = value.substring('keyboard.numpad'.length);
    return switch (suffix) {
      'Add' => 'Numpad +',
      'Subtract' => 'Numpad -',
      'Multiply' => 'Numpad *',
      'Divide' => 'Numpad /',
      _ => 'Numpad $suffix',
    };
  }
  if (value.startsWith('keyboard.f')) {
    return value.substring('keyboard.'.length).toUpperCase();
  }
  return switch (input) {
    PhysicalInputId.keyboardArrowLeft => 'Arrow Left',
    PhysicalInputId.keyboardArrowRight => 'Arrow Right',
    PhysicalInputId.keyboardArrowUp => 'Arrow Up',
    PhysicalInputId.keyboardArrowDown => 'Arrow Down',
    PhysicalInputId.keyboardPageUp => 'Page Up',
    PhysicalInputId.keyboardPageDown => 'Page Down',
    PhysicalInputId.keyboardHome => 'Home',
    PhysicalInputId.keyboardEnd => 'End',
    PhysicalInputId.keyboardSpace => 'Space',
    PhysicalInputId.keyboardEnter => 'Enter',
    PhysicalInputId.mouseWheelUp => 'Wheel Up',
    PhysicalInputId.mouseWheelDown => 'Wheel Down',
    PhysicalInputId.mouseMiddleButton => 'Mouse Middle',
    PhysicalInputId.keyboardComma => 'Comma',
    PhysicalInputId.keyboardPeriod => 'Period',
    PhysicalInputId.keyboardSlash => 'Slash',
    PhysicalInputId.keyboardSemicolon => 'Semicolon',
    PhysicalInputId.keyboardQuote => 'Quote',
    PhysicalInputId.keyboardBracketLeft => 'Bracket Left',
    PhysicalInputId.keyboardBracketRight => 'Bracket Right',
    PhysicalInputId.keyboardBackslash => 'Backslash',
    PhysicalInputId.keyboardMinus => 'Minus',
    PhysicalInputId.keyboardEqual => 'Equal',
    PhysicalInputId.keyboardBackquote => 'Backquote',
    PhysicalInputId.androidVolumeUp => 'Volume Up',
    PhysicalInputId.androidVolumeDown => 'Volume Down',
    _ => input.value,
  };
}
