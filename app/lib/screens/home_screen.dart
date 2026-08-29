import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/title_item.dart';
import '../providers/titles_provider.dart';
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
        title: const Text('Minha Watchlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Não assistidos'),
            Tab(text: 'Assistidos'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar na sua lista...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: DropdownButtonFormField<TitleType?>(
                initialValue: provider.typeFilter,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos os tipos')),
                  ...TitleType.values
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.label))),
                ],
                onChanged: (v) => provider.setTypeFilter(v),
              ),
            ),
          ),
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator())
                : provider.items.isEmpty
                    ? Center(
                        child: Text(
                          provider.watchedFilter == true
                              ? 'Nada assistido ainda.'
                              : 'Nada por aqui. Toque em + para adicionar.',
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => context.read<TitlesProvider>().load(),
                        child: ListView.builder(
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
