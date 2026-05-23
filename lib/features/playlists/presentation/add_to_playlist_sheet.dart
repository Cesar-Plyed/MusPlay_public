import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/playlist_song.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/playlist_provider.dart';

/// Bottom sheet para agregar una canción a una playlist existente o crear una nueva
class AddToPlaylistSheet extends StatelessWidget {
  final PlaylistSong song;
  const AddToPlaylistSheet({super.key, required this.song});

  static Future<void> show(BuildContext context, PlaylistSong song) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => AddToPlaylistSheet(song: song),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlaylistProvider>();
    final playlists = provider.playlists;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Center(child: Container(
          margin: const EdgeInsets.only(top: 10, bottom: 16),
          width: 36, height: 4,
          decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2)),
        )),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            const Icon(Icons.playlist_add_rounded, color: AppTheme.accent),
            const SizedBox(width: 10),
            Expanded(child: Text(
              'Agregar "${song.title}"',
              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            )),
          ]),
        ),
        const SizedBox(height: 8),
        const Divider(color: AppTheme.divider),

        // Crear nueva playlist
        ListTile(
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppTheme.accentDim, shape: BoxShape.circle),
            child: const Icon(Icons.add_rounded, color: AppTheme.accent),
          ),
          title: const Text('Crear nueva playlist',
              style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w600)),
          onTap: () => _showCreateAndAdd(context, provider),
        ),

        if (playlists.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Aún no tienes playlists',
                style: TextStyle(color: AppTheme.textSecondary), textAlign: TextAlign.center),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: playlists.length,
              itemBuilder: (ctx, i) {
                final playlist = playlists[i];
                final inPlaylist = provider.isSongInPlaylist(playlist.id, song.id);
                return ListTile(
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                        color: AppTheme.surfaceLight, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.queue_music_rounded, color: AppTheme.accent, size: 22),
                  ),
                  title: Text(playlist.name,
                      style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
                  subtitle: Text('${playlist.songCount} canciones',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  trailing: inPlaylist
                      ? const Icon(Icons.check_circle_rounded, color: Colors.greenAccent)
                      : const Icon(Icons.add_circle_outline_rounded, color: AppTheme.textSecondary),
                  onTap: inPlaylist ? null : () {
                    provider.addSong(playlist.id, song);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Agregada a "${playlist.name}"'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ));
                  },
                );
              },
            ),
          ),
        const SizedBox(height: 16),
      ]),
    );
  }

  void _showCreateAndAdd(BuildContext context, PlaylistProvider provider) {
    Navigator.pop(context);
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Nueva playlist', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl, autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Nombre', hintStyle: const TextStyle(color: AppTheme.textSecondary),
            filled: true, fillColor: AppTheme.surfaceLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              final playlist = await provider.createPlaylist(ctrl.text.trim());
              await provider.addSong(playlist.id, song);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Playlist "${playlist.name}" creada con la canción'),
                  backgroundColor: Colors.green,
                ));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: Colors.black),
            child: const Text('Crear', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
