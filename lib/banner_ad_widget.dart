import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_manager.dart';

/// Home screen & Game screen bottom AdMob Banner widget (100% Live Production Ad)
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isDisposed = false;
  bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void initState() {
    super.initState();
    if (_isMobile) {
      _loadBannerAd();
    }
  }

  void _loadBannerAd() async {
    if (_isDisposed) return;
    await AdManager.instance.initializationFuture;
    if (_isDisposed) return;

    // Use strictly live production Banner Ad Unit ID provided by User
    const adUnit = AdManager.bannerAdUnitId;

    try {
      _bannerAd = BannerAd(
        adUnitId: adUnit,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            debugPrint('[BannerAdWidget] LIVE banner ad loaded successfully!');
            if (mounted && !_isDisposed) {
              setState(() => _isLoaded = true);
            }
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('[BannerAdWidget] LIVE banner ad failed to load: $error');
            try {
              ad.dispose();
            } catch (_) {}
            _bannerAd = null;
            if (mounted && !_isDisposed) {
              setState(() => _isLoaded = false);
            }
            // Retry loading production banner ad after 15 seconds
            Future.delayed(const Duration(seconds: 15), () {
              if (mounted && !_isDisposed && !_isLoaded) {
                _loadBannerAd();
              }
            });
          },
        ),
      )..load();
    } catch (e) {
      debugPrint('Error creating banner ad: $e');
      _bannerAd = null;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    try {
      _bannerAd?.dispose();
    } catch (_) {}
    _bannerAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isMobile) {
      return const SizedBox(height: 50);
    }

    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox(height: 50);
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
