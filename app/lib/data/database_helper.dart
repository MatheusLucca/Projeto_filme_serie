import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/title_item.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'watchlist.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE titles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            status TEXT NOT NULL,
            poster_path TEXT,
            season INTEGER NOT NULL DEFAULT 1,
            episode INTEGER NOT NULL DEFAULT 1,
            total_episodes INTEGER,
            rating INTEGER,
            notes TEXT,
            overview TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE titles ADD COLUMN overview TEXT');
        }
      },
    );
  }

  Future<TitleItem> insert(TitleItem item) async {
    final db = await database;
    final map = item.toMap()..remove('id');
    final id = await db.insert('titles', map);
    return item.copyWith(id: id);
  }

  Future<int> update(TitleItem item) async {
    final db = await database;
    return db.update(
      'titles',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await database;
    return db.delete('titles', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TitleItem>> fetchAll({
    WatchStatus? status,
    TitleType? type,
    String? nameQuery,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <Object?>[];
    if (status != null) {
      where.add('status = ?');
      args.add(status.name);
    }
    if (type != null) {
      where.add('type = ?');
      args.add(type.name);
    }
    if (nameQuery != null && nameQuery.trim().isNotEmpty) {
      where.add('name LIKE ?');
      args.add('%${nameQuery.trim()}%');
    }
    final result = await db.query(
      'titles',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: where.isEmpty ? null : args,
      orderBy: 'updated_at DESC',
    );
    return result.map(TitleItem.fromMap).toList();
  }
}
