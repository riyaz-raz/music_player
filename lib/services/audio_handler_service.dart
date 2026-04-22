import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import '../models/song.dart';

class AudioHandlerService extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  List<Song> _playlist = [];
  int _currentIndex = -1;
  bool _shuffle = false;
  bool _repeatAll = true;

  void Function(int index)? onIndexChanged;

  List<Song> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  bool get isShuffle => _shuffle;
  bool get isRepeatAll => _repeatAll;

  AudioHandlerService() {
    _listenToAll();
  }

  AudioPlayer get player => _player;

  void _listenToAll() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _handleCompletion();
      }
    });

    _player.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
      ));
    });
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: _mapState(_player.processingState),
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  AudioProcessingState _mapState(ProcessingState s) {
    switch (s) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

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
  Future<void> skipToNext() => _goTo(_nextIndex());

  @override
  Future<void> skipToPrevious() {
    if (_player.position.inSeconds > 3) {
      return _player.seek(Duration.zero);
    }
    return _goTo(_prevIndex());
  }

  void setPlaylist(List<Song> songs, {int startIndex = 0}) {
    _playlist = List.unmodifiable(songs);
    if (startIndex < 0 || startIndex >= _playlist.length) startIndex = 0;
    queue.add(_playlist.map(_songToMediaItem).toList());
  }

  Future<void> playSongAt(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    _currentIndex = index;
    final song = _playlist[index];
    mediaItem.add(_songToMediaItem(song));
    await _player.setUrl(song.uri);
    await _player.play();
    onIndexChanged?.call(index);
  }

  void setShuffle(bool value) {
    _shuffle = value;
    playbackState.add(playbackState.value);
  }

  void setRepeatAll(bool value) {
    _repeatAll = value;
    playbackState.add(playbackState.value);
  }

  void clearPlaylist() {
    _playlist = [];
    _currentIndex = -1;
    queue.add([]);
  }

  int _nextIndex() {
    if (_playlist.isEmpty) return 0;
    if (_shuffle) {
      return DateTime.now().millisecondsSinceEpoch % _playlist.length;
    }
    if (_currentIndex < _playlist.length - 1) return _currentIndex + 1;
    return _repeatAll ? 0 : _currentIndex;
  }

  int _prevIndex() {
    if (_playlist.isEmpty) return 0;
    if (_currentIndex > 0) return _currentIndex - 1;
    return _repeatAll ? _playlist.length - 1 : 0;
  }

  Future<void> _goTo(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    await playSongAt(index);
  }

  Future<void> _handleCompletion() async {
    final next = _nextIndex();
    if (next != _currentIndex || _repeatAll) {
      await _goTo(next);
    }
  }

  MediaItem _songToMediaItem(Song s) => MediaItem(
    id: s.uri,
    title: s.displayTitle,
    artist: s.displayArtist,
    album: s.displayAlbum,
    duration: Duration(milliseconds: s.durationMs),
  );
}

Future<AudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => AudioHandlerService(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.zai.music_player.audio',
      androidNotificationChannelName: 'Music Player',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
}
