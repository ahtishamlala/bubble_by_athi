import 'package:flutter/material.dart';
import '../core/services/auth_service.dart';
import '../core/services/security_service.dart';
import '../core/theme/app_theme.dart';
import 'login_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = AuthService.instance.currentUser?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _openLoginDialog() {
    showDialog(
      context: context,
      builder: (_) => const LoginDialog(),
    );
  }

  void _editNameDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Update Gamer Tag', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Display Name',
            labelStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: AppTheme.backgroundDark,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = _nameController.text.trim();
              if (newName.isNotEmpty) {
                await AuthService.instance.updateDisplayName(newName);
              }
              if (mounted) Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonCyan),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        final auth = AuthService.instance;
        final user = auth.currentUser;
        final security = SecurityService.instance;
        final isAuth = user != null && !user.isGuest;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Player Profile & Security'),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Profile Avatar & Info Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.neonBoxDecoration(
                    borderColor: isAuth ? AppTheme.neonGreen : AppTheme.neonCyan,
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 42,
                            backgroundColor: (isAuth ? AppTheme.neonGreen : AppTheme.neonCyan).withValues(alpha: 0.2),
                            child: Icon(
                              Icons.person_rounded,
                              size: 52,
                              color: isAuth ? AppTheme.neonGreen : AppTheme.neonCyan,
                            ),
                          ),
                          if (isAuth)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppTheme.neonGreen,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, size: 14, color: Colors.black),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            user?.displayName ?? 'Gamer',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, size: 18, color: AppTheme.neonCyan),
                            onPressed: _editNameDialog,
                          ),
                        ],
                      ),
                      Text(
                        isAuth ? (user.email.isNotEmpty ? user.email : 'Authenticated Player') : 'Visitor / Sandbox Mode',
                        style: TextStyle(
                          color: isAuth ? AppTheme.neonGreen : Colors.white54,
                          fontSize: 13,
                          fontWeight: isAuth ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // UID & Referral chips
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundDark,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.borderGlow),
                            ),
                            child: Text(
                              'UID: ${user?.uid ?? "---"}',
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundDark,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.neonGold.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              'Ref: ${user?.referralCode ?? "---"}',
                              style: const TextStyle(color: AppTheme.neonGold, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Link / Upgrade Account
                if (!isAuth)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.neonCyan, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.security_rounded, color: AppTheme.neonCyan, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'AUTHENTICATE ACCOUNT (+100 Gems)',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Secure your high scores, unlock crypto redemptions, and sync your account by logging in with Google or Facebook.',
                          style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _openLoginDialog,
                            icon: const Icon(Icons.login_rounded, size: 18),
                            label: const Text('LOG IN / AUTHENTICATE NOW'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.neonCyan,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _openLoginDialog,
                                icon: const Icon(Icons.g_mobiledata_rounded, size: 24, color: Colors.white),
                                label: const Text('Google'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Color(0xFFEA4335)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _openLoginDialog,
                                icon: const Icon(Icons.facebook_rounded, size: 20, color: Color(0xFF1877F2)),
                                label: const Text('Facebook'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Color(0xFF1877F2)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.neonGreen, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.verified_rounded, color: AppTheme.neonGreen, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'VERIFIED & AUTHENTICATED',
                              style: TextStyle(color: AppTheme.neonGreen, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Logged in as ${user.displayName} (${user.email.isNotEmpty ? user.email : user.uid}). Your high scores, arcade progress, and wallet are safely synced to the cloud.',
                          style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _openLoginDialog,
                          icon: const Icon(Icons.switch_account_rounded, size: 18, color: AppTheme.neonCyan),
                          label: const Text('Switch / Update Account', style: TextStyle(color: AppTheme.neonCyan)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.neonCyan),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Device Fingerprint & Security Status Card
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
                          Icon(Icons.fingerprint_rounded, color: AppTheme.neonCyan, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Hardware Integrity & Anti-Fraud',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildSecurityRow(
                        label: 'Device Fingerprint',
                        value: security.deviceFingerprint,
                      ),
                      const SizedBox(height: 8),
                      _buildSecurityRow(
                        label: 'Session Token',
                        value: security.sessionToken,
                      ),
                      const SizedBox(height: 8),
                      _buildSecurityRow(
                        label: 'Physical Hardware',
                        value: security.isEmulator ? 'Emulator (Flagged)' : 'Genuine Physical Device',
                        isGood: !security.isEmulator,
                      ),
                      const SizedBox(height: 8),
                      _buildSecurityRow(
                        label: 'Integrity Status',
                        value: security.isRooted ? 'Root/Jailbreak Detected' : 'Secure & Encrypted',
                        isGood: !security.isRooted,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Sign Out / Reset Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await auth.signOut();
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Switched to visitor session.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.logout_rounded, color: Colors.white54, size: 18),
                    label: const Text('Switch Session / Guest Mode', style: TextStyle(color: Colors.white54)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSecurityRow({
    required String label,
    required String value,
    bool isGood = true,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isGood ? AppTheme.neonGreen : AppTheme.neonPink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
