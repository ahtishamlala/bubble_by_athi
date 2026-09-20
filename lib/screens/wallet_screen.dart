import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_constants.dart';
import '../core/services/wallet_service.dart';
import '../core/theme/app_theme.dart';
import 'admin_settlement_dialog.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double selectedAmountUsdt = 5.0;
  String selectedNetwork = 'Binance Pay'; // 'Binance Pay', 'USDT (TRC-20)', 'USDT (BEP-20)'
  final TextEditingController _destController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> networks = [
    'Binance Pay',
    'USDT (TRC-20)',
    'USDT (BEP-20)',
  ];

  @override
  void dispose() {
    _destController.dispose();
    super.dispose();
  }

  void _onHeaderTapped() {
    final triggered = WalletService.instance.recordHeaderTap();
    if (triggered) {
      HapticFeedback.heavyImpact();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AdminSettlementDialog(),
      );
    }
  }

  void _submitWithdrawal() async {
    final dest = _destController.text.trim();
    if (dest.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your recipient Binance ID or Crypto Address!'),
          backgroundColor: AppTheme.neonPink,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await WalletService.instance.submitWithdrawal(
        amountUsdt: selectedAmountUsdt,
        network: selectedNetwork,
        destinationAddress: dest,
      );

      if (mounted) {
        _destController.clear();
        HapticFeedback.mediumImpact();
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppTheme.cardDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppTheme.neonGreen, width: 1.5),
            ),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppTheme.neonGreen),
                SizedBox(width: 8),
                Text('Redemption Submitted!', style: TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
            content: Text(
              'Your request for \$${selectedAmountUsdt.toStringAsFixed(2)} USDT has been queued for verification. It will be credited to your $selectedNetwork account shortly.',
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonGreen),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.neonPink,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: WalletService.instance,
      builder: (context, _) {
        final wallet = WalletService.instance;
        final gems = wallet.gemsBalance;
        final usdt = wallet.usdtEquivalent;
        final requests = wallet.requests;

        return Scaffold(
          appBar: AppBar(
            title: GestureDetector(
              onTap: _onHeaderTapped,
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_balance_wallet_rounded, color: AppTheme.neonCyan, size: 20),
                    SizedBox(width: 8),
                    Text('Crypto Rewards Wallet'),
                  ],
                ),
              ),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Balance Card
                GestureDetector(
                  onTap: _onHeaderTapped,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.neonBoxDecoration(borderColor: AppTheme.neonCyan),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TOTAL GEMS BALANCE',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.neonCyan.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.4)),
                              ),
                              child: const Text(
                                '1,000 Gems = \$1.00 USDT',
                                style: TextStyle(color: AppTheme.neonCyan, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '💎 $gems',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '≈ \$${usdt.toStringAsFixed(2)} USDT',
                              style: const TextStyle(
                                color: AppTheme.neonGold,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Payout Form Card
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
                      const Text(
                        'Redeem USDT (Binance / On-Chain)',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 14),

                      // Quick Selection Chips
                      const Text('Select Amount:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 8),
                      Row(
                        children: AppConstants.withdrawalTiersUsdt.map((tier) {
                          final isSelected = selectedAmountUsdt == tier;

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text('\$$tier USDT'),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() => selectedAmountUsdt = tier);
                                HapticFeedback.selectionClick();
                              },
                              selectedColor: AppTheme.neonCyan,
                              backgroundColor: AppTheme.backgroundDark,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      // Payout Network Dropdown
                      const Text('Payout Network / Method:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderGlow),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedNetwork,
                            isExpanded: true,
                            dropdownColor: AppTheme.cardDark,
                            items: networks.map((net) {
                              return DropdownMenuItem(
                                value: net,
                                child: Text(net, style: const TextStyle(color: Colors.white, fontSize: 14)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => selectedNetwork = val);
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Recipient Address / ID TextField
                      Text(
                        selectedNetwork == 'Binance Pay'
                            ? 'Binance Pay ID / UID / Email:'
                            : (selectedNetwork == 'USDT (TRC-20)'
                                ? 'Tron (TRC-20) Address (Starts with T, 34 chars):'
                                : 'BNB Chain (BEP-20) Address (Starts with 0x, 42 chars):'),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _destController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: selectedNetwork == 'Binance Pay'
                              ? 'e.g. 849201948 or user@binance.com'
                              : (selectedNetwork == 'USDT (TRC-20)'
                                  ? 'e.g. TX... (34 characters)'
                                  : 'e.g. 0x... (42 characters)'),
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: AppTheme.backgroundDark,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.borderGlow),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submitWithdrawal,
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: Text('REDEEM \$${selectedAmountUsdt.toStringAsFixed(2)} USDT (${(selectedAmountUsdt * AppConstants.gemsPerUsdt).round()} GEMS)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.neonGreen,
                            foregroundColor: Colors.black,
                            elevation: 6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Withdrawal History Ledger
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Withdrawal History & Ledger',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      '${requests.length} Records',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (requests.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text('No withdrawals yet. Play arcade games to earn Gems!', style: TextStyle(color: Colors.white38)),
                    ),
                  )
                else
                  ...requests.map((req) {
                    final statusColor = _getStatusColor(req.status);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderGlow),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '\$${req.amountUsdt.toStringAsFixed(2)} USDT',
                                style: const TextStyle(color: AppTheme.neonCyan, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  req.status,
                                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${req.network} • To: ${req.destinationAddress}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ID: ${req.id}',
                                style: const TextStyle(color: Colors.white38, fontSize: 11),
                              ),
                              Text(
                                '${req.date.year}-${req.date.month.toString().padLeft(2, '0')}-${req.date.day.toString().padLeft(2, '0')}',
                                style: const TextStyle(color: Colors.white38, fontSize: 11),
                              ),
                            ],
                          ),
                          if (req.txHash != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'TxHash: ${req.txHash}',
                                style: const TextStyle(color: AppTheme.neonGreen, fontSize: 11),
                              ),
                            ),
                          if (req.rejectionReason != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Reason: ${req.rejectionReason}',
                                style: const TextStyle(color: AppTheme.neonPink, fontSize: 11),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved / Paid':
        return AppTheme.neonGreen;
      case 'Processing':
        return AppTheme.neonGold;
      case 'Rejected':
        return AppTheme.neonPink;
      default:
        return Colors.white54;
    }
  }
}
