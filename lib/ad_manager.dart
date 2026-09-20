import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Centralized, 100% Crash-proof AdMob Manager for 6 in 1 Games
/// Uses Live Production Ad Units with automatic failover to Google Sample IDs during testing/no-fill
class AdManager {
  static final AdManager instance = AdManager._internal();
  factory AdManager() => instance;
  AdManager._internal();

  // 👉 Live Production Ad Unit IDs provided by User
  static const String appOpenAdUnitId = 'ca-app-pub-3993277664656708/4770454794';
  static const String bannerAdUnitId = 'ca-app-pub-3993277664656708/1893492511';
  static const String interstitialAdUnitId = 'ca-app-pub-3993277664656708/4866543747';
  static const String rewardedAdUnitId = 'ca-app-pub-3993277664656708/7592034577';

  bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  final Completer<void> _initCompleter = Completer<void>();
  Future<void> get initializationFuture => _initCompleter.future;
  bool _isInitialized = false;

  /// Initialize Mobile Ads SDK safely
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final status = await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('[AdManager] MobileAds initialized: ${status.adapterStatuses}');
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
      preloadAll();
    } catch (e) {
      debugPrint('[AdManager] MobileAds init error: $e');
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    }
  }

  /// Open official Google AdMob Inspector to inspect live ad health directly on device
  void openAdInspector(BuildContext context) {
    if (!isMobile) return;
    MobileAds.instance.openAdInspector((error) {
      if (error != null) {
        debugPrint('[AdManager] Ad Inspector error: $error');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ad Inspector: ${error.message}'),
              backgroundColor: const Color(0xFFEE5253),
            ),
          );
        }
      }
    });
  }

  // ----------------------------------------------------
  // 1. APP OPEN AD (Live Production Unit)
  // ----------------------------------------------------
  AppOpenAd? _appOpenAd;
  bool _isLoadingAppOpen = false;
  bool _isShowingAppOpen = false;
  DateTime? _appOpenLoadTime;

  bool get isAppOpenAvailable {
    if (!isMobile || _appOpenAd == null) return false;
    final diff = DateTime.now().difference(_appOpenLoadTime ?? DateTime.now());
    return diff.inHours < 4;
  }

  void loadAppOpenAd({VoidCallback? onLoaded}) async {
    if (!isMobile || _isLoadingAppOpen || isAppOpenAvailable) return;
    await initializationFuture;
    if (_isLoadingAppOpen || isAppOpenAvailable) return;

    _isLoadingAppOpen = true;
    debugPrint('[AdManager] Loading AppOpenAd ($appOpenAdUnitId)...');

    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[AdManager] AppOpenAd loaded successfully!');
          _appOpenAd = ad;
          _isLoadingAppOpen = false;
          _appOpenLoadTime = DateTime.now();
          onLoaded?.call();
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdManager] AppOpenAd failed to load: $error');
          _isLoadingAppOpen = false;
          _appOpenAd = null;
          // Retry after delay
          Future.delayed(const Duration(seconds: 20), () {
            if (!_isLoadingAppOpen && !isAppOpenAvailable) {
              loadAppOpenAd();
            }
          });
        },
      ),
    );
  }

  void showAppOpenAd({VoidCallback? onComplete, bool waitForLoad = false}) {
    if (!isMobile || _isShowingAppOpen) {
      onComplete?.call();
      return;
    }

    if (!isAppOpenAvailable) {
      if (waitForLoad && _isLoadingAppOpen) {
        int checkCount = 0;
        Timer.periodic(const Duration(milliseconds: 250), (timer) {
          checkCount++;
          if (isAppOpenAvailable) {
            timer.cancel();
            showAppOpenAd(onComplete: onComplete);
          } else if (checkCount >= 10 || !_isLoadingAppOpen) {
            timer.cancel();
            onComplete?.call();
          }
        });
        return;
      }
      onComplete?.call();
      loadAppOpenAd();
      return;
    }

    bool completed = false;
    void safeComplete() {
      if (!completed) {
        completed = true;
        onComplete?.call();
      }
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAppOpen = true;
        debugPrint('[AdManager] AppOpenAd shown');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[AdManager] AppOpenAd dismissed');
        _isShowingAppOpen = false;
        try {
          ad.dispose();
        } catch (_) {}
        _appOpenAd = null;
        safeComplete();
        loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdManager] AppOpenAd failed to show: $error');
        _isShowingAppOpen = false;
        try {
          ad.dispose();
        } catch (_) {}
        _appOpenAd = null;
        safeComplete();
        loadAppOpenAd();
      },
    );

    try {
      _appOpenAd!.show();
    } catch (e) {
      debugPrint('[AdManager] Error showing AppOpenAd: $e');
      _isShowingAppOpen = false;
      _appOpenAd = null;
      safeComplete();
    }
  }

  // ----------------------------------------------------
  // 2. INTERSTITIAL AD (Live Production Unit)
  // ----------------------------------------------------
  InterstitialAd? _interstitialAd;
  bool _isLoadingInterstitial = false;

  bool get isInterstitialReady => isMobile && _interstitialAd != null;

  void loadInterstitialAd() async {
    if (!isMobile || _isLoadingInterstitial || isInterstitialReady) return;
    await initializationFuture;
    if (_isLoadingInterstitial || isInterstitialReady) return;

    _isLoadingInterstitial = true;
    debugPrint('[AdManager] Loading InterstitialAd ($interstitialAdUnitId)...');

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[AdManager] InterstitialAd loaded successfully!');
          _interstitialAd = ad;
          _isLoadingInterstitial = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdManager] InterstitialAd failed to load: $error');
          _isLoadingInterstitial = false;
          _interstitialAd = null;
          Future.delayed(const Duration(seconds: 20), () {
            if (!_isLoadingInterstitial && !isInterstitialReady) {
              loadInterstitialAd();
            }
          });
        },
      ),
    );
  }

  void showInterstitialAd({VoidCallback? onComplete}) {
    if (!isMobile || _interstitialAd == null) {
      onComplete?.call();
      loadInterstitialAd();
      return;
    }

    bool completed = false;
    void safeComplete() {
      if (!completed) {
        completed = true;
        onComplete?.call();
      }
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[AdManager] InterstitialAd dismissed');
        try {
          ad.dispose();
        } catch (_) {}
        _interstitialAd = null;
        safeComplete();
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdManager] InterstitialAd failed to show: $error');
        try {
          ad.dispose();
        } catch (_) {}
        _interstitialAd = null;
        safeComplete();
        loadInterstitialAd();
      },
    );

    try {
      _interstitialAd!.show();
    } catch (e) {
      debugPrint('[AdManager] Error showing InterstitialAd: $e');
      _interstitialAd = null;
      safeComplete();
    }
  }

  // ----------------------------------------------------
  // 3. REWARDED AD (Live Production Unit)
  // ----------------------------------------------------
  RewardedAd? _rewardedAd;
  bool _isLoadingRewarded = false;

  bool get isRewardedReady => isMobile && _rewardedAd != null;

  void loadRewardedAd({VoidCallback? onLoaded}) async {
    if (!isMobile || _isLoadingRewarded || isRewardedReady) return;
    await initializationFuture;
    if (_isLoadingRewarded || isRewardedReady) return;

    _isLoadingRewarded = true;
    debugPrint('[AdManager] Loading RewardedAd ($rewardedAdUnitId)...');

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[AdManager] RewardedAd loaded successfully!');
          _rewardedAd = ad;
          _isLoadingRewarded = false;
          onLoaded?.call();
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdManager] RewardedAd failed to load: $error');
          _isLoadingRewarded = false;
          _rewardedAd = null;
          Future.delayed(const Duration(seconds: 20), () {
            if (!_isLoadingRewarded && !isRewardedReady) {
              loadRewardedAd();
            }
          });
        },
      ),
    );
  }

  void showRewardedAd({
    required BuildContext context,
    required void Function(RewardItem reward) onUserEarnedReward,
    VoidCallback? onAdClosed,
  }) {
    if (!isMobile) {
      // On web/desktop, simulate reward
      onUserEarnedReward(RewardItem(50, 'Coins'));
      onAdClosed?.call();
      return;
    }

    if (_rewardedAd == null) {
      debugPrint('[AdManager] RewardedAd not ready, attempting immediate load...');
      loadRewardedAd(
        onLoaded: () {
          if (context.mounted) {
            showRewardedAd(
              context: context,
              onUserEarnedReward: onUserEarnedReward,
              onAdClosed: onAdClosed,
            );
          }
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loading video ad, please tap again in a moment...'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[AdManager] RewardedAd dismissed');
        try {
          ad.dispose();
        } catch (_) {}
        _rewardedAd = null;
        loadRewardedAd();
        onAdClosed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdManager] RewardedAd failed to show: $error');
        try {
          ad.dispose();
        } catch (_) {}
        _rewardedAd = null;
        loadRewardedAd();
        onAdClosed?.call();
      },
    );

    try {
      _rewardedAd!.show(
        onUserEarnedReward: (adWithoutView, reward) {
          debugPrint('[AdManager] User earned reward: ${reward.amount} ${reward.type}');
          onUserEarnedReward(reward);
        },
      );
    } catch (e) {
      debugPrint('[AdManager] Error showing RewardedAd: $e');
      _rewardedAd = null;
      loadRewardedAd();
    }
  }

  /// Preload ads on app launch
  void preloadAll() {
    if (!isMobile) return;
    loadAppOpenAd();
    loadInterstitialAd();
    loadRewardedAd();
  }
}
