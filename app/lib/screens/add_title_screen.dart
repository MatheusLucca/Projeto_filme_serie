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

  void _viewDetails(TmdbResult result) {
    if (result.type != TitleType.serie) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SelectSeasonScreen(result: result)),
    );
  }

  /// Adds the item straight away with sensible defaults: season 1 for series
  /// (using season 1's episode count when available), no episode data for movies.
  Future<void> _quickAdd(TmdbResult result) async {
    setState(() => _addingId = result.id);
    try {
      final provider = context.read<TitlesProvider>();
      if (await provider.existsByTmdbId(result.id)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${result.title}" já está na sua lista.')),
        );
        return;
      }

      String? posterPath;
      if (result.posterPath != null) {
        posterPath = await _service.downloadPoster(result.posterPath!);
      }

      int? totalEpisodes;
      int? totalSeriesEpisodes;
      if (result.type == TitleType.serie) {
        final seasons = await _service.fetchSeasons(result);
        final season1 = seasons.where((s) => s.seasonNumber == 1).toList();
        totalSeriesEpisodes = await _service.fetchTotalEpisodes(result);
        totalEpisodes = season1.isNotEmpty ? season1.first.episodeCount : totalSeriesEpisodes;
      }

      final item = TitleItem(
        name: result.title,
        type: result.type,
        status: WatchStatus.queroVer,
        posterPath: posterPath,
        totalEpisodes: totalEpisodes,
        totalSeriesEpisodes: totalSeriesEpisodes,
        overview: result.overview,
        tmdbId: result.id,
      );

      if (!mounted) return;
      await provider.addItem(item);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${result.title}" adicionado aos não assistidos.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível adicionar: $e')),
      );
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
                            '${r.type.label}${r.year != null ? ' · ${r.year}' : ''}'
                            '${r.type == TitleType.serie ? ' · toque para ver temporadas' : ''}',
                          ),
                          trailing: isAdding
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  tooltip: 'Adicionar',
                                  onPressed: () => _quickAdd(r),
                                ),
                          onTap: isAdding ? null : () => _viewDetails(r),
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
