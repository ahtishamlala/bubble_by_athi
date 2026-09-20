import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_profile.dart';
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

  Future<bool> signUpWithCredentials({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final fp = SecurityService.instance.deviceFingerprint;
      final shortId = fp.length > 8 ? fp.substring(fp.length - 6) : 'USER';
      final cleanName = name.trim().isEmpty ? 'Gamer' : name.trim();
      final cleanEmail = email.trim();
      final cleanPhone = phone.trim();

      // Referral code based on user name (no IKRAM-)
      final nameSlug = cleanName.toUpperCase().replaceAll(' ', '').replaceAll(RegExp(r'[^A-Z0-9]'), '');
      final refPrefix = nameSlug.length > 6 ? nameSlug.substring(0, 6) : (nameSlug.isEmpty ? 'USER' : nameSlug);
      final referralCode = '$refPrefix-$shortId';

      _currentUser = UserProfile(
        uid: 'usr_$shortId',
        displayName: cleanName,
        email: cleanEmail,
        phone: cleanPhone,
        avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120',
        gemsBalance: 500, // 500 Welcome Gems for registering
        referralCode: referralCode,
        isGuest: false,
        joinedAt: DateTime.now(),
        totalLevelsCleared: 0,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_password', password);
      await _saveToStorage();
      return true;
    } catch (e) {
      debugPrint('SignUp error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInAsGuest() async {
    final fp = SecurityService.instance.deviceFingerprint;
    final shortId = fp.length > 8 ? fp.substring(fp.length - 6) : 'GUEST';
    final referralCode = 'GUEST-$shortId';

    _currentUser = UserProfile(
      uid: 'guest_$shortId',
      displayName: 'Cyber Guest #$shortId',
      email: '',
      phone: '',
      avatarUrl: '',
      gemsBalance: 250, // Welcome gift for new player
      referralCode: referralCode,
      isGuest: true,
      joinedAt: DateTime.now(),
      totalLevelsCleared: 0,
    );

    await _saveToStorage();
    notifyListeners();
  }

  Future<bool> signInWithAccount({
    required String provider, // 'Google' or 'Facebook'
    required String displayName,
    required String email,
    String? phone,
    String? avatarUrl,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final fp = SecurityService.instance.deviceFingerprint;
      final shortId = fp.length > 8 ? fp.substring(fp.length - 6) : 'AUTH';
      final cleanName = displayName.trim().isEmpty ? '$provider Player' : displayName.trim();
      final cleanEmail = email.trim().isEmpty ? '${cleanName.toLowerCase().replaceAll(' ', '')}@gmail.com' : email.trim();
      final currentGems = _currentUser?.gemsBalance ?? 250;

      // Referral code based on user's name
      final nameSlug = cleanName.toUpperCase().replaceAll(' ', '').replaceAll(RegExp(r'[^A-Z0-9]'), '');
      final refPrefix = nameSlug.length > 6 ? nameSlug.substring(0, 6) : (nameSlug.isEmpty ? 'PLAYER' : nameSlug);
      final referralCode = '$refPrefix-$shortId';

      final defaultAvatar = provider == 'Google'
          ? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120'
          : 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=120';

      _currentUser = UserProfile(
        uid: '${provider.toLowerCase()}_$shortId',
        displayName: cleanName,
        email: cleanEmail,
        phone: phone ?? _currentUser?.phone ?? '',
        avatarUrl: avatarUrl ?? defaultAvatar,
        gemsBalance: currentGems + 100, // Account linking bonus
        referralCode: referralCode,
        isGuest: false,
        joinedAt: _currentUser?.joinedAt ?? DateTime.now(),
        totalLevelsCleared: _currentUser?.totalLevelsCleared ?? 0,
      );

      await _saveToStorage();
      return true;
    } catch (e) {
      debugPrint('$provider Sign-In Error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle({String? customName, String? customEmail, String? customPhone}) async {
    return signInWithAccount(
      provider: 'Google',
      displayName: customName ?? 'Google Player',
      email: customEmail ?? 'player@gmail.com',
      phone: customPhone,
      avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120',
    );
  }

  Future<bool> signInWithFacebook({String? customName, String? customEmail, String? customPhone}) async {
    return signInWithAccount(
      provider: 'Facebook',
      displayName: customName ?? 'Facebook Player',
      email: customEmail ?? 'player@facebook.com',
      phone: customPhone,
      avatarUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=120',
    );
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
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(displayName: name);
      await _saveToStorage();
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await signInAsGuest();
  }

  Future<void> _saveToStorage() async {
    if (_currentUser != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_user_profile', jsonEncode(_currentUser!.toJson()));
    }
  }
}
