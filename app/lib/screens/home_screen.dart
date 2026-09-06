import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/title_item.dart';
import '../providers/titles_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/title_card.dart';
import 'add_title_screen.dart';
import 'edit_title_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      context.read<TitlesProvider>().setWatchedFilter(_tabController.index == 1);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TitlesProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TitlesProvider>();

    if (provider.lastError != null) {
      final error = provider.lastError!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        provider.clearError();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), duration: const Duration(seconds: 6)),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Watchlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configurações',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'A ASSISTIR'),
            Tab(text: 'VISTOS'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar na sua lista',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          provider.setNameQuery('');
                          setState(() {});
                        },
                      ),
              ),
              onChanged: (v) {
                provider.setNameQuery(v);
                setState(() {});
              },
            ),
          ),
          SizedBox(
            height: 34,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              children: [
                _TypeFilterChip(
                  label: 'Todos',
                  color: Theme.of(context).colorScheme.onSurface,
                  selected: provider.typeFilter == null,
                  onTap: () => provider.setTypeFilter(null),
                ),
                for (final t in TitleType.values) ...[
                  const SizedBox(width: 8),
                  _TypeFilterChip(
                    label: t.label,
                    color: t.channelColor,
                    selected: provider.typeFilter == t,
                    onTap: () => provider.setTypeFilter(t),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator())
                : provider.items.isEmpty
                    ? _EmptyState(watched: provider.watchedFilter == true)
                    : RefreshIndicator(
                        onRefresh: () => context.read<TitlesProvider>().load(),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 88),
                          itemCount: provider.items.length,
                          itemBuilder: (context, index) {
                            final item = provider.items[index];
                            return TitleCard(
                              item: item,
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => EditTitleScreen(existing: item),
                                  ),
                                );
                                if (context.mounted) {
                                  await context.read<TitlesProvider>().load();
                                }
                              },
                              onAdvanceEpisode: () => provider.advanceEpisode(item),
                              onMarkWatched: item.type == TitleType.filme
                                  ? () => provider.markWatched(item)
                                  : null,
                              onUndoWatched:
                                  item.status == WatchStatus.visto
                                      ? () => provider.moveBackToWatchlist(item)
                                      : null,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddTitleScreen()),
          );
          if (context.mounted) {
            await context.read<TitlesProvider>().load();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TypeFilterChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeFilterChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : scheme.outline),
        ),
        alignment: Alignment.center,
        child: Text(
          label.toUpperCase(),
          style: AppFonts.mono(
            size: 11,
            weight: FontWeight.w700,
            color: selected ? color : scheme.onSurface.withValues(alpha: 0.6),
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool watched;
  const _EmptyState({required this.watched});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              watched ? Icons.check_circle_outline : Icons.local_movies_outlined,
              size: 40,
              color: scheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              watched ? 'Nada assistido ainda' : 'Sua lista está vazia',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              watched
                  ? 'O que você já assistir aparece aqui.'
                  : 'Toque em + para adicionar um filme, série ou anime.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
