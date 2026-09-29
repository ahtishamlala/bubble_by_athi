class AppConstants {
  // App Info
  static const String appName = 'Cyber Arcade';
  static const String appTagline = 'Bubble Shooter & Highway Car Racer';
  static const String packageName = 'com.ikram.bubble_by_ikram';
  static const String appVersion = '1.0.0';
  static const String privacyPolicyUrl = 'https://ikramgaminghub.com/privacy-policy';

  // Currency & Economy (Zero fiat mentions)
  static const String currencyName = 'Coins';
  static const String currencySymbol = '💎';
  static const String cryptoUnit = 'USDT';
  static const int gemsPerUsdt = 100000; // 100,000 Coins / Gems = $1.00 USDT

  // Redemption Thresholds & Quick Chips
  static const int minWithdrawalGems = 1000000; // $10.00 USDT = 1,000,000 Coins
  static const double minWithdrawalUsdt = 10.0;

  static const List<double> withdrawalTiersUsdt = [10.0, 20.0, 50.0, 100.0];
  static const String adminEmail = 'wwewrestling2k20@gmail.com';
  static const String withdrawalTimeline = '48 to 68 Hours';

  // Referral System
  static const int inviteeBonusGems = 100;
  static const int referrerRewardGems = 200;
  static const int referrerThresholdLevels = 5; // Must clear 5 levels to award referrer

  // Owner / Admin Console
  static const String adminPin = '7860';
  static const int adminTriggerTaps = 5;

  // Regex Validations
  static final RegExp trc20Regex = RegExp(r'^T[a-zA-Z0-9]{33}$');
  static final RegExp bep20Regex = RegExp(r'^0x[a-fA-F0-9]{40}$');
  static final RegExp binanceUidRegex = RegExp(r'^[0-9]{8,10}$');
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Validation Helpers
  static bool isValidTrc20(String address) => trc20Regex.hasMatch(address.trim());
  static bool isValidBep20(String address) => bep20Regex.hasMatch(address.trim());
  static bool isValidBinancePay(String idOrEmail) {
    final clean = idOrEmail.trim();
    return binanceUidRegex.hasMatch(clean) || emailRegex.hasMatch(clean);
  }

  // Games Configuration
  static const int totalGamesCount = 2;
  static const int levelsPerGame = 40;
  static const int totalLevelsCount = totalGamesCount * levelsPerGame; // 80
}
