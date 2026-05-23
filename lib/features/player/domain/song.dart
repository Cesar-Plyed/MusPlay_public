class Song {
  final int id;
  final String title;
  final String artist;
  final String album;
  final String? uri;
  final String? albumArtUri;
  final Duration duration;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    this.uri,
    this.albumArtUri,
    required this.duration,
  });

  String get durationFormatted {
    final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
