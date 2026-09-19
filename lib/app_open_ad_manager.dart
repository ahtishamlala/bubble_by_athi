import 'dart:developer';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Handles loading + showing the App Open Ad safely.
/// Preserves AdMob unit ID and ensures 100% crash-proof execution.
class AppOpenAdManager {
  static final AppOpenAdManager instance = AppOpenAdManager._internal();
  factory AppOpenAdManager() => instance;
  AppOpenAdManager._internal();

  // 👉 Aapka App Open Ad Unit ID (Intact & Preserved)
  static const String _adUnitId = 'ca-app-pub-3993277664656708/4770454794';

  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  bool _isLoadingAd = false;
  DateTime? _loadTime;

  bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Loads the App Open Ad safely in the background
  void loadAd({VoidCallback? onAdLoaded}) {
    if (!_isMobile) {
      log('Non-mobile platform detected, skipping real ad loading');
      return;
    }
    if (_isLoadingAd || isAdAvailable) return;
    _isLoadingAd = true;

    try {
      AppOpenAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            log('App Open Ad loaded successfully');
            _appOpenAd = ad;
            _isLoadingAd = false;
            _loadTime = DateTime.now();
            onAdLoaded?.call();
          },
          onAdFailedToLoad: (error) {
            log('App Open Ad failed to load: $error');
            _isLoadingAd = false;
            _appOpenAd = null;
          },
        ),
      );
    } catch (e) {
      log('Exception calling AppOpenAd.load: $e');
      _isLoadingAd = false;
      _appOpenAd = null;
    }
  }

  bool get isAdAvailable {
    if (!_isMobile || _appOpenAd == null) return false;
    final diff = DateTime.now().difference(_loadTime ?? DateTime.now());
    return diff.inHours < 4;
  }

  /// Shows the ad if available without ever blocking or freezing the app
  void showAdIfAvailable({VoidCallback? onComplete}) {
    if (!_isMobile) {
      onComplete?.call();
      return;
    }
    if (_isShowingAd) {
      log('Ad already showing, skipping');
      onComplete?.call();
      return;
    }

    if (!isAdAvailable) {
      log('Ad not ready yet, loading in background');
      onComplete?.call();
      loadAd();
      return;
    }

    bool completed = false;
    void safeComplete() {
      if (!completed) {
        completed = true;
        onComplete?.call();
      }
    }

    try {
      _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          _isShowingAd = true;
          log('App Open Ad showed');
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          log('App Open Ad failed to show: $error');
          _isShowingAd = false;
          try {
            ad.dispose();
          } catch (_) {}
          _appOpenAd = null;
          safeComplete();
          loadAd();
        },
        onAdDismissedFullScreenContent: (ad) {
          log('App Open Ad dismissed');
          _isShowingAd = false;
          try {
            ad.dispose();
          } catch (_) {}
          _appOpenAd = null;
          safeComplete();
          loadAd();
        },
      );

      _appOpenAd!.show();
    } catch (e) {
      log('Fatal error while showing AppOpenAd: $e');
      _isShowingAd = false;
      try {
        _appOpenAd?.dispose();
      } catch (_) {}
      _appOpenAd = null;
      safeComplete();
    }
  }
}
