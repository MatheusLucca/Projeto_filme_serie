import 'dart:io';

import 'package:flutter/material.dart';

import '../models/title_item.dart';
import '../services/tmdb_service.dart';
import '../theme/app_theme.dart';

/// A ticket-shaped row: a colored spine names the category, a perforated
/// seam separates the poster stub from the details, and progress reads as
/// a tape counter ("S01 · E04/10") instead of prose — the whole card is a
/// stand-in for the physical rental ticket this app replaces.
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
    final placeholder = Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(Icons.movie_outlined, size: 30, color: Theme.of(context).colorScheme.outline),
    );
    return SizedBox(
      width: 78,
      height: 116,
      child: poster != null && _posterExists(poster)
          ? Image.file(
              File(poster),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => placeholder,
            )
          : placeholder,
    );
  }

  /// Reads like a tape counter: "S01 · E04/10".
  Widget _counterBadge(BuildContext context, {required String text}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.inverseSurface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: AppFonts.mono(size: 11.5, color: scheme.onInverseSurface)),
    );
  }

  Widget _ratingRow(BuildContext context) {
    if (item.rating == null) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            item.rating! >= i ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 14,
            color: AppColors.brass,
          ),
      ],
    );
  }

  Widget _progressBar(BuildContext context, double fraction) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: fraction.clamp(0.0, 1.0),
        minHeight: 4,
        backgroundColor: scheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation(item.type.channelColor),
      ),
    );
  }

  Widget _episodicBody(BuildContext context) {
    final totalInSeries = item.totalSeriesEpisodes;
    final fraction = totalInSeries != null && totalInSeries > 0
        ? item.episodesWatched / totalInSeries
        : (item.totalEpisodes != null && item.totalEpisodes! > 0
            ? (item.episode - 1) / item.totalEpisodes!
            : 0.0);
    final counter = 'S${item.season.toString().padLeft(2, '0')} · '
        'E${item.episode.toString().padLeft(2, '0')}'
        '${item.totalEpisodes != null ? '/${item.totalEpisodes}' : ''}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _counterBadge(context, text: counter),
        if (item.tmdbId != null)
          FutureBuilder<String?>(
            future: TmdbService().fetchEpisodeName(item.tmdbId!, item.season, item.episode),
            builder: (context, snapshot) {
              final name = snapshot.data;
              if (name == null || name.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
        const SizedBox(height: 6),
        _progressBar(context, fraction),
        if (widget.onAdvanceEpisode != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Arraste pra marcar o episódio',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(Icons.check_circle_outline, color: item.type.channelColor, size: 20),
                tooltip: 'Marquei o episódio',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: widget.onAdvanceEpisode,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _watchedRow(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
        const SizedBox(width: 4),
        Text('Visto', style: AppFonts.mono(size: 11.5, color: AppColors.success)),
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
    );
  }

  Widget _info(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Text(
                  item.type.label.toUpperCase(),
                  style: AppFonts.mono(
                    size: 10,
                    weight: FontWeight.w700,
                    color: item.type.channelColor,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              item.name,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (item.rating != null) ...[
              const SizedBox(height: 3),
              _ratingRow(context),
            ],
            const SizedBox(height: 7),
            if (item.status == WatchStatus.visto)
              _watchedRow(context)
            else if (_isEpisodic)
              _episodicBody(context)
            else if (widget.onMarkWatched != null)
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canSwipe = _isEpisodic && item.status != WatchStatus.visto && widget.onAdvanceEpisode != null;

    final ticket = Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: item.type.channelColor),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _poster(context),
                  ),
                ),
                CustomPaint(
                  size: const Size(1, double.infinity),
                  painter: _PerforationPainter(color: scheme.outline),
                ),
                _info(context),
              ],
            ),
          ),
        ),
      ),
    );

    if (!canSwipe) return ticket;

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: item.type.channelColor,
              borderRadius: BorderRadius.circular(14),
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
            child: ticket,
          ),
        ),
      ],
    );
  }
}

/// Draws the dotted seam between a ticket's stub and its body.
class _PerforationPainter extends CustomPainter {
  final Color color;
  const _PerforationPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const dotRadius = 1.2;
    const gap = 6.0;
    var y = gap / 2;
    while (y < size.height) {
      canvas.drawCircle(Offset(0, y), dotRadius, paint);
      y += gap;
    }
  }

  @override
  bool shouldRepaint(covariant _PerforationPainter oldDelegate) => oldDelegate.color != color;
}
