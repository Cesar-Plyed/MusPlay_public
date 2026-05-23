import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';

import '../../../../core/theme/app_theme.dart';

class AlbumArtWidget extends StatelessWidget {
  final MediaItem mediaItem;

  const AlbumArtWidget({super.key, required this.mediaItem});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accent.withOpacity(0.15),
                blurRadius: 40,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: mediaItem.artUri != null
                ? Image.network(
                    mediaItem.artUri.toString(),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _defaultArt(),
                  )
                : _defaultArt(),
          ),
        ),
      ),
    );
  }

  Widget _defaultArt() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.surfaceLight, AppTheme.surface],
        ),
      ),
      child: const Center(
        child: Icon(Icons.music_note, color: AppTheme.accent, size: 80),
      ),
    );
  }
}
