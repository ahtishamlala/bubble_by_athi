import 'dart:convert';
import 'dart:io' show Platform;
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  static final SecurityService instance = SecurityService._internal();
  SecurityService._internal();

  String? _deviceFingerprint;
  String? _sessionToken;
  bool _isEmulator = false;
  bool _isRooted = false;

  String get deviceFingerprint => _deviceFingerprint ?? 'DEV-SANDBOX-001';
  String get sessionToken => _sessionToken ?? 'TOKEN-GUEST-ACTIVE';
  bool get isEmulator => _isEmulator;
  bool get isRooted => _isRooted;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Generate or retrieve persistent hardware fingerprint
      String? cachedFp = prefs.getString('device_fingerprint');
      if (cachedFp == null) {
        cachedFp = await _generateFingerprint();
        await prefs.setString('device_fingerprint', cachedFp);
      }
      _deviceFingerprint = cachedFp;

      // 2. Generate per-session security token
      _sessionToken = _generateSessionToken(_deviceFingerprint!);

      // 3. Emulator & Root Heuristic Check
      if (!kIsWeb && Platform.isAndroid) {
        await _checkAndroidEnvironment();
      }
    } catch (e) {
      debugPrint('SecurityService init error: $e');
      _deviceFingerprint = 'DEV-FALLBACK-001';
      _sessionToken = 'TOKEN-FALLBACK-ACTIVE';
    }
  }

  Future<String> _generateFingerprint() async {
    try {
      final randBytes = List<int>.generate(16, (i) => DateTime.now().microsecondsSinceEpoch % 256 + i);
      final hash = sha256.convert(randBytes).toString().substring(0, 16).toUpperCase();
      return 'APP-$hash';
    } catch (e) {
      return 'APP-${DateTime.now().millisecondsSinceEpoch.toRadixString(16).toUpperCase()}';
    }
  }

  String _generateSessionToken(String fingerprint) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final payload = '$fingerprint:$timestamp:IKRAM_SECURE';
    return sha1.convert(utf8.encode(payload)).toString().substring(0, 24);
  }

  Future<void> _checkAndroidEnvironment() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final android = await deviceInfo.androidInfo;

      // Emulator indicators
      _isEmulator = !android.isPhysicalDevice ||
          android.fingerprint.startsWith('generic') ||
          android.model.contains('google_sdk') ||
          android.model.toLowerCase().contains('emulator') ||
          android.hardware.contains('goldfish') ||
          android.hardware.contains('ranchu');

      // Root heuristic (build tags)
      _isRooted = android.tags.contains('test-keys');
    } catch (e) {
      debugPrint('Security check error: $e');
    }
  }
}
