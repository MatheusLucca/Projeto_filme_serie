import 'package:flutter/material.dart';

import '../models/title_item.dart';
import '../services/tmdb_service.dart';

/// Result of confirming a jump to a specific episode.
class EpisodeJumpResult {
  final int season;
  final int episode;
  final int totalEpisodesInSeason;
  final int episodesWatched;

  EpisodeJumpResult({
    required this.season,
    required this.episode,
    required this.totalEpisodesInSeason,
    required this.episodesWatched,
  });
}

/// Combo box of seasons (showing watched/total episodes) that expands into
/// a grid of episode cards for the selected season. Tapping a card and
/// confirming jumps the current watch position back to that episode,
/// unmarking every later episode as no longer watched.
class SeasonEpisodePicker extends StatefulWidget {
  final int tmdbId;
  final int currentSeason;
  final int currentEpisode;
  final ValueChanged<EpisodeJumpResult> onJump;

  const SeasonEpisodePicker({
    super.key,
    required this.tmdbId,
    required this.currentSeason,
    required this.currentEpisode,
    required this.onJump,
  });

  @override
  State<SeasonEpisodePicker> createState() => _SeasonEpisodePickerState();
}

class _SeasonEpisodePickerState extends State<SeasonEpisodePicker> {
  final _service = TmdbService();

  List<TmdbSeason> _seasons = [];
  TmdbSeason? _selectedSeason;
  List<TmdbEpisode> _episodes = [];
  bool _loadingSeasons = true;
  bool _loadingEpisodes = false;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _loadSeasons();
  }

  int _watchedInSeason(TmdbSeason s) {
    if (s.seasonNumber < widget.currentSeason) return s.episodeCount;
    if (s.seasonNumber > widget.currentSeason) return 0;
    return (widget.currentEpisode - 1).clamp(0, s.episodeCount);
  }

  Future<void> _loadSeasons() async {
    final seasons = await _service.fetchSeasons(
      TmdbResult(id: widget.tmdbId, title: '', type: TitleType.serie),
    );
    if (!mounted) return;
    setState(() {
      _seasons = seasons;
      _selectedSeason = seasons.firstWhere(
        (s) => s.seasonNumber == widget.currentSeason,
        orElse: () => seasons.isNotEmpty ? seasons.first : TmdbSeason(seasonNumber: 0, name: '', episodeCount: 0),
      );
      _loadingSeasons = false;
    });
  }

  Future<void> _loadEpisodes() async {
    if (_selectedSeason == null) return;
    setState(() => _loadingEpisodes = true);
    final episodes = await _service.fetchSeasonEpisodes(widget.tmdbId, _selectedSeason!.seasonNumber);
    if (!mounted) return;
    setState(() {
      _episodes = episodes;
      _loadingEpisodes = false;
    });
  }

  bool _isWatched(int episodeNumber) {
    final s = _selectedSeason!;
    if (s.seasonNumber < widget.currentSeason) return true;
    if (s.seasonNumber > widget.currentSeason) return false;
    return episodeNumber < widget.currentEpisode;
  }

  Future<void> _confirmJump(TmdbEpisode ep) async {
    final s = _selectedSeason!;
    final isCurrent = s.seasonNumber == widget.currentSeason && ep.episodeNumber == widget.currentEpisode;
    if (isCurrent) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Voltar para este episódio?'),
        content: Text(
          'T${s.seasonNumber} · Ep ${ep.episodeNumber} — ${ep.name}\n\n'
          'Isso vai desmarcar como assistido qualquer episódio a partir deste ponto.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirm != true) return;

    final episodesWatched = _seasons
            .where((se) => se.seasonNumber < s.seasonNumber)
            .fold<int>(0, (sum, se) => sum + se.episodeCount) +
        (ep.episodeNumber - 1);

    widget.onJump(EpisodeJumpResult(
      season: s.seasonNumber,
      episode: ep.episodeNumber,
      totalEpisodesInSeason: s.episodeCount,
      episodesWatched: episodesWatched,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingSeasons) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_seasons.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Temporadas (TMDB)', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        DropdownButtonFormField<TmdbSeason>(
          initialValue: _selectedSeason,
          isExpanded: true,
          decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Temporada'),
          items: _seasons
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text('${s.name} · ${_watchedInSeason(s)}/${s.episodeCount} assistidos'),
                  ))
              .toList(),
          onChanged: (s) {
            setState(() {
              _selectedSeason = s;
              _episodes = [];
              _expanded = false;
            });
          },
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            setState(() => _expanded = !_expanded);
            if (_expanded && _episodes.isEmpty) _loadEpisodes();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                const SizedBox(width: 4),
                Text(_expanded ? 'Ocultar episódios' : 'Ver episódios da temporada'),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          if (_loadingEpisodes)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_episodes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Não foi possível carregar os episódios.'),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 4),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 76,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _episodes.length,
              itemBuilder: (context, index) {
                final ep = _episodes[index];
                final watched = _isWatched(ep.episodeNumber);
                final isCurrent = _selectedSeason!.seasonNumber == widget.currentSeason &&
                    ep.episodeNumber == widget.currentEpisode;
                return Card(
                  color: isCurrent
                      ? Theme.of(context).colorScheme.primaryContainer
                      : watched
                          ? Theme.of(context).colorScheme.surfaceContainerHighest
                          : null,
                  child: InkWell(
                    onTap: () => _confirmJump(ep),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Text('Ep ${ep.episodeNumber}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 4),
                              if (watched)
                                const Icon(Icons.check_circle, size: 14, color: Colors.green),
                              if (isCurrent) const Icon(Icons.play_circle_fill, size: 14),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ep.name,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ],
    );
  }
}
