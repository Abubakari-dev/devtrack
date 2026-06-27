import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('devtrack_attachments.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE attachments (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        phase_id TEXT,
        task_id TEXT,
        subtask_id TEXT,
        file_name TEXT NOT NULL,
        file_type TEXT NOT NULL,
        type TEXT NOT NULL,
        file_data BLOB,
        file_url TEXT,
        file_path TEXT,
        file_size INTEGER NOT NULL,
        uploaded_at TEXT NOT NULL,
        duration_ms INTEGER,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE profile_cache (
        uid TEXT PRIMARY KEY,
        display_name TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT,
        avatar_data BLOB,
        last_synced TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE payment_receipts (
        id TEXT PRIMARY KEY,
        payment_id TEXT NOT NULL,
        receipt_data BLOB NOT NULL,
        uploaded_at TEXT NOT NULL
      )
    ''');
  }
}
