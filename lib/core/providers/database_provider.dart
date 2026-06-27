import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/connection.dart';
import '../database/db_init_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase(connect());
  
  // Initialize with seed data
  _initDb(database);
  
  ref.onDispose(database.close);
  return database;
});

Future<void> _initDb(AppDatabase db) async {
  await DbInitService.seedCategories(db);
  await DbInitService.seedInitialWallet(db);
}
