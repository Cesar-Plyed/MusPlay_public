import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
// import 'package:musplay/core/config/env_config.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

/// Modelo de canción guardada en Google Drive
class DriveSong {
  final String id; // ID del archivo en Drive
  final String title;
  final String artist;
  final String fileName;
  final int sizeBytes;
  final DateTime modifiedAt;
  String? streamUrl; // URL temporal para reproducir

  DriveSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.fileName,
    required this.sizeBytes,
    required this.modifiedAt,
    this.streamUrl,
  });

  String get sizeFormatted {
    final mb = sizeBytes / (1024 * 1024);
    if (mb < 1) return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    return '${mb.toStringAsFixed(1)} MB';
  }

  /// Extrae título y artista del nombre del archivo si viene en formato "Artista - Título"
  factory DriveSong.fromDriveFile(drive.File file) {
    final name = file.name ?? 'Sin título';
    final cleanName = name
        .replaceAll('.mp3', '')
        .replaceAll('.m4a', '')
        .replaceAll('.flac', '')
        .replaceAll('.ogg', '');

    String title = cleanName;
    String artist = 'Artista desconocido';

    if (cleanName.contains(' - ')) {
      final parts = cleanName.split(' - ');
      artist = parts[0].trim();
      title = parts.sublist(1).join(' - ').trim();
    }

    return DriveSong(
      id: file.id ?? '',
      title: title,
      artist: artist,
      fileName: name,
      sizeBytes: int.tryParse(file.size ?? '0') ?? 0,
      modifiedAt: file.modifiedTime ?? DateTime.now(),
    );
  }
}

