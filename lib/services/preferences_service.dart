import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _lastSongKey = 'last_song_id';
  static const String _lastSongTitleKey = 'last_song_title';
  static const String _lastSongArtistKey = 'last_song_artist';
  static const String _lastSongUrlKey = 'last_song_url';
  static const String _lastPositionKey = 'last_song_position';

  // Guardar última canción
  Future<void> saveLastSong({
    required String id,
    required String title,
    required String artist,
    required String url,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_lastSongKey, id),
      prefs.setString(_lastSongTitleKey, title),
      prefs.setString(_lastSongArtistKey, artist),
      prefs.setString(_lastSongUrlKey, url),
    ]);
  }

  // Guardar posición de la canción
  Future<void> saveLastPosition(int milliseconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastPositionKey, milliseconds);
  }

  // Obtener última canción
  Future<Map<String, String>?> getLastSong() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_lastSongKey);

    if (id == null) return null;

    return {
      'id': id,
      'title': prefs.getString(_lastSongTitleKey) ?? 'Sin título',
      'artist': prefs.getString(_lastSongArtistKey) ?? 'Artista desconocido',
      'url': prefs.getString(_lastSongUrlKey) ?? '',
    };
  }

  // Obtener posición guardada
  Future<int> getLastPosition() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastPositionKey) ?? 0;
  }

  // Limpiar datos de canción
  Future<void> clearLastSong() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_lastSongKey),
      prefs.remove(_lastSongTitleKey),
      prefs.remove(_lastSongArtistKey),
      prefs.remove(_lastSongUrlKey),
      prefs.remove(_lastPositionKey),
    ]);
  }
}
