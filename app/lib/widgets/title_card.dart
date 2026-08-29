import 'dart:io';

import 'package:flutter/material.dart';

import '../models/title_item.dart';

class TitleCard extends StatelessWidget {
  final TitleItem item;
  final VoidCallback onTap;
  final VoidCallback? onAdvanceEpisode;

  const TitleCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onAdvanceEpisode,
  });

  Color _statusColor(BuildContext context) {
    switch (item.status) {
      case WatchStatus.queroVer:
        return Colors.blueGrey;
      case WatchStatus.assistindo:
        return Colors.orange;
      case WatchStatus.visto:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final poster = item.posterPath;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 90,
              height: 130,
              child: poster != null && File(poster).existsSync()
                  ? Image.file(File(poster), fit: BoxFit.cover)
                  : Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.movie_outlined, size: 36),
                    ),
            ),
            Expanded(
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
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Chip(
                          label: Text(item.type.label),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        Chip(
                          label: Text(item.status.label),
                          backgroundColor: _statusColor(context).withValues(alpha: 0.15),
                          labelStyle: TextStyle(color: _statusColor(context)),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                    if (item.type != TitleType.filme) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            'T${item.season} · Ep ${item.episode}'
                            '${item.totalEpisodes != null ? '/${item.totalEpisodes}' : ''}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const Spacer(),
                          if (item.status != WatchStatus.visto && onAdvanceEpisode != null)
                            TextButton.icon(
                              onPressed: onAdvanceEpisode,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Episódio'),
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
