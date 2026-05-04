// ─────────────────────────────────────────────────────────────────────────────
// playable_song.dart  (unchanged structure, minor null-safety tightening)
//
// FIX: fromJson now uses null-safe casts so bad data from the isolate message
// doesn't crash the app with a silent null-dereference.
// ─────────────────────────────────────────────────────────────────────────────

enum SongType { local, online }

class PlayableSong {
  final String title;
  final String artist;
  final String? coverUrl;
  final String? localPath;
  final String? onlineUrl;
  final SongType type;

  PlayableSong.local({
    required this.title,
    required this.artist,
    required this.localPath,
  }) : coverUrl = null,
       onlineUrl = null,
       type = SongType.local;

  PlayableSong.online({
    required this.title,
    required this.artist,
    required this.coverUrl,
    required this.onlineUrl,
  }) : localPath = null,
       type = SongType.online;

  Map<String, dynamic> toJson() => {
    'title': title,
    'artist': artist,
    'type': type.index,
    if (localPath != null) 'localPath': localPath,
    if (onlineUrl != null) 'onlineUrl': onlineUrl,
    if (coverUrl != null) 'coverUrl': coverUrl,
  };

  // FIX: Use safe casts instead of direct `as String` which throws on null
  factory PlayableSong.fromJson(Map<String, dynamic> json) {
    final typeIndex = (json['type'] as num?)?.toInt() ?? SongType.online.index;
    if (typeIndex == SongType.local.index) {
      return PlayableSong.local(
        title: (json['title'] as String?) ?? 'Unknown',
        artist: (json['artist'] as String?) ?? 'Unknown',
        localPath: json['localPath'] as String?,
      );
    } else {
      return PlayableSong.online(
        title: (json['title'] as String?) ?? 'Unknown',
        artist: (json['artist'] as String?) ?? 'Unknown',
        coverUrl: json['coverUrl'] as String?,
        onlineUrl: json['onlineUrl'] as String?,
      );
    }
  }
}
