import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/models/cloud_song.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Subir canción a Firebase Storage
  Future<void> uploadSong({
    required File file,
    required String title,
    required String artist,
    required String userPlan,
    required Function(double) onProgress,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception(
          'Debes iniciar sesión para subir canciones. Toca el icono de Cuenta en el navbar.',
        );
      }

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final storageRef = _storage.ref().child(
        'users/${user.uid}/songs/$fileName',
      );

      final uploadTask = storageRef.putFile(file);

      // Monitorear progreso
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });

      await uploadTask;

      // Obtener URL de descarga
      final downloadUrl = await storageRef.getDownloadURL();

      // Guardar metadata en Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('songs')
          .doc(fileName)
          .set({
            'id': fileName,
            'title': title,
            'artist': artist,
            'fileName': fileName,
            'downloadUrl': downloadUrl,
            'fileSize': file.lengthSync(),
            'uploadedAt': DateTime.now(),
            'duration': null, // Se actualizará luego
            'userPlan': userPlan,
          });

      // Actualizar almacenamiento usado
      await _updateStorageUsed(user.uid, file.lengthSync());
    } catch (e) {
      print('Error subiendo canción: $e');
      rethrow;
    }
  }

  // Stream de canciones del usuario
  Stream<List<CloudSong>> getSongsStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('songs')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CloudSong.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  // Obtener canciones del usuario (Future)
  Future<List<CloudSong>> getUserSongs(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('songs')
          .orderBy('uploadedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CloudSong.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error obteniendo canciones: $e');
      return [];
    }
  }

  // Eliminar canción por objeto CloudSong
  Future<void> deleteSong(CloudSong song) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // Eliminar de Storage
      await _storage
          .ref()
          .child('users/${user.uid}/songs/${song.fileName}')
          .delete();

      // Eliminar de Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('songs')
          .doc(song.id)
          .delete();

      // Actualizar almacenamiento usado
      await _updateStorageUsed(user.uid, -song.fileSize);
    } catch (e) {
      print('Error eliminando canción: $e');
      rethrow;
    }
  }

  // Eliminar canción por parámetros (para compatibilidad)
  Future<void> deleteSongByParams(
    String userId,
    String fileName,
    int fileSize,
  ) async {
    try {
      // Eliminar de Storage
      await _storage.ref().child('users/$userId/songs/$fileName').delete();

      // Eliminar de Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('songs')
          .doc(fileName)
          .delete();

      // Actualizar almacenamiento usado
      await _updateStorageUsed(userId, -fileSize);
    } catch (e) {
      print('Error eliminando canción: $e');
      rethrow;
    }
  }

  // Actualizar almacenamiento usado
  Future<void> _updateStorageUsed(String userId, int bytes) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'storageUsed': FieldValue.increment(bytes),
      });
    } catch (e) {
      print('Error actualizando almacenamiento: $e');
    }
  }

  // Obtener información de almacenamiento
  Future<Map<String, dynamic>?> getStorageInfo(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      return {
        'used': data['storageUsed'] ?? 0,
        'max': data['maxStorage'] ?? 1073741824,
        'plan': data['plan'] ?? 'free',
      };
    } catch (e) {
      print('Error obteniendo info de almacenamiento: $e');
      return null;
    }
  }

  // Obtener bytes usados por el usuario actual
  Future<int> getUsedBytes() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return 0;

      final data = doc.data() as Map<String, dynamic>;
      return data['storageUsed'] ?? 0;
    } catch (e) {
      print('Error obteniendo bytes usados: $e');
      return 0;
    }
  }

  // ===== NUEVOS MÉTODOS PARA VER ARCHIVOS EN LA NUBE =====

  // Listar todos los archivos del usuario en Cloud Storage
  Future<List<CloudStorageFile>> listUserFiles(String userId) async {
    try {
      final List<CloudStorageFile> files = [];

      // Listar audios en users/{userId}/songs/
      final authorRef = _storage.ref('users/$userId/songs');
      try {
        final result = await authorRef.listAll();
        for (final item in result.items) {
          try {
            final metadata = await item.getMetadata();
            final url = await item.getDownloadURL();
            files.add(
              CloudStorageFile(
                name: item.name,
                fullPath: item.fullPath,
                type: 'audio',
                sizeBytes: metadata.size ?? 0,
                sizeMB: (metadata.size ?? 0) / (1024 * 1024),
                sizeGB: (metadata.size ?? 0) / (1024 * 1024 * 1024),
                contentType: metadata.contentType ?? 'audio/mpeg',
                updated: metadata.updated ?? DateTime.now(),
                downloadUrl: url,
              ),
            );
          } catch (e) {
            print('Error procesando archivo: $e');
          }
        }
      } catch (e) {
        print('Error listando audios: $e');
      }

      return files;
    } catch (e) {
      print('Error listando archivos: $e');
      return [];
    }
  }

  // Obtener estadísticas completas de almacenamiento
  Future<CloudStorageStats?> getStorageStats(String userId) async {
    try {
      final files = await listUserFiles(userId);
      final storageInfo = await getStorageInfo(userId);

      if (storageInfo == null) return null;

      final usedBytes = storageInfo['used'] as int;
      final maxBytes = storageInfo['max'] as int;
      final plan = storageInfo['plan'] as String;

      final totalAudioSizeMB = files.fold<double>(
        0,
        (sum, f) => sum + f.sizeMB,
      );
      final totalFilesCount = files.length;

      return CloudStorageStats(
        userId: userId,
        totalFileCount: totalFilesCount,
        totalAudioSizeMB: totalAudioSizeMB,
        totalSizeMB: totalAudioSizeMB,
        usedBytes: usedBytes,
        usedMB: usedBytes / (1024 * 1024),
        usedGB: usedBytes / (1024 * 1024 * 1024),
        maxBytes: maxBytes,
        maxMB: maxBytes / (1024 * 1024),
        maxGB: maxBytes / (1024 * 1024 * 1024),
        percentageUsed: (usedBytes / maxBytes) * 100,
        remainingBytes: maxBytes - usedBytes,
        remainingMB: (maxBytes - usedBytes) / (1024 * 1024),
        remainingGB: (maxBytes - usedBytes) / (1024 * 1024 * 1024),
        plan: plan,
      );
    } catch (e) {
      print('Error obteniendo estadísticas: $e');
      return null;
    }
  }

  // Eliminar archivo permanentemente
  Future<void> deleteCloudFile(String userId, String filePath) async {
    try {
      final ref = _storage.ref(filePath);
      final metadata = await ref.getMetadata();

      // Eliminar de Storage
      await ref.delete();

      // Actualizar almacenamiento usado
      await _updateStorageUsed(userId, -(metadata.size ?? 0));

      print('Archivo eliminado: $filePath');
    } catch (e) {
      print('Error eliminando archivo: $e');
      rethrow;
    }
  }

  // Descargar archivo de la nube
  Future<List<int>?> downloadFile(String filePath) async {
    try {
      final ref = _storage.ref(filePath);
      final data = await ref.getData();
      return data;
    } catch (e) {
      print('Error descargando archivo: $e');
      return null;
    }
  }
}

