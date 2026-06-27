import '../../../../core/database/app_database.dart';

class BudgetWithProgress {
  final Budget budget;
  final Category? category;
  final int spentAmount;
  final DateTime startDate;
  final DateTime endDate;
  final List<BudgetItem> items;

  BudgetWithProgress({
    required this.budget,
    this.category,
    required this.spentAmount,
    required this.startDate,
    required this.endDate,
    this.items = const [],
  });

  double get progressPercent => budget.amount == 0 ? 0 : spentAmount / budget.amount;
  int get remainingAmount => budget.amount - spentAmount;
  
  bool get isOverspent => spentAmount > budget.amount;

  double get predictedSpending {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return spentAmount.toDouble();
    if (now.isBefore(startDate)) return 0;
    
    final daysPassed = now.difference(startDate).inDays + 1;
    final totalDays = endDate.difference(startDate).inDays + 1;
    
    final dailyAverage = spentAmount / daysPassed;
    return dailyAverage * totalDays;
  }
}
