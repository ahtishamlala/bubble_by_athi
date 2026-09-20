import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'ad_manager.dart';
import 'core/constants/app_constants.dart';
import 'core/services/arcade_hub_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/referral_service.dart';
import 'core/services/security_service.dart';
import 'core/services/wallet_service.dart';
import 'core/theme/app_theme.dart';
import 'game/models/game_progress.dart';
import 'screens/hub_dashboard_screen.dart';

void main() async {
  // 1. Ensure Flutter bindings are ready at root level
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Crash-proof error handlers (prevents fatal app termination)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter error caught safely: ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform dispatcher error handled safely: $error');
    return true; // Handled, do not crash process
  };

  // 3. Initialize Core Platform Services in safe mode
  try {
    await SecurityService.instance.init();
    await AuthService.instance.init();
    await WalletService.instance.init();
    await ReferralService.instance.init();
    await ArcadeHubService.instance.init();
    await GameProgress().init();
  } catch (e) {
    debugPrint('Service initialization error: $e');
  }

  // 4. Initialize AdMob via AdManager safely
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    unawaited(AdManager.instance.initialize());
  }

  // 5. Mount the app UI immediately
  runApp(const IkramGamingHubApp());
}

class IkramGamingHubApp extends StatefulWidget {
  const IkramGamingHubApp({super.key});

  @override
  State<IkramGamingHubApp> createState() => _IkramGamingHubAppState();
}

class _IkramGamingHubAppState extends State<IkramGamingHubApp>
    with WidgetsBindingObserver {
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
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HubDashboardScreen(),
    );
  }
}
