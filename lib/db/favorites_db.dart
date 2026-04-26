import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../main.dart';

class FavoritesDB {
  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  static Future<Database> initDB() async {
    final path = join(await getDatabasesPath(), 'favorites.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE favorites (
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

  static Future<void> add(Song song) async {
    final dbClient = await db;
    await dbClient.insert(
      'favorites',
      song.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> remove(String url) async {
    final dbClient = await db;
    await dbClient.delete(
      'favorites',
      where: 'url = ?',
      whereArgs: [url],
    );
  }

  static Future<List<Song>> getAll() async {
    final dbClient = await db;
    final res = await dbClient.query('favorites');

    return res.map((e) => Song.fromMap(e)).toList();
  }
}