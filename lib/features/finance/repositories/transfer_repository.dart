import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../data/finance_repository.dart';
import 'finance_manager.dart';

class TransferRepository {
  final AppDatabase _db;
  final FinanceManager _financeManager;
  final FinanceRepository _cloudRepo = FinanceRepository();

  TransferRepository(this._db) : _financeManager = FinanceManager(_db);

  Stream<List<Transfer>> watchAllTransfers() => 
    (_db.select(_db.transfers)..orderBy([(t) => OrderingTerm.desc(t.date)])).watch();

  Future<void> performTransfer({
    required String fromWalletId,
    required String toWalletId,
    required int amount,
    int fee = 0,
    required DateTime date,
    String? note,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Transfer amount must be greater than zero.');
    }
    if (fromWalletId == toWalletId) {
      throw ArgumentError('Source and destination wallets must be different.');
    }

    await _db.transaction(() async {
      final transferId = const Uuid().v4();
      
      // 1. Create Transfer Record
      await _db.into(_db.transfers).insert(TransfersCompanion.insert(
        id: Value(transferId),
        fromWalletId: fromWalletId,
        toWalletId: toWalletId,
        amount: amount,
        fee: Value(fee),
        date: date,
        note: Value(note),
      ));

      // 2. Update local Wallet Balances
      await _financeManager.updateWalletBalance(fromWalletId);
      await _financeManager.updateWalletBalance(toWalletId);

      // 3. Sync to Cloud
      await _cloudRepo.saveTransfer({
        'id': transferId,
        'fromWalletId': fromWalletId,
        'toWalletId': toWalletId,
        'amount': amount,
        'fee': fee,
        'date': date.toIso8601String(),
        'note': note,
      });

      // Update wallets on cloud too
      final fromWallet = await (_db.select(_db.wallets)..where((w) => w.id.equals(fromWalletId))).getSingle();
      final toWallet = await (_db.select(_db.wallets)..where((w) => w.id.equals(toWalletId))).getSingle();
      
      await _cloudRepo.saveWallet({
        'id': fromWallet.id,
        'name': fromWallet.name,
        'type': fromWallet.type,
        'provider': fromWallet.provider,
        'accountNumber': fromWallet.accountNumber,
        'balance': fromWallet.balance,
        'currency': fromWallet.currency,
        'icon': fromWallet.icon,
        'color': fromWallet.color,
      });
      await _cloudRepo.saveWallet({
        'id': toWallet.id,
        'name': toWallet.name,
        'type': toWallet.type,
        'provider': toWallet.provider,
        'accountNumber': toWallet.accountNumber,
        'balance': toWallet.balance,
        'currency': toWallet.currency,
        'icon': toWallet.icon,
        'color': toWallet.color,
      });
    });
  }

  Future<int> deleteTransfer(String id, String fromId, String toId) async {
    return await _db.transaction(() async {
      final result = await (_db.delete(_db.transfers)..where((t) => t.id.equals(id))).go();
      
      // Update balances
      await _financeManager.updateWalletBalance(fromId);
      await _financeManager.updateWalletBalance(toId);
          
      return result;
    });
  }
}
