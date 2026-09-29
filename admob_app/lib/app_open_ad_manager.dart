import 'dart:developer';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Handles loading + showing the App Open Ad
/// jo app open hote hi (ya foreground me aane par) dikhta hai.
class AppOpenAdManager {
  // 👉 Aapka App Open Ad Unit ID
  static const String _adUnitId = 'ca-app-pub-3993277664656708/3949263498';

  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  bool _isLoadingAd = false;
  DateTime? _loadTime;

  bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Ad load karta hai. App start hote hi ya banane ke baad call karein.
  void loadAd({VoidCallback? onAdLoaded}) {
    if (!_isMobile) {
      log('Non-mobile platform detected, skipping real ad loading');
      return;
    }
    if (_isLoadingAd) return;
    _isLoadingAd = true;

    AppOpenAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          log('App Open Ad loaded');
          _appOpenAd = ad;
          _isLoadingAd = false;
          _loadTime = DateTime.now();
          onAdLoaded?.call();
        },
        onAdFailedToLoad: (error) {
          log('App Open Ad failed to load: $error');
          _isLoadingAd = false;
        },
      ),
    );
  }

  bool get isAdAvailable {
    if (!_isMobile || _appOpenAd == null) return false;
    final diff = DateTime.now().difference(_loadTime ?? DateTime.now());
    return diff.inHours < 4;
  }

  /// Ad show karta hai agar available ho, warna seedha onComplete call ho jata hai
  /// taake app "ruk" na jaye.
  void showAdIfAvailable({required VoidCallback onComplete}) {
    if (!_isMobile) {
      onComplete();
      return;
    }
    if (_isShowingAd) {
      log('Ad already showing');
      return;
    }

    if (!isAdAvailable) {
      log('Ad not ready yet, skipping and loading a fresh one');
      onComplete();
      loadAd();
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        log('App Open Ad showed');
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        log('App Open Ad failed to show: $error');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        onComplete();
        loadAd();
      },
      onAdDismissedFullScreenContent: (ad) {
        log('App Open Ad dismissed');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        onComplete();
        loadAd(); // agla load karo taake next time bhi ready ho
      },
    );

    _appOpenAd!.show();
  }
}
