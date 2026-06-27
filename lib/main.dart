import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'dart:io';
import 'dart:ui';
import 'dart:ffi';
import 'core/routes/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/localization/app_localizations.dart';
import 'package:devtrack/core/services/notification_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:devtrack/core/services/notification_scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:devtrack/core/database/app_database.dart';
import 'core/database/connection.dart';
import 'core/providers/database_provider.dart';
import 'core/services/data_sync_service.dart';

// Global navigator key for deep linking
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('--- APP STARTING ---');
  
  try {
    // 1. Initialize Firebase FIRST
    debugPrint('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase Initialized.');
    
    // 2. Initialize Hive
    debugPrint('Initializing Hive...');
    await Hive.initFlutter();
    debugPrint('Hive Initialized.');

    // 3. Initialize Database
    debugPrint('Connecting to Database...');
    final db = AppDatabase(connect());
    debugPrint('Database Connected.');

    // 4. Configure Google Fonts
    GoogleFonts.config.allowRuntimeFetching = true;

    // 5. Initialize Sync Service
    debugPrint('Initializing Sync Service...');
    DataSyncService().setDatabase(db);
    debugPrint('Sync Service Ready.');

    // 6. SQLCipher / Android specific
    if (Platform.isAndroid) {
      debugPrint('Initializing SQLCipher for Android...');
      try {
        open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
        DynamicLibrary.open('libsqlcipher.so');
      } catch (e) {
        debugPrint('SQLite/SQLCipher initialization failed: $e');
      }
    }

    // 7. Notification Services
    debugPrint('Initializing Notifications...');
    await AppNotificationService.instance.init();
    await NotificationScheduler.instance.start(database: db);
    debugPrint('Notifications Ready.');

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    
    debugPrint('Launching App...');
    runApp(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const DevTrackApp(),
      ),
    );
  } catch (e, stack) {
    debugPrint('FATAL ERROR DURING INIT: $e');
    debugPrint('STACK TRACE: $stack');
    
    // Fallback UI in case of total crash
    runApp(MaterialApp(home: Scaffold(body: Center(child: Text('Fatal Error: $e')))));
  }
}

class DevTrackApp extends ConsumerWidget {
  const DevTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterStateProvider);
    final locale = ref.watch(localeProvider);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeProvider.themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp.router(
          title: 'DevTrack Finance',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: currentMode,
          routerConfig: router,
          locale: locale,
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('sw'),
            Locale('fr'),
            Locale('ar'),
          ],
        );
      },
    );
  }
}
