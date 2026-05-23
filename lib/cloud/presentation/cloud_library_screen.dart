import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';

import '../../../services/google_drive_service.dart';
import '../../../services/audio_handler.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/playlists/presentation/add_to_playlist_sheet.dart';
import '../../../models/playlist_song.dart';

class CloudLibraryScreen extends StatefulWidget {
  const CloudLibraryScreen({super.key});

  @override
  State<CloudLibraryScreen> createState() => _CloudLibraryScreenState();
}

class _CloudLibraryScreenState extends State<CloudLibraryScreen> {
  bool _uploading = false;
  double _uploadProgress = 0;
  bool _loadingSongs = false;
  List<DriveSong> _songs = [];
  String? _playingId;

  @override
  void initState() {
    super.initState();
    _autoConnect();
  }

  Future<void> _autoConnect() async {
    final driveService = context.read<GoogleDriveService>();
    if (!driveService.isConnected) {
      final ok = await driveService.tryAutoConnect();
      if (ok && mounted) await _loadSongs();
    } else {
      await _loadSongs();
    }
  }

  Future<void> _connect() async {
    final driveService = context.read<GoogleDriveService>();
    final ok = await driveService.connect();
    if (ok && mounted) await _loadSongs();
  }

  Future<void> _loadSongs() async {
    setState(() => _loadingSongs = true);
    final driveService = context.read<GoogleDriveService>();
    final songs = await driveService.listSongs();
    if (mounted)
      setState(() {
        _songs = songs;
        _loadingSongs = false;
      });
  }

  Future<void> _pickAndUpload() async {
    final driveService = context.read<GoogleDriveService>();

    final result = await FilePicker.platform
        .pickFiles(type: FileType.audio, allowMultiple: true);
    if (result == null || result.files.isEmpty) return;

    setState(() {
      _uploading = true;
      _uploadProgress = 0;
    });
    int uploaded = 0;

    for (final picked in result.files) {
      if (picked.path == null) continue;
      try {
        await driveService.uploadSong(
          file: File(picked.path!),
          onProgress: (p) => setState(
              () => _uploadProgress = (uploaded + p) / result.files.length),
        );
        uploaded++;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Error subiendo ${picked.name}: $e'),
              backgroundColor: Colors.red));
        }
      }
    }

    setState(() => _uploading = false);
    if (mounted && uploaded > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '✅ $uploaded canción${uploaded > 1 ? 'es subidas' : ' subida'} exitosamente'),
          backgroundColor: Colors.green));
      await _loadSongs();
    }
  }

  Future<void> _playSong(DriveSong song) async {
    final handler = context.read<MyAudioHandler>();
    final driveService = context.read<GoogleDriveService>();

    setState(() => _playingId = song.id);
    try {
      final localPath =
          await driveService.downloadToCache(song.id, song.fileName);
      if (localPath == null) throw Exception('No se pudo descargar');
      await handler.playSingleSong(
          MediaItem(id: localPath, title: song.title, artist: song.artist));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error reproduciendo: $e'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _playingId = null);
    }
  }

  Future<void> _deleteSong(DriveSong song) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Eliminar canción',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text('¿Eliminar "${song.title}" de tu Google Drive?',
            style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar',
                  style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm == true) {
      await context.read<GoogleDriveService>().deleteSong(song.id);
      await _loadSongs();
    }
  }

  @override
  Widget build(BuildContext context) {
    final driveService = context.watch<GoogleDriveService>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(driveService),
            if (!driveService.isConnected)
              _buildConnectPrompt(driveService)
            else ...[
              if (_uploading) _buildUploadProgress(),
              Expanded(child: _buildSongList()),
            ],
          ],
        ),
      ),
      floatingActionButton: driveService.isConnected
          ? FloatingActionButton.extended(
              heroTag: 'upload',
              onPressed: _uploading ? null : _pickAndUpload,
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.upload),
              label: const Text('Subir música',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildHeader(GoogleDriveService driveService) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Mi Nube', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 4),
          Text(
              driveService.isConnected
                  ? 'Google Drive · ${driveService.userEmail ?? ''}'
                  : 'Conecta tu Google Drive',
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis),
        ])),
        const SizedBox(width: 8),
        if (driveService.isConnected)
          IconButton(
              icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
              onPressed: _loadSongs),
      ]),
    );
  }

  Widget _buildConnectPrompt(GoogleDriveService driveService) {
    return Expanded(
        child: Center(
            child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.divider)),
            child: const Icon(Icons.add_to_drive,
                color: AppTheme.accent, size: 48)),
        const SizedBox(height: 24),
        Text('Conecta tu Google Drive',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(
            'Tu música se guardará en una carpeta "MusPlayFiles" en tu Google Drive. Solo tú puedes verla.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center),
        const SizedBox(height: 32),
        if (driveService.error != null)
          Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(driveService.error!,
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center)),
        SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: driveService.isLoading ? null : _connect,
              icon: driveService.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.add_to_drive, color: Colors.black),
              label: Text(
                  driveService.isLoading
                      ? 'Conectando...'
                      : 'Conectar Google Drive',
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
            )),
      ]),
    )));
  }

  Widget _buildUploadProgress() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Subiendo a Google Drive...',
              style: TextStyle(color: AppTheme.textPrimary)),
          Text('${(_uploadProgress * 100).toInt()}%',
              style: const TextStyle(color: AppTheme.accent)),
        ]),
        const SizedBox(height: 6),
        LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: AppTheme.surfaceLight,
            valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
            borderRadius: BorderRadius.circular(4)),
      ]),
    );
  }

  Widget _buildSongList() {
    if (_loadingSongs)
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.accent));
    if (_songs.isEmpty) {
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.cloud_upload_outlined,
            color: AppTheme.textSecondary, size: 64),
        const SizedBox(height: 16),
        Text('Sin canciones en la nube',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text('Sube tu música con el botón de abajo',
            style: Theme.of(context).textTheme.bodyMedium),
      ]));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _songs.length,
      itemBuilder: (context, i) {
        final song = _songs[i];
        return _DriveSongTile(
            song: song,
            isPlaying: _playingId == song.id,
            onTap: () => _playSong(song),
            onDelete: () => _deleteSong(song),
            onAddToPlaylist: () => AddToPlaylistSheet.show(
                context,
                PlaylistSong(
                  id: song.id,
                  title: song.title,
                  artist: song.artist,
                  source: 'drive',
                )));
      },
    );
  }
}

class _DriveSongTile extends StatelessWidget {
  final DriveSong song;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onAddToPlaylist;
  const _DriveSongTile(
      {required this.song,
      required this.isPlaying,
      required this.onTap,
      required this.onDelete,
      required this.onAddToPlaylist});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  color: isPlaying ? AppTheme.accentDim : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: isPlaying
                      ? Border.all(color: AppTheme.accent, width: 1.5)
                      : null),
              child: isPlaying
                  ? const Center(
                      child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: AppTheme.accent, strokeWidth: 2)))
                  : const Icon(Icons.cloud_done,
                      color: AppTheme.accent, size: 26)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color:
                            isPlaying ? AppTheme.accent : AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Text(song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ])),
          const SizedBox(width: 8),
          Text(song.sizeFormatted,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          IconButton(
              icon: const Icon(Icons.playlist_add_rounded,
                  color: AppTheme.textSecondary, size: 20),
              onPressed: onAddToPlaylist),
          IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppTheme.textSecondary, size: 20),
              onPressed: onDelete),
        ]),
      ),
    );
  }
}
