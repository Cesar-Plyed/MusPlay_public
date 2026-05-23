import 'package:flutter/material.dart';
import '../../../../services/audio_handler.dart';
import '../../../../core/theme/app_theme.dart';

class ProgressBarWidget extends StatelessWidget {
  final MyAudioHandler handler;

  const ProgressBarWidget({super.key, required this.handler});

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: handler.positionStream,
      builder: (context, posSnap) {
        final position = posSnap.data ?? Duration.zero;

        return StreamBuilder<Duration?>(
          stream: handler.durationStream,
          builder: (context, durSnap) {
            final duration = durSnap.data ?? Duration.zero;
            final progress = duration.inMilliseconds > 0
                ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
                : 0.0;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    ),
                    child: Slider(
                      value: progress,
                      onChanged: (v) {
                        final seekPos = Duration(
                          milliseconds: (v * duration.inMilliseconds).round(),
                        );
                        handler.seek(seekPos);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_format(position),
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12)),
                        Text(_format(duration),
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
