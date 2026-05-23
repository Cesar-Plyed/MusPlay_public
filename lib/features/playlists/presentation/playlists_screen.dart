import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/playlist_model.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/playlist_provider.dart';
import 'playlist_detail_screen.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: Column(children: [
              _buildHeader(context, provider),
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                    : provider.playlists.isEmpty
                        ? _buildEmpty(context, provider)
                        : _buildList(context, provider),
              ),
            ]),
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'create_playlist',
            onPressed: () => _showCreateDialog(context, provider),
            backgroundColor: AppTheme.accent,
            foregroundColor: Colors.black,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Nueva playlist', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, PlaylistProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Playlists', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 4),
          Text('${provider.playlists.length} listas', style: Theme.of(context).textTheme.bodyMedium),
        ])),
      ]),
    );
  }

  Widget _buildEmpty(BuildContext context, PlaylistProvider provider) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.queue_music_rounded, color: AppTheme.textSecondary, size: 72),
      const SizedBox(height: 20),
      Text('Sin playlists', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      const Text('Crea tu primera lista de reproducción',
          style: TextStyle(color: AppTheme.textSecondary), textAlign: TextAlign.center),
      const SizedBox(height: 24),
      ElevatedButton.icon(
        onPressed: () => _showCreateDialog(context, provider),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Crear playlist'),
        style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accent, foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
    ]));
  }

  Widget _buildList(BuildContext context, PlaylistProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: provider.playlists.length,
      itemBuilder: (context, i) {
        final playlist = provider.playlists[i];
        return _PlaylistTile(
          playlist: playlist,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlist: playlist))),
          onDelete: () => _confirmDelete(context, provider, playlist),
        );
      },
    );
  }

  void _showCreateDialog(BuildContext context, PlaylistProvider provider) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nueva playlist', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Nombre de la playlist',
            hintStyle: const TextStyle(color: AppTheme.textSecondary),
            filled: true,
            fillColor: AppTheme.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (_) => _create(ctx, provider, ctrl.text),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () => _create(ctx, provider, ctrl.text),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Crear', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _create(BuildContext ctx, PlaylistProvider provider, String name) {
    if (name.trim().isEmpty) return;
    provider.createPlaylist(name.trim());
    Navigator.pop(ctx);
  }

  void _confirmDelete(BuildContext context, PlaylistProvider provider, PlaylistModel playlist) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Eliminar playlist', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('¿Eliminar "${playlist.name}"? Las canciones no se borran.',
            style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () { provider.deletePlaylist(playlist.id); Navigator.pop(ctx); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  final PlaylistModel playlist;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _PlaylistTile({required this.playlist, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: AppTheme.accentDim, borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.queue_music_rounded, color: AppTheme.accent, size: 28),
        ),
        title: Text(playlist.name, style: const TextStyle(
            color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(children: [
            Text('${playlist.songCount} canciones',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(width: 8),
            if (playlist.songs.any((s) => s.isDrive))
              const Icon(Icons.cloud_done_rounded, size: 12, color: AppTheme.accent),
            if (playlist.songs.any((s) => s.isLocal))
              const Padding(
                padding: EdgeInsets.only(left: 2),
                child: Icon(Icons.phone_android_rounded, size: 12, color: AppTheme.textSecondary),
              ),
          ]),
        ),
        trailing: PopupMenuButton<String>(
          color: AppTheme.surface,
          icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
          onSelected: (v) { if (v == 'delete') onDelete(); },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                  SizedBox(width: 10),
                  Text('Eliminar', style: TextStyle(color: AppTheme.textPrimary)),
                ])),
          ],
        ),
      ),
    );
  }
}
