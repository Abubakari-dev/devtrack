import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

part 'app_database.g.dart';

class Wallets extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get type => text()(); // Bank, Cash, Mobile Money, etc.
  TextColumn get provider => text().nullable()(); // Voda, Airtel, CRDB, etc.
  TextColumn get accountNumber => text().nullable()();
  IntColumn get balance => integer().withDefault(const Constant(0))(); // Smallest currency unit
  TextColumn get currency => text().withLength(min: 3, max: 3).withDefault(const Constant('USD'))();
  TextColumn get icon => text()();
  IntColumn get color => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastModifiedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Categories extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get type => text()(); // Income, Expense
  TextColumn get icon => text()();
  IntColumn get color => integer()();
  TextColumn get parentId => text().nullable().references(Categories, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastModifiedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Transactions extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  IntColumn get amount => integer()(); // Total amount in smallest unit
  TextColumn get type => text()(); // Income, Expense, Transfer
  TextColumn get walletId => text().references(Wallets, #id, onDelete: KeyAction.cascade)();
  TextColumn get note => text().nullable()();
  TextColumn get categoryId => text().nullable().references(Categories, #id, onDelete: KeyAction.setNull)();
  TextColumn get projectId => text().nullable()();
  DateTimeColumn get date => dateTime()();
  TextColumn get paymentMethodId => text().nullable().references(PaymentMethods, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastModifiedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class TransactionSplits extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get transactionId => text().references(Transactions, #id)();
  TextColumn get categoryId => text().references(Categories, #id)();
  IntColumn get amount => integer()(); // Amount for this specific category
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class TransactionAttachments extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get transactionId => text().references(Transactions, #id)();
  TextColumn get filePath => text()();
  TextColumn get fileType => text()(); // image, pdf, etc.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Tags extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get name => text().withLength(min: 1, max: 30)();
  IntColumn get color => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class TransactionTags extends Table {
  TextColumn get transactionId => text().references(Transactions, #id)();
  TextColumn get tagId => text().references(Tags, #id)();

  @override
  Set<Column> get primaryKey => {transactionId, tagId};
}

class PaymentMethods extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get name => text()(); // Cash, Card, Bank Transfer, Mobile Money
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Transfers extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get fromWalletId => text().references(Wallets, #id, onDelete: KeyAction.cascade)();
  TextColumn get toWalletId => text().references(Wallets, #id, onDelete: KeyAction.cascade)();
  IntColumn get amount => integer()();
  IntColumn get fee => integer().withDefault(const Constant(0))();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Budgets extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get name => text().nullable()();
  TextColumn get categoryId => text().nullable().references(Categories, #id, onDelete: KeyAction.setNull)(); // Null means total budget
  TextColumn get period => text()(); // daily, weekly, monthly, yearly
  IntColumn get amount => integer()();
  BoolColumn get rolloverEnabled => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class BudgetItems extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get budgetId => text().references(Budgets, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  IntColumn get estimatedPrice => integer()();
  IntColumn get actualPrice => integer().nullable()();
  BoolColumn get isChecked => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Bills extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get name => text()();
  IntColumn get amount => integer()();
  TextColumn get categoryId => text().references(Categories, #id, onDelete: KeyAction.setNull)();
  TextColumn get walletId => text().references(Wallets, #id, onDelete: KeyAction.cascade)();
  TextColumn get frequency => text()();
  DateTimeColumn get nextDueDate => dateTime()();
  IntColumn get reminderDaysBefore => integer().withDefault(const Constant(1))();
  BoolColumn get autoMarkPaid => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Subscriptions extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get name => text()();
  IntColumn get amount => integer()();
  DateTimeColumn get renewalDate => dateTime()();
  TextColumn get frequency => text()();
  TextColumn get categoryId => text().references(Categories, #id, onDelete: KeyAction.setNull)();
  BoolColumn get reminderEnabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Debts extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get contactName => text()();
  TextColumn get contactReference => text().nullable()(); // Phone or Contact ID
  TextColumn get type => text()(); // lent, borrowed
  IntColumn get principalAmount => integer()();
  IntColumn get amountPaid => integer().withDefault(const Constant(0))();
  RealColumn get interestRate => real().withDefault(const Constant(0.0))();
  DateTimeColumn get dateGiven => dateTime()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get status => text()(); // pending, partial, paid
  TextColumn get notes => text().nullable()();
  TextColumn get walletId => text().nullable().references(Wallets, #id, onDelete: KeyAction.setNull)(); 
  TextColumn get projectId => text().nullable()(); // Linked project
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class DebtPayments extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get debtId => text().references(Debts, #id, onDelete: KeyAction.cascade)();
  IntColumn get amount => integer()();
  DateTimeColumn get date => dateTime()();
  TextColumn get walletId => text().nullable().references(Wallets, #id, onDelete: KeyAction.setNull)(); 
  TextColumn get projectId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Reminders extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();
  TextColumn get type => text()(); // bill, subscription, debt, budget
  TextColumn get relatedId => text()();
  TextColumn get message => text()();
  DateTimeColumn get scheduledDate => dateTime()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [
  Wallets,
  Categories,
  Transactions,
  TransactionSplits,
  TransactionAttachments,
  Tags,
  TransactionTags,
  PaymentMethods,
  Transfers,
  Budgets,
  BudgetItems,
  Bills,
  Subscriptions,
  Debts,
  DebtPayments,
  Reminders
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // Create new tables that might be missing
            await m.createTable(budgets);
            await m.createTable(budgetItems);
            // If budgets already existed but 'name' column was missing
            try {
              await m.addColumn(budgets, budgets.name);
            } catch (e) {
              // Column might already exist if table was created in this session
            }
          }
          if (from < 3) {
            try {
              await m.addColumn(debts, debts.walletId);
              await m.addColumn(debtPayments, debtPayments.walletId);
            } catch (e) {
              // Columns might already exist
            }
          }
          if (from < 4) {
            try {
              await m.addColumn(debts, debts.projectId);
              await m.addColumn(debtPayments, debtPayments.projectId);
            } catch (e) {
              // Columns might already exist
            }
          }
          if (from < 5) {
            try {
              // Fix: Drift addColumn requires the actual table column
              await m.addColumn(transactions, transactions.projectId);
              await m.addColumn(transactions, transactions.categoryId);
            } catch (e) {
              debugPrint('Migration error: $e');
            }
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');

          // Emergency Fix: Ensure tables exist even if migration was skipped
          final m = Migrator(this);
          for (final table in allTables) {
            await m.createTable(table);
          }
        },
      );

  Future<void> clearAllData() async {
    await transaction(() async {
      for (final table in allTables) {
        await delete(table).go();
      }
    });
  }
}
