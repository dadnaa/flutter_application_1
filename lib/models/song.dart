class Song {
  final String title;
  final String artist;
  final String url;
  final String cover;
  final String description;
  final String album;
  final int year;
  final String genre;

  Song({
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

  static Song fromMap(Map<String, dynamic> map) => Song(
        title: map['title'],
        artist: map['artist'],
        url: map['url'],
        cover: map['cover'],
        description: map['description'],
        album: map['album'],
        year: map['year'],
        genre: map['genre'],
      );
}