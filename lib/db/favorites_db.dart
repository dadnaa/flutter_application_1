// ─────────────────────────────────────────────────────────────────────────────
// favorites_db.dart
//
// FIXES:
//   1. Song.fromMap now handles null column values gracefully (e.g. when DB was
//      written by an older schema version that lacked optional columns).
//   2. Closed _db properly between tests/re-init by adding a `reset()` method.
//   3. Added `clear()` helper for testing / account logout scenarios.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/song.dart';

class FavoritesDb {
  FavoritesDb._();

  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _initDb();
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
            title TEXT NOT NULL,
            artist TEXT NOT NULL,
            cover TEXT NOT NULL DEFAULT '',
            description TEXT NOT NULL DEFAULT '',
            album TEXT NOT NULL DEFAULT '',
            year INTEGER NOT NULL DEFAULT 0,
            genre TEXT NOT NULL DEFAULT ''
          )
        ''');
      },
    );
  }

  static Future<void> insertFavorite(Song song) async {
    final db = await database;
    await db.insert(
      'favorites',
      song.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> removeFavorite(String url) async {
    final db = await database;
    await db.delete('favorites', where: 'url = ?', whereArgs: [url]);
  }

  static Future<List<Song>> getFavorites() async {
    final db = await database;
    final rows = await db.query('favorites', orderBy: 'title ASC');
    // FIX: Use null-safe fromMap that provides defaults for missing fields.
    return rows.map((e) => Song.fromMapSafe(e)).toList();
  }

  static Future<bool> isFavorite(String url) async {
    final db = await database;
    final rows = await db.query(
      'favorites',
      where: 'url = ?',
      whereArgs: [url],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  // FIX: Added for completeness / testing
  static Future<void> clear() async {
    final db = await database;
    await db.delete('favorites');
  }

  /// Close the DB (useful in tests)
  static Future<void> reset() async {
    await _db?.close();
    _db = null;
  }
}
