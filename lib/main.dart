import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'ad_manager.dart';
import 'game/models/game_progress.dart';
import 'screens/main_menu_screen.dart';

void main() {
  // 1. Ensure Flutter bindings are ready at root level
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Modern crash-proof error handlers (prevents fatal app termination)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter error caught safely: ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform dispatcher error handled safely: $error');
    return true; // Handled, do not crash process
  };

  // 3. Initialize persistent game progress in background/safe mode
  GameProgress().init().catchError((e) {
    debugPrint('GameProgress init error caught: $e');
  });

  // 4. Initialize AdMob via AdManager safely
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    unawaited(AdManager.instance.initialize());
  }

  // 5. Mount the app UI immediately
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Safely show App Open Ad when returning to the app from background
      AdManager.instance.showAppOpenAd();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bubble by Athi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6C5CE7),
        scaffoldBackgroundColor: const Color(0xFF1E272E),
      ),
      home: const MainMenuScreen(),
    );
  }
}
