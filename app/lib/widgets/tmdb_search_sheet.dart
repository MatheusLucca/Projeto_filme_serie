import 'package:flutter/material.dart';

import '../models/title_item.dart';
import '../services/tmdb_service.dart';

class TmdbSearchSheet extends StatefulWidget {
  const TmdbSearchSheet({super.key});

  @override
  State<TmdbSearchSheet> createState() => _TmdbSearchSheetState();
}

class _TmdbSearchSheetState extends State<TmdbSearchSheet> {
  final _service = TmdbService();
  final _controller = TextEditingController();
  List<TmdbResult> _results = [];
  bool _loading = false;
  String? _error;

  Future<void> _search(String query) async {
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Buscar filme ou série no TMDB...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _search,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _search(_controller.text),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                    ? const Center(child: Text('Digite algo e toque em buscar.'))
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final r = _results[index];
                          return ListTile(
                            leading: SizedBox(
                              width: 46,
                              height: 66,
                              child: r.posterPath != null
                                  ? Image.network(
                                      'https://image.tmdb.org/t/p/w92${r.posterPath}',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) =>
                                          const Icon(Icons.movie_outlined),
                                    )
                                  : const Icon(Icons.movie_outlined),
                            ),
                            title: Text(r.title),
                            subtitle: Text(
                              '${r.type.label}${r.year != null ? ' · ${r.year}' : ''}',
                            ),
                            onTap: () => Navigator.of(context).pop(r),
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
