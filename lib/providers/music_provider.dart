import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../services/music_scan_service.dart';

enum ScanStatus { idle, loading, done, error }

class MusicProvider with ChangeNotifier {
  final MusicScanService _scanService = MusicScanService();

  List<Song> _songs = [];
  ScanStatus _status = ScanStatus.idle;
  String? _errorMsg;

  List<Song> get songs => _songs;
  ScanStatus get status => _status;
  String? get errorMsg => _errorMsg;
  bool get isLoading => _status == ScanStatus.loading;
  int get songCount => _songs.length;

  MusicProvider() {
    _init();
  }

  Future<void> _init() async {
    // Load cache instantly
    _songs = await _scanService.loadCachedSongs();
    notifyListeners();

    // Then do a full scan
    await _doScan();
  }

  Future<void> _doScan() async {
    _status = ScanStatus.loading;
    _errorMsg = null;
    notifyListeners();

    try {
      final result = await _scanService.scanForMusic();
      _songs = result.songs;
      _status = ScanStatus.done;
    } catch (e) {
      _errorMsg = e.toString();
      _status = ScanStatus.error;
    }
    notifyListeners();
  }

  /// Background rescan — silently updates if changes detected
  Future<void> backgroundRescan() async {
    final result = await _scanService.backgroundRescan();
    if (result != null) {
      _songs = result;
      notifyListeners();
    }
  }

  Future<void> rescan() => _doScan();

  Song? songAt(int index) {
    if (index >= 0 && index < _songs.length) return _songs[index];
    return null;
  }

  List<Song> getArtists() {
    final map = <String, List<Song>>{};
    for (final s in _songs) {
      map.putIfAbsent(s.displayArtist, () => []).add(s);
    }
    return map.keys
        .map((a) => map[a]!.first)
        .toList()
      ..sort((a, b) => a.displayArtist.compareTo(b.displayArtist));
  }

  List<Song> getSongsByArtist(String artist) =>
      _songs.where((s) => s.displayArtist == artist).toList();

  List<Song> getAlbums() {
    final map = <String, List<Song>>{};
    for (final s in _songs) {
      map.putIfAbsent(s.displayAlbum, () => []).add(s);
    }
    return map.keys
        .map((a) => map[a]!.first)
        .toList()
      ..sort((a, b) => a.displayAlbum.compareTo(b.displayAlbum));
  }

  List<Song> getSongsByAlbum(String album) =>
      _songs.where((s) => s.displayAlbum == album).toList();

  List<Song> search(String query) {
    final q = query.toLowerCase();
    return _songs
        .where((s) =>
            s.displayTitle.toLowerCase().contains(q) ||
            s.displayArtist.toLowerCase().contains(q) ||
            s.displayAlbum.toLowerCase().contains(q))
        .toList();
  }
}
