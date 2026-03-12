import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('devtrack_local.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // Incremented version to trigger onUpgrade
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    const textType = 'TEXT NOT NULL';
    const blobType = 'BLOB';
    const integerType = 'INTEGER';
    const idType = 'TEXT PRIMARY KEY';

    await db.execute('''
      CREATE TABLE attachments (
        id $idType,
        project_id $textType,
        phase_id TEXT,
        task_id TEXT,
        subtask_id TEXT,
        file_name $textType,
        file_type $textType,
        file_data $blobType,
        file_url TEXT,
        file_size $integerType,
        uploaded_at $textType,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE profile_cache (
        uid $idType,
        display_name TEXT,
        email TEXT,
        phone TEXT,
        avatar_data $blobType,
        biometric_signature TEXT,
        last_synced TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE payment_receipts (
        id $idType,
        payment_id $textType,
        receipt_data $blobType,
        uploaded_at $textType
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE profile_cache ADD COLUMN biometric_signature TEXT');
    }
  }

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<Object?>? whereArgs}) async {
    final db = await instance.database;
    return await db.query(table, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    final db = await instance.database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
