import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/title_item.dart';
import '../providers/titles_provider.dart';
import '../services/tmdb_service.dart';
import '../widgets/star_rating.dart';
import '../widgets/tmdb_search_sheet.dart';

class EditTitleScreen extends StatefulWidget {
  final TitleItem? existing;

  const EditTitleScreen({super.key, this.existing});

  @override
  State<EditTitleScreen> createState() => _EditTitleScreenState();
}

class _EditTitleScreenState extends State<EditTitleScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _seasonController;
  late TextEditingController _episodeController;
  late TextEditingController _totalEpisodesController;
  late TextEditingController _notesController;

  TitleType _type = TitleType.serie;
  WatchStatus _status = WatchStatus.queroVer;
  String? _posterPath;
  int? _rating;
  String? _overview;
  bool _fetchingPoster = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final item = widget.existing;
    _nameController = TextEditingController(text: item?.name ?? '');
    _seasonController = TextEditingController(text: (item?.season ?? 1).toString());
    _episodeController = TextEditingController(text: (item?.episode ?? 1).toString());
    _totalEpisodesController =
        TextEditingController(text: item?.totalEpisodes?.toString() ?? '');
    _notesController = TextEditingController(text: item?.notes ?? '');
    _type = item?.type ?? TitleType.serie;
    _status = item?.status ?? WatchStatus.queroVer;
    _posterPath = item?.posterPath;
    _rating = item?.rating;
    _overview = item?.overview;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _seasonController.dispose();
    _episodeController.dispose();
    _totalEpisodesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickPoster() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final appDir = await getApplicationDocumentsDirectory();
    final postersDir = Directory(p.join(appDir.path, 'posters'));
    if (!await postersDir.exists()) {
      await postersDir.create(recursive: true);
    }
    final ext = p.extension(picked.path);
    final newPath = p.join(postersDir.path, '${const Uuid().v4()}$ext');
    await File(picked.path).copy(newPath);
    setState(() => _posterPath = newPath);
  }

  Future<void> _searchTmdb() async {
    final result = await showModalBottomSheet<TmdbResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const TmdbSearchSheet(),
    );
    if (result == null) return;

    setState(() {
      _nameController.text = result.title;
      _type = result.type;
      _overview = result.overview;
      _fetchingPoster = result.posterPath != null;
    });

    if (result.posterPath != null) {
      final localPath = await TmdbService().downloadPoster(result.posterPath!);
      if (mounted) {
        setState(() {
          if (localPath != null) _posterPath = localPath;
          _fetchingPoster = false;
        });
      }
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<TitlesProvider>();
    final totalEpisodesText = _totalEpisodesController.text.trim();
    final item = TitleItem(
      id: widget.existing?.id,
      name: _nameController.text.trim(),
      type: _type,
      status: _status,
      posterPath: _posterPath,
      season: int.tryParse(_seasonController.text) ?? 1,
      episode: int.tryParse(_episodeController.text) ?? 1,
      totalEpisodes: totalEpisodesText.isEmpty ? null : int.tryParse(totalEpisodesText),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      rating: _rating,
      overview: _overview,
      createdAt: widget.existing?.createdAt,
    );
    if (_isEditing) {
      provider.updateItem(item);
    } else {
      provider.addItem(item);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isSeries = _type != TitleType.filme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar' : 'Adicionar'),
        actions: [
          IconButton(onPressed: _save, icon: const Icon(Icons.check)),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickPoster,
                child: Container(
                  width: 140,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _fetchingPoster
                      ? const Center(child: CircularProgressIndicator())
                      : _posterPath != null
                          ? Image.file(File(_posterPath!), fit: BoxFit.cover)
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, size: 36),
                                SizedBox(height: 8),
                                Text('Adicionar imagem'),
                              ],
                            ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: OutlinedButton.icon(
                onPressed: _searchTmdb,
                icon: const Icon(Icons.search),
                label: const Text('Buscar no TMDB'),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe um nome' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TitleType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
              items: TitleType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<WatchStatus>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
              items: WatchStatus.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
            if (isSeries) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _seasonController,
                      decoration: const InputDecoration(
                        labelText: 'Temporada',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _episodeController,
                      decoration: const InputDecoration(
                        labelText: 'Episódio atual',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _totalEpisodesController,
                decoration: const InputDecoration(
                  labelText: 'Total de episódios (opcional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Sua nota:'),
                const SizedBox(width: 8),
                StarRating(
                  rating: _rating,
                  onChanged: (v) => setState(() => _rating = v),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notas', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            if (_overview != null && _overview!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Sinopse (TMDB)', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(_overview!, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 24),
            if (_isEditing)
              OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Excluir'),
                      content: Text('Remover "${widget.existing!.name}" da lista?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancelar')),
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Excluir')),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await context.read<TitlesProvider>().deleteItem(widget.existing!.id!);
                    if (context.mounted) Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Excluir'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}
