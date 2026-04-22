import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'providers/music_provider.dart';
import 'providers/playback_provider.dart';
import 'services/audio_handler_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize audio service (required for background playback)
  final audioHandler = await initAudioService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => MusicProvider()),
        ChangeNotifierProvider(
          create: (_) => PlaybackProvider(audioHandler as AudioHandlerService),
        ),
      ],
      child: const MusicPlayerApp(),
    ),
  );
}

class MusicPlayerApp extends StatelessWidget {
  const MusicPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Music Player',
      debugShowCheckedModeBanner: false,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: themeProvider.themeMode,
      home: const HomeScreen(),
    );
  }
}

// ──────────── Light Theme ────────────

final ThemeData _lightTheme = ThemeData(
  brightness: Brightness.light,
  colorSchemeSeed: const Color(0xFF6750A4),
  useMaterial3: true,
  scaffoldBackgroundColor: const Color(0xFFFFFBFE),
  appBarTheme: const AppBarTheme(
    elevation: 0,
    scrolledUnderElevation: 2,
    centerTitle: true,
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    color: const Color(0xFFF5F0FF),
  ),
  listTileTheme: const ListTileThemeData(
    contentPadding: EdgeInsets.symmetric(horizontal: 16),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
  ),
);

// ──────────── Dark Theme ────────────

final ThemeData _darkTheme = ThemeData(
  brightness: Brightness.dark,
  colorSchemeSeed: const Color(0xFF6750A4),
  useMaterial3: true,
  scaffoldBackgroundColor: const Color(0xFF0F0D13),
  appBarTheme: const AppBarTheme(
    elevation: 0,
    scrolledUnderElevation: 2,
    centerTitle: true,
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    color: const Color(0xFF1D1B20),
  ),
  listTileTheme: const ListTileThemeData(
    contentPadding: EdgeInsets.symmetric(horizontal: 16),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Color(0xFF1D1B20),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
  ),
);
