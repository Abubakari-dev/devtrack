import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../core/providers/database_provider.dart';
import '../repositories/wallet_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/transaction_repository.dart';
import '../domain/use_cases/get_finance_summary_usecase.dart';
import '../services/finance_format_service.dart';
import '../domain/models/finance_summary.dart';
import 'package:devtrack/core/database/app_database.dart';
import '../repositories/debt_repository.dart';
import '../repositories/budget_repository.dart';
import '../repositories/transfer_repository.dart';
import '../domain/models/budget_with_progress.dart';
import '../data/finance_repository.dart';
import 'package:devtrack/features/projects/providers/projects_providers.dart';
import 'package:devtrack/features/projects/models/models.dart';

import '../repositories/finance_manager.dart';

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  return FinanceRepository();
});

final financeManagerProvider = Provider<FinanceManager>((ref) {
  return FinanceManager(ref.watch(databaseProvider));
});

final allPaymentsStreamProvider = StreamProvider<List<Payment>>((ref) {
  return ref.watch(transactionsStreamProvider.stream).map((txs) {
    return txs.where((t) => t.type == 'Income').map((t) {
      String catName = 'Mapato';
      if (t.categoryId == FinanceManager.CAT_DEBT_BORROWED) catName = 'Mkopo';
      if (t.categoryId == FinanceManager.CAT_DEBT_COLLECTION) catName = 'Malipo ya Deni';
      
      return Payment(
        id: t.id,
        projectId: t.projectId ?? 'GENERAL',
        label: t.note ?? catName,
        amount: t.amount / 100.0,
        date: t.date,
        isReceived: true,
        walletId: t.walletId,
      );
    }).toList();
  });
});

final allExpensesStreamProvider = StreamProvider<List<Expense>>((ref) {
  return ref.watch(transactionsStreamProvider.stream).map((txs) {
    return txs.where((t) => t.type == 'Expense').map((t) {
      String catName = 'Matumizi';
      if (t.categoryId == FinanceManager.CAT_DEBT_REPAYMENT) catName = 'Kulipa Deni';
      if (t.categoryId == FinanceManager.CAT_DEBT_LENT) catName = 'Kukopesha';
      
      return Expense(
        id: t.id,
        projectId: t.projectId ?? 'GENERAL',
        name: t.note ?? catName,
        amount: t.amount / 100.0,
        date: t.date,
        category: catName,
      );
    }).toList();
  });
});

final projectPaymentsStreamProvider = StreamProvider.family<List<Payment>, String>((ref, projectId) {
  return ref.watch(transactionsStreamProvider.stream).map((txs) {
    return txs.where((t) => t.type == 'Income' && t.projectId == projectId).map((t) {
      String catName = 'Mapato';
      if (t.categoryId == FinanceManager.CAT_DEBT_BORROWED) catName = 'Mkopo';
      if (t.categoryId == FinanceManager.CAT_DEBT_COLLECTION) catName = 'Malipo ya Deni';
      
      return Payment(
        id: t.id,
        projectId: t.projectId ?? 'GENERAL',
        label: t.note ?? catName,
        amount: t.amount / 100.0,
        date: t.date,
        isReceived: true,
        walletId: t.walletId,
      );
    }).toList();
  });
});

final projectExpensesStreamProvider = StreamProvider.family<List<Expense>, String>((ref, projectId) {
  return ref.watch(transactionsStreamProvider.stream).map((txs) {
    return txs.where((t) => t.type == 'Expense' && t.projectId == projectId).map((t) {
      String catName = 'Matumizi';
      if (t.categoryId == FinanceManager.CAT_DEBT_REPAYMENT) catName = 'Kulipa Deni';
      if (t.categoryId == FinanceManager.CAT_DEBT_LENT) catName = 'Kukopesha';
      
      return Expense(
        id: t.id,
        projectId: t.projectId ?? 'GENERAL',
        name: t.note ?? catName,
        amount: t.amount / 100.0,
        date: t.date,
        category: catName,
      );
    }).toList();
  });
});

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(ref.watch(databaseProvider));
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(databaseProvider));
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(databaseProvider));
});

