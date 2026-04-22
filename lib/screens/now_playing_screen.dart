import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/playback_provider.dart';
import '../models/song.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playback = context.watch<PlaybackProvider>();
    final song = playback.currentSong;
    final colorScheme = Theme.of(context).colorScheme;

    if (song == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Now Playing'),
        ),
        body: Center(
          child: Text('No song playing',
              style: Theme.of(context).textTheme.bodyLarge),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down),
                    iconSize: 32,
                    onPressed: () => Navigator.pop(context),
                  ),
                  Column(
                    children: [
                      const Text('NOW PLAYING',
                          style:
                              TextStyle(fontSize: 11, letterSpacing: 1.2)),
                      const SizedBox(height: 2),
                      Text(song.displayAlbum,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showQueueSheet(context, playback),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // Album art
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: _AlbumArt(song: song),
            ),

            const Spacer(flex: 3),

            // Song info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          song.displayTitle,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (playback.hasQueue)
                        IconButton(
                          icon: Icon(playback.shuffle
                              ? Icons.shuffle_rounded
                              : Icons.shuffle),
                          color: playback.shuffle
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          onPressed: () => playback.toggleShuffle(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      song.displayArtist,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Seek bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _SeekBar(playback: playback),
            ),

            // Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
              child: _Controls(playback: playback),
            ),
          ],
        ),
      ),
    );
  }

  void _showQueueSheet(BuildContext context, PlaybackProvider playback) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.queue_music_rounded, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Playing Queue',
                      style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  Text('${playback.playlist.length} songs',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: playback.playlist.length,
                itemExtent: 64,
                itemBuilder: (context, index) {
                  final s = playback.playlist[index];
                  final isActive = index == playback.currentIndex;
                  return ListTile(
                    dense: true,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isActive
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: isActive
                          ? Icon(Icons.equalizer_rounded,
                              color: colorScheme.primary, size: 18)
                          : Text(
                              '${index + 1}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                    ),
                    title: Text(
                      s.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.normal,
                        color: isActive ? colorScheme.primary : null,
                      ),
                    ),
                    subtitle: Text(
                      s.displayArtist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: Text(
                      s.formattedDuration,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    onTap: () {
                      playback.playSongFromList(playback.playlist, index);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────── Album Art ────────────

class _AlbumArt extends StatelessWidget {
  final Song song;
  const _AlbumArt({required this.song});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width - 80;
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.surfaceContainerHighest,
          ],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          size: 80,
          color: colorScheme.primary.withOpacity(0.5),
        ),
      ),
    );
  }
}

// ──────────── Seek Bar ────────────

class _SeekBar extends StatefulWidget {
  final PlaybackProvider playback;
  const _SeekBar({required this.playback});

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  bool _dragging = false;
  double _dragValue = 0;

  @override
  Widget build(BuildContext context) {
    final playback = widget.playback;
    final duration = playback.duration;
    final colorScheme = Theme.of(context).colorScheme;

    if (duration == null) return const SizedBox(height: 24);

    final current = _dragging
        ? Duration(
            milliseconds: (_dragValue * duration.inMilliseconds).round())
        : playback.position;

    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3,
            thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape:
                const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: colorScheme.primary,
            inactiveTrackColor: colorScheme.surfaceContainerHighest,
            thumbColor: colorScheme.primary,
          ),
          child: Slider(
            value: _dragging ? _dragValue : playback.progress,
            onChangeStart: (_) => setState(() => _dragging = true),
            onChanged: (v) => setState(() => _dragValue = v),
            onChangeEnd: (v) {
              setState(() => _dragging = false);
              playback.seekTo(Duration(
                  milliseconds: (v * duration.inMilliseconds).round()));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(current),
                  style: Theme.of(context).textTheme.bodySmall),
              Text(_formatDuration(duration),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}

// ──────────── Controls ────────────

class _Controls extends StatelessWidget {
  final PlaybackProvider playback;
  const _Controls({required this.playback});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(
            playback.repeatAll
                ? Icons.repeat_rounded
                : Icons.repeat,
            color: playback.repeatAll ? colorScheme.primary : null,
          ),
          iconSize: 24,
          onPressed: () => playback.cycleRepeat(),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded),
          iconSize: 36,
          onPressed: () => playback.skipPrevious(),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              playback.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: colorScheme.onPrimary,
              size: 36,
            ),
            iconSize: 48,
            onPressed: () => playback.playPause(),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.skip_next_rounded),
          iconSize: 36,
          onPressed: () => playback.skipNext(),
        ),
        const SizedBox(width: 8),
        const SizedBox(width: 24),
      ],
    );
  }
}
