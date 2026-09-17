import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';

import '../domain/account/account_client.dart';
import '../domain/account/device_identity.dart';
import '../domain/account/account_models.dart';
import 'providers.dart';

/// Account settings intentionally delegates authentication to the system
/// browser. No email, Google or other third-party login form lives in XAOCEN.
class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  XaocenAccountClient? _client;
  DeviceAuthorization? _authorization;
  AccountProfile? _profile;
  List<AccountEntitlement> _entitlements = const [];
  String? _status;
  bool _busy = false;
  bool _pollInFlight = false;
  Timer? _pollTimer;
  DeviceIdentityInfo? _identity;

  @override
  void initState() {
    super.initState();
    unawaited(_restore());
  }

  Future<void> _restore() async {
    final client = ref.read(accountClientProvider);
    _client = client;
    try {
      final session = await client.restoreSession();
      if (session != null) await _loadAccount();
    } catch (error) {
      if (mounted) setState(() => _status = _friendlyError(error));
    }
  }

  Future<void> _startAuthorization() async {
    final XaocenAccountClient client =
        _client ?? ref.read(accountClientProvider);
    _client = client;
    setState(() {
      _busy = true;
      _status = '正在生成设备授权…';
    });
    try {
      final identity = await DeviceIdentity().loadOrCreate();
      _identity = identity;
      final auth = await client.startDeviceAuthorization(
        deviceName: Platform.operatingSystem,
        devicePublicKey: identity.publicKeySpkiPem,
      );
      _authorization = auth;
      final uri = auth.verificationUriComplete ?? auth.verificationUri;
      await _openExternalUri(uri);
      _status = '请在浏览器完成 XAOCEN Account 授权，然后返回此处。';
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(
        auth.interval,
        (_) => unawaited(_pollAuthorization()),
      );
    } catch (error) {
      _status = _friendlyError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pollAuthorization() async {
    if (_pollInFlight) return;
    final auth = _authorization;
    final clientValue = _client;
    if (auth == null || clientValue == null) return;
    final client = clientValue;
    _pollInFlight = true;
    try {
      final status = await client.deviceStatus(auth.deviceCode);
      if (!mounted) return;
      setState(
        () => _status = switch (status.status) {
          'pending' => '等待浏览器授权…',
          'approved' => '授权成功，正在建立会话…',
          'denied' => '授权已拒绝',
          'expired' => '授权已过期，请重新开始',
          _ => status.message ?? '授权状态：${status.status}',
        },
      );
      if (status.isApproved) {
        _pollTimer?.cancel();
        await client.deviceToken(auth.deviceCode);
        await _loadAccount();
      } else if (status.isTerminal) {
        _pollTimer?.cancel();
      }
    } catch (error) {
      if (mounted) setState(() => _status = _friendlyError(error));
    } finally {
      _pollInFlight = false;
    }
  }

  Future<void> _loadAccount() async {
    final XaocenAccountClient client =
        _client ?? ref.read(accountClientProvider);
    try {
      final profile = await client.accountMe();
      final entitlements = await client.entitlements();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _entitlements = entitlements;
        _status = '已连接 XAOCEN Account';
      });
    } catch (error) {
      if (mounted) setState(() => _status = _friendlyError(error));
    }
  }

  Future<void> _logout() async {
    final XaocenAccountClient client =
        _client ?? ref.read(accountClientProvider);
    await client.logout();
    if (mounted) {
      setState(() {
        _profile = null;
        _entitlements = const [];
        _status = '已退出账号';
      });
    }
  }

  Future<void> _importLicense() async {
    final result = await FilePicker.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['xaocen-license', 'txt'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final text = file.bytes != null
        ? String.fromCharCodes(file.bytes!)
        : (file.path == null ? '' : await File(file.path!).readAsString());
    if (text.trim().isEmpty) return;
    try {
      final XaocenAccountClient client =
          _client ?? ref.read(accountClientProvider);
      await client.checkOfflineLicense(text);
      if (mounted) setState(() => _status = '离线授权验证成功');
    } catch (error) {
      if (mounted) setState(() => _status = _friendlyError(error));
    }
  }

  Future<void> _showDeviceQr() async {
    final identity = _identity ?? await DeviceIdentity().loadOrCreate();
    if (!mounted) return;
    setState(() => _identity = identity);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设备授权二维码'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(data: identity.qrPayload, size: 220),
              const SizedBox(height: 12),
              Text(
                '请使用已登录 XAOCEN Account 的设备扫描。二维码只包含设备公钥，不包含访问令牌。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Future<void> _importLicenseString() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入离线授权字符串'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(hintText: '粘贴 compactLicense'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('验证'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.trim().isEmpty) return;
    try {
      final XaocenAccountClient client =
          _client ?? ref.read(accountClientProvider);
      await client.checkOfflineLicense(value);
      if (mounted) setState(() => _status = '离线授权验证成功');
    } catch (error) {
      if (mounted) setState(() => _status = _friendlyError(error));
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final signedIn = _profile != null;
    return Scaffold(
      appBar: AppBar(title: const Text('XAOCEN Account')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(
                      Icons.person_outline,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          signedIn
                              ? (_profile!.displayName ?? 'XAOCEN Account')
                              : '未连接账号',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (signedIn && _profile!.email != null)
                          Text(
                            _profile!.email!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (_status != null)
                          Text(
                            _status!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (!signedIn)
            FilledButton.icon(
              onPressed: _busy ? null : _startAuthorization,
              icon: const Icon(Icons.open_in_browser),
              label: const Text('在浏览器中连接 XAOCEN Account'),
            ),
          if (signedIn) ...[
            for (final entitlement in _entitlements)
              ListTile(
                leading: const Icon(Icons.verified_outlined),
                title: Text(entitlement.productId),
                subtitle: Text(
                  '${entitlement.licenseType ?? '授权'} · ${entitlement.status}',
                ),
              ),
            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('退出账号'),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _importLicense,
            icon: const Icon(Icons.qr_code_2),
            label: const Text('导入离线授权文件'),
          ),
          OutlinedButton.icon(
            onPressed: _importLicenseString,
            icon: const Icon(Icons.content_paste),
            label: const Text('粘贴离线授权字符串'),
          ),
          if (Platform.isWindows) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _showDeviceQr,
              icon: const Icon(Icons.qr_code),
              label: const Text('显示设备授权二维码'),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '登录由 XAOCEN Account 官方页面完成；本应用不保存密码或验证码。访问令牌仅保存在内存中。',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  String _friendlyError(Object error) => error is AccountApiException
      ? '${error.message}（${error.code}）'
      : '账号服务暂不可用，请稍后重试';

  Future<void> _openExternalUri(Uri uri) async {
    final host = uri.host.toLowerCase();
    final trusted =
        uri.scheme == 'https' &&
        (host == 'xaocen.studio' || host.endsWith('.xaocen.studio'));
    if (!trusted) {
      throw const AccountProtocolException('账号服务返回了不受信任的授权地址');
    }
    if (Platform.isAndroid) {
      await const MethodChannel(
        'xaocen.reader/account',
      ).invokeMethod<void>('openExternalUrl', uri.toString());
      return;
    }
    if (Platform.isWindows) {
      await Process.start('explorer.exe', [uri.toString()]);
      return;
    }
    throw const AccountProtocolException('当前平台无法打开系统浏览器');
  }
}
