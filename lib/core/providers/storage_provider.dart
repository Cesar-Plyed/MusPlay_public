import 'package:flutter/foundation.dart';
import '../../../services/storage_service.dart';

/// Provider para gestionar el estado del almacenamiento en la nube
class StorageProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();

  CloudStorageStats? _stats;
  List<CloudStorageFile> _files = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  CloudStorageStats? get stats => _stats;
  List<CloudStorageFile> get files => _files;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Cargar estadísticas de almacenamiento
  Future<void> loadStorageStats(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _stats = await _storageService.getStorageStats(userId);

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Cargar lista de archivos
  Future<void> loadFiles(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _files = await _storageService.listUserFiles(userId);

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Cargar stats y files juntos
  Future<void> loadAll(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final stats = await _storageService.getStorageStats(userId);
      final files = await _storageService.listUserFiles(userId);

      _stats = stats;
      _files = files;

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Eliminar archivo
  Future<void> deleteFile(String userId, String filePath) async {
    try {
      _error = null;
      await _storageService.deleteCloudFile(userId, filePath);
      // Recargar lista y stats
      await loadAll(userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Descargar archivo
  Future<String?> downloadFile(String filePath) async {
    try {
      _error = null;
      await _storageService.downloadFile(filePath);
      notifyListeners();
      return null; // Retorna null (descarga iniciada)
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Limpiar el error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Resetear provider
  void reset() {
    _stats = null;
    _files = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
