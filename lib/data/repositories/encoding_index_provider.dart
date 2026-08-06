import 'dart:io';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../../sources/local_txt/gb18030_index_data.dart';
import '../../sources/local_txt/gb18030_index_loader.dart';

/// GB18030 索引数据提供者抽象。
///
/// - 首次需要 GB18030 时加载；
/// - 进程内缓存（同一 provider 实例只解析一次）；
/// - 并发请求只加载一次（[Future] 去重）；
/// - 加载失败抛 [Gb18030IndexException]（明确错误，不自动回退系统编码）。
abstract class EncodingIndexProvider {
  Future<Gb18030IndexData> load();
}

/// Flutter AssetBundle 实现（正式运行时使用）。
///
/// 通过 rootBundle 加载 `assets/encoding/gb18030_index.bin`。
class FlutterAssetEncodingIndexProvider implements EncodingIndexProvider {
  FlutterAssetEncodingIndexProvider({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  static const String _assetPath = 'assets/encoding/gb18030_index.bin';

  Future<Gb18030IndexData>? _cached;
  Future<Gb18030IndexData>? _inFlight;

  @override
  Future<Gb18030IndexData> load() {
    final cached = _cached;
    if (cached != null) return cached;
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;
    final future = _loadOnce();
    _inFlight = future;
    return future;
  }

  Future<Gb18030IndexData> _loadOnce() async {
    try {
      final data = await _bundle.load(_assetPath);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final parsed = const Gb18030IndexLoader().parse(bytes);
      _cached = Future.value(parsed);
      _inFlight = null;
      return parsed;
    } catch (e) {
      _inFlight = null;
      rethrow;
    }
  }
}

/// 文件系统实现（仅供 tool 与测试使用）。
class FileEncodingIndexProvider implements EncodingIndexProvider {
  FileEncodingIndexProvider(this.binFile);

  final File binFile;

  Future<Gb18030IndexData>? _cached;

  @override
  Future<Gb18030IndexData> load() {
    final cached = _cached;
    if (cached != null) return cached;
    final future = _loadOnce();
    _cached = future;
    return future;
  }

  Future<Gb18030IndexData> _loadOnce() async {
    final bytes = await binFile.readAsBytes();
    return const Gb18030IndexLoader().parse(bytes);
  }
}

/// 内存实现（测试注入）。
class MemoryEncodingIndexProvider implements EncodingIndexProvider {
  MemoryEncodingIndexProvider(this.index);

  final Gb18030IndexData index;

  @override
  Future<Gb18030IndexData> load() async => index;
}
