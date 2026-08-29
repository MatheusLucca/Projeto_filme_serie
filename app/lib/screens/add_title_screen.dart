import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/title_item.dart';
import '../providers/titles_provider.dart';
import '../services/tmdb_service.dart';
import 'edit_title_screen.dart';
import 'select_season_screen.dart';

class AddTitleScreen extends StatefulWidget {
  const AddTitleScreen({super.key});

  @override
  State<AddTitleScreen> createState() => _AddTitleScreenState();
}

class _AddTitleScreenState extends State<AddTitleScreen> {
  final _service = TmdbService();
  final _controller = TextEditingController();
  Timer? _debounce;
  List<TmdbResult> _results = [];
  bool _loading = false;
  String? _error;
  int? _addingId;

  void _onChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _error = null;
        _loading = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () => _search(query));
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await _service.search(query);
      if (!mounted) return;
      setState(() => _results = results);
    } on TmdbException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Não foi possível buscar. Verifique sua conexão.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _select(TmdbResult result) async {
    if (result.type == TitleType.serie) {
      // SelectSeasonScreen pops itself and this screen once the item is added.
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SelectSeasonScreen(result: result)),
      );
      return;
    }

    setState(() => _addingId = result.id);
    try {
      String? posterPath;
      if (result.posterPath != null) {
        posterPath = await _service.downloadPoster(result.posterPath!);
      }

      final item = TitleItem(
        name: result.title,
        type: result.type,
        status: WatchStatus.queroVer,
        posterPath: posterPath,
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
    _debounce?.cancel();
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
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          _onChanged('');
                          setState(() {});
                        },
                      ),
              ),
              onChanged: (v) {
                _onChanged(v);
                setState(() {});
              },
            ),
          ),
          if (_loading) const Expanded(child: Center(child: CircularProgressIndicator())),
          if (!_loading && _error != null)
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
                  ? const Center(child: Text('Digite um nome para buscar.'))
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
                              : const Icon(Icons.chevron_right),
                          onTap: isAdding ? null : () => _select(r),
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
