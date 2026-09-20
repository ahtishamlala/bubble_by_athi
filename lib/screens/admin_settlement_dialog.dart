import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_constants.dart';
import '../core/services/wallet_service.dart';
import '../core/theme/app_theme.dart';
import '../models/withdrawal_request.dart';

class AdminSettlementDialog extends StatefulWidget {
  const AdminSettlementDialog({super.key});

  @override
  State<AdminSettlementDialog> createState() => _AdminSettlementDialogState();
}

class _AdminSettlementDialogState extends State<AdminSettlementDialog> {
  final TextEditingController _pinController = TextEditingController();
  bool _isAuthenticated = false;
  String? _pinError;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _verifyPin() {
    if (_pinController.text.trim() == AppConstants.adminPin) {
      setState(() {
        _isAuthenticated = true;
        _pinError = null;
      });
      HapticFeedback.mediumImpact();
    } else {
      setState(() {
        _pinError = 'Incorrect Admin PIN!';
      });
      HapticFeedback.heavyImpact();
    }
  }

  void _showCompleteDialog(WithdrawalRequest req) {
    final txController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Complete Payout', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Request ID: ${req.id}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            Text('Amount: \$${req.amountUsdt.toStringAsFixed(2)} USDT', style: const TextStyle(color: AppTheme.neonGreen, fontWeight: FontWeight.bold)),
            Text('Destination: ${req.destinationAddress}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 14),
            TextField(
              controller: txController,
              decoration: InputDecoration(
                labelText: 'Paste Binance TxID / Hash (Optional)',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: AppTheme.backgroundDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await WalletService.instance.markRequestCompleted(
                req.id,
                txController.text,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Request ${req.id} marked as Approved / Paid!'),
                    backgroundColor: AppTheme.neonGreen,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonGreen),
            child: const Text('Mark Paid'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(WithdrawalRequest req) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Reject Redemption', style: TextStyle(color: AppTheme.neonPink)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Request ID: ${req.id}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 6),
            const Text(
              'Rejecting this request will automatically refund the spent Gems back to the user\'s wallet.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Reason for Rejection',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: AppTheme.backgroundDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await WalletService.instance.markRequestRejected(
                req.id,
                reasonController.text.trim().isEmpty ? 'Invalid destination' : reasonController.text.trim(),
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Request ${req.id} rejected and Gems refunded.'),
                    backgroundColor: AppTheme.neonPink,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonPink),
            child: const Text('Reject & Refund'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.neonCyan, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings_rounded, color: AppTheme.neonCyan),
            SizedBox(width: 8),
            Text('Owner Console', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your Admin PIN to inspect and settle crypto payouts:', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 14),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'PIN (Default: 7860)',
                hintStyle: const TextStyle(color: Colors.white38),
                errorText: _pinError,
                filled: true,
                fillColor: AppTheme.backgroundDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (_) => _verifyPin(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: _verifyPin,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonCyan),
            child: const Text('Unlock'),
          ),
        ],
      );
    }

    return ListenableBuilder(
      listenable: WalletService.instance,
      builder: (context, _) {
        final requests = WalletService.instance.requests;

        return Dialog(
          backgroundColor: AppTheme.backgroundDark,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            width: double.maxFinite,
            height: 600,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.neonCyan, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.admin_panel_settings_rounded, color: AppTheme.neonCyan, size: 24),
                        SizedBox(width: 8),
                        Text('Owner Settlement Console', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(color: AppTheme.borderGlow),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Total Requests: ${requests.length} • Pending: ${requests.where((r) => r.status == 'Processing').length}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 12),

                // Requests List
                Expanded(
                  child: requests.isEmpty
                      ? const Center(child: Text('No redemption requests found.', style: TextStyle(color: Colors.white38)))
                      : ListView.separated(
                          itemCount: requests.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final req = requests[i];
                            final isPending = req.status == 'Processing';

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.cardDark,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isPending ? AppTheme.neonGold : AppTheme.borderGlow,
                                  width: isPending ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(req.id, style: const TextStyle(color: AppTheme.neonCyan, fontWeight: FontWeight.bold, fontSize: 13)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(req.status).withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          req.status,
                                          style: TextStyle(color: _getStatusColor(req.status), fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '\$${req.amountUsdt.toStringAsFixed(2)} USDT (${req.gemsSpent} Gems) • ${req.network}',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  // Destination Address with 1-tap copy
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'To: ${req.destinationAddress}',
                                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.copy_rounded, size: 16, color: AppTheme.neonCyan),
                                        tooltip: 'Copy Destination for Binance App',
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(text: req.destinationAddress));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Address copied! Paste into Binance app to send.'),
                                              duration: Duration(seconds: 2),
                                              backgroundColor: AppTheme.neonCyan,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  if (req.txHash != null)
                                    Text('TxID: ${req.txHash}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                  if (req.rejectionReason != null)
                                    Text('Reason: ${req.rejectionReason}', style: const TextStyle(color: AppTheme.neonPink, fontSize: 11)),

                                  if (isPending) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton(
                                          onPressed: () => _showRejectDialog(req),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppTheme.neonPink,
                                            side: const BorderSide(color: AppTheme.neonPink),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          ),
                                          child: const Text('Reject', style: TextStyle(fontSize: 12)),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () => _showCompleteDialog(req),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.neonGreen,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                          ),
                                          child: const Text('Mark Paid', style: TextStyle(fontSize: 12)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),
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
