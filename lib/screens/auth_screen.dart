import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/services/auth_service.dart';
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
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoginMode = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();
      final password = _passwordController.text.trim();

      bool success = false;
      if (_isLoginMode) {
        // Sign in existing
        success = await AuthService.instance.signUpWithCredentials(
          name: name.isNotEmpty ? name : 'Gamer',
          email: email,
          phone: phone,
          password: password,
        );
      } else {
        // Create new account
        success = await AuthService.instance.signUpWithCredentials(
          name: name,
          email: email,
          phone: phone,
          password: password,
        );
      }

      if (mounted && success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HubDashboardScreen()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Welcome ${AuthService.instance.currentUser?.displayName}! Account Authenticated!'),
            backgroundColor: AppTheme.neonGreen,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication failed. Please check your details.'),
            backgroundColor: AppTheme.neonPink,
          ),
        );
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

  void _handleSocialLogin(String provider) async {
    setState(() => _isLoading = true);
    HapticFeedback.selectionClick();

    final customName = _nameController.text.trim();
    final customEmail = _emailController.text.trim();
    final customPhone = _phoneController.text.trim();

    try {
      final success = await AuthService.instance.signInWithAccount(
        provider: provider,
        displayName: customName.isNotEmpty ? customName : '$provider Gamer',
        email: customEmail.isNotEmpty ? customEmail : 'user@${provider.toLowerCase()}.com',
        phone: customPhone,
      );

      if (mounted && success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HubDashboardScreen()),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _continueAsGuest() async {
    setState(() => _isLoading = true);
    await AuthService.instance.signInAsGuest();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HubDashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // App Logo
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.neonCyan, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.neonCyan.withValues(alpha: 0.35),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.gamepad_rounded,
                            color: AppTheme.neonCyan,
                            size: 38,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // App Title
                    const Text(
                      '6 IN 1 GAMES',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isLoginMode
                          ? 'Welcome Back! Log in to continue'
                          : 'Create your account & get +500 Welcome Coins!',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    // 1. Full Name / Gamer Tag
                    if (!_isLoginMode) ...[
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Full Name / Gamer Tag',
                          labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
                          hintText: 'e.g. Ali Khan',
                          hintStyle: const TextStyle(color: Colors.white30),
                          prefixIcon: const Icon(Icons.person_outline_rounded, color: AppTheme.neonCyan, size: 20),
                          filled: true,
                          fillColor: AppTheme.cardDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppTheme.neonCyan, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                        validator: (val) {
                          if (!_isLoginMode && (val == null || val.trim().isEmpty)) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    // 2. Email Address
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
                        hintText: 'e.g. user@gmail.com',
                        hintStyle: const TextStyle(color: Colors.white30),
                        prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.neonCyan, size: 20),
                        filled: true,
                        fillColor: AppTheme.cardDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppTheme.neonCyan, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!val.contains('@') || !val.contains('.')) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    // 3. Phone Number
                    if (!_isLoginMode) ...[
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
                          hintText: 'e.g. +92 300 1234567',
                          hintStyle: const TextStyle(color: Colors.white30),
                          prefixIcon: const Icon(Icons.phone_outlined, color: AppTheme.neonCyan, size: 20),
                          filled: true,
                          fillColor: AppTheme.cardDark,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppTheme.neonCyan, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                        validator: (val) {
                          if (!_isLoginMode && (val == null || val.trim().isEmpty)) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    // 4. Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
                        hintText: '••••••••',
                        hintStyle: const TextStyle(color: Colors.white30),
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.neonCyan, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: Colors.white54,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: AppTheme.cardDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppTheme.neonCyan, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (val.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Submit Button
                    if (_isLoading)
                      const CircularProgressIndicator(color: AppTheme.neonCyan)
                    else ...[
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.neonCyan,
                            foregroundColor: Colors.black,
                            elevation: 8,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            _isLoginMode ? 'SIGN IN' : 'CREATE ACCOUNT & GET +500 COINS',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Toggle Login / Sign Up
                      TextButton(
                        onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
                        child: Text(
                          _isLoginMode
                              ? "Don't have an account? Sign Up"
                              : 'Already have an account? Sign In',
                          style: const TextStyle(color: AppTheme.neonCyan, fontSize: 13),
                        ),
                      ),

                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white24)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('OR', style: TextStyle(color: Colors.white38, fontSize: 12)),
                          ),
                          Expanded(child: Divider(color: Colors.white24)),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Social Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _handleSocialLogin('Google'),
                              icon: const Icon(Icons.g_mobiledata_rounded, size: 24, color: Colors.white),
                              label: const Text('Google', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEA4335),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _handleSocialLogin('Facebook'),
                              icon: const Icon(Icons.facebook_rounded, size: 18, color: Colors.white),
                              label: const Text('Facebook', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1877F2),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Continue as Guest
                      TextButton(
                        onPressed: _continueAsGuest,
                        child: const Text(
                          'Skip & Play as Visitor (Sandbox Mode)',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
