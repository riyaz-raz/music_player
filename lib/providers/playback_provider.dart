import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../services/audio_handler_service.dart';

enum RepeatMode { off, all, one }

class PlaybackProvider extends ChangeNotifier {
  final AudioHandlerService _handler;

  PlaybackProvider(this._handler) {
    _handler.playbackState.listen((_) => notifyListeners());
    _handler.mediaItem.listen((_) => notifyListeners());
    _handler.player.positionStream.listen((_) => notifyListeners());
    _handler.player.durationStream.listen((_) => notifyListeners());
    _handler.onIndexChanged = (_) => notifyListeners();
  }

  AudioHandlerService get handler => _handler;
  AudioPlayer get player => _handler.player;

  Song? get currentSong {
    final idx = _handler.currentIndex;
    if (idx >= 0 && idx < _handler.playlist.length) {
      return _handler.playlist[idx];
    }
    return null;
  }

  bool get isPlaying => _handler.player.playing;
  bool get hasQueue => _handler.playlist.isNotEmpty;
  Duration get position => _handler.player.position;
  Duration? get duration => _handler.player.duration;
  double get progress => duration != null && duration!.inMilliseconds > 0
      ? (position.inMilliseconds / duration!.inMilliseconds).clamp(0.0, 1.0)
      : 0.0;
  int get currentIndex => _handler.currentIndex;
  List<Song> get playlist => _handler.playlist;
  bool get shuffle => _handler.isShuffle;
  bool get repeatAll => _handler.isRepeatAll;
  RepeatMode get repeatMode =>
      _handler.isRepeatAll ? RepeatMode.all : RepeatMode.off;

  Future<void> playPause() async {
    if (_handler.player.playing) {
      await _handler.pause();
    } else {
      await _handler.play();
    }
  }

  Future<void> seekTo(Duration pos) => _handler.seek(pos);
  Future<void> skipNext() => _handler.skipToNext();
  Future<void> skipPrevious() => _handler.skipToPrevious();

  Future<void> playSongFromList(List<Song> songs, int index) async {
    _handler.setPlaylist(songs, startIndex: index);
    await _handler.playSongAt(index);
  }

  void toggleShuffle() {
    _handler.setShuffle(!_handler.isShuffle);
    notifyListeners();
  }

  void cycleRepeat() {
    _handler.setRepeatAll(!_handler.isRepeatAll);
    notifyListeners();
  }

  void clearQueue() {
    _handler.clearPlaylist();
    notifyListeners();
  }

  void reorderPlaylist(int oldIndex, int newIndex) {
    final songs = List<Song>.from(_handler.playlist);
    if (oldIndex < newIndex) newIndex -= 1;
    final item = songs.removeAt(oldIndex);
    songs.insert(newIndex, item);
    _handler.setPlaylist(songs, startIndex: _handler.currentIndex);
    notifyListeners();
  }
}
