import '../models/finance_summary.dart';
import '../../repositories/transaction_repository.dart';
import '../../repositories/wallet_repository.dart';

class GetFinanceSummaryUseCase {
  final TransactionRepository _transactionRepo;
  final WalletRepository _walletRepo;

  GetFinanceSummaryUseCase(this._transactionRepo, this._walletRepo);

  Future<FinanceSummary> execute() async {
    final wallets = await _walletRepo.getAllWallets();
    final transactions = await _transactionRepo.getAllTransactions();

    int totalBalance = 0;
    for (var wallet in wallets) {
      totalBalance += wallet.balance;
    }

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

    return FinanceSummary(
      totalBalance: totalBalance,
      monthlyIncome: monthlyIncome,
      monthlyExpense: monthlyExpense,
      netCashFlow: monthlyIncome - monthlyExpense,
    );
  }
}
