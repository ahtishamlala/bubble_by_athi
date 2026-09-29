import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/services/referral_service.dart';
import '../core/theme/app_theme.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _redeemCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      await ReferralService.instance.redeemCode(code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Welcome Bonus: 100 Ikram Gems added to your wallet!'),
            backgroundColor: AppTheme.neonGreen,
          ),
        );
        _codeController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.neonPink,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ReferralService.instance,
      builder: (context, _) {
        final referralService = ReferralService.instance;
        final myCode = referralService.userReferralCode;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Invite & Earn'),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Hero Banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.neonBoxDecoration(borderColor: AppTheme.neonGold),
                  child: Column(
                    children: [
                      const Text(
                        '🎁 INVITE FRIENDS & EARN BONUS GEMS',
                        style: TextStyle(
                          color: AppTheme.neonGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Share your code with fellow gamers. They get 100 Gems upon sign-up, and you earn 200 Gems once they clear 5 levels!',
                        style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      // Your Code Box
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundDark,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.neonCyan, width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              myCode,
                              style: const TextStyle(
                                color: AppTheme.neonCyan,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3.0,
                              ),
                            ),
                            const SizedBox(width: 14),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, color: Colors.white70),
                              tooltip: 'Copy Code',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: myCode));
                                HapticFeedback.selectionClick();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Referral code copied to clipboard!'),
                                    duration: Duration(seconds: 2),
                                    backgroundColor: AppTheme.neonCyan,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Share Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => referralService.shareReferralCode(),
                          icon: const Icon(Icons.share_rounded, size: 20),
                          label: const Text('SHARE VIA WHATSAPP / TELEGRAM / X'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.neonGold,
                            foregroundColor: Colors.black,
                            elevation: 6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Redeem Code Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderGlow),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.card_giftcard_rounded, color: AppTheme.neonCyan, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Have an Invitation Code?',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Redeem a friend\'s referral code to instantly claim 100 free welcome Gems!',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 14),
                      if (referralService.hasRedeemedCode)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.neonGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.neonGreen.withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: AppTheme.neonGreen, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'You have already claimed your 100 Welcome Gems bonus!',
                                  style: TextStyle(color: AppTheme.neonGreen, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _codeController,
                                textCapitalization: TextCapitalization.characters,
                                decoration: InputDecoration(
                                  hintText: 'e.g. IKRAM-7X9Y',
                                  hintStyle: const TextStyle(color: Colors.white38),
                                  filled: true,
                                  fillColor: AppTheme.backgroundDark,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppTheme.borderGlow),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: _isSubmitting ? null : _redeemCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.neonCyan,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Text('Redeem'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Referral Milestone Rules
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderGlow),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rules & Anti-Bot Threshold',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      _buildMilestoneRow(
                        step: '1',
                        title: 'Share your code',
                        desc: 'Invite friends across any messenger or social platform.',
                      ),
                      const SizedBox(height: 8),
                      _buildMilestoneRow(
                        step: '2',
                        title: 'Instant 100 Gems to Invitee',
                        desc: 'Your friend gets 100 Gems immediately upon applying the code.',
                      ),
                      const SizedBox(height: 8),
                      _buildMilestoneRow(
                        step: '3',
                        title: '200 Gems Referrer Reward',
                        desc: 'Credited to you once your invitee beats 5 arcade levels (anti-bot security).',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMilestoneRow({
    required String step,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: AppTheme.neonCyan.withValues(alpha: 0.2),
          child: Text(step, style: const TextStyle(color: AppTheme.neonCyan, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}
