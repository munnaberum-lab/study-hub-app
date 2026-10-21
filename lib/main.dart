import 'package:flutter/material.dart';

import 'api.dart';
import 'home.dart';
import 'library.dart';
import 'shorts.dart';
import 'videos.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Koi error aaye to blank/atka hua screen ki jagah text dikhe.
  ErrorWidget.builder = (details) => Material(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Text('Error: ${details.exceptionAsString()}', style: const TextStyle(color: Colors.red, fontSize: 13)),
          ),
        ),
      );
  runApp(const Boot());
}

/// Pehle turant screen dikhata hai, phir saved login load karta hai (kabhi atakta nahi).
class Boot extends StatefulWidget {
  const Boot({super.key});
  @override
  State<Boot> createState() => _BootState();
}

class _BootState extends State<Boot> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    Api.init().timeout(const Duration(seconds: 5)).catchError((_) {}).whenComplete(() {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return const StudyHubApp();
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text('Study Hub'),
          ]),
        ),
      ),
    );
  }
}

class StudyHubApp extends StatelessWidget {
  const StudyHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0E0E13);
    const card = Color(0xFF1C1B26);
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF7C4DFF),
      brightness: Brightness.dark,
    ).copyWith(primary: const Color(0xFF9C6BFF), surface: bg);
    final dark = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      appBarTheme: const AppBarTheme(backgroundColor: bg, elevation: 0, scrolledUnderElevation: 0),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF14131B),
        indicatorColor: const Color(0x339C6BFF),
        height: 66,
        labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: card,
        selectedColor: const Color(0x449C6BFF),
        side: const BorderSide(color: Colors.white12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: dark,
      darkTheme: dark,
      home: const Shell(),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _i, children: [
        HomeScreen(onSeeShorts: () => setState(() => _i = 1), onSeeVideos: () => setState(() => _i = 2)),
        ShortsScreen(active: _i == 1),
        const VideosScreen(),
        const LibraryScreen(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (i) => setState(() => _i = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.smartphone), label: 'Shorts'),
          NavigationDestination(icon: Icon(Icons.video_library_outlined), selectedIcon: Icon(Icons.video_library), label: 'Videos'),
          NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Library'),
        ],
      ),
    );
  }
}
