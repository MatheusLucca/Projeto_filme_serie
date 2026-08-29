import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/title_item.dart';
import '../providers/titles_provider.dart';
import '../services/tmdb_service.dart';
import 'edit_title_screen.dart';

class AddTitleScreen extends StatefulWidget {
  const AddTitleScreen({super.key});

  @override
  State<AddTitleScreen> createState() => _AddTitleScreenState();
}

class _AddTitleScreenState extends State<AddTitleScreen> {
  final _service = TmdbService();
  final _controller = TextEditingController();
  List<TmdbResult> _results = [];
  bool _loading = false;
  String? _error;
  int? _addingId;

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await _service.search(query);
      setState(() => _results = results);
    } on TmdbException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Não foi possível buscar. Verifique sua conexão.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _add(TmdbResult result) async {
    setState(() => _addingId = result.id);
    try {
      String? posterPath;
      if (result.posterPath != null) {
        posterPath = await _service.downloadPoster(result.posterPath!);
      }
      final totalEpisodes = await _service.fetchTotalEpisodes(result);

      final item = TitleItem(
        name: result.title,
        type: result.type,
        status: WatchStatus.queroVer,
        posterPath: posterPath,
        totalEpisodes: totalEpisodes,
        overview: result.overview,
      );

      if (!mounted) return;
      await context.read<TitlesProvider>().addItem(item);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${result.title}" adicionado aos não assistidos.')),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _addingId = null);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar título')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Buscar filme, série, anime...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => _search(_controller.text),
                ),
              ),
              onSubmitted: _search,
            ),
          ),
          if (_loading) const Expanded(child: Center(child: CircularProgressIndicator())),
          if (_error != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_error!, textAlign: TextAlign.center),
                ),
              ),
            ),
          if (!_loading && _error == null)
            Expanded(
              child: _results.isEmpty
                  ? const Center(child: Text('Digite um nome e toque em buscar.'))
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final r = _results[index];
                        final isAdding = _addingId == r.id;
                        return ListTile(
                          leading: SizedBox(
                            width: 46,
                            height: 66,
                            child: r.posterPath != null
                                ? Image.network(
                                    'https://image.tmdb.org/t/p/w92${r.posterPath}',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(Icons.movie_outlined),
                                  )
                                : const Icon(Icons.movie_outlined),
                          ),
                          title: Text(r.title),
                          subtitle: Text(
                            '${r.type.label}${r.year != null ? ' · ${r.year}' : ''}',
                          ),
                          trailing: isAdding
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.check_circle_outline),
                                  tooltip: 'Adicionar',
                                  onPressed: () => _add(r),
                                ),
                          onTap: isAdding ? null : () => _add(r),
                        );
                      },
                    ),
            ),
          if (!_loading)
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditTitleScreen()),
                ),
                child: const Text('Não achou? Adicionar manualmente'),
              ),
            ),
        ],
      ),
    );
  }
}
