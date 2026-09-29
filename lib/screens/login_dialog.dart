import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/services/auth_service.dart';
import '../core/theme/app_theme.dart';

class LoginDialog extends StatefulWidget {
  const LoginDialog({super.key});

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _handleSocialLogin(String provider) async {
    final customName = _nameController.text.trim();
    final customEmail = _emailController.text.trim();

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    try {
      final success = await AuthService.instance.signInWithAccount(
        provider: provider,
        displayName: customName.isNotEmpty ? customName : '$provider Gamer',
        email: customEmail.isNotEmpty
            ? customEmail
            : '${(customName.isNotEmpty ? customName : "user").toLowerCase().replaceAll(' ', '')}@${provider.toLowerCase()}.com',
      );

      if (mounted && success) {
        final userName = AuthService.instance.currentUser?.displayName ?? 'Player';
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Welcome $userName! Account Authenticated (+100 Gems)!'),
            backgroundColor: AppTheme.neonGreen,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e'), backgroundColor: AppTheme.neonPink),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.backgroundDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppTheme.neonCyan, width: 1.5),
      ),
      child: Container(
        padding: const EdgeInsets.all(22),
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.neonCyan, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonCyan.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(Icons.security_rounded, color: AppTheme.neonCyan, size: 32),
              ),
              const SizedBox(height: 14),

              const Text(
                'AUTHENTICATE ACCOUNT',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Sign in to save your high scores, sync gameplay progress across devices, and get +100 Welcome Gems!',
                style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Gamer Name Input
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Your Name / Gamer Tag',
                  labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
                  hintText: 'e.g. Ikram Khan',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: AppTheme.neonCyan, size: 20),
                  filled: true,
                  fillColor: AppTheme.cardDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),

              const SizedBox(height: 12),

              // Email Input (Optional)
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Email Address (Optional)',
                  labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
                  hintText: 'e.g. ikram@gmail.com',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.neonCyan, size: 20),
                  filled: true,
                  fillColor: AppTheme.cardDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),

              const SizedBox(height: 20),

              if (_isSubmitting)
                const CircularProgressIndicator(color: AppTheme.neonCyan)
              else ...[
                // Google Login Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleSocialLogin('Google'),
                    icon: const Icon(Icons.g_mobiledata_rounded, size: 28, color: Colors.white),
                    label: const Text('CONTINUE WITH GOOGLE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA4335),
                      foregroundColor: Colors.white,
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Facebook Login Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleSocialLogin('Facebook'),
                    icon: const Icon(Icons.facebook_rounded, size: 22, color: Colors.white),
                    label: const Text('CONTINUE WITH FACEBOOK'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1877F2),
                      foregroundColor: Colors.white,
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Continue as Guest / Cancel
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Play as Guest / Sandbox Mode', style: TextStyle(color: Colors.white54, fontSize: 12)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
