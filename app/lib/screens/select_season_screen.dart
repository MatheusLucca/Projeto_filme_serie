import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/title_item.dart';
import '../providers/titles_provider.dart';
import '../services/tmdb_service.dart';

class SelectSeasonScreen extends StatefulWidget {
  final TmdbResult result;

  const SelectSeasonScreen({super.key, required this.result});

  @override
  State<SelectSeasonScreen> createState() => _SelectSeasonScreenState();
}

class _SelectSeasonScreenState extends State<SelectSeasonScreen> {
  final _service = TmdbService();
  List<TmdbSeason> _seasons = [];
  TmdbSeason? _selected;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final seasons = await _service.fetchSeasons(widget.result);
    setState(() {
      _seasons = seasons;
      _selected = seasons.isNotEmpty ? seasons.first : null;
      _loading = false;
    });
  }

  Future<void> _confirm() async {
    setState(() => _saving = true);
    try {
      final provider = context.read<TitlesProvider>();
      if (await provider.existsByTmdbId(widget.result.id)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${widget.result.title}" já está na sua lista.')),
        );
        Navigator.of(context)
          ..pop()
          ..pop();
        return;
      }

      String? posterPath;
      if (widget.result.posterPath != null) {
        posterPath = await _service.downloadPoster(widget.result.posterPath!);
      }

      final item = TitleItem(
        name: widget.result.title,
        type: widget.result.type,
        status: WatchStatus.queroVer,
        posterPath: posterPath,
        season: _selected?.seasonNumber ?? 1,
        episode: 1,
        totalEpisodes: _selected?.episodeCount,
        overview: widget.result.overview,
        tmdbId: widget.result.id,
      );

      if (!mounted) return;
      await provider.addItem(item);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${widget.result.title}" adicionado aos não assistidos.')),
      );
      Navigator.of(context)
        ..pop()
        ..pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.result.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_seasons.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Não encontramos as temporadas dessa série no TMDB. '
                      'Ela será adicionada começando na T1, Ep 1, e você pode '
                      'ajustar o total de episódios depois na tela de edição.',
                    ),
                  )
                else ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      'Em qual temporada você está?',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: RadioGroup<TmdbSeason>(
                      groupValue: _selected,
                      onChanged: (v) => setState(() => _selected = v),
                      child: ListView.builder(
                        itemCount: _seasons.length,
                        itemBuilder: (context, index) {
                          final s = _seasons[index];
                          return RadioListTile<TmdbSeason>(
                            value: s,
                            title: Text(s.name),
                            subtitle: Text('${s.episodeCount} episódios'),
                          );
                        },
                      ),
                    ),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : _confirm,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Adicionar aos não assistidos'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
