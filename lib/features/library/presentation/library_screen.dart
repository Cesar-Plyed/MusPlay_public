import 'dart:io';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:audio_service/audio_service.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../services/audio_handler.dart';
import '../../../core/theme/app_theme.dart';
import '../../playlists/presentation/add_to_playlist_sheet.dart';
import '../../../models/playlist_song.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> _songs = [];
  bool _loading = true;
  String _searchQuery = '';
  late TabController _tabController;

  // Favoritos (en memoria — persistencia real se puede agregar con SharedPreferences)
  final Set<int> _favoriteIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _requestPermissionAndLoad();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissionAndLoad() async {
    bool granted = false;
    if (Platform.isAndroid) {
      final storageStatus = await Permission.storage.request();
      final audioStatus = await Permission.audio.request();
      granted = storageStatus.isGranted || audioStatus.isGranted;
    } else {
      granted = await Permission.storage.request().isGranted;
    }
    if (granted) await _loadSongs();
    else setState(() => _loading = false);
  }

  Future<void> _loadSongs() async {
    final songs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
    setState(() {
      _songs = songs.where((s) => s.duration != null && s.duration! > 30000).toList();
      _loading = false;
    });
  }

  List<SongModel> get _filteredSongs {
    if (_searchQuery.isEmpty) return _songs;
    final q = _searchQuery.toLowerCase();
    return _songs.where((s) =>
        s.title.toLowerCase().contains(q) ||
        (s.artist ?? '').toLowerCase().contains(q)).toList();
  }

  List<SongModel> get _favoriteSongs =>
      _songs.where((s) => _favoriteIds.contains(s.id)).toList();

  void _playSong(SongModel song, int index, List<SongModel> list) {
    final handler = context.read<MyAudioHandler>();

    final mediaItems = list.map((s) => MediaItem(
      id: s.uri ?? '',
      title: s.title,
      artist: s.artist ?? 'Artista desconocido',
      album: s.album ?? 'Álbum desconocido',
      duration: Duration(milliseconds: s.duration ?? 0),
      artUri: s.albumId != null
          ? Uri.parse('content://media/external/audio/albumart/${s.albumId}')
          : null,
    )).toList();

    handler.loadSongs(mediaItems, initialIndex: index);
    handler.play();
  }

  void _playShuffle(List<SongModel> list) {
    if (list.isEmpty) return;
    final handler = context.read<MyAudioHandler>();

    final shuffled = List<SongModel>.from(list)..shuffle();
    final mediaItems = shuffled.map((s) => MediaItem(
      id: s.uri ?? '',
      title: s.title,
      artist: s.artist ?? 'Artista desconocido',
      album: s.album ?? 'Álbum desconocido',
      duration: Duration(milliseconds: s.duration ?? 0),
      artUri: s.albumId != null
          ? Uri.parse('content://media/external/audio/albumart/${s.albumId}')
          : null,
    )).toList();

    handler.loadSongs(mediaItems, initialIndex: 0);
    handler.setShuffleMode(AudioServiceShuffleMode.all);
    handler.setRepeatMode(AudioServiceRepeatMode.all);
    handler.play();
  }

  void _toggleFavorite(int songId) {
    setState(() {
      if (_favoriteIds.contains(songId)) {
        _favoriteIds.remove(songId);
      } else {
        _favoriteIds.add(songId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSongsTab(),
                  _buildPlaylistsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Mi Música', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 4),
        Text('${_songs.length} canciones', style: Theme.of(context).textTheme.bodyMedium),
      ]),
    );
  }

  Widget _buildSongsTab() {
    return Column(children: [
      _buildSearchBar(),
      Expanded(child: _buildSongList()),
    ]);
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'Buscar canción o artista...',
          hintStyle: const TextStyle(color: AppTheme.textSecondary),
          prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
          filled: true,
          fillColor: AppTheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSongList() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    if (_songs.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.music_off, color: AppTheme.textSecondary, size: 64),
        const SizedBox(height: 16),
        Text('No se encontró música', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text('Otorga permiso de almacenamiento', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _requestPermissionAndLoad,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
          child: const Text('Reintentar'),
        ),
      ]));
    }

    final songs = _filteredSongs;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: songs.length + 1, // +1 para el botón shuffle al inicio
      itemBuilder: (context, index) {
        if (index == 0) return _buildShuffleButton(songs);
        final song = songs[index - 1];
        final isFav = _favoriteIds.contains(song.id);
        return _SongTile(
          song: song,
          isFavorite: isFav,
          onTap: () => _playSong(song, index - 1, songs),
          onFavorite: () => _toggleFavorite(song.id),
          onAddToPlaylist: () => AddToPlaylistSheet.show(context, PlaylistSong(
            id: song.uri ?? song.id.toString(),
            title: song.title,
            artist: song.artist ?? 'Artista desconocido',
            source: 'local',
            durationMs: song.duration,
            albumId: song.albumId,
          )),
        );
      },
    );
  }

  Widget _buildShuffleButton(List<SongModel> songs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: songs.isEmpty ? null : () => _playShuffle(songs),
          icon: const Icon(Icons.shuffle_rounded, size: 20),
          label: Text(
            'Reproducir aleatoriamente (${songs.length})',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  // ── Tab Playlists ──────────────────────────────────────────────────────────

  Widget _buildPlaylistsTab() {
    final favSongs = _favoriteSongs;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPlaylistCard(
          icon: Icons.favorite_rounded,
          iconColor: Colors.redAccent,
          name: 'Mis Favoritas',
          count: favSongs.length,
          onTap: favSongs.isEmpty ? null : () => _openFavorites(favSongs),
        ),
        const SizedBox(height: 12),
        // Placeholder para playlists futuras
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.divider, style: BorderStyle.solid),
          ),
          child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.divider, width: 1, style: BorderStyle.solid),
              ),
              child: const Icon(Icons.add_rounded, color: AppTheme.textSecondary),
            ),
            const SizedBox(width: 14),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Nueva playlist', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
              Text('Próximamente', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ])),
          ]),
        ),
      ],
    );
  }

  Widget _buildPlaylistCard({
    required IconData icon,
    required Color iconColor,
    required String name,
    required int count,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
            Text('$count canciones', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ])),
          if (onTap != null)
            const Icon(Icons.play_circle_filled_rounded, color: AppTheme.accent, size: 34),
        ]),
      ),
    );
  }

  void _openFavorites(List<SongModel> favSongs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(children: [
              const Icon(Icons.favorite_rounded, color: Colors.redAccent),
              const SizedBox(width: 10),
              Expanded(child: Text('Mis Favoritas',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(color: AppTheme.textPrimary))),
              IconButton(
                icon: const Icon(Icons.shuffle_rounded, color: AppTheme.accent),
                onPressed: () { Navigator.pop(ctx); _playShuffle(favSongs); },
              ),
            ]),
          ),
          const Divider(color: AppTheme.divider),
          Expanded(
            child: ListView.builder(
              controller: controller,
              itemCount: favSongs.length,
              itemBuilder: (_, i) {
                final s = favSongs[i];
                return _SongTile(
                  song: s,
                  isFavorite: true,
                  onTap: () { Navigator.pop(ctx); _playSong(s, i, favSongs); },
                  onFavorite: () { _toggleFavorite(s.id); Navigator.pop(ctx); }, onAddToPlaylist: () {  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Song Tile ──────────────────────────────────────────────────────────────

class _SongTile extends StatelessWidget {
  final SongModel song;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onAddToPlaylist;

  const _SongTile({
    required this.song,
    required this.isFavorite,
    required this.onTap,
    required this.onFavorite,
    required this.onAddToPlaylist,
  });

  String _formatDuration(int? ms) {
    if (ms == null) return '--:--';
    final d = Duration(milliseconds: ms);
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: QueryArtworkWidget(
              id: song.id,
              type: ArtworkType.AUDIO,
              artworkHeight: 52,
              artworkWidth: 52,
              artworkFit: BoxFit.cover,
              nullArtworkWidget: Container(
                height: 52, width: 52,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.music_note, color: AppTheme.accent, size: 24),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(song.title,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 3),
            Text(song.artist ?? 'Artista desconocido',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ])),
          const SizedBox(width: 4),
          Text(_formatDuration(song.duration),
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 20,
              color: isFavorite ? Colors.redAccent : AppTheme.textSecondary,
            ),
            onPressed: onFavorite,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          IconButton(
            icon: const Icon(Icons.playlist_add_rounded, size: 20, color: AppTheme.textSecondary),
            onPressed: onAddToPlaylist,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ]),
      ),
    );
  }
}
