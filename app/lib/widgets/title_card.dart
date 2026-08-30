import 'dart:io';

import 'package:flutter/material.dart';

import '../models/title_item.dart';

class TitleCard extends StatelessWidget {
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

  bool get _isEpisodic => item.type != TitleType.filme;

  bool _posterExists(String path) {
    try {
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
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
                  if (onUndoWatched != null) ...[
                    const Spacer(),
                    TextButton(
                      onPressed: onUndoWatched,
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
              Row(
                children: [
                  Text(
                    'T${item.season} · Ep ${item.episode}'
                    '${item.totalEpisodes != null ? '/${item.totalEpisodes}' : ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  const Icon(Icons.swipe, size: 14, color: Colors.grey),
                ],
              ),
              if (item.totalEpisodes != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Faltam ${item.totalEpisodes! - item.episode + 1} episódio(s)',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey),
                ),
              ],
            ] else if (onMarkWatched != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: onMarkWatched,
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
    final card = Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [_poster(context), _info(context)],
        ),
      ),
    );

    final canAdvance = _isEpisodic && item.status != WatchStatus.visto && onAdvanceEpisode != null;
    if (!canAdvance) return card;

    return Dismissible(
      key: ValueKey('title-${item.id}'),
      direction: DismissDirection.startToEnd,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Row(
          children: [
            Icon(Icons.check, color: Colors.white),
            SizedBox(width: 8),
            Text('Episódio assistido', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        onAdvanceEpisode?.call();
        return false;
      },
      child: card,
    );
  }
}
