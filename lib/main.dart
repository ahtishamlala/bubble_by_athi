import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app_open_ad_manager.dart';
import 'game/models/game_progress.dart';
import 'screens/main_menu_screen.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('Flutter error caught: ${details.exceptionAsString()}');
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('Platform dispatcher error caught: $error');
      return true;
    };

    try {
      await GameProgress().init();
    } catch (e) {
      debugPrint('GameProgress init error: $e');
    }

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        await MobileAds.instance.initialize();
      } catch (e) {
        debugPrint('MobileAds initialization error: $e');
      }
    }

    runApp(const MyApp());
  }, (error, stack) {
    debugPrint('Top-level zone error: $error');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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

/// App Open Ad load + show karta hai, uske baad MainMenuScreen par le jata hai.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  final AppOpenAdManager _appOpenAdManager = AppOpenAdManager();
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    try {
      _appOpenAdManager.loadAd(onAdLoaded: _showAdAndProceed);
    } catch (e) {
      debugPrint('SplashGate loadAd error: $e');
    }

    // 2 second baad automatically game menu me le jaye bina kisi rukawat ke
    Future.delayed(const Duration(milliseconds: 2000), _showAdAndProceed);
  }

  void _showAdAndProceed() {
    if (_navigated) return;
    _navigated = true;

    try {
      _appOpenAdManager.showAdIfAvailable(
        onComplete: _goToMainMenu,
      );
    } catch (e) {
      debugPrint('Error showing ad: $e');
      _goToMainMenu();
    }
  }

  void _goToMainMenu() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainMenuScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2C3E50), Color(0xFF341F97), Color(0xFF1E272E)],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bubble_chart_rounded, color: Color(0xFF1DD1A1), size: 84),
              SizedBox(height: 16),
              Text(
                'BUBBLE by ATHI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Loading Fun & Bubbles...',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              SizedBox(height: 28),
              CircularProgressIndicator(
                color: Color(0xFF1DD1A1),
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
