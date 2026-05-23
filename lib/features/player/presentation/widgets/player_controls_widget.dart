import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../services/audio_handler.dart';
import '../../../../core/theme/app_theme.dart';

class PlayerControlsWidget extends StatelessWidget {
  final MyAudioHandler handler;

  const PlayerControlsWidget({super.key, required this.handler});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ShuffleButton(handler: handler),
          _SkipButton(
            icon: Icons.skip_previous_rounded,
            onTap: () => handler.skipToPrevious(),
          ),
          _PlayPauseButton(handler: handler),
          _SkipButton(
            icon: Icons.skip_next_rounded,
            onTap: () {
              handler.skipToNext();
            },
          ),
          _RepeatButton(handler: handler),
        ],
      ),
    );
  }
}

// ── Play / Pause ──────────────────────────────────────────────────────────────

class _PlayPauseButton extends StatelessWidget {
  final MyAudioHandler handler;
  const _PlayPauseButton({required this.handler});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: handler.playingStream,
      builder: (context, snap) {
        final playing = snap.data ?? false;
        return GestureDetector(
          onTap: () => playing ? handler.pause() : handler.play(),
          child: Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accent,
            ),
            child: Icon(
              playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: AppTheme.background,
              size: 36,
            ),
          ),
        );
      },
    );
  }
}

// ── Skip buttons ──────────────────────────────────────────────────────────────

class _SkipButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SkipButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: 44,
      icon: Icon(icon, color: AppTheme.textPrimary),
      onPressed: onTap,
    );
  }
}

// ── Shuffle ───────────────────────────────────────────────────────────────────

class _ShuffleButton extends StatelessWidget {
  final MyAudioHandler handler;
  const _ShuffleButton({required this.handler});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: handler.shuffleModeStream,
      builder: (context, snap) {
        final enabled = snap.data ?? false;
        return IconButton(
          icon: Icon(
            Icons.shuffle_rounded,
            color: enabled ? AppTheme.accent : AppTheme.textSecondary,
            size: 22,
          ),
          onPressed: () => handler.setShuffleMode(
            enabled ? AudioServiceShuffleMode.none : AudioServiceShuffleMode.all,
          ),
        );
      },
    );
  }
}

// ── Repeat ────────────────────────────────────────────────────────────────────

class _RepeatButton extends StatelessWidget {
  final MyAudioHandler handler;
  const _RepeatButton({required this.handler});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LoopMode>(
      stream: handler.loopModeStream,
      builder: (context, snap) {
        final mode = snap.data ?? LoopMode.off;
        final (icon, color) = switch (mode) {
          LoopMode.off => (Icons.repeat_rounded, AppTheme.textSecondary),
          LoopMode.all => (Icons.repeat_rounded, AppTheme.accent),
          LoopMode.one => (Icons.repeat_one_rounded, AppTheme.accent),
        };

        return IconButton(
          icon: Icon(icon, color: color, size: 22),
          onPressed: () {
            final next = switch (mode) {
              LoopMode.off => AudioServiceRepeatMode.all,
              LoopMode.all => AudioServiceRepeatMode.one,
              _ => AudioServiceRepeatMode.none,
            };
            handler.setRepeatMode(next);
          },
        );
      },
    );
  }
}
