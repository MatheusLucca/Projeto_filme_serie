import 'package:flutter/foundation.dart';

import '../data/database_helper.dart';
import '../models/title_item.dart';

class TitlesProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<TitleItem> _items = [];
  bool? _watchedFilter = false;
  TitleType? _typeFilter;
  String _nameQuery = '';
  bool _loading = false;
  String? _lastError;

  List<TitleItem> get items => _items;
  bool? get watchedFilter => _watchedFilter;
  TitleType? get typeFilter => _typeFilter;
  String get nameQuery => _nameQuery;
  bool get loading => _loading;

  /// Set whenever load()/addItem()/updateItem()/deleteItem() fails, so the
  /// UI can surface it instead of failing silently. Cleared on next success.
  String? get lastError => _lastError;

  void clearError() {
    _lastError = null;
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      _items = await _dbHelper.fetchAll(
        watched: _watchedFilter,
        type: _typeFilter,
        nameQuery: _nameQuery,
      );
      _lastError = null;
    } catch (e) {
      _lastError = 'Erro ao carregar a lista: $e';
    }
    _loading = false;
    notifyListeners();
  }

  /// false = não assistidos (quero ver + assistindo), true = assistidos, null = todos.
  Future<void> setWatchedFilter(bool? watched) async {
    _watchedFilter = watched;
    await load();
  }

  Future<void> setTypeFilter(TitleType? type) async {
    _typeFilter = type;
    await load();
  }

  Future<void> setNameQuery(String query) async {
    _nameQuery = query;
    await load();
  }

  Future<void> addItem(TitleItem item) async {
    try {
      await _dbHelper.insert(item);
    } catch (e) {
      _lastError = 'Erro ao adicionar "${item.name}": $e';
      notifyListeners();
      rethrow;
    }
    await load();
  }

  Future<void> updateItem(TitleItem item) async {
    try {
      await _dbHelper.update(item.copyWith(updatedAt: DateTime.now()));
    } catch (e) {
      _lastError = 'Erro ao salvar "${item.name}": $e';
      notifyListeners();
      rethrow;
    }
    await load();
  }

  Future<void> deleteItem(int id) async {
    try {
      await _dbHelper.delete(id);
    } catch (e) {
      _lastError = 'Erro ao excluir: $e';
      notifyListeners();
      rethrow;
    }
    await load();
  }

  Future<void> advanceEpisode(TitleItem item) async {
    var newEpisode = item.episode + 1;
    var newSeason = item.season;
    var newStatus = item.status;
    if (item.totalEpisodes != null && newEpisode > item.totalEpisodes!) {
      newStatus = WatchStatus.visto;
      newEpisode = item.totalEpisodes!;
    } else if (item.status == WatchStatus.queroVer) {
      newStatus = WatchStatus.assistindo;
    }
    await updateItem(item.copyWith(
      episode: newEpisode,
      season: newSeason,
      status: newStatus,
    ));
  }

  Future<void> markWatched(TitleItem item) async {
    await updateItem(item.copyWith(status: WatchStatus.visto));
  }

  Future<void> moveBackToWatchlist(TitleItem item) async {
    await updateItem(item.copyWith(status: WatchStatus.queroVer));
  }
}
