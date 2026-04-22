class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String uri;
  final int durationMs;
  final String? albumArt;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.uri,
    required this.durationMs,
    this.albumArt,
  });

  int get durationSeconds => durationMs ~/ 1000;

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String,
      uri: json['uri'] as String,
      durationMs: json['durationMs'] as int,
      albumArt: json['albumArt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'album': album,
        'uri': uri,
        'durationMs': durationMs,
        'albumArt': albumArt,
      };

  String get displayTitle => title.isNotEmpty ? title : 'Unknown Title';
  String get displayArtist => artist.isNotEmpty ? artist : 'Unknown Artist';
  String get displayAlbum => album.isNotEmpty ? album : 'Unknown Album';

  String get formattedDuration {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class SongCache {
  final List<Song> songs;
  final DateTime cachedAt;
  final int? hashCodeValue;

  SongCache({required this.songs, required this.cachedAt, this.hashCodeValue});

  Map<String, dynamic> toJson() => {
        'songs': songs.map((s) => s.toJson()).toList(),
        'cachedAt': cachedAt.toIso8601String(),
        'hashCode': hashCodeValue,
      };

  factory SongCache.fromJson(Map<String, dynamic> json) => SongCache(
        songs: (json['songs'] as List)
            .map((s) => Song.fromJson(s as Map<String, dynamic>))
            .toList(),
        cachedAt: DateTime.parse(json['cachedAt'] as String),
        hashCodeValue: json['hashCode'] as int?,
      );
}
