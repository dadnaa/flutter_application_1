class LocalSong {
  final String title;
  final String artist;
  final String path;
  final int? id;

  LocalSong({required this.title, required this.artist, required this.path, this.id});

  Map<String, dynamic> toJson() => {
        'title': title,
        'artist': artist,
        'path': path,
      };

  factory LocalSong.fromJson(Map<String, dynamic> json) => LocalSong(
        title: json['title'],
        artist: json['artist'],
        path: json['path'],
      );
}