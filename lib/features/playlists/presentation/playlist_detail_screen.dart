import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';
import 'package:on_audio_query/on_audio_query.dart' hide PlaylistModel;

import '../../../models/playlist_model.dart';
import '../../../models/playlist_song.dart';
import '../../../services/audio_handler.dart';
import '../../../services/google_drive_service.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/playlist_provider.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final PlaylistModel playlist;
  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  // Obtener la playlist actualizada desde el provider
  PlaylistModel _getPlaylist(PlaylistProvider provider) =>
      provider.playlists.firstWhere((p) => p.id == widget.playlist.id,
          orElse: () => widget.playlist);

  Future<void> _playSong(PlaylistSong song, int index, List<PlaylistSong> all) async {
    final handler = context.read<MyAudioHandler>();
    final driveService = context.read<GoogleDriveService>();

    // Construir MediaItems
    final items = <MediaItem>[];
    for (final s in all) {
      String uri = s.id;
      if (s.isDrive) {
        final local = await driveService.downloadToCache(s.id, '${s.title}.mp3');
        if (local == null) continue;
        uri = local;
      }
      items.add(MediaItem(
        id: uri,
        title: s.title,
        artist: s.artist,
        artUri: s.albumId != null
            ? Uri.parse('content://media/external/audio/albumart/${s.albumId}')
            : null,
      ));
    }

    if (items.isEmpty) return;
    await handler.loadSongs(items, initialIndex: index.clamp(0, items.length - 1));
    await handler.play();
  }

  Future<void> _playShuffle(List<PlaylistSong> songs) async {
    final shuffled = List<PlaylistSong>.from(songs)..shuffle();
    await _playSong(shuffled.first, 0, shuffled);
    await context.read<MyAudioHandler>().setShuffleMode(AudioServiceShuffleMode.all);
    await context.read<MyAudioHandler>().setRepeatMode(AudioServiceRepeatMode.all);
  }

  void _confirmRemoveSong(BuildContext context, PlaylistProvider provider, String playlistId, PlaylistSong song) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Eliminar canción', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('¿Quitar "${song.title}" de esta playlist?',
            style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); provider.removeSong(playlistId, song.id); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistProvider>(
      builder: (context, provider, _) {
        final playlist = _getPlaylist(provider);
        final songs = playlist.songs;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: AppTheme.surface,
            iconTheme: const IconThemeData(color: AppTheme.textPrimary),
            title: Text(playlist.name,
                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: AppTheme.accent),
                onPressed: () => _showRenameDialog(context, provider, playlist),
              ),
            ],
          ),
          body: songs.isEmpty
              ? _buildEmpty()
              : Column(children: [
                  _buildHeader(songs, playlist),
                  Expanded(child: _buildSongList(songs, playlist.id, provider)),
                ]),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.queue_music_rounded, color: AppTheme.textSecondary, size: 64),
      const SizedBox(height: 16),
      const Text('Playlist vacía', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('Agrega canciones desde tu biblioteca\no desde Mi Nube',
          style: TextStyle(color: AppTheme.textSecondary), textAlign: TextAlign.center),
    ]));
  }

  Widget _buildHeader(List<PlaylistSong> songs, PlaylistModel playlist) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppTheme.surface,
      child: Row(children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: AppTheme.accentDim,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.queue_music_rounded, color: AppTheme.accent, size: 36),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(playlist.name, style: const TextStyle(
              color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('${songs.length} canciones', style: const TextStyle(color: AppTheme.textSecondary)),
        ])),
        IconButton(
          icon: const Icon(Icons.shuffle_rounded, color: AppTheme.accent, size: 28),
          onPressed: songs.isEmpty ? null : () => _playShuffle(songs),
          tooltip: 'Aleatorio',
        ),
        IconButton(
          icon: const Icon(Icons.play_circle_filled_rounded, color: AppTheme.accent, size: 36),
          onPressed: songs.isEmpty ? null : () => _playSong(songs.first, 0, songs),
          tooltip: 'Reproducir',
        ),
      ]),
    );
  }

  Widget _buildSongList(List<PlaylistSong> songs, String playlistId, PlaylistProvider provider) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: songs.length,
      onReorder: (oldIdx, newIdx) async {
        if (newIdx > oldIdx) newIdx--;
        final reordered = List<PlaylistSong>.from(songs);
        final item = reordered.removeAt(oldIdx);
        reordered.insert(newIdx, item);
        // Guardar nuevo orden
        final playlist = provider.playlists.firstWhere((p) => p.id == playlistId);
        final updated = playlist.copyWith(songs: reordered, updatedAt: DateTime.now());
        final idx = provider.playlists.indexOf(playlist);
        if (idx != -1) {
          provider.playlists[idx] = updated;
          // ignore: invalid_use_of_protected_member
          // provider.notifyListeners();
        }
      },
      itemBuilder: (context, i) {
        final song = songs[i];
        return ListTile(
          key: ValueKey(song.id),
          leading: _songArtwork(song),
          title: Text(song.title,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
          subtitle: Text(song.artist,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(song.isDrive ? Icons.cloud_done_rounded : Icons.phone_android_rounded,
                size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent, size: 20),
              onPressed: () => _confirmRemoveSong(context, provider, playlistId, song),
            ),
          ]),
          onTap: () => _playSong(song, i, songs),
        );
      },
    );
  }

  Widget _songArtwork(PlaylistSong song) {
    if (song.isLocal && song.albumId != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: QueryArtworkWidget(
          id: song.albumId!,
          type: ArtworkType.AUDIO,
          artworkHeight: 44, artworkWidth: 44,
          artworkFit: BoxFit.cover,
          nullArtworkWidget: _defaultArtwork(song.isDrive),
        ),
      );
    }
    return _defaultArtwork(song.isDrive);
  }

  Widget _defaultArtwork(bool isDrive) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(6)),
      child: Icon(isDrive ? Icons.cloud_done_rounded : Icons.music_note_rounded,
          color: AppTheme.accent, size: 22),
    );
  }

  void _showRenameDialog(BuildContext context, PlaylistProvider provider, PlaylistModel playlist) {
    final ctrl = TextEditingController(text: playlist.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Renombrar playlist', style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Nombre de la playlist',
            hintStyle: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                provider.renamePlaylist(playlist.id, ctrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: Colors.black),
            child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
