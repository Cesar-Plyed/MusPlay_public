class CloudSong {
  final String id;
  final String title;
  final String artist;
  final String fileName;
  final String downloadUrl;
  final int fileSize;
  final DateTime uploadedAt;
  final Duration? duration;

  CloudSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.fileName,
    required this.downloadUrl,
    required this.fileSize,
    required this.uploadedAt,
    this.duration,
  });

  // Getter para tamaño formateado
  String get sizeFormatted {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024)
      return '${(fileSize / 1024).toStringAsFixed(2)}KB';
    if (fileSize < 1024 * 1024 * 1024)
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(2)}MB';
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
  }

  // Factory para crear desde Firestore
  factory CloudSong.fromFirestore(Map<String, dynamic> data, String id) {
    return CloudSong(
      id: id,
      title: data['title'] ?? 'Sin título',
      artist: data['artist'] ?? 'Artista desconocido',
      fileName: data['fileName'] ?? '',
      downloadUrl: data['downloadUrl'] ?? '',
      fileSize: data['fileSize'] ?? 0,
      uploadedAt: (data['uploadedAt'] as dynamic)?.toDate() ?? DateTime.now(),
      duration: data['duration'] != null
          ? Duration(milliseconds: data['duration'])
          : null,
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'artist': artist,
      'fileName': fileName,
      'downloadUrl': downloadUrl,
      'fileSize': fileSize,
      'uploadedAt': uploadedAt,
      'duration': duration?.inMilliseconds,
    };
  }
}
