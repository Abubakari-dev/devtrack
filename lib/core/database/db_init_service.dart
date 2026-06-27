import 'package:drift/drift.dart';
import 'app_database.dart';
import 'package:uuid/uuid.dart';

class DbInitService {
  static Future<void> seedCategories(AppDatabase db) async {
    final count = await db.select(db.categories).get().then((list) => list.length);
    if (count == 0) {
      final defaultCategories = [
        // Expenses
        CategoriesCompanion.insert(
          id: Value(const Uuid().v4()),
          name: 'Food & Drinks', 
          type: 'Expense', 
          icon: 'restaurant_rounded', 
          color: 0xFFF43F5E
        ),
        CategoriesCompanion.insert(
          id: Value(const Uuid().v4()),
          name: 'Transport', 
          type: 'Expense', 
          icon: 'directions_bus_rounded', 
          color: 0xFF6366F1
        ),
        CategoriesCompanion.insert(
          id: Value(const Uuid().v4()),
          name: 'Shopping', 
          type: 'Expense', 
          icon: 'shopping_bag_rounded', 
          color: 0xFFEC4899
        ),
        CategoriesCompanion.insert(
          id: Value(const Uuid().v4()),
          name: 'Bills', 
          type: 'Expense', 
          icon: 'receipt_long_rounded', 
          color: 0xFFF59E0B
        ),
        CategoriesCompanion.insert(
          id: Value(const Uuid().v4()),
          name: 'Entertainment', 
          type: 'Expense', 
          icon: 'sports_esports_rounded', 
          color: 0xFF8B5CF6
        ),
        // Income
        CategoriesCompanion.insert(
          id: Value(const Uuid().v4()),
          name: 'Salary', 
          type: 'Income', 
          icon: 'payments_rounded', 
          color: 0xFF10B981
        ),
        CategoriesCompanion.insert(
          id: Value(const Uuid().v4()),
          name: 'Business', 
          type: 'Income', 
          icon: 'storefront_rounded', 
          color: 0xFF06B6D4
        ),
        CategoriesCompanion.insert(
          id: Value(const Uuid().v4()),
          name: 'Investment', 
          type: 'Income', 
          icon: 'trending_up_rounded', 
          color: 0xFF8250DF
        ),
      ];

      for (var cat in defaultCategories) {
        await db.into(db.categories).insert(cat);
      }
    }
  }

  static Future<void> seedInitialWallet(AppDatabase db) async {
    final count = await db.select(db.wallets).get().then((list) => list.length);
    if (count == 0) {
      await db.into(db.wallets).insert(
        WalletsCompanion.insert(
          id: Value(const Uuid().v4()),
          name: 'Primary Wallet',
          type: 'Cash',
          balance: const Value(0),
          currency: const Value('TSh'),
          icon: 'account_balance_wallet_rounded',
          color: 0xFF4F46E5, // AppColors.indigo
        ),
      );
    }
  }
}