// ===== MODELOS PARA CLOUD STORAGE =====

class CloudStorageFile {
  final String name;
  final String fullPath;
  final String type; // 'audio', 'image', etc
  final int sizeBytes;
  final double sizeMB;
  final double sizeGB;
  final String contentType;
  final DateTime updated;
  final String downloadUrl;

  CloudStorageFile({
    required this.name,
    required this.fullPath,
    required this.type,
    required this.sizeBytes,
    required this.sizeMB,
    required this.sizeGB,
    required this.contentType,
    required this.updated,
    required this.downloadUrl,
  });

  String get formattedSize {
    if (sizeMB < 1) {
      return '${(sizeBytes / 1024).toStringAsFixed(2)} KB';
    } else if (sizeMB < 1024) {
      return '${sizeMB.toStringAsFixed(2)} MB';
    } else {
      return '${sizeGB.toStringAsFixed(2)} GB';
    }
  }

  String get formattedDate {
    return '${updated.day}/${updated.month}/${updated.year} ${updated.hour}:${updated.minute.toString().padLeft(2, '0')}';
  }
}

class CloudStorageStats {
  final String userId;
  final int totalFileCount;
  final double totalAudioSizeMB;
  final double totalSizeMB;
  final int usedBytes;
  final double usedMB;
  final double usedGB;
  final int maxBytes;
  final double maxMB;
  final double maxGB;
  final double percentageUsed;
  final int remainingBytes;
  final double remainingMB;
  final double remainingGB;
  final String plan;

  CloudStorageStats({
    required this.userId,
    required this.totalFileCount,
    required this.totalAudioSizeMB,
    required this.totalSizeMB,
    required this.usedBytes,
    required this.usedMB,
    required this.usedGB,
    required this.maxBytes,
    required this.maxMB,
    required this.maxGB,
    required this.percentageUsed,
    required this.remainingBytes,
    required this.remainingMB,
    required this.remainingGB,
    required this.plan,
  });

  String get formattedUsed {
    if (usedMB < 1024) {
      return '${usedMB.toStringAsFixed(2)} MB';
    } else {
      return '${usedGB.toStringAsFixed(2)} GB';
    }
  }

  String get formattedMax {
    if (maxMB < 1024) {
      return '${maxMB.toStringAsFixed(2)} MB';
    } else {
      return '${maxGB.toStringAsFixed(2)} GB';
    }
  }

  String get formattedRemaining {
    if (remainingMB < 1024) {
      return '${remainingMB.toStringAsFixed(2)} MB';
    } else {
      return '${remainingGB.toStringAsFixed(2)} GB';
    }
  }

  String get formattedPercentage => percentageUsed.toStringAsFixed(1);

  String get planLabel {
    switch (plan) {
      case 'premium':
        return '⭐ Premium - 50 GB';
      case 'pro':
        return '💎 Pro - 500 GB';
      default:
        return '📦 Free - 1 GB';
    }
  }
}
