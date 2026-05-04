// ─────────────────────────────────────────────────────────────────────────────
// song.dart
//
// FIX: Added `fromMapSafe` factory that provides default values for any column
// that may be null (e.g. after schema migration or partial insert).
// The original `fromMap` is kept unchanged for backward compatibility.
// ─────────────────────────────────────────────────────────────────────────────

class Song {
  final String title;
  final String artist;
  final String url;
  final String cover;
  final String description;
  final String album;
  final int year;
  final String genre;

  const Song({
    required this.title,
    required this.artist,
    required this.url,
    required this.cover,
    required this.description,
    required this.album,
    required this.year,
    required this.genre,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'artist': artist,
    'url': url,
    'cover': cover,
    'description': description,
    'album': album,
    'year': year,
    'genre': genre,
  };

  /// Original factory – will throw if any field is null (kept for compat)
  static Song fromMap(Map<String, dynamic> map) => Song(
    title: map['title'] as String,
    artist: map['artist'] as String,
    url: map['url'] as String,
    cover: map['cover'] as String,
    description: map['description'] as String,
    album: map['album'] as String,
    year: map['year'] as int,
    genre: map['genre'] as String,
  );

  /// FIX: Null-safe factory used by FavoritesDb.getFavorites().
  /// Provides sensible defaults so the app never crashes on malformed rows.
  factory Song.fromMapSafe(Map<String, dynamic> map) => Song(
    title: (map['title'] as String?) ?? 'Unknown',
    artist: (map['artist'] as String?) ?? 'Unknown',
    url: (map['url'] as String?) ?? '',
    cover: (map['cover'] as String?) ?? '',
    description: (map['description'] as String?) ?? '',
    album: (map['album'] as String?) ?? '',
    year: (map['year'] as int?) ?? 0,
    genre: (map['genre'] as String?) ?? '',
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Song && other.url == url);

  @override
  int get hashCode => url.hashCode;
}
