class WalletSummary {
  final double balance;
  final double withdrawableBalance;
  final double totalEarned;
  final String currency;
  final int totalJobs;
  final int completedJobs;
  final int cancelledJobs;
  final double averageRating;

  WalletSummary({
    required this.balance,
    required this.withdrawableBalance,
    required this.totalEarned,
    required this.currency,
    required this.totalJobs,
    required this.completedJobs,
    required this.cancelledJobs,
    required this.averageRating,
  });

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    return WalletSummary(
      balance: (json['balance'] ?? 0).toDouble(),
      withdrawableBalance: (json['withdrawable_balance'] ?? 0).toDouble(),
      totalEarned: (json['total_earned'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'THB',
      totalJobs: json['total_jobs'] ?? 0,
      completedJobs: json['completed_jobs'] ?? 0,
      cancelledJobs: json['cancelled_jobs'] ?? 0,
      averageRating: (json['average_rating'] ?? 0).toDouble(),
    );
  }
}