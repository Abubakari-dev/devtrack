import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';

class CategoryRepository {
  final AppDatabase _db;

  CategoryRepository(this._db);

  Future<List<Category>> getAllCategories() => _db.select(_db.categories).get();

  Stream<List<Category>> watchAllCategories() => _db.select(_db.categories).watch();

  Stream<List<Category>> watchCategoriesByType(String type) => 
    (_db.select(_db.categories)..where((t) => t.type.equals(type))).watch();

  Future<int> addCategory(CategoriesCompanion category) => _db.into(_db.categories).insert(category);

  Future<bool> updateCategory(Category category) => _db.update(_db.categories).replace(category);

  Future<int> deleteCategory(String id) => 
    (_db.delete(_db.categories)..where((t) => t.id.equals(id))).go();

  Future<void> seedDefaultCategories() async {
    final count = await _db.select(_db.categories).get().then((list) => list.length);
    
    // Always ensure debt categories exist to prevent Foreign Key errors
    final List<String> debtIds = ['INVESTMENT', 'DEBT_BORROWED', 'DEBT_LENT', 'DEBT_REPAYMENT', 'DEBT_COLLECTION'];
    for (var id in debtIds) {
      final exists = await (_db.select(_db.categories)..where((c) => c.id.equals(id))).getSingleOrNull();
      if (exists == null) {
        await _db.into(_db.categories).insert(CategoriesCompanion.insert(
          id: Value(id),
          name: id.replaceAll('_', ' '),
          type: (id.contains('BORROWED') || id.contains('COLLECTION') || id == 'INVESTMENT') ? 'Income' : 'Expense',
          icon: 'price_check_rounded',
          color: 0xFF6366F1,
        ));
      }
    }

    if (count == 0) {
      final defaultCategories = [
        // ... (Kodi ya awali inabaki kama ilivyokuwa)
        // --- Income (Mapato) ---
        CategoriesCompanion.insert(name: 'Project Revenue (Malipo ya Kazi)', type: 'Income', icon: 'business_center_rounded', color: 0xFF10B981),
        CategoriesCompanion.insert(name: 'Salary (Mshahara)', type: 'Income', icon: 'payments_rounded', color: 0xFF059669),
        CategoriesCompanion.insert(name: 'Loan/Investment (Mkopo/Mtaji)', type: 'Income', icon: 'account_balance_rounded', color: 0xFF6366F1),
        CategoriesCompanion.insert(name: 'Other Income', type: 'Income', icon: 'add_circle_outline_rounded', color: 0xFF94A3B8),

        // --- Operating Expenses (Gharama za Kazi) ---
        CategoriesCompanion.insert(name: 'Materials (Vifaa)', type: 'Expense', icon: 'inventory_2_rounded', color: 0xFFF43F5E),
        CategoriesCompanion.insert(name: 'Labor/Vibarua (Fundi)', type: 'Expense', icon: 'engineering_rounded', color: 0xFFF59E0B),
        CategoriesCompanion.insert(name: 'Transport/Nauli', type: 'Expense', icon: 'directions_bus_rounded', color: 0xFF6366F1),
        CategoriesCompanion.insert(name: 'Food/Drinks (Chakula)', type: 'Expense', icon: 'restaurant_rounded', color: 0xFFFB7185),
        CategoriesCompanion.insert(name: 'Internet/Airtime (MB/Vocha)', type: 'Expense', icon: 'signal_cellular_alt_rounded', color: 0xFF06B6D4),
        
        // --- Fixed & Growth (Ukuaji) ---
        CategoriesCompanion.insert(name: 'Rent & Bills (Kodi/Bili)', type: 'Expense', icon: 'home_work_rounded', color: 0xFF475569),
        CategoriesCompanion.insert(name: 'Taxes/TRA (Kodi ya Serikali)', type: 'Expense', icon: 'gavel_rounded', color: 0xFF334155),
        CategoriesCompanion.insert(name: 'Debt Repayment (Kulipa Deni)', type: 'Expense', icon: 'price_check_rounded', color: 0xFFEF4444),
        CategoriesCompanion.insert(name: 'Savings/Akiba (Investment)', type: 'Expense', icon: 'savings_rounded', color: 0xFF8250DF),
      ];

      for (var cat in defaultCategories) {
        await addCategory(cat);
      }
    }
  }
}
