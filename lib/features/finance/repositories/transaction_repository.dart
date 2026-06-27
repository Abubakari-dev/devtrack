import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../../../core/database/app_database.dart';
import '../data/finance_repository.dart';
import 'finance_manager.dart';
import 'package:devtrack/features/projects/models/models.dart';

class TransactionRepository {
  final AppDatabase _db;
  final FinanceRepository _cloudRepo = FinanceRepository();
  late final FinanceManager _financeManager;

  TransactionRepository(this._db) {
    _financeManager = FinanceManager(_db);
  }

  Future<List<Transaction>> getAllTransactions() => 
    (_db.select(_db.transactions)..orderBy([(t) => OrderingTerm.desc(t.date)])).get();

  Stream<List<Transaction>> watchAllTransactions() => 
    (_db.select(_db.transactions)..orderBy([(t) => OrderingTerm.desc(t.date)])).watch();

  Stream<List<Transaction>> watchTransactionsByWallet(String walletId) => 
    (_db.select(_db.transactions)..where((t) => t.walletId.equals(walletId))..orderBy([(t) => OrderingTerm.desc(t.date)])).watch();

  Future<void> addTransaction(TransactionsCompanion transaction) async {
    await _financeManager.recordTransaction(
      transactionId: transaction.id.present ? transaction.id.value : null,
      amount: transaction.amount.value, // Passing int cents directly
      type: transaction.type.value,
      walletId: transaction.walletId.value,
      note: transaction.note.value,
      date: transaction.date.value,
      projectId: transaction.projectId.present ? transaction.projectId.value : null,
      categoryId: transaction.categoryId.present ? transaction.categoryId.value : null,
    );
  }

  Future<void> createSimpleTransaction({
    required TransactionsCompanion transaction,
    required String categoryId,
    String? attachmentPath,
  }) async {
    final txId = transaction.id.present ? transaction.id.value : const Uuid().v4();
    
    await _financeManager.recordTransaction(
      transactionId: txId,
      amount: transaction.amount.value, // Passing int cents directly
      type: transaction.type.value,
      walletId: transaction.walletId.value,
      note: transaction.note.value,
      date: transaction.date.value,
      projectId: transaction.projectId.present ? transaction.projectId.value : null,
      categoryId: categoryId,
    );

    if (attachmentPath != null) {
      await _db.into(_db.transactionAttachments).insert(TransactionAttachmentsCompanion.insert(
        transactionId: txId,
        filePath: attachmentPath,
        fileType: 'image',
      ));
    }
  }

  Future<void> createSplitTransaction({
    required TransactionsCompanion transaction,
    required List<TransactionSplitsCompanion> splits,
    String? attachmentPath,
  }) async {
    final int totalAmount = transaction.amount.value;
    final int splitsSum = splits.fold(0, (sum, split) => sum + split.amount.value);

    if (totalAmount != splitsSum) {
      throw ArgumentError('Split sum mismatch');
    }

    await _db.transaction(() async {
      final txId = transaction.id.present ? transaction.id.value : const Uuid().v4();
      final tx = transaction.copyWith(id: Value(txId));
      await _db.into(_db.transactions).insert(tx);

      for (var split in splits) {
        await _db.into(_db.transactionSplits).insert(split.copyWith(transactionId: Value(txId)));
      }

      if (attachmentPath != null) {
        await _db.into(_db.transactionAttachments).insert(TransactionAttachmentsCompanion.insert(
          transactionId: txId, filePath: attachmentPath, fileType: 'image',
        ));
      }

      await _financeManager.updateWalletBalance(tx.walletId.value);
      
      final fullTx = await (_db.select(_db.transactions)..where((t) => t.id.equals(txId))).getSingle();
      
      await _cloudRepo.saveTransaction({
        'id': fullTx.id,
        'amount': fullTx.amount,
        'type': fullTx.type,
        'walletId': fullTx.walletId,
        'note': fullTx.note,
        'date': fullTx.date.toIso8601String(),
        'splits': splits.map((s) => {'categoryId': s.categoryId.value, 'amount': s.amount.value}).toList(),
        'projectId': fullTx.projectId,
      });
    });
  }

  Future<bool> updateTransaction(Transaction transaction) async {
    final success = await _db.update(_db.transactions).replace(transaction);
    if (success) {
      await _financeManager.updateWalletBalance(transaction.walletId);
      await _cloudRepo.saveTransaction({
        'id': transaction.id,
        'amount': transaction.amount,
        'type': transaction.type,
        'walletId': transaction.walletId,
        'note': transaction.note,
        'date': transaction.date.toIso8601String(),
        'projectId': transaction.projectId,
        'categoryId': transaction.categoryId,
      });
    }
    return success;
  }

  Future<int> deleteTransaction(String id) async {
    final tx = await (_db.select(_db.transactions)..where((t) => t.id.equals(id))).getSingleOrNull();
    final result = await (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();
    if (tx != null) {
      await _financeManager.updateWalletBalance(tx.walletId);
    }
    return result;
  }

  Future<int> calculateWalletBalance(String walletId) async {
    await _financeManager.updateWalletBalance(walletId);
    final wallet = await (_db.select(_db.wallets)..where((w) => w.id.equals(walletId))).getSingle();
    return wallet.balance;
  }
}
