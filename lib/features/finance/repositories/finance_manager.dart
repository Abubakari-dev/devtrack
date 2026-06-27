import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../data/finance_repository.dart';
import '../../projects/models/models.dart';

/// Professional Finance Manager for DevTrack.
/// Handles the core business logic for all financial transactions in a Tanzanian context.
/// Ensures Mapato (Income), Matumizi (Expenses), and Akiba (Savings) are perfectly balanced.
class FinanceManager {
  final AppDatabase _db;
  final FinanceRepository _cloudRepo = FinanceRepository();

  // Core Category Constants for consistent logic
  static const String CAT_INVESTMENT = 'INVESTMENT';
  static const String CAT_DEBT_BORROWED = 'DEBT_BORROWED';
  static const String CAT_DEBT_LENT = 'DEBT_LENT';
  static const String CAT_DEBT_REPAYMENT = 'DEBT_REPAYMENT';
  static const String CAT_DEBT_COLLECTION = 'DEBT_COLLECTION';

  FinanceManager(this._db);

  /// Centralized amount parser to prevent decimal errors.
  /// Standard: Input can be int (cents), double (standard), or String (from UI).
  /// If input is String, it is cleaned and converted to cents.
  /// If input is double, it is multiplied by 100 and rounded.
  /// If input is int, it is assumed to ALREADY be in cents.
  int parseToCents(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return (value * 100).round();
    if (value is String) {
      final cleaned = value.replaceAll(',', '').trim();
      if (cleaned.isEmpty) return 0;
      
      // Check if it's already an integer representation
      final asInt = int.tryParse(cleaned);
      if (asInt != null && !cleaned.contains('.')) {
        // If it looks like a raw integer String from a cents source
        // This is tricky. Let's assume String from UI is always standard (non-cents).
      }

      final parsed = double.tryParse(cleaned) ?? 0.0;
      return (parsed * 100).round();
    }
    return 0;
  }

  /// Records a financial transaction with atomic balance updates.
  /// Handles local Drift storage and triggers Cloud sync.
  Future<void> recordTransaction({
    required dynamic amount, // Can be String, double, or int (cents)
    required String type, // 'Income', 'Expense', 'Transfer'
    required String walletId,
    String? note,
    DateTime? date,
    String? categoryId,
    String? projectId,
    String? transactionId,
    bool syncToCloud = true,
  }) async {
    final txId = transactionId ?? const Uuid().v4();
    final txDate = date ?? DateTime.now();
    final int amountInt = parseToCents(amount);

    if (amountInt <= 0) return;

    await _db.transaction(() async {
      // Check if category exists before inserting to avoid Foreign Key errors
      String? validCategoryId = categoryId;
      if (categoryId != null) {
        final cat = await (_db.select(_db.categories)..where((c) => c.id.equals(categoryId))).getSingleOrNull();
        if (cat == null) {
          validCategoryId = null; // Fallback to no category if it doesn't exist
        }
      }

      // 1. Local Database Insert
      await _db.into(_db.transactions).insert(TransactionsCompanion.insert(
        id: Value(txId),
        amount: amountInt,
        type: type,
        walletId: walletId,
        note: Value(note),
        date: txDate,
        categoryId: Value(validCategoryId),
        projectId: Value(projectId),
      ));

      // 2. Atomic Balance Update
      await updateWalletBalance(walletId);

      // 3. Sync to Cloud
      if (syncToCloud) {
        _syncTransactionToCloud(txId, amountInt, type, walletId, note, txDate, categoryId, projectId);
      }
    });
  }

  /// Specialized logic for Syncing and Unified View
  Future<void> _syncTransactionToCloud(
    String txId, int amountInt, String type, String walletId, 
    String? note, DateTime txDate, String? categoryId, String? projectId
  ) async {
    try {
      // Save raw transaction
      await _cloudRepo.saveTransaction({
        'id': txId,
        'amount': amountInt,
        'type': type,
        'walletId': walletId,
        'note': note,
        'date': txDate.toIso8601String(),
        'projectId': projectId,
        'categoryId': categoryId,
      });

      // Handle dual-recording for legacy "Payments" and "Expenses" collections in Firestore
      // This ensures compatibility with existing Firestore-based analytics screens.
      await _handleUnifiedFinanceSync(
        txId: txId,
        amountInt: amountInt,
        type: type,
        categoryId: categoryId,
        projectId: projectId,
        walletId: walletId,
        note: note,
        txDate: txDate,
      );
    } catch (e) {
      debugPrint('Cloud sync failed for transaction $txId: $e');
    }
  }

