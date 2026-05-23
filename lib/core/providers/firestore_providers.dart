import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/playlist_model.dart';
import '../../models/song_model.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

// ===== PROVEEDOR DE USUARIO =====

class UserProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _loading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get loading => _loading;
  String? get error => _error;
  String? get currentUserId => _authService.currentUser?.uid;

  StreamSubscription? _userSubscription;

  void watchUser(String userId) {
    _userSubscription?.cancel();
    _userSubscription = _firestoreService
        .getUserStream(userId)
        .listen(
          (user) {
            _currentUser = user;
            _loading = false;
            notifyListeners();
          },
          onError: (e) {
            _error = e.toString();
            _loading = false;
            notifyListeners();
          },
        );
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    _loading = true;
    notifyListeners();
    try {
      await _firestoreService.updateUser(uid, data);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}

// ===== PROVEEDOR DE PLAYLISTS =====

class PlaylistsProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<PlaylistModel> _playlists = [];
  bool _loading = false;
  String? _error;

  List<PlaylistModel> get playlists => _playlists;
  bool get loading => _loading;
  String? get error => _error;

  StreamSubscription? _playlistsSubscription;

  void watchUserPlaylists(String userId) {
    _playlistsSubscription?.cancel();
    _playlistsSubscription = _firestoreService
        .getUserPlaylistsStream(userId)
        .listen(
          (playlists) {
            _playlists = playlists;
            _loading = false;
            notifyListeners();
          },
          onError: (e) {
            _error = e.toString();
            _loading = false;
            notifyListeners();
          },
        );
  }

  Future<String> createPlaylist(PlaylistModel playlist) async {
    _loading = true;
    notifyListeners();
    try {
      final id = await _firestoreService.createPlaylist(playlist);
      _error = null;
      return id;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updatePlaylist(
    String playlistId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestoreService.updatePlaylist(playlistId, data);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
    notifyListeners();
  }

  Future<void> deletePlaylist(String playlistId) async {
    _loading = true;
    notifyListeners();
    try {
      await _firestoreService.deletePlaylist(playlistId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    try {
      await _firestoreService.addSongToPlaylist(playlistId, songId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
    notifyListeners();
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    try {
      await _firestoreService.removeSongFromPlaylist(playlistId, songId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _playlistsSubscription?.cancel();
    super.dispose();
  }
}

// ===== PROVEEDOR DE CANCIONES =====

class SongsProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<SongModel> _songs = [];
  List<SongModel> _popularSongs = [];
  List<SongModel> _favoriteSongs = [];
  bool _loading = false;
  String? _error;

  List<SongModel> get songs => _songs;
  List<SongModel> get popularSongs => _popularSongs;
  List<SongModel> get favoriteSongs => _favoriteSongs;
  bool get loading => _loading;
  String? get error => _error;

  StreamSubscription? _songsSubscription;
  StreamSubscription? _popularSongsSubscription;

  void watchUserSongs(String userId) {
    _songsSubscription?.cancel();
    _songsSubscription = _firestoreService
        .getUserSongsStream(userId)
        .listen(
          (songs) {
            _songs = songs;
            _loading = false;
            notifyListeners();
          },
          onError: (e) {
            _error = e.toString();
            _loading = false;
            notifyListeners();
          },
        );
  }

  void watchPopularSongs({int limit = 20}) {
    _popularSongsSubscription?.cancel();
    _popularSongsSubscription = _firestoreService
        .getPopularSongsStream(limit: limit)
        .listen(
          (songs) {
            _popularSongs = songs;
            _loading = false;
            notifyListeners();
          },
          onError: (e) {
            _error = e.toString();
            _loading = false;
            notifyListeners();
          },
        );
  }

  Future<String> createSong(SongModel song) async {
    _loading = true;
    notifyListeners();
    try {
      final id = await _firestoreService.createSong(song);
      _error = null;
      return id;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateSong(String songId, Map<String, dynamic> data) async {
    try {
      await _firestoreService.updateSong(songId, data);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
    notifyListeners();
  }

  Future<void> deleteSong(String songId) async {
    _loading = true;
    notifyListeners();
    try {
      await _firestoreService.deleteSong(songId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> likeSong(String songId, String userId) async {
    try {
      await _firestoreService.likeSong(songId, userId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
    notifyListeners();
  }

  Future<void> unlikeSong(String songId, String userId) async {
    try {
      await _firestoreService.unlikeSong(songId, userId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
    notifyListeners();
  }

  Future<void> loadFavoriteSongs(String userId) async {
    _loading = true;
    notifyListeners();
    try {
      _favoriteSongs = await _firestoreService.getUserFavoriteSongs(userId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<List<SongModel>> searchSongs(String query) async {
    _loading = true;
    notifyListeners();
    try {
      final results = await _firestoreService.searchSongs(query);
      _error = null;
      return results;
    } catch (e) {
      _error = e.toString();
      return [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _songsSubscription?.cancel();
    _popularSongsSubscription?.cancel();
    super.dispose();
  }
}
