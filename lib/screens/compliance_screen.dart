import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';

class ComplianceScreen extends StatefulWidget {
  const ComplianceScreen({super.key});

  @override
  State<ComplianceScreen> createState() => _ComplianceScreenState();
}

class _ComplianceScreenState extends State<ComplianceScreen> {
  bool isUrdu = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_rounded, color: AppTheme.neonCyan, size: 22),
            SizedBox(width: 8),
            Text('Legal & Policy Center'),
          ],
        ),
        actions: [
          // Language Switcher
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(isUrdu ? 'اردو / Roman Urdu' : 'English'),
              selected: isUrdu,
              onSelected: (val) => setState(() => isUrdu = val),
              selectedColor: AppTheme.neonCyan,
              backgroundColor: AppTheme.cardDark,
              labelStyle: TextStyle(
                color: isUrdu ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header Badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.neonBoxDecoration(borderColor: AppTheme.neonCyan),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.neonCyan.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: AppTheme.neonCyan, size: 32),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isUrdu ? 'گوگل پلے پالیسی اور حفاظت' : 'Google Play & Security Compliance',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isUrdu
                            ? 'مکمل شفافیت اور مہارت پر مبنی گیمنگ معیارات'
                            : '100% Skill-Based Arcade • Transparent Data Safety',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Section 1: Anti-Gambling & Skill-Based Arcade
            _buildSectionCard(
              icon: Icons.sports_esports_rounded,
              color: AppTheme.neonGreen,
              title: isUrdu ? '1. مہارت پر مبنی گیمنگ (کوئی جوا نہیں)' : '1. 100% Skill-Based (Anti-Gambling)',
              content: isUrdu
                  ? '• اکرام آرکیڈ ہب مکمل طور پر آرکیڈ اور کیژول گیمز کا پلیٹ فارم ہے۔\n'
                    '• یہاں کسی قسم کا جوا، بیٹنگ یا لاٹری نہیں ہے۔ انعامات (Ikram Gems) صرف آپ کی گیمنگ مہارت، لیولز مکمل کرنے اور ہائی اسکورز حاصل کرنے پر ملتے ہیں۔\n'
                    '• حقیقی رقم کے ذریعے سکے خریدنا یا پے-ٹو-ون (Pay-to-Win) مکینکس مکمل طور پر ممنوع ہیں۔'
                  : '• ${AppConstants.appName} is strictly categorized under Arcade & Casual Gaming.\n'
                    '• NO gambling, betting, or wagering mechanics exist. Ikram Gems are earned purely through skill progression (completing puzzle levels, 3-star clears, beating high scores).\n'
                    '• Zero "Pay-to-Win" or randomized loot boxes with monetary value.',
            ),

            const SizedBox(height: 12),

            // Section 2: AdMob Policy Compliance
            _buildSectionCard(
              icon: Icons.ads_click_rounded,
              color: AppTheme.neonGold,
              title: isUrdu ? '2. ایڈموب پالیسی اور منصفانہ اشتہارات' : '2. Google AdMob Policy Safeguards',
              content: isUrdu
                  ? '• صارفین کو کبھی بھی اشتہارات پر کلک کرنے کے لیے مجبور یا اکسایا نہیں جاتا۔\n'
                    '• ریوارڈڈ اشتہارات صرف گیم کے فائدے کے لیے ہیں (مثلاً اضافی مووز یا دوبارہ زندگی)۔\n'
                    '• گوگل کے آفیشل ٹیسٹ ایڈ یونٹس کا بیک اپ ہمیشہ دستیاب رہتا ہے تاکہ ایپ بغیر کسی مسئلے کے چلے۔'
                  : '• No Paid Clicks / Rewarded Click Fraud: Users are never forced or incentivized to click banner or interstitial ads.\n'
                    '• Rewarded Video Ads are strictly designated for in-game perks only (e.g. extra moves, revives, or free game boosters).\n'
                    '• Automatic fallback failover to Google test units guarantees 100% crash-free stability.',
            ),

            const SizedBox(height: 12),

            // Section 3: COPPA & Data Safety
            _buildSectionCard(
              icon: Icons.lock_outline_rounded,
              color: AppTheme.neonCyan,
              title: isUrdu ? '3. ڈیٹا سیفٹی اور پرائیویسی' : '3. COPPA & Data Safety Declaration',
              content: isUrdu
                  ? '• یہ ایپ 13 سال یا اس سے زیادہ عمر کے افراد کے لیے بنائی گئی ہے۔\n'
                    '• آپ کا تمام ڈیٹا انکرپٹڈ (HTTPS / SSL) پروٹوکول کے ذریعے محفوظ رہتا ہے۔\n'
                    '• ہم آپ کی نجی معلومات کو کسی تیسرے فریق کو فروخت نہیں کرتے۔'
                  : '• Target audience: 13+.\n'
                    '• Encryption in transit (HTTPS/SSL) ensures all cloud sync and wallet records are encrypted.\n'
                    '• Zero third-party data sales. Transparent user control over accounts and local data.',
            ),

            const SizedBox(height: 12),

            // Section 4: Anti-Fraud & Emulator Guard
            _buildSectionCard(
              icon: Icons.security_rounded,
              color: AppTheme.neonPink,
              title: isUrdu ? '4. اینٹی فراڈ اور ایمولیٹر قوانین' : '4. Anti-Fraud & Emulator Guard',
              content: isUrdu
                  ? '• بوٹس، آٹو کلکرز، اور کمپیوٹر ایمولیٹرز (Bluestacks/Nox) پر پابندی ہے۔\n'
                    '• ہارڈ ویئر فنگر پرنٹنگ کی مدد سے ایک ہی ڈیوائس پر متعدد فیک اکاؤنٹس کی روک تھام کی جاتی ہے۔\n'
                    '• خودکار بوٹس یا فراڈ کی صورت میں والٹ خودکار طور پر فریز کر دیا جائے گا۔'
                  : '• Root, jailbreak, emulator (Bluestacks/Nox), auto-clicker, and VPN/Proxy detection are actively monitored.\n'
                    '• Hardware device fingerprinting prevents multi-accounting on the same physical hardware.\n'
                    '• Automated bots or fraud attempts result in immediate wallet freeze.',
            ),

            const SizedBox(height: 16),

            // Crypto Standard Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderGlow),
              ),
              child: Text(
                isUrdu
                    ? 'تبادلہ کا معیار: 1,000 اکرام جیمز = 1.00 USDT (بائننس پے / آن چین والٹ)'
                    : 'Exchange Standard: 1,000 Ikram Gems = \$1.00 USDT (Binance Pay / TRC-20 / BEP-20)',
                style: const TextStyle(color: AppTheme.neonGold, fontWeight: FontWeight.bold, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}