final transferRepositoryProvider = Provider<TransferRepository>((ref) {
  return TransferRepository(
    ref.watch(databaseProvider),
  );
});

final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  return DebtRepository(ref.watch(databaseProvider));
});

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(ref.watch(databaseProvider));
});

// Domain Providers
final getFinanceSummaryUseCaseProvider = Provider<GetFinanceSummaryUseCase>((ref) {
  return GetFinanceSummaryUseCase(
    ref.watch(transactionRepositoryProvider),
    ref.watch(walletRepositoryProvider),
  );
});

// Service Providers
final financeFormatServiceProvider = Provider<FinanceFormatService>((ref) {
  return FinanceFormatService();
});

// Data Stream Providers
final walletsStreamProvider = StreamProvider<List<Wallet>>((ref) {
  final repo = ref.watch(walletRepositoryProvider);
  return repo.watchAllWallets();
});

final categoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  repo.seedDefaultCategories();
  return repo.watchAllCategories();
});

final transactionsStreamProvider = StreamProvider<List<Transaction>>((ref) {
  return ref.watch(transactionRepositoryProvider).watchAllTransactions();
});

enum TransactionTypeFilter { all, income, expense, transfer }

class TransactionFilterState {
  final TransactionTypeFilter type;
  final String searchQuery;
  final DateTimeRange? dateRange;

  TransactionFilterState({
    this.type = TransactionTypeFilter.all,
    this.searchQuery = '',
    this.dateRange,
  });

  TransactionFilterState copyWith({
    TransactionTypeFilter? type,
    String? searchQuery,
    DateTimeRange? dateRange,
  }) {
    return TransactionFilterState(
      type: type ?? this.type,
      searchQuery: searchQuery ?? this.searchQuery,
      dateRange: dateRange ?? this.dateRange,
    );
  }
}

final transactionFilterProvider = StateProvider<TransactionFilterState>((ref) {
  return TransactionFilterState();
});

