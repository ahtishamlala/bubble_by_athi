import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/withdrawal_request.dart';
import '../constants/app_constants.dart';
import 'auth_service.dart';

class WalletService extends ChangeNotifier {
  static final WalletService instance = WalletService._internal();
  WalletService._internal();

  final List<WithdrawalRequest> _requests = [];
  int _adminTapCount = 0;
  DateTime? _lastAdminTap;

  List<WithdrawalRequest> get requests => List.unmodifiable(_requests);

  int get gemsBalance => AuthService.instance.currentUser?.gemsBalance ?? 0;
  double get usdtEquivalent => gemsBalance / AppConstants.gemsPerUsdt;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('wallet_withdrawal_history');

      if (historyJson != null) {
        final List<dynamic> list = jsonDecode(historyJson);
        _requests.clear();
        for (final item in list) {
          _requests.add(WithdrawalRequest.fromJson(item as Map<String, dynamic>));
        }
      } else {
        // Add an initial sample request for demonstration
        _requests.add(
          WithdrawalRequest(
            id: 'REQ-DEMO-001',
            userId: AuthService.instance.currentUser?.uid ?? 'guest_001',
            date: DateTime.now().subtract(const Duration(days: 2)),
            amountUsdt: 5.0,
            gemsSpent: 5000,
            network: 'Binance Pay',
            destinationAddress: '839201948',
            txHash: 'BINANCE-PAY-TX-8921849',
            status: 'Approved / Paid',
          ),
        );
      }
    } catch (e) {
      debugPrint('WalletService init error: $e');
    }
    notifyListeners();
  }

  Future<void> addGems(int amount, {String reason = 'Game Reward'}) async {
    final current = gemsBalance;
    final newBalance = current + amount;
    await AuthService.instance.updateGems(newBalance);
    notifyListeners();
  }

  Future<bool> submitWithdrawal({
    required double amountUsdt,
    required String network,
    required String destinationAddress,
  }) async {
    final requiredGems = (amountUsdt * AppConstants.gemsPerUsdt).round();

    // 1. Balance validation
    if (gemsBalance < requiredGems) {
      throw Exception('Insufficient Gems! You need $requiredGems Gems for \$${amountUsdt.toStringAsFixed(2)} USDT.');
    }

    // 2. Minimum payout threshold check
    if (amountUsdt < AppConstants.minWithdrawalUsdt) {
      throw Exception('Minimum redemption threshold is \$${AppConstants.minWithdrawalUsdt.toStringAsFixed(2)} USDT (${AppConstants.minWithdrawalGems} Gems).');
    }

    // 3. Client-side Regex Validation
    final cleanDest = destinationAddress.trim();
    if (network == 'USDT (TRC-20)') {
      if (!AppConstants.isValidTrc20(cleanDest)) {
        throw Exception('Invalid TRC-20 Address! Must start with "T" and be exactly 34 characters.');
      }
    } else if (network == 'USDT (BEP-20)') {
      if (!AppConstants.isValidBep20(cleanDest)) {
        throw Exception('Invalid BEP-20 Address! Must start with "0x" and be 42 characters.');
      }
    } else if (network == 'Binance Pay') {
      if (!AppConstants.isValidBinancePay(cleanDest)) {
        throw Exception('Invalid Binance Pay ID! Enter an 8-10 digit Binance UID or registered email.');
      }
    }

    // 4. Deduct gems
    await AuthService.instance.updateGems(gemsBalance - requiredGems);

    // 5. Create request
    final newReq = WithdrawalRequest(
      id: 'REQ-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      userId: AuthService.instance.currentUser?.uid ?? 'unknown',
      date: DateTime.now(),
      amountUsdt: amountUsdt,
      gemsSpent: requiredGems,
      network: network,
      destinationAddress: cleanDest,
      status: 'Processing',
    );

    _requests.insert(0, newReq);
    await _saveHistory();
    notifyListeners();
    return true;
  }

  // Hidden 5-tap gesture detection
  bool recordHeaderTap() {
    final now = DateTime.now();
    if (_lastAdminTap == null || now.difference(_lastAdminTap!) > const Duration(seconds: 2)) {
      _adminTapCount = 1;
    } else {
      _adminTapCount++;
    }
    _lastAdminTap = now;

    if (_adminTapCount >= AppConstants.adminTriggerTaps) {
      _adminTapCount = 0;
      return true; // Trigger PIN dialog
    }
    return false;
  }

  // Admin Settlement Operations
  Future<void> markRequestCompleted(String requestId, String txHash) async {
    final idx = _requests.indexWhere((r) => r.id == requestId);
    if (idx != -1) {
      _requests[idx] = _requests[idx].copyWith(
        status: 'Approved / Paid',
        txHash: txHash.trim().isEmpty ? 'TX-${DateTime.now().millisecondsSinceEpoch}' : txHash.trim(),
      );
      await _saveHistory();
      notifyListeners();
    }
  }

  Future<void> markRequestRejected(String requestId, String reason) async {
    final idx = _requests.indexWhere((r) => r.id == requestId);
    if (idx != -1) {
      final req = _requests[idx];
      _requests[idx] = req.copyWith(
        status: 'Rejected',
        rejectionReason: reason,
      );

      // Refund the gems back to user
      await addGems(req.gemsSpent, reason: 'Withdrawal Refund');
      await _saveHistory();
      notifyListeners();
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _requests.map((r) => r.toJson()).toList();
    await prefs.setString('wallet_withdrawal_history', jsonEncode(jsonList));
  }
}
