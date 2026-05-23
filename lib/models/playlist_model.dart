import 'dart:convert';
import 'playlist_song.dart';

class PlaylistModel {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final List<PlaylistSong> songs;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlaylistModel({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.songs,
    required this.createdAt,
    required this.updatedAt,
  });

  int get songCount => songs.length;
  bool get isEmpty => songs.isEmpty;

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'name': name,
    'description': description,
    'songs': songs.map((s) => s.toMap()).toList(),
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory PlaylistModel.fromMap(Map<String, dynamic> map, String id) {
    final rawSongs = map['songs'];
    List<PlaylistSong> songs = [];
    if (rawSongs is List) {
      songs = rawSongs
          .map((s) => PlaylistSong.fromMap(Map<String, dynamic>.from(s)))
          .toList();
    }
    return PlaylistModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? 'Playlist',
      description: map['description'],
      songs: songs,
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  // Para guardar localmente (SharedPreferences) como JSON
  String toJsonString() => jsonEncode({
    'id': id,
    'userId': userId,
    'name': name,
    'description': description,
    'songs': songs.map((s) => s.toMap()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  });

  factory PlaylistModel.fromJsonString(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    final rawSongs = map['songs'] as List? ?? [];
    return PlaylistModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? 'Playlist',
      description: map['description'],
      songs: rawSongs.map((s) => PlaylistSong.fromMap(Map<String, dynamic>.from(s))).toList(),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  PlaylistModel copyWith({
    String? id, String? userId, String? name, String? description,
    List<PlaylistSong>? songs, DateTime? createdAt, DateTime? updatedAt,
  }) => PlaylistModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    description: description ?? this.description,
    songs: songs ?? this.songs,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
