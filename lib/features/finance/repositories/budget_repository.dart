import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/notification_service.dart';
import '../data/finance_repository.dart';
import 'finance_manager.dart';

class BudgetRepository {
  final AppDatabase _db;
  final FinanceRepository _cloudRepo = FinanceRepository();
  late final FinanceManager _financeManager;

  BudgetRepository(this._db) {
    _financeManager = FinanceManager(_db);
  }

  Future<List<Budget>> getAllBudgets() => _db.select(_db.budgets).get();

  Stream<List<Budget>> watchAllBudgets() => _db.select(_db.budgets).watch();

  Future<int> addBudget(BudgetsCompanion budget) async {
    final id = await _db.into(_db.budgets).insert(budget);
    final newBudget = await (_db.select(_db.budgets)..where((t) => t.id.equals(budget.id.value))).getSingle();
    
    // Sync to Cloud
    await _cloudRepo.saveBudget({
      'id': newBudget.id,
      'name': newBudget.name,
      'categoryId': newBudget.categoryId,
      'period': newBudget.period,
      'amount': newBudget.amount,
      'rolloverEnabled': newBudget.rolloverEnabled,
    });
    
    return id;
  }

  Future<bool> updateBudget(Budget budget) async {
    final success = await _db.update(_db.budgets).replace(budget);
    if (success) {
      // Sync to Cloud
      await _cloudRepo.saveBudget({
        'id': budget.id,
        'name': budget.name,
        'categoryId': budget.categoryId,
        'period': budget.period,
        'amount': budget.amount,
        'rolloverEnabled': budget.rolloverEnabled,
      });
    }
    return success;
  }

  Future<int> deleteBudget(String id) => 
    (_db.delete(_db.budgets)..where((t) => t.id.equals(id))).go();

  Future<List<BudgetItem>> getItemsForBudget(String budgetId) => 
    (_db.select(_db.budgetItems)..where((t) => t.budgetId.equals(budgetId))).get();

  Stream<List<BudgetItem>> watchItemsForBudget(String budgetId) => 
    (_db.select(_db.budgetItems)..where((t) => t.budgetId.equals(budgetId))).watch();

  Future<int> addBudgetItem(BudgetItemsCompanion item) => _db.into(_db.budgetItems).insert(item);

  Future<bool> updateBudgetItem(BudgetItem item) => _db.update(_db.budgetItems).replace(item);

  Future<int> deleteBudgetItem(String id) => 
    (_db.delete(_db.budgetItems)..where((t) => t.id.equals(id))).go();

  Future<void> markItemAsSpent(BudgetItem item, int actualPrice, String walletId) async {
    return _db.transaction(() async {
      // 1. Update the BudgetItem locally
      await _db.update(_db.budgetItems).replace(item.copyWith(
        isChecked: true,
        actualPrice: Value(actualPrice),
      ));

      // 2. Get budget info to find category
      final budget = await (_db.select(_db.budgets)..where((t) => t.id.equals(item.budgetId))).getSingle();
      
      final transactionId = const Uuid().v4();
      final now = DateTime.now();

      // 3. Record the transaction using FinanceManager
      // This handles: Local insertion, Wallet balance update, Cloud Sync, and Project Sync if applicable
      await _financeManager.recordTransaction(
        transactionId: transactionId,
        amount: actualPrice, // Passing int (cents) directly
        type: 'Expense',
        walletId: walletId,
        date: now,
        note: 'Budget Item: ${item.name}',
        categoryId: budget.categoryId,
      );

      // 4. Check Budget Status for notification
      final start = DateTime(now.year, now.month, 1); // Simple monthly check
      final end = DateTime(now.year, now.month + 1, 0);
      final totalSpent = await getSpendingForCategory(budget.categoryId, start, end);
      
      await AppNotificationService.instance.checkBudgetStatus(
        budget.name ?? 'Budget',
        budget.amount.toDouble(),
        totalSpent.toDouble(),
      );
    });
  }

  Future<int> getSpendingForCategory(String? categoryId, DateTime start, DateTime end) async {
    // If categoryId is null, it's a total budget (all expense transactions)
    final query = _db.selectOnly(_db.transactions);
    query.addColumns([_db.transactions.amount.sum()]);
    
    Expression<bool> predicate = _db.transactions.type.equals('Expense') & 
                                  _db.transactions.date.isBetweenValues(start, end);
    
    if (categoryId != null) {
      // Need to join with TransactionSplits to get category-specific spending
      final splitQuery = _db.selectOnly(_db.transactionSplits)
        ..addColumns([_db.transactionSplits.amount.sum()])
        ..join([
          innerJoin(_db.transactions, _db.transactions.id.equalsExp(_db.transactionSplits.transactionId))
        ])
        ..where(_db.transactionSplits.categoryId.equals(categoryId) & 
               _db.transactions.date.isBetweenValues(start, end) &
               _db.transactions.type.equals('Expense'));
      
      final result = await splitQuery.getSingle();
      return result.read(_db.transactionSplits.amount.sum()) ?? 0;
    } else {
      query.where(predicate);
      final result = await query.getSingle();
      return result.read(_db.transactions.amount.sum()) ?? 0;
    }
  }
}
