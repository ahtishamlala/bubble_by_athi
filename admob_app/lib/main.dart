import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app_open_ad_manager.dart';
import 'game/models/game_progress.dart';
import 'screens/main_menu_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GameProgress().init();

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint('MobileAds initialization error: $e');
    }
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bubble Hit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6C5CE7),
        scaffoldBackgroundColor: const Color(0xFF1E272E),
        fontFamily: 'Roboto',
      ),
      home: const SplashGate(),
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
    _appOpenAdManager.loadAd(onAdLoaded: _showAdAndProceed);

    // 2.5 second baad bhi app aage badh jaye agar ad delay ho
    Future.delayed(const Duration(milliseconds: 2500), _showAdAndProceed);
  }

  void _showAdAndProceed() {
    if (_navigated) return;
    _navigated = true;
    _appOpenAdManager.showAdIfAvailable(
      onComplete: () {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainMenuScreen()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_rounded, color: Colors.white, size: 72),
            SizedBox(height: 16),
            Text(
              'AdMob Mediation App',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
