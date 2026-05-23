/// Referencia a una canción dentro de una playlist.
/// Puede ser local (del teléfono) o de Drive (nube).
class PlaylistSong {
  final String id;          // uri local o driveFileId
  final String title;
  final String artist;
  final String source;      // 'local' | 'drive'
  final int? durationMs;
  final int? albumId;       // solo para locales (artwork)

  const PlaylistSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.source,
    this.durationMs,
    this.albumId,
  });

  bool get isLocal => source == 'local';
  bool get isDrive => source == 'drive';

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'artist': artist,
    'source': source,
    'durationMs': durationMs,
    'albumId': albumId,
  };

  factory PlaylistSong.fromMap(Map<String, dynamic> m) => PlaylistSong(
    id: m['id'] ?? '',
    title: m['title'] ?? 'Sin título',
    artist: m['artist'] ?? 'Artista desconocido',
    source: m['source'] ?? 'local',
    durationMs: m['durationMs'],
    albumId: m['albumId'],
  );

  String toJson() {
    final map = toMap();
    return '{"id":"${map['id']}","title":"${map['title']}","artist":"${map['artist']}","source":"${map['source']}","durationMs":${map['durationMs'] ?? 'null'},"albumId":${map['albumId'] ?? 'null'}}';
  }
}
