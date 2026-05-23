import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:provider/provider.dart';

import '../../../services/audio_handler.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/album_art_widget.dart';
import 'widgets/progress_bar_widget.dart';
import 'widgets/player_controls_widget.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final handler = context.read<MyAudioHandler>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: StreamBuilder<MediaItem?>(
          stream: handler.mediaItem,
          builder: (context, snapshot) {
            final mediaItem = snapshot.data;

            if (mediaItem == null) {
              return _buildEmpty(context);
            }

            return Column(
              children: [
                _buildTopBar(context, mediaItem),
                Expanded(child: AlbumArtWidget(mediaItem: mediaItem)),
                _buildSongInfo(context, mediaItem),
                ProgressBarWidget(handler: handler),
                PlayerControlsWidget(handler: handler),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.divider, width: 2),
                  ),
                  child: const Icon(Icons.music_note, color: AppTheme.accent, size: 52),
                ),
                const SizedBox(height: 24),
                Text('Sin reproducción',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Selecciona una canción desde la biblioteca',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context, MediaItem item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Reproduciendo',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(letterSpacing: 1.5),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOptions(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSongInfo(BuildContext context, MediaItem item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  item.artist ?? 'Artista desconocido',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          _FavoriteButton(),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _OptionsSheet(),
    );
  }
}

class _FavoriteButton extends StatefulWidget {
  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton> {
  bool _isFav = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _isFav ? Icons.favorite : Icons.favorite_border,
        color: _isFav ? AppTheme.accent : AppTheme.textSecondary,
      ),
      onPressed: () => setState(() => _isFav = !_isFav),
    );
  }
}

class _OptionsSheet extends StatelessWidget {
  const _OptionsSheet();

  @override
  Widget build(BuildContext context) {
    final options = [
      (Icons.add_to_queue, 'Agregar a cola'),
      (Icons.share, 'Compartir'),
      (Icons.info_outline, 'Info de la canción'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: options.map((o) {
          return ListTile(
            leading: Icon(o.$1, color: AppTheme.accent),
            title: Text(o.$2,
                style: const TextStyle(color: AppTheme.textPrimary)),
            onTap: () => Navigator.pop(context),
          );
        }).toList(),
      ),
    );
  }
}
