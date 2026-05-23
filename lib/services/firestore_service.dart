import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===== USUARIOS =====

  // Obtener usuario por UID
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, uid);
      }
      return null;
    } catch (e) {
      print('Error obteniendo usuario: $e');
      return null;
    }
  }

  // Stream de usuario en tiempo real
  Stream<UserModel?> getUserStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return UserModel.fromMap(doc.data()!, uid);
          }
          return null;
        })
        .handleError((e) {
          print('Error en stream de usuario: $e');
        });
  }

  // Crear usuario
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      print('Error creando usuario: $e');
      rethrow;
    }
  }

  // Actualizar usuario
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      print('Error actualizando usuario: $e');
      rethrow;
    }
  }

  // ===== PLAYLISTS =====

  // Obtener todas las playlists de un usuario
  Future<List<PlaylistModel>> getUserPlaylists(String userId) async {
    try {
      final query = await _firestore
          .collection('playlists')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => PlaylistModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error obteniendo playlists: $e');
      return [];
    }
  }

  // Stream de playlists en tiempo real
  Stream<List<PlaylistModel>> getUserPlaylistsStream(String userId) {
    return _firestore
        .collection('playlists')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PlaylistModel.fromMap(doc.data(), doc.id))
              .toList(),
        )
        .handleError((e) {
          print('Error en stream de playlists: $e');
        });
  }

  // Obtener una playlist por ID
  Future<PlaylistModel?> getPlaylist(String playlistId) async {
    try {
      final doc = await _firestore
          .collection('playlists')
          .doc(playlistId)
          .get();
      if (doc.exists) {
        return PlaylistModel.fromMap(doc.data()!, playlistId);
      }
      return null;
    } catch (e) {
      print('Error obteniendo playlist: $e');
      return null;
    }
  }

  // Crear playlist
  Future<String> createPlaylist(PlaylistModel playlist) async {
    try {
      final doc = await _firestore
          .collection('playlists')
          .add(playlist.toMap());
      return doc.id;
    } catch (e) {
      print('Error creando playlist: $e');
      rethrow;
    }
  }

  // Actualizar playlist
  Future<void> updatePlaylist(
    String playlistId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection('playlists').doc(playlistId).update(data);
    } catch (e) {
      print('Error actualizando playlist: $e');
      rethrow;
    }
  }

  // Eliminar playlist
  Future<void> deletePlaylist(String playlistId) async {
    try {
      await _firestore.collection('playlists').doc(playlistId).delete();
    } catch (e) {
      print('Error eliminando playlist: $e');
      rethrow;
    }
  }

  // Agregar canción a playlist
  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    try {
      await _firestore.collection('playlists').doc(playlistId).update({
        'songIds': FieldValue.arrayUnion([songId]),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      print('Error agregando canción a playlist: $e');
      rethrow;
    }
  }

  // Eliminar canción de playlist
  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    try {
      await _firestore.collection('playlists').doc(playlistId).update({
        'songIds': FieldValue.arrayRemove([songId]),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      print('Error removiendo canción de playlist: $e');
      rethrow;
    }
  }

  // ===== CANCIONES =====

  // Obtener todas las canciones de un usuario
  Future<List<SongModel>> getUserSongs(String userId) async {
    try {
      final query = await _firestore
          .collection('songs')
          .where('userId', isEqualTo: userId)
          .orderBy('uploadedAt', descending: true)
          .get();

      return query.docs
          .map((doc) => SongModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error obteniendo canciones: $e');
      return [];
    }
  }

  // Stream de canciones en tiempo real
  Stream<List<SongModel>> getUserSongsStream(String userId) {
    return _firestore
        .collection('songs')
        .where('userId', isEqualTo: userId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SongModel.fromMap(doc.data(), doc.id))
              .toList(),
        )
        .handleError((e) {
          print('Error en stream de canciones: $e');
        });
  }

  // Obtener una canción por ID
  Future<SongModel?> getSong(String songId) async {
    try {
      final doc = await _firestore.collection('songs').doc(songId).get();
      if (doc.exists) {
        return SongModel.fromMap(doc.data()!, songId);
      }
      return null;
    } catch (e) {
      print('Error obteniendo canción: $e');
      return null;
    }
  }

  // Crear canción
  Future<String> createSong(SongModel song) async {
    try {
      final doc = await _firestore.collection('songs').add(song.toMap());
      return doc.id;
    } catch (e) {
      print('Error creando canción: $e');
      rethrow;
    }
  }

  // Actualizar canción
  Future<void> updateSong(String songId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('songs').doc(songId).update(data);
    } catch (e) {
      print('Error actualizando canción: $e');
      rethrow;
    }
  }

  // Eliminar canción
  Future<void> deleteSong(String songId) async {
    try {
      await _firestore.collection('songs').doc(songId).delete();
    } catch (e) {
      print('Error eliminando canción: $e');
      rethrow;
    }
  }

  // Marcar canción como favorita
  Future<void> likeSong(String songId, String userId) async {
    try {
      await _firestore.collection('songs').doc(songId).update({
        'likedByUsers': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      print('Error marcando canción como favorita: $e');
      rethrow;
    }
  }

  // Desmarcar canción como favorita
  Future<void> unlikeSong(String songId, String userId) async {
    try {
      await _firestore.collection('songs').doc(songId).update({
        'likedByUsers': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      print('Error desmarcando canción como favorita: $e');
      rethrow;
    }
  }

  // Incrementar contador de reproducciones
  Future<void> incrementSongPlays(String songId) async {
    try {
      await _firestore.collection('songs').doc(songId).update({
        'plays': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error incrementando reproducciones: $e');
    }
  }

  // Obtener canciones favoritas del usuario
  Future<List<SongModel>> getUserFavoriteSongs(String userId) async {
    try {
      final query = await _firestore
          .collection('songs')
          .where('likedByUsers', arrayContains: userId)
          .orderBy('uploadedAt', descending: true)
          .get();

      return query.docs
          .map((doc) => SongModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error obteniendo canciones favoritas: $e');
      return [];
    }
  }

  // Stream de canciones más reproducidas
  Stream<List<SongModel>> getPopularSongsStream({int limit = 20}) {
    return _firestore
        .collection('songs')
        .orderBy('plays', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SongModel.fromMap(doc.data(), doc.id))
              .toList(),
        )
        .handleError((e) {
          print('Error en stream de canciones populares: $e');
        });
  }

  // Buscar canciones
  Future<List<SongModel>> searchSongs(String query) async {
    try {
      final result = await _firestore
          .collection('songs')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: query + 'z')
          .get();

      return result.docs
          .map((doc) => SongModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error buscando canciones: $e');
      return [];
    }
  }

  // ===== REGLAS Y VALIDACIONES =====

  // Validar, límite de almacenamiento
  Future<bool> canUploadSong(String userId, double fileSizeInMB) async {
    try {
      final user = await getUser(userId);
      if (user == null) return false;

      final usedStorage = user.storageUsed;
      final maxStorage = user.maxStorage;
      final availableStorage =
          (maxStorage - usedStorage) / (1024 * 1024); // convertir a MB

      return fileSizeInMB <= availableStorage;
    } catch (e) {
      print('Error validando almacenamiento: $e');
      return false;
    }
  }

  // Actualizar almacenamiento usado
  Future<void> updateStorageUsed(String userId, double fileSizeInBytes) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'storageUsed': FieldValue.increment(fileSizeInBytes.toInt()),
      });
    } catch (e) {
      print('Error actualizando almacenamiento: $e');
      rethrow;
    }
  }
}
