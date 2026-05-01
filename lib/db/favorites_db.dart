import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/song.dart';

class FavoritesDb {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'favorites.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE favorites(
            url TEXT PRIMARY KEY,
            title TEXT,
            artist TEXT,
            cover TEXT,
            description TEXT,
            album TEXT,
            year INTEGER,
            genre TEXT
          )
        ''');
      },
    );
  }

  static Future<void> insertFavorite(Song song) async {
    final db = await database;
    await db.insert('favorites', song.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> removeFavorite(String url) async {
    final db = await database;
    await db.delete('favorites', where: 'url = ?', whereArgs: [url]);
  }

  static Future<List<Song>> getFavorites() async {
    final db = await database;
    final rows = await db.query('favorites');
    return rows.map((e) => Song.fromMap(e)).toList();
  }

  static Future<bool> isFavorite(String url) async {
    final db = await database;
    final rows =
        await db.query('favorites', where: 'url = ?', whereArgs: [url]);
    return rows.isNotEmpty;
  }
}