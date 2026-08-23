import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/remote/feed_subscription.dart';
import '../domain/remote/remote_source.dart';
import 'feed_article_reader_page.dart';
import 'providers.dart';
import '../sources/remote/feed_error_messages.dart';

/// Minimal profile-scoped RSS/Atom subscription surface.
class FeedSubscriptionsPage extends ConsumerStatefulWidget {
  const FeedSubscriptionsPage({super.key});

  @override
  ConsumerState<FeedSubscriptionsPage> createState() =>
      _FeedSubscriptionsPageState();
}

class _FeedSubscriptionsPageState extends ConsumerState<FeedSubscriptionsPage> {
  bool _refreshing = false;
  String? _status;

  @override
  Widget build(BuildContext context) {
    final subscriptions = ref.watch(feedSubscriptionsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的订阅'),
        actions: [
          IconButton(
            tooltip: '刷新全部订阅',
            onPressed: _refreshing ? null : _refreshAll,
            icon: _refreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: '添加订阅',
            onPressed: _addSubscription,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: subscriptions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: '订阅加载失败：$error',
          onRetry: () => ref.invalidate(feedSubscriptionsProvider),
        ),
        data: (items) => _buildContent(context, items),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<FeedSubscription> items) {
    final scheme = Theme.of(context).colorScheme;
    final desktop = MediaQuery.sizeOf(context).width >= 720;
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          desktop ? 32 : 16,
          16,
          desktop ? 32 : 16,
          32,
        ),
        children: [
          Text(
            '手动管理订阅内容，不会在后台自动刷新。',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (_status != null) ...[
            const SizedBox(height: 10),
            _StatusBanner(key: const Key('feed-status'), message: _status!),
          ],
          const SizedBox(height: 12),
          if (items.isEmpty)
            const _EmptyFeedState()
          else
            ...items.map(
              (subscription) => _SubscriptionCard(
                subscription: subscription,
                onOpen: () => _openSubscription(subscription),
                onRefresh: () => _refreshOne(subscription),
                onRemove: () => _removeSubscription(subscription),
                busy: _refreshing,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _addSubscription() async {
    final request = await showDialog<_FeedAddRequest>(
      context: context,
      builder: (_) => const _AddFeedDialog(),
    );
    if (request == null || !mounted) return;
    final endpoint = Uri.tryParse(request.endpoint.trim());
    if (endpoint == null ||
        (endpoint.scheme != 'http' && endpoint.scheme != 'https') ||
        endpoint.host.isEmpty) {
      _showStatus('请输入有效的 HTTP/HTTPS 地址');
      return;
    }
    final sourceId =
        'feed-${sha256.convert(endpoint.toString().codeUnits).toString().substring(0, 24)}';
    final source = StandardFeedSource(
      id: RemoteSourceId(sourceId),
      endpoint: endpoint,
      // The parser detects RSS 2.0/Atom from the document root. Keeping this
      // internal default keeps the user flow format-neutral.
      format: 'rss',
    );
    try {
      final service = ref.read(feedSubscriptionServiceProvider);
      await service.addSubscription(source);
      try {
        await service.refresh(source.id.value);
        _showStatus('订阅已添加并刷新');
      } catch (error) {
        _showStatus('订阅已保存，${describeFeedRefreshFailure(error)}');
      }
      ref.invalidate(feedSubscriptionsProvider);
    } catch (error) {
      _showStatus('添加订阅失败：${describeFeedRefreshFailure(error)}');
    }
  }

  Future<void> _refreshAll() async {
    if (_refreshing) return;
    setState(() {
      _refreshing = true;
      _status = null;
    });
    try {
      final subscriptions = await ref.read(feedSubscriptionsProvider.future);
      var success = 0;
      var failed = 0;
      final failureReasons = <String>[];
      final service = ref.read(feedSubscriptionServiceProvider);
      for (final subscription in subscriptions) {
        try {
          await service.refresh(subscription.sourceId);
          success++;
        } catch (error) {
          failed++;
          final reason = describeFeedRefreshFailure(error);
          if (!failureReasons.contains(reason)) failureReasons.add(reason);
        }
      }
      if (!mounted) return;
      setState(() {
        _refreshing = false;
        _status = failed == 0
            ? '已刷新 $success 个订阅'
            : '已刷新 $success 个，$failed 个失败：${failureReasons.join('、')}';
      });
      ref.invalidate(feedSubscriptionsProvider);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _refreshing = false;
        _status = '刷新失败：${describeFeedRefreshFailure(error)}';
      });
    }
  }

  Future<void> _refreshOne(FeedSubscription subscription) async {
    try {
      await ref
          .read(feedSubscriptionServiceProvider)
          .refresh(subscription.sourceId);
      _showStatus('“${subscription.title}”已刷新');
      ref.invalidate(feedSubscriptionsProvider);
    } catch (error) {
      _showStatus('刷新失败：${describeFeedRefreshFailure(error)}');
    }
  }

  Future<void> _removeSubscription(FeedSubscription subscription) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除订阅？'),
        content: Text('将移除“${subscription.title}”及其已保存文章。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref
        .read(feedSubscriptionServiceProvider)
        .removeSubscription(subscription.sourceId);
    _showStatus('订阅已删除');
    ref.invalidate(feedSubscriptionsProvider);
  }

  Future<void> _openSubscription(FeedSubscription subscription) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FeedArticleListPage(sourceId: subscription.sourceId),
      ),
    );
    if (mounted) ref.invalidate(feedSubscriptionsProvider);
  }

  void _showStatus(String message) {
    if (!mounted) return;
    setState(() => _status = message);
  }
}

class FeedArticleListPage extends ConsumerStatefulWidget {
  const FeedArticleListPage({super.key, required this.sourceId});

