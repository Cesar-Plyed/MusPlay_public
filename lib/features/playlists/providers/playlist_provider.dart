import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/playlist_model.dart';
import '../../../models/playlist_song.dart';

class PlaylistProvider extends ChangeNotifier {
  static const String _localKey = 'local_playlists';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<PlaylistModel> _playlists = [];
  bool _isLoading = false;
  String? _userId;
  bool _isPremium = false;

  List<PlaylistModel> get playlists => _playlists;
  bool get isLoading => _isLoading;

  /// Llamar al iniciar sesión o cambiar plan
  Future<void> initialize(String userId, bool isPremium) async {
    _userId = userId;
    _isPremium = isPremium;
    await _load();
  }

  Future<void> _load() async {
    _isLoading = true;
    notifyListeners();
    if (_isPremium && _userId != null) {
      await _loadFromFirebase();
    } else {
      await _loadFromLocal();
    }
    _isLoading = false;
    notifyListeners();
  }

  // ── Local (SharedPreferences) ──────────────────────────────────────────────

  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_localKey) ?? [];
    _playlists = raw.map((s) => PlaylistModel.fromJsonString(s)).toList();
  }

  Future<void> _saveToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_localKey, _playlists.map((p) => p.toJsonString()).toList());
  }

  // ── Firebase (Premium) ────────────────────────────────────────────────────

  Future<void> _loadFromFirebase() async {
    try {
      final snap = await _firestore
          .collection('playlists')
          .where('userId', isEqualTo: _userId)
          .orderBy('updatedAt', descending: true)
          .get();
      _playlists = snap.docs
          .map((d) => PlaylistModel.fromMap(d.data(), d.id))
          .toList();
      // También guardar localmente como caché offline
      await _saveToLocal();
    } catch (e) {
      debugPrint('Error cargando playlists de Firebase: $e');
      // Fallback a local si falla Firebase
      await _loadFromLocal();
    }
  }

  Future<void> _saveToFirebase(PlaylistModel playlist) async {
    if (_userId == null) return;
    try {
      if (playlist.id.isEmpty || playlist.id.startsWith('local_')) {
        // Crear nuevo documento
        final ref = await _firestore.collection('playlists').add(playlist.toMap());
        // Actualizar el id local
        final idx = _playlists.indexWhere((p) => p.id == playlist.id);
        if (idx != -1) {
          _playlists[idx] = playlist.copyWith(id: ref.id);
        }
      } else {
        await _firestore.collection('playlists').doc(playlist.id).set(playlist.toMap());
      }
    } catch (e) {
      debugPrint('Error guardando playlist en Firebase: $e');
    }
  }

  Future<void> _deleteFromFirebase(String playlistId) async {
    try {
      if (!playlistId.startsWith('local_')) {
        await _firestore.collection('playlists').doc(playlistId).delete();
      }
    } catch (e) {
      debugPrint('Error eliminando playlist de Firebase: $e');
    }
  }

  // ── CRUD Público ──────────────────────────────────────────────────────────

  Future<PlaylistModel> createPlaylist(String name, {String? description}) async {
    final now = DateTime.now();
    final playlist = PlaylistModel(
      id: 'local_${now.millisecondsSinceEpoch}',
      userId: _userId ?? '',
      name: name,
      description: description,
      songs: [],
      createdAt: now,
      updatedAt: now,
    );

    _playlists.insert(0, playlist);

    if (_isPremium) {
      await _saveToFirebase(playlist);
    }
    await _saveToLocal();
    notifyListeners();
    return _playlists.first;
  }

  Future<void> renamePlaylist(String playlistId, String newName) async {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx == -1) return;

    _playlists[idx] = _playlists[idx].copyWith(name: newName, updatedAt: DateTime.now());

    if (_isPremium) await _saveToFirebase(_playlists[idx]);
    await _saveToLocal();
    notifyListeners();
  }

  Future<void> deletePlaylist(String playlistId) async {
    _playlists.removeWhere((p) => p.id == playlistId);
    if (_isPremium) await _deleteFromFirebase(playlistId);
    await _saveToLocal();
    notifyListeners();
  }

  Future<void> addSong(String playlistId, PlaylistSong song) async {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx == -1) return;

    // No duplicar
    final already = _playlists[idx].songs.any((s) => s.id == song.id);
    if (already) return;

    final updated = _playlists[idx].copyWith(
      songs: [..._playlists[idx].songs, song],
      updatedAt: DateTime.now(),
    );
    _playlists[idx] = updated;

    if (_isPremium) await _saveToFirebase(updated);
    await _saveToLocal();
    notifyListeners();
  }

  Future<void> removeSong(String playlistId, String songId) async {
    final idx = _playlists.indexWhere((p) => p.id == playlistId);
    if (idx == -1) return;

    final updated = _playlists[idx].copyWith(
      songs: _playlists[idx].songs.where((s) => s.id != songId).toList(),
      updatedAt: DateTime.now(),
    );
    _playlists[idx] = updated;

    if (_isPremium) await _saveToFirebase(updated);
    await _saveToLocal();
    notifyListeners();
  }

  bool isSongInPlaylist(String playlistId, String songId) {
    final p = _playlists.firstWhere((p) => p.id == playlistId, orElse: () =>
        PlaylistModel(id: '', userId: '', name: '', songs: [], createdAt: DateTime.now(), updatedAt: DateTime.now()));
    return p.songs.any((s) => s.id == songId);
  }

  List<PlaylistModel> playlistsContaining(String songId) =>
      _playlists.where((p) => p.songs.any((s) => s.id == songId)).toList();

  /// Sincronizar cuando el usuario sube a premium (migrar local → Firebase)
  Future<void> migrateToFirebase(String userId) async {
    _userId = userId;
    _isPremium = true;
    for (final p in _playlists) {
      await _saveToFirebase(p);
    }
    await _loadFromFirebase();
    notifyListeners();
  }

  void reset() {
    _playlists = [];
    _userId = null;
    _isPremium = false;
    notifyListeners();
  }
}
