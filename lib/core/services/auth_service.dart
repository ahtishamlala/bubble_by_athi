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
  bool get isAuthenticated => _currentUser != null;
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
      } else {
        // Auto-login as Guest / Visitor
        await signInAsGuest();
      }
    } catch (e) {
      debugPrint('AuthService init error: $e');
      await signInAsGuest();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInAsGuest() async {
    final fp = SecurityService.instance.deviceFingerprint;
    final shortId = fp.length > 8 ? fp.substring(fp.length - 6) : 'GUEST';
    final referralCode = 'IKRAM-$shortId';

    _currentUser = UserProfile(
      uid: 'guest_$shortId',
      displayName: 'Cyber Guest #$shortId',
      email: '',
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

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate/Trigger Google OAuth
      await Future.delayed(const Duration(milliseconds: 1200));

      final fp = SecurityService.instance.deviceFingerprint;
      final shortId = fp.length > 8 ? fp.substring(fp.length - 6) : 'GOOGLE';
      final currentGems = _currentUser?.gemsBalance ?? 350;

      _currentUser = UserProfile(
        uid: 'g_$shortId',
        displayName: 'Google Player',
        email: 'player_$shortId@gmail.com',
        avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120',
        gemsBalance: currentGems + 100, // Linked bonus
        referralCode: 'IKRAM-$shortId',
        isGuest: false,
        joinedAt: _currentUser?.joinedAt ?? DateTime.now(),
        totalLevelsCleared: _currentUser?.totalLevelsCleared ?? 0,
      );

      await _saveToStorage();
      return true;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithFacebook() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate/Trigger Facebook OAuth
      await Future.delayed(const Duration(milliseconds: 1200));

      final fp = SecurityService.instance.deviceFingerprint;
      final shortId = fp.length > 8 ? fp.substring(fp.length - 6) : 'FB';
      final currentGems = _currentUser?.gemsBalance ?? 350;

      _currentUser = UserProfile(
        uid: 'fb_$shortId',
        displayName: 'Facebook Player',
        email: 'fb_user_$shortId@facebook.com',
        avatarUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=120',
        gemsBalance: currentGems + 100, // Linked bonus
        referralCode: 'IKRAM-$shortId',
        isGuest: false,
        joinedAt: _currentUser?.joinedAt ?? DateTime.now(),
        totalLevelsCleared: _currentUser?.totalLevelsCleared ?? 0,
      );

      await _saveToStorage();
      return true;
    } catch (e) {
      debugPrint('Facebook Sign-In Error: $e');
      return false;
    } finally {
      _isLoading = false;
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
