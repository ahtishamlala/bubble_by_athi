class WithdrawalRequest {
  final String id;
  final String userId;
  final DateTime date;
  final double amountUsdt;
  final int gemsSpent;
  final String network; // 'Binance Pay', 'USDT (TRC-20)', 'USDT (BEP-20)'
  final String destinationAddress;
  final String? txHash;
  final String status; // 'Processing', 'Approved / Paid', 'Rejected'
  final String? rejectionReason;

  WithdrawalRequest({
    required this.id,
    required this.userId,
    required this.date,
    required this.amountUsdt,
    required this.gemsSpent,
    required this.network,
    required this.destinationAddress,
    this.txHash,
    this.status = 'Processing',
    this.rejectionReason,
  });

  WithdrawalRequest copyWith({
    String? id,
    String? userId,
    DateTime? date,
    double? amountUsdt,
    int? gemsSpent,
    String? network,
    String? destinationAddress,
    String? txHash,
    String? status,
    String? rejectionReason,
  }) {
    return WithdrawalRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      amountUsdt: amountUsdt ?? this.amountUsdt,
      gemsSpent: gemsSpent ?? this.gemsSpent,
      network: network ?? this.network,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      txHash: txHash ?? this.txHash,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'amountUsdt': amountUsdt,
      'gemsSpent': gemsSpent,
      'network': network,
      'destinationAddress': destinationAddress,
      'txHash': txHash,
      'status': status,
      'rejectionReason': rejectionReason,
    };
  }

  factory WithdrawalRequest.fromJson(Map<String, dynamic> json) {
    return WithdrawalRequest(
      id: json['id'] as String? ?? 'REQ-${DateTime.now().millisecondsSinceEpoch}',
      userId: json['userId'] as String? ?? '',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      amountUsdt: (json['amountUsdt'] as num?)?.toDouble() ?? 5.0,
      gemsSpent: (json['gemsSpent'] as num?)?.toInt() ?? 5000,
      network: json['network'] as String? ?? 'Binance Pay',
      destinationAddress: json['destinationAddress'] as String? ?? '',
      txHash: json['txHash'] as String?,
      status: json['status'] as String? ?? 'Processing',
      rejectionReason: json['rejectionReason'] as String?,
    );
  }
}