  /// Ensures every expense/income is visible in the legacy Expenses/Payments lists
  Future<void> _handleUnifiedFinanceSync({
    required String txId,
    required int amountInt,
    required String type,
    String? categoryId,
    String? projectId,
    required String walletId,
    String? note,
    required DateTime txDate,
  }) async {
    final double amountDouble = amountInt / 100.0;
    
    if (type == 'Income') {
      String labelPrefix = '';
      bool isRevenue = true;

      if (categoryId == CAT_DEBT_BORROWED) {
        labelPrefix = '[Mkopo] ';
        isRevenue = false;
      } else if (categoryId == CAT_DEBT_COLLECTION) {
        labelPrefix = '[Malipo ya Deni] ';
        isRevenue = false;
      } else if (categoryId == CAT_INVESTMENT) {
        labelPrefix = '[Uwekezaji] ';
        isRevenue = false;
      }

      await _cloudRepo.recordPayment(Payment(
        id: txId,
        projectId: projectId ?? 'GENERAL', 
        label: '$labelPrefix${note ?? 'Mapato'}',
        amount: amountDouble, 
        date: txDate,
        isReceived: true,
        walletId: walletId,
      ));

      // Tanzanian Growth Logic: AKIBA (Auto-Savings)
      if (isRevenue && projectId != null && projectId != 'GENERAL') {
        _calculateAndNotifySavings(projectId, amountDouble);
      }
    } else if (type == 'Expense') {
      String labelPrefix = '';
      String categoryName = 'General';

      if (categoryId == CAT_DEBT_REPAYMENT) {
        labelPrefix = '[Kulipa Deni] ';
        categoryName = 'Debt Repayment';
      } else if (categoryId == CAT_DEBT_LENT) {
        labelPrefix = '[Kukopesha] ';
        categoryName = 'Lending';
      } else if (categoryId != null) {
        try {
          final cat = await (_db.select(_db.categories)..where((c) => c.id.equals(categoryId))).getSingle();
          categoryName = cat.name;
        } catch (_) {}
      }

      await _cloudRepo.recordExpense(Expense(
        id: txId,
        projectId: projectId ?? 'GENERAL', 
        name: '$labelPrefix${note ?? 'Matumizi'}',
        amount: amountDouble,
        date: txDate,
        category: categoryName,
      ));
    }
  }

  Future<void> _calculateAndNotifySavings(String projectId, double amountDouble) async {
    try {
      final projectData = await _cloudRepo.getProjectById(projectId);
      if (projectData != null) {
        final double savingsPercent = (projectData['savingsPercentage'] as num?)?.toDouble() ?? 0.0;
        if (savingsPercent > 0) {
          final double savingsAmount = amountDouble * (savingsPercent / 100.0);
          await _db.into(_db.reminders).insert(RemindersCompanion.insert(
            type: 'budget',
            relatedId: projectId,
            message: 'AKIBA (${savingsPercent}%): TSh ${NumberFormat('#,###').format(savingsAmount)} imetengwa kwa ukuaji.',
            scheduledDate: DateTime.now(),
          ));
        }
      }
    } catch (e) {
      debugPrint('Savings calc error: $e');
    }
  }

