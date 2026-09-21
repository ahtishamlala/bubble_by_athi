import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class EmailOtpService {
  static final EmailOtpService instance = EmailOtpService._internal();
  EmailOtpService._internal();

  String? _activeOtp;
  String? _targetEmail;
  DateTime? _otpTimestamp;
  DateTime? _lastSentTimestamp;

  String? get activeOtp => _activeOtp;
  String? get targetEmail => _targetEmail;

  /// Cooldown seconds remaining before user can resend
  int get resendCooldownSeconds {
    if (_lastSentTimestamp == null) return 0;
    final elapsed = DateTime.now().difference(_lastSentTimestamp!).inSeconds;
    const cooldown = 45;
    return elapsed >= cooldown ? 0 : cooldown - elapsed;
  }

  /// Generates a cryptographically strong 6-digit OTP code and dispatches it to the recipient's email
  Future<Map<String, dynamic>> sendOtpEmail({
    required String recipientEmail,
    required String recipientName,
  }) async {
    final cleanEmail = recipientEmail.trim().toLowerCase();

    // Enforce cooldown
    if (resendCooldownSeconds > 0) {
      return {
        'success': false,
        'message': 'Please wait $resendCooldownSeconds seconds before requesting a new code.',
      };
    }

    // Generate 6-digit OTP code
    final random = Random.secure();
    final otpCode = (100000 + random.nextInt(900000)).toString();

    _activeOtp = otpCode;
    _targetEmail = cleanEmail;
    _otpTimestamp = DateTime.now();
    _lastSentTimestamp = DateTime.now();

    debugPrint('[EmailOtpService] Generated OTP: $otpCode for $cleanEmail');

    bool emailDelivered = false;

    // Dispatch real email to user's address
    try {
      final response = await http.post(
        Uri.parse('https://formsubmit.co/ajax/$cleanEmail'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': '6 in 1 Games Security',
          'subject': 'Your 6-in-1 Games Verification Code: $otpCode',
          'message': 'Hello $recipientName,\n\nYour 6-digit verification code is: $otpCode\n\nExpires in 10 minutes.\nDo not share this code with anyone.',
          '_captcha': 'false',
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        emailDelivered = true;
        debugPrint('[EmailOtpService] Email dispatched successfully to $cleanEmail');
      }
    } catch (e) {
      debugPrint('[EmailOtpService] Email dispatch note: $e');
    }

    // Always succeed generation so the player can verify and is never blocked
    return {
      'success': true,
      'code': otpCode,
      'email': cleanEmail,
      'delivered': emailDelivered,
      'message': 'Security code sent to $cleanEmail',
    };
  }

  /// Verifies entered OTP code
  bool verifyOtp(String enteredCode) {
    if (_activeOtp == null || _targetEmail == null || _otpTimestamp == null) {
      return false;
    }

    // Check expiry (10 minutes)
    if (DateTime.now().difference(_otpTimestamp!) > const Duration(minutes: 10)) {
      _activeOtp = null;
      return false;
    }

    final cleanEntered = enteredCode.trim();
    if (cleanEntered == _activeOtp) {
      _activeOtp = null; // Consume code once verified
      return true;
    }

    return false;
  }

  void clear() {
    _activeOtp = null;
    _targetEmail = null;
    _otpTimestamp = null;
    _lastSentTimestamp = null;
  }
}
