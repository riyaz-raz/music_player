import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';

class MusicScanService {
  static const _cacheKey = 'music_cache';

  final OnAudioQuery _audioQuery = OnAudioQuery();

  /// Load cached songs instantly
  Future<List<Song>> loadCachedSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return [];
    try {
      final cache = SongCache.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      return cache.songs;
    } catch (_) {
      return [];
    }
  }

  /// Full scan — returns songs and whether cache changed
  Future<({List<Song> songs, bool changed})> scanForMusic() async {
    final granted = await _audioQuery.permissionsRequest();
    if (!granted) {
      throw Exception('Storage permission denied');
    }

    final songs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      // uriType defaults to EXTERNAL
    );

    final mapped = songs
        .where((s) => (s.duration ?? 0) > 5000 && s.data.isNotEmpty)
        .map((s) => Song(
              id: s.id.toString(),
              title: s.title,
              artist: s.artist ?? 'Unknown Artist',
              album: s.album ?? 'Unknown Album',
              uri: s.data,
              durationMs: s.duration ?? 0,
              // album art will be queried separately when needed
              albumArt: null,
            ))
        .toList();

    // Build hash to detect changes quickly
    final hashBuffer = StringBuffer();
    for (final s in mapped) {
      hashBuffer.write('${s.id}:${s.durationMs};');
    }
    final newHash = hashBuffer.toString().hashCode;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    int? oldHash;
    if (raw != null) {
      try {
        final cache = SongCache.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        oldHash = cache.hashCodeValue;
      } catch (_) {}
    }

    final changed = oldHash != newHash;

    if (changed || raw == null) {
      final cache = SongCache(songs: mapped, cachedAt: DateTime.now(), hashCodeValue: newHash);
      await prefs.setString(_cacheKey, jsonEncode(cache.toJson()));
    }

    return (songs: mapped, changed: changed);
  }

  /// Query artwork bytes for a song's album id
  Future<Uint8List?> queryAlbumArt(int albumId) async {
    try {
      return await _audioQuery.queryArtwork(
        albumId,
        ArtworkType.ALBUM,
        format: ArtworkFormat.PNG,
        size: 200,
      );
    } catch (_) {
      return null;
    }
  }

  /// Background rescan — silently updates cache, returns new list if changed
  Future<List<Song>?> backgroundRescan() async {
    try {
      final result = await scanForMusic();
      return result.changed ? result.songs : null;
    } catch (_) {
      return null;
    }
  }
}
