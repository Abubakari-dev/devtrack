import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:devtrack/core/database/app_database.dart';
import 'package:devtrack/core/services/notification_service.dart';
import 'package:devtrack/features/finance/data/finance_repository.dart';
import 'package:devtrack/features/finance/repositories/finance_manager.dart';
import 'package:devtrack/features/projects/models/models.dart';

class DebtRepository {
  final AppDatabase _db;
  final FinanceRepository _cloudRepo = FinanceRepository();
  late final FinanceManager _financeManager;

  DebtRepository(this._db) {
    _financeManager = FinanceManager(_db);
  }

  Future<List<Debt>> getAllDebts() => 
    (_db.select(_db.debts)..orderBy([(t) => OrderingTerm.desc(t.dateGiven)])).get();

  Stream<List<Debt>> watchAllDebts() => 
    (_db.select(_db.debts)..orderBy([(t) => OrderingTerm.desc(t.dateGiven)])).watch();

  Future<int> addDebt(DebtsCompanion debt) async {
    return await _db.transaction(() async {
      final id = await _db.into(_db.debts).insert(debt);
      final newDebt = await (_db.select(_db.debts)..where((t) => t.id.equals(debt.id.value))).getSingle();
      
      // If a wallet was selected, create a transaction to affect balances
      if (newDebt.walletId != null) {
        // If I lent money: it's an Expense from my wallet.
        // If I borrowed money: it's Income to my wallet.
        final txType = newDebt.type == 'lent' ? 'Expense' : 'Income';
        final txId = const Uuid().v4();
        
        String notePrefix = newDebt.type == 'lent' ? 'Kutoa (Lent)' : 'Kupokea (Borrowed)';
        String projectInfo = '';
        if (newDebt.projectId != null) {
          try {
            final project = await _cloudRepo.getProjectById(newDebt.projectId!);
            if (project != null) {
              projectInfo = ' | Project: ${project['name']}';
            }
          } catch (e) {
            projectInfo = ' | Project ID: ${newDebt.projectId}';
          }
        }

        await _financeManager.recordTransaction(
          transactionId: txId,
          amount: newDebt.principalAmount, // Passing int cents directly
          type: txType,
          walletId: newDebt.walletId!,
          date: newDebt.dateGiven,
          note: '$notePrefix to/from ${newDebt.contactName}$projectInfo',
          projectId: newDebt.projectId,
          categoryId: newDebt.type == 'lent' ? FinanceManager.CAT_DEBT_LENT : FinanceManager.CAT_DEBT_BORROWED,
        );
      }

      // Sync to Cloud
      await _cloudRepo.saveDebt({
        'id': newDebt.id,
        'contactName': newDebt.contactName,
        'contactReference': newDebt.contactReference,
        'type': newDebt.type,
        'principalAmount': newDebt.principalAmount,
        'amountPaid': newDebt.amountPaid,
        'interestRate': newDebt.interestRate,
        'dateGiven': newDebt.dateGiven.toIso8601String(),
        'dueDate': newDebt.dueDate?.toIso8601String(),
        'status': newDebt.status,
        'notes': newDebt.notes,
        'walletId': newDebt.walletId,
        'projectId': newDebt.projectId,
      });

      await AppNotificationService.instance.scheduleDebtReminders(_db, newDebt);
      return id;
    });
  }

  Future<void> _updateWalletBalance(String walletId) async {
    await _financeManager.updateWalletBalance(walletId);
  }

  Future<bool> updateDebt(Debt debt) async {
    final success = await _db.update(_db.debts).replace(debt);
    if (success) {
      // Sync to Cloud
      await _cloudRepo.saveDebt({
        'id': debt.id,
        'contactName': debt.contactName,
        'contactReference': debt.contactReference,
        'type': debt.type,
        'principalAmount': debt.principalAmount,
        'amountPaid': debt.amountPaid,
        'interestRate': debt.interestRate,
        'dateGiven': debt.dateGiven.toIso8601String(),
        'dueDate': debt.dueDate?.toIso8601String(),
        'status': debt.status,
        'notes': debt.notes,
        'walletId': debt.walletId,
      });
      await AppNotificationService.instance.scheduleDebtReminders(_db, debt);
    }
    return success;
  }

  Future<int> deleteDebt(String id) async {
    return (_db.delete(_db.debts)..where((t) => t.id.equals(id))).go();
  }

