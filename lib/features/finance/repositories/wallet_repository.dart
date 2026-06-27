import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../data/finance_repository.dart';

class WalletRepository {
  final AppDatabase _db;
  final FinanceRepository _cloudRepo = FinanceRepository();

  WalletRepository(this._db);

  Future<List<Wallet>> getAllWallets() => _db.select(_db.wallets).get();

  Stream<List<Wallet>> watchAllWallets() => _db.select(_db.wallets).watch();

  Future<Wallet> getWalletById(String id) => 
    (_db.select(_db.wallets)..where((t) => t.id.equals(id))).getSingle();

  Future<int> addWallet(WalletsCompanion wallet) async {
    final idToUse = wallet.id.present ? wallet.id.value : const Uuid().v4();
    final companionToUse = wallet.copyWith(id: Value(idToUse));
    
    final rowId = await _db.into(_db.wallets).insert(companionToUse);
    
    // IF WALLET HAS INITIAL BALANCE, RECORD IT AS AN INCOME TRANSACTION
    if (wallet.balance.present && wallet.balance.value > 0) {
      await _db.into(_db.transactions).insert(TransactionsCompanion.insert(
        id: Value(const Uuid().v4()),
        amount: wallet.balance.value,
        type: 'Income',
        walletId: idToUse,
        note: const Value('Opening Balance'),
        date: DateTime.now(),
      ));
    }

    final newWallet = await (_db.select(_db.wallets)..where((t) => t.id.equals(idToUse))).getSingle();
    
    // Sync to Cloud
    await _cloudRepo.saveWallet({
      'id': newWallet.id,
      'name': newWallet.name,
      'type': newWallet.type,
      'provider': newWallet.provider,
      'accountNumber': newWallet.accountNumber,
      'balance': newWallet.balance,
      'currency': newWallet.currency,
      'icon': newWallet.icon,
      'color': newWallet.color,
    });
    
    return rowId;
  }

  Future<bool> updateWallet(Wallet wallet) async {
    final success = await _db.update(_db.wallets).replace(wallet);
    if (success) {
      // Sync to Cloud
      await _cloudRepo.saveWallet({
        'id': wallet.id,
        'name': wallet.name,
        'type': wallet.type,
        'provider': wallet.provider,
        'accountNumber': wallet.accountNumber,
        'balance': wallet.balance,
        'currency': wallet.currency,
        'icon': wallet.icon,
        'color': wallet.color,
      });
    }
    return success;
  }

  Future<int> deleteWallet(String id) => 
    (_db.delete(_db.wallets)..where((t) => t.id.equals(id))).go();

  Future<void> seedDefaultWallet() async {
    final count = await _db.select(_db.wallets).get().then((list) => list.length);
    if (count == 0) {
      await addWallet(WalletsCompanion.insert(
        name: 'Main Wallet',
        type: 'Cash',
        balance: const Value(0),
        currency: const Value('TSh'),
        icon: 'payments_rounded',
        color: 0xFF6366F1, // AppColors.indigo
      ));
    }
  }
}
