import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/services/audio_service.dart';
import '../core/services/auth_service.dart';
import '../core/services/email_otp_service.dart';
import '../core/theme/app_theme.dart';
import 'hub_dashboard_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 6 OTP Digit Controllers
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _isOtpStep = false;
  bool _isSignInMode = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;
  String? _dispatchedCodeForTesting;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldownTimer() {
    _cooldownSeconds = 45;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_cooldownSeconds > 0) {
          _cooldownSeconds--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  /// Step 1: Request 6-digit OTP code to Email
  Future<void> _handleRequestOtp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (!_isSignInMode && name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name (at least 2 characters)'),
          backgroundColor: AppTheme.neonPink,
        ),
      );
      return;
    }

    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (email.isEmpty || !regex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: AppTheme.neonPink,
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: AppTheme.neonPink,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    AudioService.instance.playClick();

    try {
      final result = await EmailOtpService.instance.sendOtpEmail(
        recipientEmail: email,
        recipientName: name.isNotEmpty ? name : 'Player',
      );

      if (mounted) {
        if (result['success'] == true) {
          _dispatchedCodeForTesting = result['code'] as String?;
          setState(() {
            _isOtpStep = true;
          });
          _startCooldownTimer();

          // Auto focus first OTP digit
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) _otpFocusNodes[0].requestFocus();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '📧 Security code sent to $email!\n(Verification Code: ${_dispatchedCodeForTesting ?? ""})',
              ),
              backgroundColor: AppTheme.neonGreen,
              duration: const Duration(seconds: 6),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] as String? ?? 'Could not send code'),
              backgroundColor: AppTheme.neonPink,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.neonPink),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Step 2: Verify 6-digit OTP and complete registration
  Future<void> _handleVerifyOtp() async {
    final enteredOtp = _otpControllers.map((c) => c.text.trim()).join();
    if (enteredOtp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the full 6-digit code!'),
          backgroundColor: AppTheme.neonPink,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final success = await AuthService.instance.verifyAndRegisterWithOtp(
        name: name,
        email: email,
        password: password,
        otpCode: enteredOtp,
      );

      if (mounted && success) {
        AudioService.instance.playVictory();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HubDashboardScreen()),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Verified! Welcome ${AuthService.instance.currentUser?.displayName}! +500 Coins added!'),
            backgroundColor: AppTheme.neonGreen,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        AudioService.instance.playGameOver();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.neonPink,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Returning user quick sign in with password
  Future<void> _handleDirectSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (email.isEmpty || !regex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: AppTheme.neonPink,
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: AppTheme.neonPink,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.selectionClick();

    try {
      final success = await AuthService.instance.quickLoginWithCredentials(
        email: email,
        password: password,
      );

      if (mounted && success) {
        AudioService.instance.playVictory();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HubDashboardScreen()),
        );
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / Hero Glow Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.cyberGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.neonCyan.withValues(alpha: 0.4),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.sports_esports_rounded, size: 44, color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  const Text(
                    '6 IN 1 GAMES',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isOtpStep
                        ? 'ENTER EMAIL VERIFICATION CODE'
                        : (_isSignInMode ? 'SIGN IN WITH PASSWORD' : 'AUTHENTICATE & PLAY'),
                    style: const TextStyle(
                      color: AppTheme.neonCyan,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Main Interactive Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _isOtpStep ? AppTheme.neonGreen : AppTheme.neonCyan.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isOtpStep ? AppTheme.neonGreen : AppTheme.neonCyan).withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: _isOtpStep ? _buildOtpView() : _buildCredentialsForm(),
                  ),

                  const SizedBox(height: 24),

                  // Toggle between Sign In / Sign Up (Only on non-OTP step)
                  if (!_isOtpStep)
                    TextButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _isSignInMode = !_isSignInMode;
                        });
                      },
                      child: Text(
                        _isSignInMode
                            ? "Don't have an account? Register with OTP"
                            : "Already registered? Sign in with Password",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Step 1 Form: Username, Email, Password
  Widget _buildCredentialsForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Username Field (Only for Sign Up)
          if (!_isSignInMode) ...[
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: _inputDecoration(
                label: 'Gamer Username / Name',
                icon: Icons.person_outline_rounded,
                hint: 'e.g. CyberHero',
              ),
              validator: (v) {
                if (v == null || v.trim().length < 2) {
                  return 'Please enter at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],

          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: _inputDecoration(
              label: 'Email Address',
              icon: Icons.email_outlined,
              hint: 'e.g. player@gmail.com',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!regex.hasMatch(v.trim())) return 'Enter a valid email address';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: _inputDecoration(
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              hint: 'Min. 6 characters',
            ).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: Colors.white54,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Action Button
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : (_isSignInMode ? _handleDirectSignIn : _handleRequestOtp),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonCyan,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                    )
                  : Text(
                      _isSignInMode ? 'SIGN IN' : 'SEND EMAIL OTP CODE',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Step 2 Form: 6-Digit OTP Verification Box
  Widget _buildOtpView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Code sent to:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            GestureDetector(
              onTap: () {
                setState(() => _isOtpStep = false);
              },
              child: const Row(
                children: [
                  Icon(Icons.edit, size: 14, color: AppTheme.neonCyan),
                  SizedBox(width: 4),
                  Text('Change', style: TextStyle(color: AppTheme.neonCyan, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _emailController.text.trim(),
          style: const TextStyle(color: AppTheme.neonGreen, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 24),

        // 6 Digit PIN Boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 44,
              height: 54,
              child: TextFormField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                style: const TextStyle(
                  color: AppTheme.neonGreen,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: AppTheme.surfaceDark,
                  contentPadding: EdgeInsets.zero,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.neonGreen.withValues(alpha: 0.4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.neonGreen, width: 2),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    if (index < 5) {
                      _otpFocusNodes[index + 1].requestFocus();
                    } else {
                      _otpFocusNodes[index].unfocus();
                      _handleVerifyOtp();
                    }
                  } else if (index > 0) {
                    _otpFocusNodes[index - 1].requestFocus();
                  }
                },
              ),
            );
          }),
        ),
        if (_dispatchedCodeForTesting != null && _dispatchedCodeForTesting!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  final code = _dispatchedCodeForTesting!;
                  for (int i = 0; i < code.length && i < 6; i++) {
                    _otpControllers[i].text = code[i];
                  }
                  _handleVerifyOtp();
                },
                icon: const Icon(Icons.flash_on_rounded, size: 16, color: AppTheme.neonGold),
                label: Text(
                  'Quick Fill OTP: $_dispatchedCodeForTesting',
                  style: const TextStyle(color: AppTheme.neonGold, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ),
        const SizedBox(height: 20),

        // Verify Button
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleVerifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonGreen,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 4,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                  )
                : const Text(
                    'VERIFY & ENTER ARCADE',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1),
                  ),
          ),
        ),
        const SizedBox(height: 16),

        // Resend Timer Row
        Center(
          child: _cooldownSeconds > 0
              ? Text(
                  'Resend code in ${_cooldownSeconds}s',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                )
              : TextButton(
                  onPressed: _isLoading ? null : _handleRequestOtp,
                  child: const Text(
                    'Resend Code',
                    style: TextStyle(color: AppTheme.neonCyan, fontWeight: FontWeight.bold),
                  ),
                ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
      labelStyle: const TextStyle(color: Colors.white70, fontSize: 14),
      prefixIcon: Icon(icon, color: AppTheme.neonCyan, size: 20),
      filled: true,
      fillColor: AppTheme.surfaceDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppTheme.borderGlow.withValues(alpha: 0.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.neonCyan, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.neonPink),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.neonPink, width: 1.5),
      ),
    );
  }
}
