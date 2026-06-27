class FinanceSummary {
  final int totalBalance;
  final int monthlyIncome;
  final int monthlyExpense;
  final int netCashFlow;

  FinanceSummary({
    required this.totalBalance,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.netCashFlow,
  });

  double get savingsRate {
    if (monthlyIncome == 0) return 0.0;
    return (netCashFlow / monthlyIncome) * 100;
  }
}
