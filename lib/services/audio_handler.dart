import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'preferences_service.dart';

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final _preferencesService = PreferencesService();

  MyAudioHandler() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    _player.currentIndexStream.listen((index) {
      if (index != null && queue.value.isNotEmpty) {
        final mediaItem = queue.value[index];
        this.mediaItem.add(mediaItem);
        _saveCurrentSong(mediaItem);
      }
    });

    _player.sequenceStateStream.listen((state) {
      final sequence = state.effectiveSequence;
      if (sequence.isEmpty) return;

      final items = sequence
          .where((s) => s.tag is MediaItem) // ← solo los que sean MediaItem
          .map((s) => s.tag as MediaItem)
          .toList();

      if (items.isNotEmpty) queue.add(items);
    });

    _player.positionStream.listen((_) {
      _preferencesService.saveLastPosition(_player.position.inMilliseconds);
    });
  }

  Future<void> _saveCurrentSong(MediaItem item) async {
    await _preferencesService.saveLastSong(
      id: item.id,
      title: item.title,
      artist: item.artist ?? 'Artista desconocido',
      url: item.id,
    );
  }

  Future<void> restoreLastSong() async {
    try {
      final lastSong = await _preferencesService.getLastSong();
      if (lastSong == null) return;

      final url = lastSong['url'] ?? '';
      if (url.isEmpty) return;

      final mediaItem = MediaItem(
        id: url,
        title: lastSong['title'] ?? 'Sin título',
        artist: lastSong['artist'] ?? 'Artista desconocido',
      );

      // ✅ Fix: cargar sin reproducir automáticamente al restaurar
      this.mediaItem.add(mediaItem);
      await _player.setUrl(url);

      final lastPosition = await _preferencesService.getLastPosition();
      if (lastPosition > 0) {
        await _player.seek(Duration(milliseconds: lastPosition));
      }
      // No llamar play() — solo restaurar el estado visual
    } catch (e) {
      print('Error restaurando última canción: $e');
      // No relanzar — si falla la restauración la app sigue funcionando
    }
  }

  // ── Controles básicos ─────────────────────────────────────────────────────

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await _player.setShuffleModeEnabled(
      shuffleMode == AudioServiceShuffleMode.all,
    );
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    await _player.setLoopMode(
      {
        AudioServiceRepeatMode.none: LoopMode.off,
        AudioServiceRepeatMode.one: LoopMode.one,
        AudioServiceRepeatMode.all: LoopMode.all,
      }[repeatMode]!,
    );
  }

  // ── Cargar canciones ──────────────────────────────────────────────────────

  Future<void> loadSongs(List<MediaItem> items, {int initialIndex = 0}) async {
    if (items.isEmpty) return; // ✅ Fix: no cargar lista vacía
    queue.add(items);
    final audioSources = items.map((item) {
      return AudioSource.uri(Uri.parse(item.id), tag: item);
    }).toList();

    await _player.setAudioSource(
      ConcatenatingAudioSource(children: audioSources),
      initialIndex: initialIndex,
    );
  }

  Future<void> playSingleSong(MediaItem item) async {
    if (item.id.isEmpty) return; // ✅ Fix: no cargar ID vacío
    mediaItem.add(item);
    await _player.setUrl(item.id);
    play();
  }

  // ── Streams públicos ──────────────────────────────────────────────────────

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<bool> get playingStream => _player.playingStream;
  Stream<LoopMode> get loopModeStream => _player.loopModeStream;
  Stream<bool> get shuffleModeStream => _player.shuffleModeEnabledStream;
  bool get playing => _player.playing;

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        _player.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }
}