final filteredTransactionsProvider = Provider<AsyncValue<List<Transaction>>>((ref) {
  final transactionsAsync = ref.watch(transactionsStreamProvider);
  final filter = ref.watch(transactionFilterProvider);

  return transactionsAsync.when(
    data: (transactions) {
      var filtered = transactions;

      // Filter by type
      if (filter.type != TransactionTypeFilter.all) {
        final typeStr = filter.type == TransactionTypeFilter.income 
            ? 'Income' 
            : filter.type == TransactionTypeFilter.expense 
                ? 'Expense' 
                : 'Transfer';
        filtered = filtered.where((tx) => tx.type == typeStr).toList();
      }

      // Filter by search query
      if (filter.searchQuery.isNotEmpty) {
        final query = filter.searchQuery.toLowerCase();
        filtered = filtered.where((tx) {
          final noteMatch = tx.note?.toLowerCase().contains(query) ?? false;
          final typeMatch = tx.type.toLowerCase().contains(query);
          return noteMatch || typeMatch;
        }).toList();
      }

      // Filter by date range
      if (filter.dateRange != null) {
        filtered = filtered.where((tx) {
          return tx.date.isAfter(filter.dateRange!.start) && 
                 tx.date.isBefore(filter.dateRange!.end.add(const Duration(days: 1)));
        }).toList();
      }

      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

final groupedTransactionsProvider = Provider<AsyncValue<Map<DateTime, List<Transaction>>>>((ref) {
  final filteredAsync = ref.watch(filteredTransactionsProvider);
  
  return filteredAsync.when(
    data: (transactions) {
      final groups = <DateTime, List<Transaction>>{};
      for (final tx in transactions) {
        final date = DateTime(tx.date.year, tx.date.month, tx.date.day);
        if (groups[date] == null) groups[date] = [];
        groups[date]!.add(tx);
      }
      return AsyncValue.data(groups);
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

final debtsStreamProvider = StreamProvider<List<Debt>>((ref) {
  return ref.watch(debtRepositoryProvider).watchAllDebts();
});

final budgetsStreamProvider = StreamProvider<List<Budget>>((ref) {
  return ref.watch(budgetRepositoryProvider).watchAllBudgets();
});

final debtPaymentsStreamProvider = StreamProvider.family<List<DebtPayment>, String>((ref, debtId) {
  return ref.watch(debtRepositoryProvider).watchPaymentsForDebt(debtId);
});

final debtRemindersStreamProvider = StreamProvider.family<List<Reminder>, String>((ref, debtId) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.reminders)
        ..where((t) => t.relatedId.equals(debtId))
        ..orderBy([(t) => OrderingTerm.desc(t.scheduledDate)]))
      .watch();
});

final pendingBudgetItemsProvider = StreamProvider<List<BudgetItem>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.budgetItems)..where((t) => t.isChecked.equals(false))).watch();
});

final budgetsWithProgressProvider = StreamProvider<List<BudgetWithProgress>>((ref) {
  final budgetRepo = ref.watch(budgetRepositoryProvider);
  final categoriesAsync = ref.watch(categoriesStreamProvider);
  
  return ref.watch(budgetsStreamProvider).when(
    data: (budgets) async* {
      final categories = categoriesAsync.value ?? [];
      final now = DateTime.now();
      
      List<BudgetWithProgress> list = [];
      for (var budget in budgets) {
        DateTime start;
        DateTime end;
        
        switch (budget.period) {
          case 'daily':
            start = DateTime(now.year, now.month, now.day);
            end = DateTime(now.year, now.month, now.day, 23, 59, 59);
            break;
          case 'weekly':
            // Assume week starts on Monday
            int dayOffset = now.weekday - 1;
            start = DateTime(now.year, now.month, now.day).subtract(Duration(days: dayOffset));
            end = start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
            break;
          case 'monthly':
            start = DateTime(now.year, now.month, 1);
            end = DateTime(now.year, now.month + 1, 1).subtract(const Duration(seconds: 1));
            break;
          case 'yearly':
            start = DateTime(now.year, 1, 1);
            end = DateTime(now.year, 12, 31, 23, 59, 59);
            break;
          default:
            start = DateTime(now.year, now.month, 1);
            end = DateTime(now.year, now.month + 1, 1).subtract(const Duration(seconds: 1));
        }
        
        final spent = await budgetRepo.getSpendingForCategory(budget.categoryId, start, end);
        final items = await budgetRepo.getItemsForBudget(budget.id);
        final category = budget.categoryId != null 
            ? categories.firstWhere((c) => c.id == budget.categoryId)
            : null;
            
        list.add(BudgetWithProgress(
          budget: budget,
          category: category,
          spentAmount: spent,
          startDate: start,
          endDate: end,
          items: items,
        ));
      }
      yield list;
    },
    loading: () async* { yield []; },
    error: (e, s) async* { yield []; },
  );
});

final projectFinancialSummaryProvider = FutureProvider.family<Map<String, double>, String>((ref, projectId) {
  return ref.watch(financeManagerProvider).getProjectFinancialSummary(projectId);
});

final globalFinancialSummaryProvider = FutureProvider<Map<String, double>>((ref) {
  // Watch transactions to trigger refresh
  ref.watch(transactionsStreamProvider);
  return ref.watch(financeManagerProvider).getGlobalFinancialSummary();
});

final financeSummaryProvider = Provider<AsyncValue<FinanceSummary>>((ref) {
  final walletsAsync = ref.watch(walletsStreamProvider);
  final transactionsAsync = ref.watch(transactionsStreamProvider);
  final manager = ref.watch(financeManagerProvider);

  return walletsAsync.when(
    data: (wallets) => transactionsAsync.when(
      data: (transactions) {
        // Calculate Total Balance directly from wallets (Source of Truth)
        int totalBalance = wallets.fold(0, (sum, w) => sum + w.balance);

        final now = DateTime.now();
        final firstDayOfMonth = DateTime(now.year, now.month, 1);

        int monthlyIncome = 0;
        int monthlyExpense = 0;

        for (var tx in transactions) {
          if (tx.date.isAfter(firstDayOfMonth) || tx.date.isAtSameMomentAs(firstDayOfMonth)) {
            if (tx.type == 'Income') {
              monthlyIncome += tx.amount;
            } else if (tx.type == 'Expense') {
              monthlyExpense += tx.amount;
            }
          }
        }

        return AsyncValue.data(FinanceSummary(
          totalBalance: totalBalance,
          monthlyIncome: monthlyIncome,
          monthlyExpense: monthlyExpense,
          netCashFlow: monthlyIncome - monthlyExpense,
        ));
      },
      loading: () => const AsyncValue.loading(),
      error: (err, stack) => AsyncValue.error(err, stack),
    ),
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

class FinanceOverviewData {
  final List<Project> projects;
  final List<Payment> payments;
  final List<Expense> expenses;
  final FinanceSummary summary;

  FinanceOverviewData({
    required this.projects,
    required this.payments,
    required this.expenses,
    required this.summary,
  });
}

final financeOverviewDataProvider = Provider<AsyncValue<FinanceOverviewData>>((ref) {
  final projectsAsync = ref.watch(allProjectsStreamProvider);
  final paymentsAsync = ref.watch(allPaymentsStreamProvider);
  final expensesAsync = ref.watch(allExpensesStreamProvider);
  final summaryAsync = ref.read(financeSummaryProvider);

  return projectsAsync.when(
    data: (projects) => paymentsAsync.when(
      data: (payments) => expensesAsync.when(
        data: (expenses) {
          // If summary is still loading, we can't yield full data yet
          return summaryAsync.when(
            data: (summary) => AsyncValue.data(FinanceOverviewData(
              projects: projects,
              payments: payments,
              expenses: expenses,
              summary: summary,
            )),
            loading: () => const AsyncValue.loading(),
            error: (e, s) => AsyncValue.error(e, s),
          );
        },
        loading: () => const AsyncValue.loading(),
        error: (e, s) => AsyncValue.error(e, s),
      ),
      loading: () => const AsyncValue.loading(),
      error: (e, s) => AsyncValue.error(e, s),
    ),
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});

class FinanceFilter {
  final String type; // 'Month' or 'Year'
  final DateTime selectedDate;

  FinanceFilter({required this.type, required this.selectedDate});

  DateTimeRange get range {
    if (type == 'Month') {
      return DateTimeRange(
        start: DateTime(selectedDate.year, selectedDate.month, 1),
        end: DateTime(selectedDate.year, selectedDate.month + 1, 1).subtract(const Duration(seconds: 1)),
      );
    } else {
      return DateTimeRange(
        start: DateTime(selectedDate.year, 1, 1),
        end: DateTime(selectedDate.year, 12, 31, 23, 59, 59),
      );
    }
  }

  FinanceFilter copyWith({String? type, DateTime? selectedDate}) {
    return FinanceFilter(
      type: type ?? this.type,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}

final financeFilterProvider = StateProvider<FinanceFilter>((ref) {
  return FinanceFilter(type: 'Month', selectedDate: DateTime.now());
});

final filteredFinanceDataProvider = Provider<AsyncValue<FilteredFinanceData>>((ref) {
  final transactionsAsync = ref.watch(transactionsStreamProvider);
  final projectsAsync = ref.watch(allProjectsStreamProvider);
  final walletsAsync = ref.watch(walletsStreamProvider);
  final filter = ref.watch(financeFilterProvider);

  return transactionsAsync.when(
    data: (transactions) => projectsAsync.when(
      data: (projects) => walletsAsync.when(
        data: (wallets) {
          final range = filter.range;
          
          bool isWithinRange(DateTime date) {
            return (date.isAfter(range.start) || date.isAtSameMomentAs(range.start)) && 
                   (date.isBefore(range.end) || date.isAtSameMomentAs(range.end));
          }

          final filteredTransactions = transactions.where((tx) => isWithinRange(tx.date)).toList();
          
          // Map Transactions to UI-friendly models if needed, but here we can calculate directly
          double totalRevenue = 0;
          double totalCollected = 0;
          double totalExpenses = 0;

          // Project-based filtering
          final filteredProjects = projects.where((p) => isWithinRange(p.createdAt)).toList();

          for (final tx in filteredTransactions) {
            if (tx.type == 'Income') {
              // Standard Revenue calculation (excluding loans, collections, and investments)
              if (tx.categoryId != FinanceManager.CAT_DEBT_BORROWED && 
                  tx.categoryId != FinanceManager.CAT_DEBT_COLLECTION &&
                  tx.categoryId != FinanceManager.CAT_INVESTMENT) {
                totalRevenue += tx.amount / 100.0;
              }
              totalCollected += tx.amount / 100.0;
            } else if (tx.type == 'Expense') {
              totalExpenses += tx.amount / 100.0;
            }
          }

          // Group by projects for the UI list
          final Map<String, List<Transaction>> projectTxs = {};
          for (final tx in transactions) {
            if (tx.projectId != null) {
              projectTxs.putIfAbsent(tx.projectId!, () => []).add(tx);
            }
          }

          // Create legacy models for UI compatibility with enhanced category detection
          final payments = filteredTransactions
              .where((tx) => tx.type == 'Income')
              .map((tx) {
                String catName = 'Mapato';
                if (tx.categoryId == FinanceManager.CAT_DEBT_BORROWED) catName = 'Mkopo';
                if (tx.categoryId == FinanceManager.CAT_DEBT_COLLECTION) catName = 'Malipo ya Deni';
                if (tx.categoryId == FinanceManager.CAT_INVESTMENT) catName = 'Uwekezaji';
                
                return Payment(
                  id: tx.id,
                  projectId: tx.projectId ?? 'GENERAL',
                  label: tx.note ?? catName,
                  amount: tx.amount / 100.0,
                  date: tx.date,
                  isReceived: true,
                  walletId: tx.walletId,
                );
              })
              .toList();

          final expenses = filteredTransactions
              .where((tx) => tx.type == 'Expense')
              .map((tx) {
                String catName = 'Matumizi';
                if (tx.categoryId == FinanceManager.CAT_DEBT_REPAYMENT) catName = 'Kulipa Deni';
                if (tx.categoryId == FinanceManager.CAT_DEBT_LENT) catName = 'Kukopesha';
                
                return Expense(
                  id: tx.id,
                  projectId: tx.projectId ?? 'GENERAL',
                  name: tx.note ?? catName,
                  amount: tx.amount / 100.0,
                  date: tx.date,
                  category: catName,
                );
              })
              .toList();

          return AsyncValue.data(FilteredFinanceData(
            projects: projects, // Show all projects or filtered ones
            payments: payments,
            expenses: expenses,
            allPayments: payments, // In this context, filtered = all we care about
            allExpenses: expenses,
            totalRevenue: totalRevenue,
            totalCollected: totalCollected,
            totalExpenses: totalExpenses,
            totalBalance: wallets.fold(0, (sum, w) => sum + w.balance),
          ));
        },
        loading: () => const AsyncValue.loading(),
        error: (err, stack) => AsyncValue.error(err, stack),
      ),
      loading: () => const AsyncValue.loading(),
      error: (err, stack) => AsyncValue.error(err, stack),
    ),
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});

class FilteredFinanceData {
  final List<Project> projects;
  final List<Payment> payments;
  final List<Expense> expenses;
  final List<Payment> allPayments;
  final List<Expense> allExpenses;
  final double totalRevenue;
  final double totalCollected;
  final double totalExpenses;
  final int totalBalance;

  FilteredFinanceData({
    required this.projects,
    required this.payments,
    required this.expenses,
    required this.allPayments,
    required this.allExpenses,
    required this.totalRevenue,
    required this.totalCollected,
    required this.totalExpenses,
    required this.totalBalance,
  });

  double get pendingRevenue => totalRevenue - totalCollected;
  
  // Tanzanian Growth logic: Retained Profit (Faida iliyobaki mkononi)
  double get retainedProfit => totalCollected - totalExpenses;
}
