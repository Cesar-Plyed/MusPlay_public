class SongModel {
  final String id;
  final String userId;
  final String title;
  final String artist;
  final String? album;
  final String? coverUrl;
  final String audioUrl;
  final int duration; // en segundos
  final int plays;
  final List<String> likedByUsers;
  final DateTime uploadedAt;
  final double fileSize; // en MB

  SongModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.artist,
    this.album,
    this.coverUrl,
    required this.audioUrl,
    required this.duration,
    this.plays = 0,
    this.likedByUsers = const [],
    required this.uploadedAt,
    required this.fileSize,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'artist': artist,
      'album': album,
      'coverUrl': coverUrl,
      'audioUrl': audioUrl,
      'duration': duration,
      'plays': plays,
      'likedByUsers': likedByUsers,
      'uploadedAt': uploadedAt,
      'fileSize': fileSize,
    };
  }

  factory SongModel.fromMap(Map<String, dynamic> map, String id) {
    return SongModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? 'Sin título',
      artist: map['artist'] ?? 'Artista desconocido',
      album: map['album'],
      coverUrl: map['coverUrl'],
      audioUrl: map['audioUrl'] ?? '',
      duration: map['duration'] ?? 0,
      plays: map['plays'] ?? 0,
      likedByUsers: List<String>.from(map['likedByUsers'] ?? []),
      uploadedAt: (map['uploadedAt'] as dynamic)?.toDate() ?? DateTime.now(),
      fileSize: (map['fileSize'] as num?)?.toDouble() ?? 0.0,
    );
  }

  bool isLikedByUser(String userId) => likedByUsers.contains(userId);

  SongModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? artist,
    String? album,
    String? coverUrl,
    String? audioUrl,
    int? duration,
    int? plays,
    List<String>? likedByUsers,
    DateTime? uploadedAt,
    double? fileSize,
  }) {
    return SongModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      coverUrl: coverUrl ?? this.coverUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      duration: duration ?? this.duration,
      plays: plays ?? this.plays,
      likedByUsers: likedByUsers ?? this.likedByUsers,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      fileSize: fileSize ?? this.fileSize,
    );
  }
}
