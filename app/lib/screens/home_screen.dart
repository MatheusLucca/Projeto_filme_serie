import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/title_item.dart';
import '../providers/titles_provider.dart';
import '../widgets/title_card.dart';
import 'edit_title_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TitlesProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TitlesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Watchlist'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<WatchStatus?>(
                    initialValue: provider.statusFilter,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos')),
                      ...WatchStatus.values
                          .map((s) => DropdownMenuItem(value: s, child: Text(s.label))),
                    ],
                    onChanged: (v) => provider.setStatusFilter(v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<TitleType?>(
                    initialValue: provider.typeFilter,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos')),
                      ...TitleType.values
                          .map((t) => DropdownMenuItem(value: t, child: Text(t.label))),
                    ],
                    onChanged: (v) => provider.setTypeFilter(v),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator())
                : provider.items.isEmpty
                    ? const Center(child: Text('Nada por aqui ainda. Toque em + para adicionar.'))
                    : ListView.builder(
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
                            },
                            onAdvanceEpisode: () => provider.advanceEpisode(item),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EditTitleScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