/// Cliente HTTP autenticado con Google
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class GoogleDriveService extends ChangeNotifier {
  static const String _folderName = 'MusPlayFiles';
  static const String _folderIdKey = 'musplay_drive_folder_id';

  late final GoogleSignIn _googleSignIn;

  GoogleDriveService() {
    _googleSignIn = GoogleSignIn(
      scopes: [
        'email',
        'profile',
        drive.DriveApi
            .driveFileScope, // Acceso solo a archivos creados por la app
      ]/* ,
      serverClientId: EnvConfig.googleAndroidClientId.isNotEmpty
          ? EnvConfig.googleAndroidClientId
          : null, */
    );
  }

  GoogleSignInAccount? _account;
  drive.DriveApi? _driveApi;
  String? _folderId;
  bool _isConnected = false;
  bool _isLoading = false;
  String? _error;

  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get userEmail => _account?.email;

  // ── Conectar a Google Drive ──────────────────────────────────────────────

  Future<bool> connect() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Intentar reconectar silenciosamente primero
      _account = await _googleSignIn.signInSilently();
      _account ??= await _googleSignIn.signIn();

      if (_account == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _initDriveApi();
      await _getOrCreateFolder();

      _isConnected = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error conectando a Google Drive: $e';
      _isLoading = false;
      _isConnected = false;
      notifyListeners();
      debugPrint('Drive connect error: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    await _googleSignIn.signOut();
    _account = null;
    _driveApi = null;
    _folderId = null;
    _isConnected = false;
    notifyListeners();
  }

  /// Reconectar automáticamente si ya hay sesión
  Future<bool> tryAutoConnect() async {
    try {
      _account = await _googleSignIn.signInSilently();
      if (_account == null) return false;

      await _initDriveApi();

      // Recuperar folder ID guardado
      final prefs = await SharedPreferences.getInstance();
      _folderId = prefs.getString(_folderIdKey);

      // Verificar que la carpeta aún existe
      if (_folderId != null) {
        final exists = await _folderExists(_folderId!);
        if (!exists) _folderId = null;
      }

      _folderId ??= await _getOrCreateFolder();

      _isConnected = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Auto connect failed: $e');
      return false;
    }
  }

  // ── Inicializar API ──────────────────────────────────────────────────────

  Future<void> _initDriveApi() async {
    final headers = await _account!.authHeaders;
    final client = _GoogleAuthClient(headers);
    _driveApi = drive.DriveApi(client);
  }

  // ── Carpeta MusPlayFiles ─────────────────────────────────────────────────

  Future<String> _getOrCreateFolder() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_folderIdKey);

    // Verificar si ya existe
    if (savedId != null && await _folderExists(savedId)) {
      _folderId = savedId;
      return savedId;
    }

    // Buscar carpeta existente en Drive
    const query =
        "mimeType='application/vnd.google-apps.folder' and name='$_folderName' and trashed=false";
    final result = await _driveApi!.files.list(q: query, spaces: 'drive');

    if (result.files != null && result.files!.isNotEmpty) {
      _folderId = result.files!.first.id!;
      await prefs.setString(_folderIdKey, _folderId!);
      debugPrint('Carpeta encontrada: $_folderId');
      return _folderId!;
    }

    // Crear carpeta nueva
    final folder = drive.File()
      ..name = _folderName
      ..mimeType = 'application/vnd.google-apps.folder';

    final created = await _driveApi!.files.create(folder);
    _folderId = created.id!;
    await prefs.setString(_folderIdKey, _folderId!);
    debugPrint('Carpeta creada: $_folderId');
    return _folderId!;
  }

  Future<bool> _folderExists(String folderId) async {
    try {
      await _driveApi!.files.get(folderId);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Subir canción ────────────────────────────────────────────────────────

  Future<DriveSong?> uploadSong({
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    if (_driveApi == null || _folderId == null) {
      throw Exception('No conectado a Google Drive');
    }

    final fileName = path.basename(file.path);
    final fileSize = await file.length();

    // Verificar si ya existe para sobreescribir
    final existingId = await _findFileByName(fileName);

    final driveFile = drive.File()
      ..name = fileName
      ..parents = existingId == null ? [_folderId!] : null;

    final media = drive.Media(
      _fileStream(file, fileSize, onProgress),
      fileSize,
      contentType: _getMimeType(fileName),
    );

    drive.File result;
    if (existingId != null) {
      // Sobreescribir archivo existente
      debugPrint('Sobreescribiendo: $fileName');
      result = await _driveApi!.files.update(
        driveFile,
        existingId,
        uploadMedia: media,
      );
      result.id ??= existingId;
    } else {
      // Subir nuevo
      debugPrint('Subiendo nuevo: $fileName');
      result = await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
      );
    }

    return DriveSong(
      id: result.id ?? existingId ?? '',
      title: _titleFromFileName(fileName),
      artist: _artistFromFileName(fileName),
      fileName: fileName,
      sizeBytes: fileSize,
      modifiedAt: DateTime.now(),
    );
  }

  /// Stream del archivo con reporte de progreso
  Stream<List<int>> _fileStream(
      File file, int totalSize, void Function(double)? onProgress) async* {
    int sent = 0;
    final stream = file.openRead();
    await for (final chunk in stream) {
      sent += chunk.length;
      onProgress?.call(sent / totalSize);
      yield chunk;
    }
  }

  // ── Listar canciones ─────────────────────────────────────────────────────

  Future<List<DriveSong>> listSongs() async {
    if (_driveApi == null || _folderId == null) return [];

    try {
      final query =
          "'$_folderId' in parents and trashed=false and (mimeType='audio/mpeg' or mimeType='audio/mp4' or mimeType='audio/flac' or mimeType='audio/ogg' or mimeType='audio/x-m4a' or fileExtension='mp3' or fileExtension='m4a' or fileExtension='flac')";

      final result = await _driveApi!.files.list(
        q: query,
        $fields: 'files(id,name,size,modifiedTime,mimeType)',
        orderBy: 'name',
      );

      return (result.files ?? [])
          .map((f) => DriveSong.fromDriveFile(f))
          .toList();
    } catch (e) {
      debugPrint('Error listando canciones: $e');
      return [];
    }
  }

  // ── Obtener URL para reproducir ──────────────────────────────────────────

  Future<String?> getStreamUrl(String fileId) async {
    if (_driveApi == null) return null;
    try {
      // Obtener media del archivo como stream
      final media = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      // Guardar temporalmente para reproducir con just_audio
      final dir = await getTemporaryDirectory();
      final tempFile = File('${dir.path}/$fileId.tmp');

      final bytes = <int>[];
      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }
      await tempFile.writeAsBytes(bytes);
      return tempFile.path;
    } catch (e) {
      debugPrint('Error obteniendo stream URL: $e');
      return null;
    }
  }

  /// Para canciones pequeñas: descargar a caché y reproducir local
  Future<String?> downloadToCache(String fileId, String fileName) async {
    try {
      final dir = await getTemporaryDirectory();
      final cacheFile =
          File('${dir.path}/musplay_$fileId${path.extension(fileName)}');

      // Si ya está en caché, usarla
      if (await cacheFile.exists()) {
        debugPrint('Usando caché: ${cacheFile.path}');
        return cacheFile.path;
      }

      debugPrint('Descargando a caché: $fileName');
      final media = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final sink = cacheFile.openWrite();
      await media.stream.pipe(sink);
      await sink.close();

      return cacheFile.path;
    } catch (e) {
      debugPrint('Error descargando a caché: $e');
      return null;
    }
  }

  // ── Eliminar canción ─────────────────────────────────────────────────────

  Future<void> deleteSong(String fileId) async {
    if (_driveApi == null) return;
    try {
      await _driveApi!.files.delete(fileId);
      debugPrint('Archivo eliminado: $fileId');
    } catch (e) {
      debugPrint('Error eliminando: $e');
      rethrow;
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<String?> _findFileByName(String fileName) async {
    try {
      final query =
          "'$_folderId' in parents and name='$fileName' and trashed=false";
      final result =
          await _driveApi!.files.list(q: query, $fields: 'files(id)');
      if (result.files != null && result.files!.isNotEmpty) {
        return result.files!.first.id;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String _getMimeType(String fileName) {
    final ext = path.extension(fileName).toLowerCase();
    return switch (ext) {
      '.mp3' => 'audio/mpeg',
      '.m4a' => 'audio/mp4',
      '.flac' => 'audio/flac',
      '.ogg' => 'audio/ogg',
      _ => 'audio/mpeg',
    };
  }

  String _titleFromFileName(String fileName) {
    final clean = fileName
        .replaceAll('.mp3', '')
        .replaceAll('.m4a', '')
        .replaceAll('.flac', '')
        .replaceAll('.ogg', '');
    if (clean.contains(' - ')) {
      final parts = clean.split(' - ');
      return parts.sublist(1).join(' - ').trim();
    }
    return clean.trim();
  }

  String _artistFromFileName(String fileName) {
    final clean = fileName
        .replaceAll('.mp3', '')
        .replaceAll('.m4a', '')
        .replaceAll('.flac', '')
        .replaceAll('.ogg', '');
    if (clean.contains(' - ')) {
      return clean.split(' - ')[0].trim();
    }
    return 'Artista desconocido';
  }

  /// Espacio usado estimado en bytes
  Future<int> getUsedBytes() async {
    final songs = await listSongs();
    return songs.fold<int>(0, (sum, s) => sum + s.sizeBytes);
  }
}