  /// Recalculates the balance of a wallet based on ALL transactions and transfers.
  /// This is the "Source of Truth" for account balances.
  Future<void> updateWalletBalance(String walletId) async {
    // 1. Standard Income/Expense Transactions
    final incomeQuery = _db.selectOnly(_db.transactions)
      ..addColumns([_db.transactions.amount.sum()])
      ..where(_db.transactions.walletId.equals(walletId) & _db.transactions.type.equals('Income'));
    final income = await incomeQuery.map((row) => row.read(_db.transactions.amount.sum())).getSingle() ?? 0;

    final expenseQuery = _db.selectOnly(_db.transactions)
      ..addColumns([_db.transactions.amount.sum()])
      ..where(_db.transactions.walletId.equals(walletId) & _db.transactions.type.equals('Expense'));
    final expense = await expenseQuery.map((row) => row.read(_db.transactions.amount.sum())).getSingle() ?? 0;

    // 2. Transfers (Money moving between wallets)
    final transferOutQuery = _db.selectOnly(_db.transfers)
      ..addColumns([_db.transfers.amount.sum(), _db.transfers.fee.sum()])
      ..where(_db.transfers.fromWalletId.equals(walletId));
    final transferOutRow = await transferOutQuery.getSingle();
    final transferOut = (transferOutRow.read(_db.transfers.amount.sum()) ?? 0) + 
                        (transferOutRow.read(_db.transfers.fee.sum()) ?? 0);

    final transferInQuery = _db.selectOnly(_db.transfers)
      ..addColumns([_db.transfers.amount.sum()])
      ..where(_db.transfers.toWalletId.equals(walletId));
    final transferIn = await transferInQuery.map((row) => row.read(_db.transfers.amount.sum())).getSingle() ?? 0;

    // 3. Debt Payments (if not already covered by transactions)
    // Note: In our current logic, recordPayment in DebtRepository ALREADY creates a Transaction.
    // So we don't double-count them here.

    final newBalance = (income - expense - transferOut + transferIn).toInt();

    await (_db.update(_db.wallets)..where((w) => w.id.equals(walletId)))
        .write(WalletsCompanion(balance: Value(newBalance)));
    
    // Also sync wallet balance to cloud
    await _cloudRepo.saveWallet({
      'id': walletId,
      'balance': newBalance,
    });
  }

  /// Financial Summary for a specific project.
  Future<Map<String, double>> getProjectFinancialSummary(String projectId) async {
    final txs = await (_db.select(_db.transactions)..where((t) => t.projectId.equals(projectId))).get();
    
    int revenue = 0;      
    int directCosts = 0;   
    
    for (var tx in txs) {
      if (tx.type == 'Income') {
        // Exclude loans, debt collections and investments from Project Revenue
        if (tx.categoryId != CAT_DEBT_BORROWED && 
            tx.categoryId != CAT_DEBT_COLLECTION && 
            tx.categoryId != CAT_INVESTMENT) {
          revenue += tx.amount;
        }
      } else if (tx.type == 'Expense') {
        // Exclude debt repayments and lending from Project Costs
        if (tx.categoryId != CAT_DEBT_REPAYMENT && tx.categoryId != CAT_DEBT_LENT) {
          directCosts += tx.amount;
        }
      }
    }

    return {
      'revenue': revenue / 100.0,
      'directCosts': directCosts / 100.0,
      'grossProfit': (revenue - directCosts) / 100.0,
    };
  }

  /// Global Financial Dashboard Logic.
  /// Categorizes every cent into proper business buckets.
  Future<Map<String, double>> getGlobalFinancialSummary() async {
    final allTxs = await _db.select(_db.transactions).get();
    
    int totalProjectRevenue = 0;
    int totalProjectDirectCosts = 0;
    int generalOverheads = 0; 
    int financialIn = 0;      // Loans received, Debt collections, Investments
    int financialOut = 0;     // Loan repayments, Lending
    
    for (var tx in allTxs) {
      bool hasProject = tx.projectId != null && tx.projectId!.isNotEmpty && tx.projectId != 'GENERAL';

      if (tx.type == 'Income') {
        if (tx.categoryId == CAT_DEBT_BORROWED || 
            tx.categoryId == CAT_DEBT_COLLECTION || 
            tx.categoryId == CAT_INVESTMENT) {
          financialIn += tx.amount;
        } else {
          totalProjectRevenue += tx.amount;
        }
      } else if (tx.type == 'Expense') {
        if (tx.categoryId == CAT_DEBT_REPAYMENT || tx.categoryId == CAT_DEBT_LENT) {
          financialOut += tx.amount;
        } else if (hasProject) {
          totalProjectDirectCosts += tx.amount;
        } else {
          generalOverheads += tx.amount;
        }
      }
    }

    double rev = totalProjectRevenue / 100.0;
    double costs = totalProjectDirectCosts / 100.0;
    double overheads = generalOverheads / 100.0;
    double finIn = financialIn / 100.0;
    double finOut = financialOut / 100.0;

    return {
      'totalRevenue': rev,
      'directCosts': costs,
      'grossProfit': rev - costs,
      'generalOverheads': overheads,
      'operatingProfit': rev - costs - overheads,
      'netCashFlow': (rev + finIn) - (costs + overheads + finOut),
      'financialIn': finIn,
      'financialOut': finOut,
    };
  }
}