  Future<List<DebtPayment>> getPaymentsForDebt(String debtId) =>
    (_db.select(_db.debtPayments)..where((t) => t.debtId.equals(debtId))..orderBy([(t) => OrderingTerm.desc(t.date)])).get();

  Stream<List<DebtPayment>> watchPaymentsForDebt(String debtId) =>
    (_db.select(_db.debtPayments)..where((t) => t.debtId.equals(debtId))..orderBy([(t) => OrderingTerm.desc(t.date)])).watch();

  Future<void> recordPayment(DebtPaymentsCompanion payment, {bool updateDebt = true}) async {
    await _db.transaction(() async {
      final paymentId = payment.id.present ? payment.id.value : const Uuid().v4();
      final paymentToInsert = payment.copyWith(id: Value(paymentId));
      
      await _db.into(_db.debtPayments).insert(paymentToInsert);
      
      final debtId = paymentToInsert.debtId.value;
      final debt = await (_db.select(_db.debts)..where((t) => t.id.equals(debtId))).getSingle();

      // If a wallet was selected for the payment, create a transaction
      if (paymentToInsert.walletId.present && paymentToInsert.walletId.value != null) {
        // Payment Logic:
        // If I lent (type='lent'): receiving money is Income.
        // If I borrowed (type='borrowed'): paying back is Expense.
        final txType = debt.type == 'lent' ? 'Income' : 'Expense';
        final txId = const Uuid().v4();
        
        String notePrefix = txType == 'Income' ? 'Kupokea Malipo (Lent Payment)' : 'Kulipa Deni (Debt Repayment)';
        String projectInfo = '';
        if (paymentToInsert.projectId.present && paymentToInsert.projectId.value != null) {
          try {
            final project = await _cloudRepo.getProjectById(paymentToInsert.projectId.value!);
            if (project != null) {
              projectInfo = ' | Project: ${project['name']}';
            }
          } catch (e) {
            projectInfo = ' | Project ID: ${paymentToInsert.projectId.value}';
          }
        }

        await _financeManager.recordTransaction(
          transactionId: txId,
          amount: paymentToInsert.amount.value, // Passing int cents directly
          type: txType,
          walletId: paymentToInsert.walletId.value!,
          date: paymentToInsert.date.value,
          note: '$notePrefix kutoka/kwa ${debt.contactName}$projectInfo',
          projectId: paymentToInsert.projectId.value,
          categoryId: txType == 'Income' ? FinanceManager.CAT_DEBT_COLLECTION : FinanceManager.CAT_DEBT_REPAYMENT,
        );
      }
      
      if (updateDebt) {
        final newAmountPaid = debt.amountPaid + paymentToInsert.amount.value;
        String newStatus = debt.status;
        
        if (newAmountPaid >= debt.principalAmount) {
          newStatus = 'paid';
        } else if (newAmountPaid > 0) {
          newStatus = 'partial';
        }
        
        await (_db.update(_db.debts)..where((t) => t.id.equals(debtId))).write(
          DebtsCompanion(
            amountPaid: Value(newAmountPaid),
            status: Value(newStatus),
          )
        );
      }

      _cloudRepo.saveDebtPayment({
        'id': paymentId,
        'debtId': debtId,
        'amount': paymentToInsert.amount.value,
        'date': paymentToInsert.date.value.toIso8601String(),
        'walletId': paymentToInsert.walletId.value,
        'projectId': paymentToInsert.projectId.value,
      }).catchError((e) => debugPrint('Sync Payment failed: $e'));

      final updatedDebt = await (_db.select(_db.debts)..where((t) => t.id.equals(debtId))).getSingle();
      _cloudRepo.saveDebt({
        'id': updatedDebt.id,
        'contactName': updatedDebt.contactName,
        'contactReference': updatedDebt.contactReference,
        'type': updatedDebt.type,
        'principalAmount': updatedDebt.principalAmount,
        'amountPaid': updatedDebt.amountPaid,
        'interestRate': updatedDebt.interestRate,
        'dateGiven': updatedDebt.dateGiven.toIso8601String(),
        'dueDate': updatedDebt.dueDate?.toIso8601String(),
        'status': updatedDebt.status,
        'notes': updatedDebt.notes,
        'walletId': updatedDebt.walletId,
        'projectId': updatedDebt.projectId,
      }).catchError((e) => debugPrint('Sync Debt failed: $e'));

      await AppNotificationService.instance.scheduleDebtReminders(_db, updatedDebt);
    });
  }
}