  final String sourceId;

  @override
  ConsumerState<FeedArticleListPage> createState() =>
      _FeedArticleListPageState();
}

class _FeedArticleListPageState extends ConsumerState<FeedArticleListPage> {
  bool _refreshing = false;
  String? _status;

  @override
  Widget build(BuildContext context) {
    final subscription = ref.watch(feedSubscriptionProvider(widget.sourceId));
    return Scaffold(
      appBar: AppBar(
        title: Text(subscription.valueOrNull?.title ?? '订阅文章'),
        actions: [
          IconButton(
            tooltip: '手动刷新',
            onPressed: _refreshing ? null : _refresh,
            icon: _refreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: subscription.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: '文章加载失败：$error',
          onRetry: () =>
              ref.invalidate(feedSubscriptionProvider(widget.sourceId)),
        ),
        data: (value) {
          if (value == null) {
            return const Center(child: Text('订阅不存在或已删除'));
          }
          return _buildArticles(context, value);
        },
      ),
    );
  }

  Widget _buildArticles(BuildContext context, FeedSubscription subscription) {
    if (subscription.articles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _status ?? '暂无已保存文章，点击右上角刷新',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (subscription.description != null &&
            subscription.description!.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              subscription.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        Text(
          '${subscription.articles.length} 篇文章 · ${subscription.endpoint.host}',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        if (_status != null) ...[
          const SizedBox(height: 10),
          _StatusBanner(message: _status!),
        ],
        const SizedBox(height: 8),
        for (var index = 0; index < subscription.articles.length; index++) ...[
          _FeedArticleTile(
            article: subscription.articles[index],
            onTap: () => openRemoteFeedArticle(
              context,
              subscription: subscription,
              article: subscription.articles[index],
              dataRoot: ref.read(dataRootProvider),
            ),
          ),
          if (index != subscription.articles.length - 1)
            const Divider(height: 1),
        ],
      ],
    );
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() {
      _refreshing = true;
      _status = null;
    });
    try {
      await ref.read(feedSubscriptionServiceProvider).refresh(widget.sourceId);
      if (!mounted) return;
      setState(() {
        _refreshing = false;
        _status = '刷新完成';
      });
      ref.invalidate(feedSubscriptionProvider(widget.sourceId));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _refreshing = false;
        _status = '刷新失败：${describeFeedRefreshFailure(error)}';
      });
    }
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.subscription,
    required this.onOpen,
    required this.onRefresh,
    required this.onRemove,
    required this.busy,
  });

  final FeedSubscription subscription;
  final VoidCallback onOpen;
  final VoidCallback onRefresh;
  final VoidCallback onRemove;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onOpen,
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: const Icon(Icons.rss_feed),
        ),
        title: Text(subscription.title),
        subtitle: Text(
          [
            '${subscription.articles.length} 篇文章',
            subscription.endpoint.host,
            if (subscription.lastRefreshedAt != null)
              '更新于 ${_formatDate(subscription.lastRefreshedAt!)}',
          ].join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Wrap(
          spacing: 0,
          children: [
            IconButton(
              tooltip: '刷新',
              onPressed: busy ? null : onRefresh,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: '删除',
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFeedState extends StatelessWidget {
  const _EmptyFeedState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 24),
      child: Column(
        children: [
          Icon(Icons.rss_feed, size: 48, color: scheme.primary),
          const SizedBox(height: 12),
          const Text('还没有订阅'),
          const SizedBox(height: 4),
          Text(
            '点击右上角加号，粘贴订阅地址即可。',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: scheme.onPrimaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedArticleTile extends StatelessWidget {
  const _FeedArticleTile({required this.article, required this.onTap});

  final FeedArticle article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final metadata = <String>[
      if (article.author != null) article.author!,
      if (article.publishedAt != null) _formatDate(article.publishedAt!),
    ];
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      title: Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (metadata.isNotEmpty)
            Text(
              metadata.join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (article.summary != null && article.summary!.isNotEmpty)
            Text(
              article.summary!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    ),
  );
}

class _FeedAddRequest {
  const _FeedAddRequest({required this.endpoint});

  final String endpoint;
}

class _AddFeedDialog extends StatefulWidget {
  const _AddFeedDialog();

  @override
  State<_AddFeedDialog> createState() => _AddFeedDialogState();
}

class _AddFeedDialogState extends State<_AddFeedDialog> {
  final _endpoint = TextEditingController();

  @override
  void dispose() {
    _endpoint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('添加订阅'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _endpoint,
            autofocus: true,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: '订阅地址',
              hintText: '粘贴 RSS / Atom 地址',
              helperText: '系统会自动识别订阅格式',
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: () =>
            Navigator.pop(context, _FeedAddRequest(endpoint: _endpoint.text)),
        child: const Text('添加'),
      ),
    ],
  );
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}
