import 'dart:io';

import 'package:flutter/material.dart';

import '../models/title_item.dart';
import '../services/tmdb_service.dart';

class TitleCard extends StatefulWidget {
  final TitleItem item;
  final VoidCallback onTap;
  final VoidCallback? onAdvanceEpisode;
  final VoidCallback? onMarkWatched;
  final VoidCallback? onUndoWatched;

  const TitleCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onAdvanceEpisode,
    this.onMarkWatched,
    this.onUndoWatched,
  });

  @override
  State<TitleCard> createState() => _TitleCardState();
}

class _TitleCardState extends State<TitleCard> with SingleTickerProviderStateMixin {
  static const _swipeThreshold = 90.0;

  late final AnimationController _controller;
  double _dragExtent = 0;

  TitleItem get item => widget.item;
  bool get _isEpisodic => item.type != TitleType.filme;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: 0,
    )..addListener(() => setState(() => _dragExtent = _controller.value));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _posterExists(String path) {
    try {
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (widget.onAdvanceEpisode == null) return;
    setState(() {
      _dragExtent = (_dragExtent + details.delta.dx).clamp(0.0, _swipeThreshold * 1.5);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (widget.onAdvanceEpisode == null) return;
    if (_dragExtent >= _swipeThreshold) {
      widget.onAdvanceEpisode!.call();
    }
    _controller.value = _dragExtent;
    _controller.animateTo(0, curve: Curves.easeOut);
  }

  Widget _poster(BuildContext context) {
    final poster = item.posterPath;
    return SizedBox(
      width: 90,
      height: 130,
      child: poster != null && _posterExists(poster)
          ? Image.file(
              File(poster),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.movie_outlined, size: 36),
              ),
            )
          : Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.movie_outlined, size: 36),
            ),
    );
  }

  Widget _episodeInfo(BuildContext context) {
    final remainingInSeries = item.totalSeriesEpisodes != null
        ? item.totalSeriesEpisodes! - item.episodesWatched
        : (item.totalEpisodes != null ? item.totalEpisodes! - item.episode + 1 : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'T${item.season} · Ep ${item.episode}'
          '${item.totalEpisodes != null ? '/${item.totalEpisodes}' : ''}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (item.tmdbId != null)
          FutureBuilder<String?>(
            future: TmdbService().fetchEpisodeName(item.tmdbId!, item.season, item.episode),
            builder: (context, snapshot) {
              final name = snapshot.data;
              if (name == null || name.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  name,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontStyle: FontStyle.italic),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
        if (remainingInSeries != null) ...[
          const SizedBox(height: 2),
          Text(
            'Faltam $remainingInSeries episódio(s) pra acabar a série',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ],
    );
  }

  Widget _info(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              item.name,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (item.rating != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  for (var i = 1; i <= 5; i++)
                    Icon(
                      item.rating! >= i ? Icons.star : Icons.star_border,
                      size: 14,
                      color: Colors.amber,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 6),
            Chip(
              label: Text(item.type.label),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            if (item.status == WatchStatus.visto) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  const Text('Visto', style: TextStyle(color: Colors.green)),
                  if (widget.onUndoWatched != null) ...[
                    const Spacer(),
                    TextButton(
                      onPressed: widget.onUndoWatched,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                      child: const Text('Desfazer'),
                    ),
                  ],
                ],
              ),
            ] else if (_isEpisodic) ...[
              const SizedBox(height: 8),
              _episodeInfo(context),
              if (widget.onAdvanceEpisode != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.swipe, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        'Arraste para o lado para marcar',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline),
                      tooltip: 'Marquei o episódio',
                      visualDensity: VisualDensity.compact,
                      onPressed: widget.onAdvanceEpisode,
                    ),
                  ],
                ),
              ],
            ] else if (widget.onMarkWatched != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: widget.onMarkWatched,
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                  child: const Text('Marcar como assistido'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSwipe = _isEpisodic && item.status != WatchStatus.visto && widget.onAdvanceEpisode != null;

    final card = Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: widget.onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [_poster(context), _info(context)],
          ),
        ),
      ),
    );

    if (!canSwipe) return card;

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            child: Opacity(
              opacity: (_dragExtent / _swipeThreshold).clamp(0.0, 1.0),
              child: const Row(
                children: [
                  Icon(Icons.check, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Episódio assistido', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(_dragExtent, 0),
          child: GestureDetector(
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            child: card,
          ),
        ),
      ],
    );
  }
}
