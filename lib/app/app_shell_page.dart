import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/reader/reading_history.dart';
import '../reader/reader_page.dart';
import 'library_page.dart';
import 'providers.dart';
import 'reading_history_page.dart';

/// The V3 primary information architecture shared by desktop and mobile.
/// This widget owns only top-level navigation and responsive chrome.
class AppShellPage extends ConsumerStatefulWidget {
  const AppShellPage({super.key});

  @override
  ConsumerState<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends ConsumerState<AppShellPage> {
  int _selectedIndex = 0;

  static const _destinations = <_ShellDestination>[
    _ShellDestination('\u9996\u9875', Icons.home_outlined, Icons.home),
    _ShellDestination(
      '\u4e66\u67b6',
      Icons.menu_book_outlined,
      Icons.menu_book,
    ),
    _ShellDestination('\u6211\u7684', Icons.person_outline, Icons.person),
  ];

  void _select(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 720;
    final body = Column(
      children: [
        _ShellHeader(
          title: _destinations[_selectedIndex].label,
          isDesktop: isDesktop,
        ),
        Expanded(
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              _HomeSurface(
                onOpenShelf: () => _select(1),
                onOpen: _openHistoryEntry,
              ),
              const LibraryPage(embedded: true),
              _MeSurface(onChanged: _refreshAfterRoute),
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      body: isDesktop
          ? Row(
              children: [
                _DesktopSidebar(
                  selectedIndex: _selectedIndex,
                  onSelect: _select,
                ),
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _select,
              destinations: [
                for (final destination in _destinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: destination.label,
                  ),
              ],
            ),
    );
  }

  void _refreshAfterRoute() {
    ref.invalidate(collectionsProvider);
    ref.invalidate(recentReadingProvider);
  }

  Future<void> _openHistoryEntry(ReadingHistoryEntry entry) async {
    final collectionId = entry.collectionId;
    if (collectionId == null) return;
    final repository = ref.read(libraryRepositoryProvider);
    final collection = await repository.getCollection(collectionId);
    if (!mounted || collection == null) return;
    final documents = await repository.getDocuments(collection.id);
    final toc = await repository.getToc(collection.id);
    if (!mounted || documents.isEmpty) return;
    await openReader(
      context,
      ReaderLaunchContext(
        collection: collection,
        documents: documents,
        toc: toc,
        normalizedCharacterLength: collection.normalizedCharacterLength,
        documentLoader: ref.read(documentLoaderProvider),
        progressRepository: ref.read(readingProgressRepositoryProvider),
        bookmarkRepository: ref.read(readerBookmarkRepositoryProvider),
        preferencesRepository: ref.read(readerPreferencesRepositoryProvider),
        appearanceAssetRepository: ref.read(
          readerAppearanceAssetRepositoryProvider,
        ),
        readingHistoryRepository: ref.read(readingHistoryRepositoryProvider),
        readingSessionRepository: ref.read(readingSessionRepositoryProvider),
        inputBindingsRepository: ref.read(
          readerInputBindingsRepositoryProvider,
        ),
        autoReadPreferencesRepository: ref.read(
          autoReadPreferencesRepositoryProvider,
        ),
      ),
    );
    if (mounted) ref.invalidate(recentReadingProvider);
  }
}

class _HomeSurface extends StatelessWidget {
  const _HomeSurface({required this.onOpenShelf, required this.onOpen});

  final VoidCallback onOpenShelf;
  final ValueChanged<ReadingHistoryEntry> onOpen;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 720;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 1000 : double.infinity,
        ),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 32 : 20,
            20,
            isDesktop ? 32 : 20,
            32,
          ),
          children: [
            Text(
              '\u7ee7\u7eed\u9605\u8bfb',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            RecentReadingSection(onOpen: onOpen, showEmpty: true),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: const Text('\u672c\u5730\u4e66\u5e93'),
                subtitle: const Text(
                  '\u7ba1\u7406\u5df2\u5bfc\u5165\u7684 TXT \u4e66\u7c4d',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: onOpenShelf,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeSurface extends StatelessWidget {
  const _MeSurface({required this.onChanged});

  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 720;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: desktop ? 760 : double.infinity),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            desktop ? 32 : 20,
            20,
            desktop ? 32 : 20,
            32,
          ),
          children: [
            Text(
              '\u6211\u7684',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              '\u4e2a\u4eba\u9605\u8bfb\u4fe1\u606f\u4e0e\u5e94\u7528\u8bbe\u7f6e',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            _MeSectionLabel(label: '\u9605\u8bfb\u4fe1\u606f'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.history),
                title: const Text('\u9605\u8bfb\u5386\u53f2'),
                subtitle: const Text(
                  '\u67e5\u770b\u9605\u8bfb\u65f6\u95f4\u3001\u4f1a\u8bdd\u548c\u4e66\u7c4d\u72b6\u6001',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ReadingHistoryPage(),
                    ),
                  );
                  onChanged();
                },
              ),
            ),
            const SizedBox(height: 20),
            _MeSectionLabel(label: '\u5e94\u7528\u8bbe\u7f6e'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('\u9605\u8bfb\u8bbe\u7f6e'),
                subtitle: const Text(
                  '\u6309\u952e\u4e0e\u64cd\u4f5c\u7b49\u5e94\u7528\u5c42\u8bbe\u7f6e',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.of(context).pushNamed('/settings');
                  onChanged();
                },
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '\u6bcf\u672c\u4e66\u7684\u5b57\u53f7\u3001\u95f4\u8ddd\u3001\u8fb9\u8ddd\u548c\u4e3b\u9898\u53ef\u5728 Reader \u4e2d\u901a\u8fc7 Aa \u8c03\u6574\u3002',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeSectionLabel extends StatelessWidget {
  const _MeSectionLabel({required this.label});

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

class _ShellHeader extends StatelessWidget {
  const _ShellHeader({required this.title, required this.isDesktop});

  final String title;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SizedBox(
        height: isDesktop ? 64 : 56,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 28 : 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
        ),
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({required this.selectedIndex, required this.onSelect});

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainer,
      child: SizedBox(
        width: 224,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 26, 20, 28),
              child: Text(
                'XAOCEN Reader',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (
              var index = 0;
              index < _AppShellPageState._destinations.length;
              index++
            )
              _DesktopNavItem(
                destination: _AppShellPageState._destinations[index],
                selected: index == selectedIndex,
                onTap: () => onSelect(index),
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                '\u672c\u5730\u9605\u8bfb',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopNavItem extends StatelessWidget {
  const _DesktopNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _ShellDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: ListTile(
        selected: selected,
        selectedTileColor: scheme.secondaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(selected ? destination.selectedIcon : destination.icon),
        title: Text(destination.label),
        onTap: onTap,
      ),
    );
  }
}

class _ShellDestination {
  const _ShellDestination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
