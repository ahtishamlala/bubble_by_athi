import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_profile.dart';
import 'email_otp_service.dart';
import 'security_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  UserProfile? _currentUser;
  bool _isLoading = false;

  UserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null && !_currentUser!.isGuest;
  bool get isGuest => _currentUser?.isGuest ?? true;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJsonStr = prefs.getString('auth_user_profile');

      if (userJsonStr != null) {
        final Map<String, dynamic> json = jsonDecode(userJsonStr);
        _currentUser = UserProfile.fromJson(json);
      }
    } catch (e) {
      debugPrint('AuthService init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Verifies entered 6-digit OTP code and registers an authentic account
  Future<bool> verifyAndRegisterWithOtp({
    required String name,
    required String email,
    required String password,
    required String otpCode,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final isValid = EmailOtpService.instance.verifyOtp(otpCode);
      if (!isValid) {
        throw Exception('Invalid or expired OTP code! Please enter the correct 6-digit code.');
      }

      final fp = SecurityService.instance.deviceFingerprint;
      final shortId = fp.length > 8 ? fp.substring(fp.length - 6) : 'USER';
      final cleanName = name.trim().isEmpty ? 'Gamer' : name.trim();
      final cleanEmail = email.trim();

      // Referral code based on user's name
      final nameSlug = cleanName.toUpperCase().replaceAll(' ', '').replaceAll(RegExp(r'[^A-Z0-9]'), '');
      final refPrefix = nameSlug.length > 6 ? nameSlug.substring(0, 6) : (nameSlug.isEmpty ? 'USER' : nameSlug);
      final referralCode = '$refPrefix-$shortId';

      _currentUser = UserProfile(
        uid: 'usr_$shortId',
        displayName: cleanName,
        email: cleanEmail,
        avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120',
        gemsBalance: 500, // 500 Welcome Coins
        referralCode: referralCode,
        isGuest: false,
        joinedAt: DateTime.now(),
        totalLevelsCleared: 0,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_password', password);
      await prefs.setString('auth_email', cleanEmail);
      await prefs.setString('auth_name', cleanName);
      await _saveToStorage();
      return true;
    } catch (e) {
      debugPrint('verifyAndRegisterWithOtp error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in existing user directly with email and password
  Future<bool> quickLoginWithCredentials({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('auth_email') ?? '';
      final savedPass = prefs.getString('auth_password') ?? '';
      final savedName = prefs.getString('auth_name') ?? 'Gamer';

      if (savedEmail.isNotEmpty && savedEmail.toLowerCase() == email.trim().toLowerCase()) {
        if (savedPass.isNotEmpty && savedPass != password.trim()) {
          throw Exception('Incorrect password! Please recheck your password.');
        }
      }

      final fp = SecurityService.instance.deviceFingerprint;
      final shortId = fp.length > 8 ? fp.substring(fp.length - 6) : 'USER';
      final cleanName = savedName.isNotEmpty ? savedName : 'Gamer';

      final nameSlug = cleanName.toUpperCase().replaceAll(' ', '').replaceAll(RegExp(r'[^A-Z0-9]'), '');
      final refPrefix = nameSlug.length > 6 ? nameSlug.substring(0, 6) : 'USER';
      final referralCode = '$refPrefix-$shortId';

      _currentUser = UserProfile(
        uid: 'usr_$shortId',
        displayName: cleanName,
        email: email.trim(),
        avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120',
        gemsBalance: _currentUser?.gemsBalance ?? 500,
        referralCode: referralCode,
        isGuest: false,
        joinedAt: DateTime.now(),
        totalLevelsCleared: 0,
      );

      await prefs.setString('auth_email', email.trim());
      await prefs.setString('auth_password', password.trim());
      await _saveToStorage();
      return true;
    } catch (e) {
      debugPrint('quickLogin error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Legacy helper for backward compatibility
  Future<bool> signUpWithCredentials({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    return quickLoginWithCredentials(email: email, password: password);
  }

  Future<bool> signInWithAccount({
    required String provider,
    required String displayName,
    required String email,
    String? phone,
    String? avatarUrl,
  }) async {
    return quickLoginWithCredentials(email: email, password: 'SocialUser123');
  }

  /// Updates profile details (photo, date of birth, gender, name)
  Future<void> updateProfileDetails({
    String? displayName,
    String? avatarPath,
    String? avatarUrl,
    String? dateOfBirth,
    String? gender,
  }) async {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        displayName: displayName ?? _currentUser!.displayName,
        avatarPath: avatarPath ?? _currentUser!.avatarPath,
        avatarUrl: avatarUrl ?? _currentUser!.avatarUrl,
        dateOfBirth: dateOfBirth ?? _currentUser!.dateOfBirth,
        gender: gender ?? _currentUser!.gender,
      );
      await _saveToStorage();
      notifyListeners();
    }
  }

  Future<void> updateGems(int newBalance) async {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(gemsBalance: newBalance);
      await _saveToStorage();
      notifyListeners();
    }
  }

  Future<void> incrementLevelsCleared() async {
    if (_currentUser != null) {
      final updatedCount = _currentUser!.totalLevelsCleared + 1;
      _currentUser = _currentUser!.copyWith(totalLevelsCleared: updatedCount);
      await _saveToStorage();
      notifyListeners();
    }
  }

  Future<void> updateDisplayName(String name) async {
    await updateProfileDetails(displayName: name);
  }

  Future<void> continueAsGuest() async {
    final randId = DateTime.now().millisecondsSinceEpoch % 10000;
    _currentUser = UserProfile(
      uid: 'guest_$randId',
      displayName: 'Guest Player $randId',
      email: '',
      avatarUrl: '',
      gemsBalance: 200,
      referralCode: 'GUEST-$randId',
      isGuest: true,
      joinedAt: DateTime.now(),
      totalLevelsCleared: 0,
    );
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_user_profile');
    _currentUser = null;
    notifyListeners();
  }

  /// Permanently deletes user account, credentials, and all local records pursuant to Google Play Policy
  Future<void> deleteAccountAndData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_user_profile');
    await prefs.remove('auth_email');
    await prefs.remove('auth_password');
    await prefs.remove('auth_name');
    await prefs.remove('wallet_withdrawal_history');
    await prefs.remove('device_fingerprint');
    _currentUser = null;
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    if (_currentUser != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_user_profile', jsonEncode(_currentUser!.toJson()));
    }
  }
}
