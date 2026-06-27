import 'dart:ffi';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/open.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';

QueryExecutor connect({bool logStatements = false, String? password}) {
  return LazyDatabase(() async {
    if (Platform.isAndroid) {
      try {
        // Force the sqlite3 package to use SQLCipher
        open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
        
        // Manual trigger to ensure the library is loaded into memory
        DynamicLibrary.open('libsqlcipher.so');
      } catch (e) {
        print('SQLCipher manual load notice: $e');
      }
    }

    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'finance_tracker.db'));

    return NativeDatabase(
      file,
      logStatements: logStatements,
      setup: (rawDb) {
        final key = password ?? 'dev_placeholder_key';
        rawDb.execute("PRAGMA key = '$key';");
      },
    );
  });
}
