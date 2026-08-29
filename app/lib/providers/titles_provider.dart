import 'package:flutter/foundation.dart';

import '../data/database_helper.dart';
import '../models/title_item.dart';

class TitlesProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<TitleItem> _items = [];
  WatchStatus? _statusFilter;
  TitleType? _typeFilter;
  bool _loading = false;

  List<TitleItem> get items => _items;
  WatchStatus? get statusFilter => _statusFilter;
  TitleType? get typeFilter => _typeFilter;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _items = await _dbHelper.fetchAll(status: _statusFilter, type: _typeFilter);
    _loading = false;
    notifyListeners();
  }

  Future<void> setStatusFilter(WatchStatus? status) async {
    _statusFilter = status;
    await load();
  }

  Future<void> setTypeFilter(TitleType? type) async {
    _typeFilter = type;
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
}
