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

  List<TitleItem> get items => _items;
  bool? get watchedFilter => _watchedFilter;
  TitleType? get typeFilter => _typeFilter;
  String get nameQuery => _nameQuery;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _items = await _dbHelper.fetchAll(
      watched: _watchedFilter,
      type: _typeFilter,
      nameQuery: _nameQuery,
    );
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
    await _dbHelper.insert(item);
    await load();
  }

  Future<void> updateItem(TitleItem item) async {
    await _dbHelper.update(item.copyWith(updatedAt: DateTime.now()));
    await load();
  }

  Future<void> deleteItem(int id) async {
    await _dbHelper.delete(id);
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
