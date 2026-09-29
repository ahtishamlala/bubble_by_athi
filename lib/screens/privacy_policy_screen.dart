import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  bool isUrdu = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.privacy_tip_rounded, color: AppTheme.neonCyan, size: 22),
            SizedBox(width: 8),
            Text('Privacy Policy & Safety'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(isUrdu ? 'اردو' : 'English'),
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
            // Top Hero Badge
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
                    child: const Icon(Icons.shield_outlined, color: AppTheme.neonCyan, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isUrdu ? 'گوگل پلے پرائیویسی پالیسی' : 'Google Play Privacy Declaration',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isUrdu
                              ? 'شفاف، محفوظ اور گوگل کے تمام رہنما اصولوں کے مطابق'
                              : 'Transparent, Secure & 100% Policy-Compliant',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Policy Section 1: Overview
            _buildSection(
              icon: Icons.info_outline_rounded,
              color: AppTheme.neonCyan,
              title: isUrdu ? '1. تعارف اور جائزہ' : '1. Overview & Information We Collect',
              body: isUrdu
                  ? '${AppConstants.appName} آپ کی نجی معلومات کے تحفظ کا پورا خیال رکھتا ہے۔\n'
                    '• نجی ڈیٹا برائے نام: ہم صرف آپ کا گیمر نام، اسکورز اور لیول کی پیشرفت محفوظ کرتے ہیں۔\n'
                    '• صفر غیر ضروری پرمیشنز: ایپ کیمرہ، ایس ایم ایس یا کنٹیکٹس تک رسائی نہیں مانگتی۔\n'
                    '• محفوظ اسٹوریج: تمام معلومات آپ کے فون پر مقامی طور پر اور محفوظ انکرپشن کے ساتھ رہتی ہیں۔'
                  : '${AppConstants.appName} is committed to user privacy and strict adherence to Google Play policies:\n'
                    '• Minimal Data Collection: We only store your gamer handle, game high scores, unlocked levels, and earned virtual badges.\n'
                    '• Zero Excessive Permissions: We DO NOT request or require access to your Contacts, SMS, Microphone, or Precise Location.\n'
                    '• Local & Encrypted: Your gameplay progression is saved securely on your device using encrypted local storage.',
            ),

            const SizedBox(height: 12),

            // Policy Section 2: Advertising & Google AdMob
            _buildSection(
              icon: Icons.ads_click_rounded,
              color: AppTheme.neonGold,
              title: isUrdu ? '2. اشتہارات (گوگل ایڈموب)' : '2. Advertisements & Google AdMob',
              body: isUrdu
                  ? '• ہم صرف گوگل کے آفیشل ایڈموب نیٹ ورک کے ذریعے اشتہارات دکھاتے ہیں۔\n'
                    '• ایڈموب گوگل کے تصدیق شدہ ایڈورٹائزنگ آئی ڈی (AD_ID) کا استعمال کرتا ہے۔\n'
                    '• دھوکہ دہی سے پاک: صارفین کو کبھی بھی اشتہارات پر زبردستی کلک کرنے پر مجبور نہیں کیا جاتا۔ ریوارڈڈ ویڈیو اشتہارات مکمل طور پر اختیاری ہیں تاکہ آپ گیم میں اضافی زندگیاں یا بوسٹرز حاصل کر سکیں۔'
                  : '• We utilize Google Mobile Ads (AdMob) to serve context-appropriate ads that support free development.\n'
                    '• Google AdMob handles device advertising identifiers (AD_ID) according to Google Play Ads Policy.\n'
                    '• Fair Ad Experience: We adhere to Better Ads Standards. Rewarded video ads are strictly 100% opt-in to grant in-game continues, extra shots, or bonus level boosters.',
            ),

            const SizedBox(height: 12),

            // Policy Section 3: In-Game Economy & Anti-Gambling
            _buildSection(
              icon: Icons.sports_esports_rounded,
              color: AppTheme.neonGreen,
              title: isUrdu ? '3. کھیل کی معیشت اور گیم کوائنز' : '3. Virtual Arcade Economy (Skill-Based)',
              body: isUrdu
                  ? '• کھیل کے کوائنز اور جیمز صرف ورچوئل تفریحی ٹوکن ہیں جو گیم میں لیولز پاس کرنے پر ملتے ہیں۔\n'
                    '• یہاں کوئی حقیقی رقم کا جوا یا بیٹنگ شامل نہیں ہے۔ تمام ورچوئل انعامات صرف گیمنگ مہارت سے حاصل ہوتے ہیں اور گیم کے اندر ہی استعمال ہوتے ہیں۔'
                  : '• Virtual Game Coins / Gems are strictly non-monetary in-game points earned through skill and level progression.\n'
                    '• NO real-money gambling, wagering, or pay-to-win mechanics exist. Coins are utilized exclusively within the app for arcade power-ups, themes, and avatar customizations.',
            ),

            const SizedBox(height: 12),

            // Policy Section 4: Child Safety & COPPA
            _buildSection(
              icon: Icons.child_care_rounded,
              color: AppTheme.neonCyan,
              title: isUrdu ? '4. بچوں کی حفاظت اور COPPA' : '4. Child Safety & COPPA Compliance',
              body: isUrdu
                  ? '• ہماری ایپ تمام صارفین بشمول نوعمر افراد کے لیے موزوں ہے۔\n'
                    '• ہم 13 سال سے کم عمر بچوں کی ذاتی شناخت یا لوکیشن کا ڈیٹا اکٹھا نہیں کرتے۔\n'
                    '• دکھائے جانے والے تمام اشتہارات فیملی فرینڈلی معیارات کے مطابق فلٹر کیے جاتے ہیں۔'
                  : '• Our games are family-friendly and suitable for players aged 13 and above.\n'
                    '• We do not knowingly collect personal information from children under 13.\n'
                    '• Ad content ratings are restricted to ensure family-safe, non-explicit advertisements.',
            ),

            const SizedBox(height: 12),

            // Policy Section 5: Data & Account Deletion Mandate
            _buildSection(
              icon: Icons.delete_forever_rounded,
              color: AppTheme.neonPink,
              title: isUrdu ? '5. اکاؤنٹ اور ڈیٹا ڈیلیٹ کرنے کا حق' : '5. Account & Data Deletion Mandate',
              body: isUrdu
                  ? 'گوگل پلے پالیسی کے مطابق ہر صارف کو اپنا ڈیٹا مکمل ڈیلیٹ کرنے کا اختیار ہے:\n'
                    '1. ایپ کے اندر: پروفائل اسکرین میں جا کر "Delete Account & Clear Data" پر ٹیپ کریں، سارا ریکارڈ فوری ختم ہو جائے گا۔\n'
                    '2. ای میل درخواست: آپ بغیر ایپ انسٹال کیے بھی ${AppConstants.adminEmail} پر ای میل بھیج کر ڈیٹا ڈیلیٹ کروا سکتے ہیں۔'
                  : 'Pursuant to Google Play Data Deletion requirements, users retain full autonomy over their data:\n'
                    '1. In-App Deletion: Navigate to the Player Profile screen and tap "Delete Account & Clear Data" to instantly purge all stored records, credentials, and progress.\n'
                    '2. Web/Email Deletion Request: You may also email ${AppConstants.adminEmail} with subject "Account Deletion Request". All associated records will be permanently erased without needing to reinstall the app.',
            ),

            const SizedBox(height: 16),

            // Footer info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderGlow),
              ),
              child: const Column(
                children: [
                  Text(
                    'Effective Date: 2026-09-29 • Version ${AppConstants.appVersion}',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Contact / Data Officer: ${AppConstants.adminEmail}',
                    style: TextStyle(color: AppTheme.neonCyan, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
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
            body,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.45),
          ),
        ],
      ),
    );
  }
}
