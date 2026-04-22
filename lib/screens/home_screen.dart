import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../providers/playback_provider.dart';
import '../providers/theme_provider.dart';
import '../models/song.dart';
import 'now_playing_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final playbackProvider = context.watch<PlaybackProvider>();
    final songs = _isSearching
        ? musicProvider.search(_searchController.text)
        : musicProvider.songs;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search songs, artists, albums...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onChanged: (_) => setState(() {}),
              )
            : const Text('Music Player'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
      body: _buildBody(musicProvider, songs, playbackProvider),
      bottomNavigationBar:
          playbackProvider.hasQueue ? const _MiniPlayer() : null,
    );
  }

  Widget _buildBody(
      MusicProvider provider, List<Song> songs, PlaybackProvider playbackProvider) {
    if (provider.status == ScanStatus.loading && provider.songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Scanning for music...',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    if (provider.status == ScanStatus.error && provider.songs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 64, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Could not access music files',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                provider.errorMsg ?? 'Unknown error',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => provider.rescan(),
                icon: const Icon(Icons.refresh),
                label: const Text('Grant Permission & Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_off_rounded,
                size: 80,
                color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              'No music found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Add music files to your device and rescan',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => provider.rescan(),
              icon: const Icon(Icons.refresh),
              label: const Text('Rescan'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text(
                _isSearching
                    ? '${songs.length} result${songs.length != 1 ? 's' : ''}'
                    : '${songs.length} song${songs.length != 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const Spacer(),
              if (!_isSearching)
                TextButton.icon(
                  onPressed: () => provider.rescan(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Rescan'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: songs.length,
            itemExtent: 72,
            itemBuilder: (context, index) {
              final song = songs[index];
              final isActive = playbackProvider.hasQueue &&
                  playbackProvider.currentSong?.id == song.id;
              return _SongTile(
                song: song,
                isActive: isActive,
                onTap: () => _playSong(context, songs, index),
              );
            },
          ),
        ),
      ],
    );
  }

  void _playSong(BuildContext context, List<Song> songs, int index) {
    final playbackProvider = context.read<PlaybackProvider>();
    playbackProvider.playSongFromList(songs, index);
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _SettingsSheet(),
    );
  }
}

// ──────────── Song tile ────────────

class _SongTile extends StatelessWidget {
  final Song song;
  final bool isActive;
  final VoidCallback onTap;

  const _SongTile(
      {required this.song, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: _buildArtwork(colorScheme),
      title: Text(
        song.displayTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isActive ? colorScheme.primary : colorScheme.onSurface,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      subtitle: Text(
        '${song.displayArtist} · ${song.formattedDuration}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall,
      ),
      trailing: isActive
          ? SizedBox(
              width: 20,
              height: 20,
              child: _PlayingBars(color: colorScheme.primary),
            )
          : const Icon(Icons.play_arrow_rounded, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildArtwork(ColorScheme colorScheme) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isActive
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.music_note_rounded,
        color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
        size: 24,
      ),
    );
  }
}

// ──────────── Animated playing bars ────────────

class _PlayingBars extends StatefulWidget {
  final Color color;
  const _PlayingBars({required this.color});

  @override
  State<_PlayingBars> createState() => _PlayingBarsState();
}

class _PlayingBarsState extends State<_PlayingBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _BarsPainter(
            animation: _controller.value,
            color: widget.color,
          ),
          size: const Size(20, 20),
        );
      },
    );
  }
}

class _BarsPainter extends CustomPainter {
  final double animation;
  final Color color;
  _BarsPainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width / 5;
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.7;

    for (int i = 0; i < 3; i++) {
      final offset = i * 0.3;
      final h =
          (0.3 + 0.7 * ((animation * 2 + offset) % 1)) * size.height;
      final x = w * (1 + i * 1.5);
      canvas.drawLine(
          Offset(x, size.height), Offset(x, size.height - h), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter old) => true;
}

// ──────────── Mini player ────────────

class _MiniPlayer extends StatelessWidget {
  const _MiniPlayer();

  @override
  Widget build(BuildContext context) {
    final playbackProvider = context.watch<PlaybackProvider>();
    final song = playbackProvider.currentSong;
    final colorScheme = Theme.of(context).colorScheme;
    final progress = playbackProvider.progress;

    if (song == null) return const SizedBox.shrink();

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: progress,
            minHeight: 2,
            backgroundColor: colorScheme.surfaceContainerHighest,
          ),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.music_note,
                  color: colorScheme.primary, size: 20),
            ),
            title: Text(
              song.displayTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              song.displayArtist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(playbackProvider.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded),
                  onPressed: () => playbackProvider.playPause(),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded),
                  onPressed: () => playbackProvider.skipNext(),
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const NowPlayingScreen(),
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ──────────── Settings sheet ────────────

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final musicProvider = context.watch<MusicProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Settings', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),

          // Theme
          Text('Theme', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<AppThemeMode>(
            segments: const [
              ButtonSegment(value: AppThemeMode.system, label: Text('System')),
              ButtonSegment(value: AppThemeMode.light, label: Text('Light')),
              ButtonSegment(value: AppThemeMode.dark, label: Text('Dark')),
            ],
            selected: {themeProvider.mode},
            onSelectionChanged: (selected) =>
                themeProvider.setMode(selected.first),
          ),
          const SizedBox(height: 24),

          // Rescan
          ListTile(
            leading: const Icon(Icons.folder_copy),
            title: const Text('Rescan for music'),
            subtitle: Text('${musicProvider.songCount} songs indexed'),
            trailing: musicProvider.isLoading
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
            onTap: musicProvider.isLoading
                ? null
                : () {
                    musicProvider.rescan();
                    Navigator.pop(context);
                  },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
