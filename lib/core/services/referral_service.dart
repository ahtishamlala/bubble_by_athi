import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'auth_service.dart';
import 'wallet_service.dart';

class ReferralService extends ChangeNotifier {
  static final ReferralService instance = ReferralService._internal();
  ReferralService._internal();

  bool _hasRedeemedCode = false;
  int _referralsCount = 0;

  bool get hasRedeemedCode => _hasRedeemedCode;
  int get referralsCount => _referralsCount;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasRedeemedCode = prefs.getBool('has_redeemed_referral') ?? false;
      _referralsCount = prefs.getInt('referrals_count') ?? 2; // Initial demo count
    } catch (e) {
      debugPrint('ReferralService init error: $e');
    }
    notifyListeners();
  }

  String get userReferralCode {
    return AuthService.instance.currentUser?.referralCode ?? 'IKRAM-7X9Y';
  }

  Future<void> shareReferralCode() async {
    final code = userReferralCode;
    final message =
        '🔥 Join me on Ikram Arcade Hub! Play 6-in-1 cyber arcade games and earn crypto loyalty gems redeemable for USDT!\n\n'
        '🎁 Use my referral code *$code* to get 100 FREE Gems instantly!\n\n'
        'Download now: https://play.google.com/store/apps/details?id=${AppConstants.packageName}';

    await Share.share(message, subject: 'Claim 100 Gems on Ikram Arcade Hub!');
  }

  Future<bool> redeemCode(String code) async {
    final cleanCode = code.trim().toUpperCase();

    if (_hasRedeemedCode) {
      throw Exception('You have already redeemed a referral welcome bonus!');
    }

    if (cleanCode.isEmpty) {
      throw Exception('Please enter a valid referral code.');
    }

    if (cleanCode == userReferralCode) {
      throw Exception('You cannot use your own referral code!');
    }

    // Award invitee welcome bonus: 100 Gems
    await WalletService.instance.addGems(
      AppConstants.inviteeBonusGems,
      reason: 'Referral Welcome Bonus',
    );

    _hasRedeemedCode = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_redeemed_referral', true);
    notifyListeners();
    return true;
  }
}
