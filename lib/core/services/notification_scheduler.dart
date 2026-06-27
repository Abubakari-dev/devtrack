import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:drift/drift.dart' as drift;
import '../../features/projects/models/models.dart';
import '../../firebase_options.dart';
import '../database/app_database.dart';
import '../database/connection.dart';
import 'notification_service.dart';

/// Top-level callback for Workmanager. Must be outside any class.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('Workmanager: Executing background health check: $task');

    try {
      // 1. Initialize Firebase for background process
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // 2. Initialize Database connection
      final db = AppDatabase(connect());

      // 3. Trigger health check
      await NotificationScheduler.instance.backgroundHealthCheck(database: db);

      await db.close();
      return true;
    } catch (e) {
      debugPrint('Workmanager Task Error: $e');
      return false;
    }
  });
}

/// Automatically schedules and manages notifications for projects and payments.
/// Uses a hybrid approach:
/// - Foreground: Timers for immediate responsiveness.
/// - Background: WorkManager for periodic checks when the app is closed.
class NotificationScheduler {
  NotificationScheduler._();
  static final NotificationScheduler instance = NotificationScheduler._();

  final List<Timer> _timers = [];
  final _notificationService = AppNotificationService.instance;
  AppDatabase? _db;

  static const String backgroundTaskName = 'com.devtrack.health_check_task';

  // ─── CONFIGURATION ──────────────────────────────────────────────────────────

  // Tanzanian time to 24h mapping
  static const int _saa2Asubuhi = 8;
  static const int _saa6Mchana = 12;
  static const int _saa10Jioni = 16;
  static const int _saa2Usiku = 20;

