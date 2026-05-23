class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final String plan; // 'free', 'premium', 'pro'
  final int storageUsed;
  final int maxStorage;
  final List<String> favoritePlaylistIds;
  final List<String> favoriteSongIds;
  final bool isActive;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.plan,
    required this.storageUsed,
    required this.maxStorage,
    this.favoritePlaylistIds = const [],
    this.favoriteSongIds = const [],
    this.isActive = true,
  });

  // Convertir a JSON para Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt,
      'plan': plan,
      'storageUsed': storageUsed,
      'maxStorage': maxStorage,
      'favoritePlaylistIds': favoritePlaylistIds,
      'favoriteSongIds': favoriteSongIds,
      'isActive': isActive,
    };
  }

  // Crear desde JSON de Firestore
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? 'Usuario',
      photoUrl: map['photoUrl'],
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      plan: map['plan'] ?? 'free',
      storageUsed: map['storageUsed'] ?? 0,
      maxStorage: map['maxStorage'] ?? 1073741824, // 1GB
      favoritePlaylistIds: List<String>.from(map['favoritePlaylistIds'] ?? []),
      favoriteSongIds: List<String>.from(map['favoriteSongIds'] ?? []),
      isActive: map['isActive'] ?? true,
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    String? plan,
    int? storageUsed,
    int? maxStorage,
    List<String>? favoritePlaylistIds,
    List<String>? favoriteSongIds,
    bool? isActive,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      plan: plan ?? this.plan,
      storageUsed: storageUsed ?? this.storageUsed,
      maxStorage: maxStorage ?? this.maxStorage,
      favoritePlaylistIds: favoritePlaylistIds ?? this.favoritePlaylistIds,
      favoriteSongIds: favoriteSongIds ?? this.favoriteSongIds,
      isActive: isActive ?? this.isActive,
    );
  }
}