  /// Start the notification scheduler
  Future<void> start({AppDatabase? database}) async {
    _db = database;
    
    // 1. Setup Foreground Timers (responsive while using app)
    stop();
    _checkAndScheduleNotifications();
    _scheduleCheckAt(_saa2Asubuhi, 0, label: 'Morning Check (Saa 2 Asubuhi)');
    _scheduleCheckAt(_saa6Mchana, 0, label: 'Mid-day Check (Saa 6 Mchana)');
    _scheduleCheckAt(_saa10Jioni, 0, label: 'Evening Check (Saa 10 Jioni)');
    _scheduleCheckAt(_saa2Usiku, 0, label: 'Nightly Review (Saa 2 Usiku)');

    // 2. Setup WorkManager (for background checks when app is closed)
    try {
      await Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);
      await Workmanager().registerPeriodicTask(
        '1', // Unique ID
        backgroundTaskName,
        frequency: const Duration(hours: 4), // Checks every 4 hours
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
        constraints: Constraints(
          networkType: NetworkType.connected, // Only check if online
        ),
      );
      debugPrint('NotificationScheduler: Background WorkManager registered.');
    } catch (e) {
      debugPrint('NotificationScheduler: WorkManager init failed: $e');
    }
  }

  /// Entry point for background execution
  Future<void> backgroundHealthCheck({required AppDatabase database}) async {
    _db = database;
    await _checkAndScheduleNotifications();
  }

  /// Stop the notification scheduler and clean up resources
  void stop() {
    for (var timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
    debugPrint('NotificationScheduler: All timers stopped.');
  }

  /// Schedule checks at a specific hour and minute
  void _scheduleCheckAt(int hour, int minute, {required String label}) {
    final now = DateTime.now();
    var nextRun = DateTime(now.year, now.month, now.day, hour, minute);
    
    if (now.isAfter(nextRun)) {
      nextRun = nextRun.add(const Duration(days: 1));
    }

    final initialDelay = nextRun.difference(now);

    final timer = Timer(initialDelay, () {
      _checkAndScheduleNotifications();
      // Schedule recurring check every 24 hours after the first run
      final periodicTimer = Timer.periodic(const Duration(days: 1), (_) {
        _checkAndScheduleNotifications();
      });
      _timers.add(periodicTimer);
    });
    
    _timers.add(timer);
    debugPrint('NotificationScheduler: $label scheduled for ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
  }

  /// Centralized logic to evaluate projects and payments
  Future<void> _checkAndScheduleNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    debugPrint('NotificationScheduler: Executing health check for User: ${user.uid}');

    try {
      await Future.wait([
        _checkProjects(user.uid),
        _checkDebts(),
      ]);
    } catch (e) {
      debugPrint('NotificationScheduler Error: $e');
    }
  }

  /// Inspect projects for start dates and deadlines
  Future<void> _checkProjects(String userId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final projectsSnapshot = await FirebaseFirestore.instance
        .collection('projects')
        .where('ownerId', isEqualTo: userId)
        .where('status', isNotEqualTo: ProjectStatus.completed.name)
        .get();

    for (var doc in projectsSnapshot.docs) {
      final data = doc.data();
      final projectName = data['name'] as String? ?? 'Unnamed Project';
      final statusStr = data['status'] as String? ?? ProjectStatus.planned.name;
      
      final status = ProjectStatus.values.firstWhere(
        (e) => e.name == statusStr, 
        orElse: () => ProjectStatus.planned,
      );
      
      // 1. Handle Project Start Dates
      final startDateStr = data['startDate'] as String?;
      if (startDateStr != null) {
        final startDate = DateTime.parse(startDateStr);
        final startDateOnly = DateTime(startDate.year, startDate.month, startDate.day);
        
        if (status == ProjectStatus.planned) {
          if (startDateOnly.isAtSameMomentAs(today)) {
            // It's the day!
            await _notificationService.notifyProjectStart(
              projectName: projectName,
              id: doc.id.hashCode,
            );
          } else if (startDateOnly.isBefore(today)) {
            // It was supposed to start already
            await _notificationService.showNotification(
              type: NotificationType.projectStart,
              title: '🚀 Action Required: Project Delayed',
              body: 'Project "$projectName" was due to start on ${startDate.day}/${startDate.month}. Update its status to Active!',
              id: doc.id.hashCode + 100,
            );
          }
        }
      }

      // 2. Handle Project Deadlines
      final deadlineStr = data['endDate'] as String?; // Project model uses endDate for deadline
      if (deadlineStr != null) {
        final deadline = DateTime.parse(deadlineStr);
        final deadlineOnly = DateTime(deadline.year, deadline.month, deadline.day);
        final daysUntilDeadline = deadlineOnly.difference(today).inDays;

        if (daysUntilDeadline < 0) {
          // Project is overdue
          await _notificationService.notifyProjectOverdue(
            projectName: projectName,
            daysOverdue: -daysUntilDeadline,
            id: doc.id.hashCode + 200,
          );
        } else if (daysUntilDeadline >= 0 && daysUntilDeadline <= 3) {
          // Deadline approaching
          await _notificationService.notifyProjectDeadline(
            projectName: projectName,
            deadline: deadline,
            daysRemaining: daysUntilDeadline,
            id: doc.id.hashCode + 300,
          );
        }
      }
    }
  }

  /// Inspect local debts for due dates
  Future<void> _checkDebts() async {
    if (_db == null) return;
    
    final debts = await _db!.select(_db!.debts).get();
    for (var debt in debts) {
      await _notificationService.scheduleDebtReminders(_db!, debt);
    }
  }

  /// Manually trigger a check
  Future<void> checkNow() async {
    await _checkAndScheduleNotifications();
  }

  /// Clean cancellation logic
  Future<void> cancelProjectNotifications(String projectId) async {
    await _notificationService.cancelNotification(projectId.hashCode);
    await _notificationService.cancelNotification(projectId.hashCode + 100);
    await _notificationService.cancelNotification(projectId.hashCode + 200);
    await _notificationService.cancelNotification(projectId.hashCode + 300);
  }
}
