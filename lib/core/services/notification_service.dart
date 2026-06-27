import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:devtrack/features/projects/models/models.dart';
import '../database/app_database.dart';

/// Notification service with custom sounds and notification types
class AppNotificationService {
  AppNotificationService._();
  static final AppNotificationService instance = AppNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  bool _initialized = false;
  
  static const String _tokenBoxName = 'notification_settings';
  static const String _lastTokenKey = 'last_fcm_token';

  // ─── NOTIFICATION CHANNELS WITH CUSTOM SOUNDS ───────────────────────────────

  // Critical Alerts Channel - Highest Priority
  static final AndroidNotificationChannel _criticalChannel = AndroidNotificationChannel(
    'critical_alerts',
    'Critical Alerts',
    description: 'Urgent alerts requiring immediate attention',
    importance: Importance.max,
    playSound: true,
    sound: const RawResourceAndroidNotificationSound('critical_alert'),
    enableVibration: true,
    vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
    showBadge: true,
    enableLights: true,
    ledColor: const Color(0xFFFF0000),
  );

  // Payment Notifications Channel
  static final AndroidNotificationChannel _paymentChannel = AndroidNotificationChannel(
    'payment_notifications',
    'Payment Notifications',
    description: 'Payment reminders, due dates, and overdue alerts',
    importance: Importance.max,
    playSound: true,
    sound: const RawResourceAndroidNotificationSound('payment_sound'),
    enableVibration: true,
    vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
    showBadge: true,
    enableLights: true,
    ledColor: const Color(0xFFFF5252),
  );

  // Project Deadlines Channel
  static final AndroidNotificationChannel _projectChannel = AndroidNotificationChannel(
    'project_notifications',
    'Project Deadlines',
    description: 'Project deadlines, overdue alerts, and milestone notifications',
    importance: Importance.high,
    playSound: true,
    sound: const RawResourceAndroidNotificationSound('project_alert'),
    enableVibration: true,
    vibrationPattern: Int64List.fromList([0, 300, 200, 300]),
    showBadge: true,
    enableLights: true,
    ledColor: const Color(0xFFFFA726),
  );

  // Task Reminders Channel
  static final AndroidNotificationChannel _reminderChannel = AndroidNotificationChannel(
    'reminder_notifications',
    'Task Reminders',
    description: 'Task reminders, subtask alerts, and project start notifications',
    importance: Importance.high,
    playSound: true,
    sound: const RawResourceAndroidNotificationSound('reminder_tone'),
    enableVibration: true,
    vibrationPattern: Int64List.fromList([0, 200, 100, 200]),
    showBadge: true,
  );

  // Success & Completion Channel
  static final AndroidNotificationChannel _successChannel = AndroidNotificationChannel(
    'success_notifications',
    'Success & Completion',
    description: 'Project completion, payment received, and success notifications',
    importance: Importance.defaultImportance,
    playSound: true,
    sound: const RawResourceAndroidNotificationSound('success_sound'),
    enableVibration: true,
    vibrationPattern: Int64List.fromList([0, 100, 50, 100]),
    showBadge: true,
    enableLights: true,
    ledColor: const Color(0xFF4CAF50),
  );

  // Finance & Budget Channel
  static final AndroidNotificationChannel _financeChannel = AndroidNotificationChannel(
    'finance_notifications',
    'Finance & Budget',
    description: 'Budget alerts, expense tracking, and savings reminders',
    importance: Importance.high,
    playSound: true,
    sound: const RawResourceAndroidNotificationSound('finance_alert'),
    enableVibration: true,
    vibrationPattern: Int64List.fromList([0, 250, 150, 250]),
    showBadge: true,
    enableLights: true,
    ledColor: const Color(0xFF66BB6A),
  );

  // Daily Summary Channel
  static final AndroidNotificationChannel _summaryChannel = AndroidNotificationChannel(
    'daily_summary',
    'Daily Summary',
    description: 'Daily project summaries and productivity reports',
    importance: Importance.defaultImportance,
    playSound: true,
    sound: const RawResourceAndroidNotificationSound('notification_gentle'),
    enableVibration: false,
    showBadge: true,
  );

  // General Updates Channel
  static final AndroidNotificationChannel _generalChannel = AndroidNotificationChannel(
    'general_updates',
    'General Updates',
    description: 'App updates, tips, and general information',
    importance: Importance.low,
    playSound: true,
    sound: const RawResourceAndroidNotificationSound('notification_soft'),
    enableVibration: false,
    showBadge: true,
  );

  // ─── INITIALIZATION ─────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;

    // 1. Initialize Local Timezones
    tz_data.initializeTimeZones();
    try {
      final dynamic timezoneResult = await FlutterTimezone.getLocalTimezone();
      String timeZoneName = timezoneResult.toString();
      
      // Improved parsing: search for the first valid timezone ID in the string
      // Timezone IDs usually contain a '/' (e.g. Africa/Dar_es_Salaam)
      final allNames = tz.timeZoneDatabase.locations.keys;
      
      bool found = false;
      for (var name in allNames) {
        if (timeZoneName.contains(name)) {
          tz.setLocalLocation(tz.getLocation(name));
          found = true;
          break;
        }
      }

      if (!found) {
        // Fallback to extraction if not found in database keys directly
        if (timeZoneName.contains('(')) {
          timeZoneName = timeZoneName.split('(')[1].split(',')[0].trim();
        }
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      }
    } catch (e) {
      debugPrint('AppNotificationService: Timezone setup failed: $e');
      try {
        tz.setLocalLocation(tz.getLocation('Africa/Nairobi'));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    }

    // 2. Register Android Channels
    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_criticalChannel);
      await androidPlugin?.createNotificationChannel(_paymentChannel);
      await androidPlugin?.createNotificationChannel(_projectChannel);
      await androidPlugin?.createNotificationChannel(_reminderChannel);
      await androidPlugin?.createNotificationChannel(_successChannel);
      await androidPlugin?.createNotificationChannel(_financeChannel);
      await androidPlugin?.createNotificationChannel(_summaryChannel);
      await androidPlugin?.createNotificationChannel(_generalChannel);
    }

    // 3. Local Notification Settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    // 4. Request Push Permissions (Silent Request)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: true,
    );

    // 5. Handle Messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    _initialized = true;
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _saveDeviceToken();
        _listenForCloudNotifications();
      }
    });
  }

  // ─── NOTIFICATION HANDLERS ──────────────────────────────────────────────────

  void _handleNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped with payload: ${response.payload}');
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (message.notification != null) {
      final type = _getNotificationTypeFromData(message.data);
      showNotification(
        type: type,
        title: message.notification!.title ?? 'DevTrack',
        body: message.notification!.body ?? '',
        payload: message.data['projectId'] ?? '',
      );
    }
  }

  // ─── REAL-TIME CLOUD LISTENER ────────────────────────
  
  void _listenForCloudNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null) {
            final type = _getNotificationTypeFromData(data);
            showNotification(
              id: change.doc.id.hashCode,
              type: type,
              title: data['title'] ?? 'DevTrack Alert',
              body: data['body'] ?? '',
              payload: data['projectId'] ?? change.doc.id,
            );
          }
        }
      }
    });
  }

  NotificationType _getNotificationTypeFromData(Map<String, dynamic> data) {
    final typeStr = data['type'] as String?;
    return NotificationType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => NotificationType.general,
    );
  }

  // ─── READ/WRITE OPERATIONS ─────────────────────────────────────────────────

  Future<void> markAsRead(String notificationId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('AppNotificationService: Error marking as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();
      
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('AppNotificationService: Error marking all as read: $e');
    }
  }

  // ─── FCM TOKEN MANAGEMENT ───────────────────────────────────────────────────

  Future<void> _saveDeviceToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      String? token = await _fcm.getToken();
      if (token == null) return;

      final box = await Hive.openBox(_tokenBoxName);
      final lastToken = box.get(_lastTokenKey);

      if (token != lastToken) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
              'fcmToken': token,
              'lastTokenUpdate': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
        
        await box.put(_lastTokenKey, token);
        debugPrint('AppNotificationService: New FCM Token saved to cloud');
      }
    } catch (e) {
      debugPrint('AppNotificationService: Error saving token: $e');
    }
  }

  // ─── SHOW NOTIFICATION ──────────────────────────────────────────────────────

  Future<void> showNotification({
    required NotificationType type,
    required String title,
    required String body,
    String? payload,
    int? id,
  }) async {
    final notificationId = id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000);
    final details = _getNotificationDetails(type, title, body);

    await _plugin.show(notificationId, title, body, details, payload: payload);
  }

  NotificationDetails _getNotificationDetails(NotificationType type, String title, String body) {
    switch (type) {
      case NotificationType.paymentOverdue:
      case NotificationType.projectOverdue:
      case NotificationType.budgetExceeded:
        return NotificationDetails(
          android: AndroidNotificationDetails(
            _criticalChannel.id,
            _criticalChannel.name,
            channelDescription: _criticalChannel.description,
            importance: _criticalChannel.importance,
            priority: Priority.max,
            playSound: true,
            enableVibration: true,
            vibrationPattern: _criticalChannel.vibrationPattern,
            styleInformation: BigTextStyleInformation(
              body,
              contentTitle: title,
              summaryText: 'Urgent Action Required',
            ),
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            color: const Color(0xFFFF0000),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'critical_alert.wav',
            interruptionLevel: InterruptionLevel.critical,
          ),
        );

      case NotificationType.paymentDue:
      case NotificationType.paymentPartial:
        return NotificationDetails(
          android: AndroidNotificationDetails(
            _paymentChannel.id,
            _paymentChannel.name,
            channelDescription: _paymentChannel.description,
            importance: _paymentChannel.importance,
            priority: Priority.max,
            playSound: true,
            enableVibration: true,
            vibrationPattern: _paymentChannel.vibrationPattern,
            styleInformation: BigTextStyleInformation(
              body,
              contentTitle: title,
              summaryText: 'Payment Alert',
            ),
            fullScreenIntent: true,
            category: AndroidNotificationCategory.reminder,
            color: const Color(0xFFFF5252),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        );

      case NotificationType.projectDeadline:
      case NotificationType.projectUpdated:
      case NotificationType.milestoneApproaching:
        return NotificationDetails(
          android: AndroidNotificationDetails(
            _projectChannel.id,
            _projectChannel.name,
            channelDescription: _projectChannel.description,
            importance: _projectChannel.importance,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            vibrationPattern: _projectChannel.vibrationPattern,
            styleInformation: BigTextStyleInformation(
              body,
              contentTitle: title,
              summaryText: 'Project Alert',
            ),
            category: AndroidNotificationCategory.reminder,
            color: const Color(0xFFFFA726),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        );

      case NotificationType.projectStart:
      case NotificationType.taskReminder:
      case NotificationType.taskOverdue:
      case NotificationType.subtaskReminder:
        return NotificationDetails(
          android: AndroidNotificationDetails(
            _reminderChannel.id,
            _reminderChannel.name,
            channelDescription: _reminderChannel.description,
            importance: _reminderChannel.importance,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            vibrationPattern: _reminderChannel.vibrationPattern,
            styleInformation: BigTextStyleInformation(
              body,
              contentTitle: title,
              summaryText: 'Reminder',
            ),
            category: AndroidNotificationCategory.reminder,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          ),
        );

      case NotificationType.projectCompleted:
      case NotificationType.paymentReceived:
      case NotificationType.projectCreated:
      case NotificationType.taskCompleted:
      case NotificationType.milestoneReached:
      case NotificationType.dataSaved:
      case NotificationType.syncCompleted:
      case NotificationType.backupCompleted:
        return NotificationDetails(
          android: AndroidNotificationDetails(
            _successChannel.id,
            _successChannel.name,
            channelDescription: _successChannel.description,
            importance: _successChannel.importance,
            priority: Priority.defaultPriority,
            playSound: true,
            enableVibration: true,
            vibrationPattern: _successChannel.vibrationPattern,
            styleInformation: BigTextStyleInformation(
              body,
              contentTitle: title,
              summaryText: 'Success',
            ),
            category: AndroidNotificationCategory.status,
            color: const Color(0xFF4CAF50),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          ),
        );

      case NotificationType.budgetWarning:
      case NotificationType.savingsReminder:
      case NotificationType.expenseAdded:
        return NotificationDetails(
          android: AndroidNotificationDetails(
            _financeChannel.id,
            _financeChannel.name,
            channelDescription: _financeChannel.description,
            importance: _financeChannel.importance,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            vibrationPattern: _financeChannel.vibrationPattern,
            styleInformation: BigTextStyleInformation(
              body,
              contentTitle: title,
              summaryText: 'Finance Alert',
            ),
            category: AndroidNotificationCategory.reminder,
            color: const Color(0xFF66BB6A),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          ),
        );

      case NotificationType.dailySummary:
      case NotificationType.weeklyReport:
        return NotificationDetails(
          android: AndroidNotificationDetails(
            _summaryChannel.id,
            _summaryChannel.name,
            channelDescription: _summaryChannel.description,
            importance: _summaryChannel.importance,
            priority: Priority.defaultPriority,
            playSound: true,
            enableVibration: false,
            styleInformation: BigTextStyleInformation(
              body,
              contentTitle: title,
              summaryText: 'Daily Report',
            ),
            category: AndroidNotificationCategory.status,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: false,
          ),
        );

      case NotificationType.general:
        return NotificationDetails(
          android: AndroidNotificationDetails(
            _generalChannel.id,
            _generalChannel.name,
            channelDescription: _generalChannel.description,
            importance: _generalChannel.importance,
            priority: Priority.low,
            playSound: false,
            styleInformation: BigTextStyleInformation(body),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: false,
          ),
        );
    }
  }

  // ─── SCHEDULE NOTIFICATION ──────────────────────────────────────────────────

  Future<void> schedule({
    required NotificationType type,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    int? id,
  }) async {
    return scheduleNotification(
      type: type,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: payload,
      id: id,
    );
  }

  Future<void> scheduleNotification({
    required NotificationType type,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    int? id,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) {
      debugPrint('Cannot schedule notification in the past');
      return;
    }

    final notificationId = id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000);
    final details = _getNotificationDetails(type, title, body);

    await _plugin.zonedSchedule(
      notificationId,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  // ─── PROJECT REMINDER LOGIC ────────────────────────────────────────────────

  Future<void> scheduleProjectReminders(Project project) async {
    final now = DateTime.now();

    // Cancel existing project notifications
    await cancelNotification(project.id.hashCode);
    await cancelNotification(project.id.hashCode + 1);
    await cancelNotification(project.id.hashCode + 99);

    // 1. Overdue Alert
    if (project.endDate.isBefore(now) && project.status != ProjectStatus.completed) {
      final daysOverdue = now.difference(project.endDate).inDays;
      await notifyProjectOverdue(
        projectName: project.name, 
        daysOverdue: daysOverdue,
        id: project.id.hashCode + 99,
      );
    }

    // 2. Start Reminder
    final startReminderTime = DateTime(
      project.startDate.year,
      project.startDate.month,
      project.startDate.day,
      8, 0,
    );

    if (startReminderTime.isAfter(now)) {
      await scheduleProjectStartReminder(
        projectName: project.name,
        startDate: startReminderTime,
        id: project.id.hashCode,
      );
    }

    // 3. Deadline Approaching (3 days before)
    if (project.deadlineReminder) {
      final deadlineReminderTime = project.endDate.subtract(const Duration(days: 3)).copyWith(hour: 9);
      if (deadlineReminderTime.isAfter(now)) {
        await scheduleProjectDeadlineReminder(
          projectName: project.name,
          deadline: project.endDate,
          daysBeforeDeadline: 3,
          id: project.id.hashCode + 1,
        );
      }
    }

    // 4. Task & Subtask Reminders
    for (final phase in project.phases) {
      for (final task in phase.tasks) {
        if (task.status != TaskStatus.done) {
          for (final subtask in task.subtasks) {
            if (!subtask.isDone && subtask.reminderDate != null) {
              if (subtask.reminderDate!.isAfter(now)) {
                await cancelNotification(subtask.id.hashCode);
                await scheduleNotification(
                  type: NotificationType.taskReminder,
                  title: '📋 Task Reminder',
                  body: 'Don\'t forget: "${subtask.name}" in project "${project.name}"',
                  scheduledDate: subtask.reminderDate!,
                  id: subtask.id.hashCode,
                );
              }
            }
          }
        }
      }
    }
  }

  // ─── DEBT REMINDER LOGIC ──────────────────────────────────────────────────

  DateTime _ensureDaytime(DateTime date) {
    if (date.hour >= 20) {
      // If after 8 PM, move to 9 AM tomorrow
      return DateTime(date.year, date.month, date.day + 1, 9, 0);
    } else if (date.hour < 8) {
      // If before 8 AM, move to 9 AM today
      return DateTime(date.year, date.month, date.day, 9, 0);
    }
    return date;
  }

  Future<void> scheduleDebtReminders(AppDatabase db, Debt debt) async {
    final now = DateTime.now();
    final debtIdHash = debt.id.hashCode;

    // Cancel existing debt notifications (up to 4 to cover new logic)
    await cancelNotification(debtIdHash);
    await cancelNotification(debtIdHash + 1);
    await cancelNotification(debtIdHash + 2);
    await cancelNotification(debtIdHash + 3);

    // Also clear from local DB reminders table for this debt
    await (db.delete(db.reminders)..where((t) => t.relatedId.equals(debt.id))).go();

    if (debt.status == 'paid') return;

    if (debt.dueDate != null) {
      final title = debt.type == 'lent' ? '💰 Debt Collection' : '💸 Repayment Due';
      final remaining = debt.principalAmount - debt.amountPaid;

      // 1. Reminder 3 days before
      final r3 = _ensureDaytime(debt.dueDate!.subtract(const Duration(days: 3)).copyWith(hour: 9));
      if (r3.isAfter(now)) {
        await _scheduleDebtNotification(db, debt.id, debtIdHash + 1, title, '$remaining is due in 3 days from ${debt.contactName}.', r3);
      }

      // 2. Reminder 1 day before
      final r1 = _ensureDaytime(debt.dueDate!.subtract(const Duration(days: 1)).copyWith(hour: 10));
      if (r1.isAfter(now)) {
        await _scheduleDebtNotification(db, debt.id, debtIdHash + 2, title, '$remaining is due tomorrow from ${debt.contactName}.', r1);
      }

      // 3. Reminder on Due Day
      final rDay = _ensureDaytime(debt.dueDate!.copyWith(hour: 8));
      if (rDay.isAfter(now)) {
        await _scheduleDebtNotification(db, debt.id, debtIdHash + 3, title, 'Today is the deadline for $remaining from ${debt.contactName}.', rDay);
      }

      // 4. Overdue Alert (Only show immediately if currently daytime)
      if (debt.dueDate!.isBefore(now)) {
        final days = now.difference(debt.dueDate!).inDays;
        if (now.hour >= 8 && now.hour < 20) {
          await showNotification(
            type: NotificationType.paymentOverdue,
            title: '🚨 Debt Overdue',
            body: '${debt.contactName}\'s payment is $days days overdue.',
            id: debtIdHash,
          );
        }
      }
    }
  }

  Future<void> _scheduleDebtNotification(AppDatabase db, String debtId, int id, String title, String body, DateTime date) async {
    await scheduleNotification(
      type: NotificationType.paymentDue,
      title: title,
      body: body,
      scheduledDate: date,
      id: id,
    );

    await db.into(db.reminders).insert(RemindersCompanion.insert(
      type: 'debt',
      relatedId: debtId,
      message: '$title: $body',
      scheduledDate: date,
    ));
  }

  // ─── BUDGET REMINDER LOGIC ────────────────────────────────────────────────

  Future<void> checkBudgetStatus(String projectName, double budget, double spent) async {
    if (budget <= 0) return;
    
    final percent = (spent / budget) * 100;
    
    if (spent > budget) {
      await notifyBudgetExceeded(projectName: projectName, budget: budget, spent: spent);
    } else if (percent >= 90) {
      await notifyBudgetWarning(
        projectName: projectName, 
        budget: budget, 
        spent: spent, 
        percentUsed: percent.toInt()
      );
    }
  }

  // ─── SPECIFIC NOTIFICATION METHODS ──────────────────────────────────────────

  Future<void> notifyDataSaved({required String message, int? id}) async {
    await showNotification(
      type: NotificationType.dataSaved,
      title: '✅ Changes Saved',
      body: message,
      payload: 'data_saved',
      id: id,
    );
  }

  Future<void> notifyProjectCreated({required String projectName, int? id}) async {
    await showNotification(
      type: NotificationType.projectCreated,
      title: '🏗️ Project Created',
      body: 'Project "$projectName" has been created successfully!',
      payload: 'project_created',
      id: id,
    );
  }

  Future<void> notifyPaymentDue({
    required String projectName,
    required double amount,
    required DateTime dueDate,
    int? id,
  }) async {
    await showNotification(
      type: NotificationType.paymentDue,
      title: '💰 Payment Due',
      body: 'Payment of \$$amount for "$projectName" is due on ${_formatDate(dueDate)}',
      payload: 'payment_due',
      id: id,
    );
  }

  Future<void> notifyPaymentOverdue({
    required String projectName,
    required double amount,
    required int daysOverdue,
    int? id,
  }) async {
    await showNotification(
      type: NotificationType.paymentOverdue,
      title: '🚨 Payment Overdue!',
      body: 'Payment of \$$amount for "$projectName" is $daysOverdue days overdue!',
      payload: 'payment_overdue',
      id: id,
    );
  }

  Future<void> notifyProjectOverdue({
    required String projectName,
    required int daysOverdue,
    int? id,
  }) async {
    await showNotification(
      type: NotificationType.projectOverdue,
      title: '🚨 Project Out of Time!',
      body: 'Project "$projectName" is $daysOverdue days overdue! Take action now.',
      payload: 'project_overdue',
      id: id,
    );
  }

  Future<void> notifyProjectDeadline({
    required String projectName,
    required DateTime deadline,
    required int daysRemaining,
    int? id,
  }) async {
    await showNotification(
      type: NotificationType.projectDeadline,
      title: '⏰ Project Deadline Approaching',
      body: 'Project "$projectName" is due in $daysRemaining days (${_formatDate(deadline)})',
      payload: 'project_deadline',
      id: id,
    );
  }

  Future<void> notifyProjectStart({required String projectName, int? id}) async {
    await showNotification(
      type: NotificationType.projectStart,
      title: '🚀 Time to Start!',
      body: 'Project "$projectName" is scheduled to start today!',
      payload: 'project_start',
      id: id,
    );
  }

  Future<void> notifyProjectCompleted({required String projectName, int? id}) async {
    await showNotification(
      type: NotificationType.projectCompleted,
      title: '🎉 Project Completed!',
      body: 'Congratulations! "$projectName" has been completed successfully!',
      payload: 'project_completed',
      id: id,
    );
  }

  Future<void> notifyTaskReminder({
    required String taskName,
    required String projectName,
    int? id,
  }) async {
    await showNotification(
      type: NotificationType.taskReminder,
      title: '📋 Task Reminder',
      body: 'Don\'t forget: "$taskName" in project "$projectName"',
      payload: 'task_reminder',
      id: id,
    );
  }

  Future<void> notifyPaymentReceived({
    required String projectName,
    required double amount,
    int? id,
  }) async {
    await showNotification(
      type: NotificationType.paymentReceived,
      title: '✅ Payment Received',
      body: 'Payment of TSh ${amount.toInt()} received for "$projectName"',
      payload: 'payment_received',
      id: id,
    );
  }

  Future<void> notifyBudgetExceeded({
    required String projectName,
    required double budget,
    required double spent,
    int? id,
  }) async {
    final overAmount = spent - budget;
    await showNotification(
      type: NotificationType.budgetExceeded,
      title: '🚨 Budget Exceeded!',
      body: 'Project "$projectName" has exceeded budget by TSh ${overAmount.toInt()}. Budget: TSh ${budget.toInt()}, Spent: TSh ${spent.toInt()}',
      payload: 'budget_exceeded',
      id: id,
    );
  }

  Future<void> notifyBudgetWarning({
    required String projectName,
    required double budget,
    required double spent,
    required int percentUsed,
    int? id,
  }) async {
    await showNotification(
      type: NotificationType.budgetWarning,
      title: '⚠️ Budget Warning',
      body: 'Project "$projectName" has used $percentUsed% of budget (TSh ${spent.toInt()} of TSh ${budget.toInt()})',
      payload: 'budget_warning',
      id: id,
    );
  }

  Future<void> notifySavingsReminder({
    required String projectName,
    required double targetSavings,
    int? id,
  }) async {
    await showNotification(
      type: NotificationType.savingsReminder,
      title: '💰 Savings Reminder',
      body: 'Remember to save TSh ${targetSavings.toInt()} from project "$projectName"',
      payload: 'savings_reminder',
      id: id,
    );
  }

  Future<void> notifyExpenseAdded({
    required String projectName,
    required double amount,
    required String category,
    int? id,
  }) async {
    await showNotification(
      type: NotificationType.expenseAdded,
      title: '💸 Expense Recorded',
      body: 'TSh ${amount.toInt()} expense added to "$projectName" ($category)',
      payload: 'expense_added',
      id: id,
    );
  }

  Future<void> notifyTaskCompleted({
    required String taskName,
    required String projectName,
    int? id,
  }) async {
    await showNotification(
      type: NotificationType.taskCompleted,
      title: '✅ Task Completed',
      body: 'Task "$taskName" in project "$projectName" has been completed!',
      payload: 'task_completed',
      id: id,
    );
  }

  Future<void> notifyTaskOverdue({
    required String taskName,
    required String projectName,
    required int daysOverdue,
    int? id,
  }) async {
    await showNotification(
      type: NotificationType.taskOverdue,
      title: '⏰ Task Overdue',
      body: 'Task "$taskName" in "$projectName" is $daysOverdue days overdue',
      payload: 'task_overdue',
      id: id,
    );
  }

  Future<void> notifyMilestoneReached({
    required String milestoneName,
    required String projectName,
    int? id,
  }) async {
    await showNotification(
      type: NotificationType.milestoneReached,
      title: '🎯 Milestone Reached!',
      body: 'Milestone "$milestoneName" in project "$projectName" has been achieved!',
      payload: 'milestone_reached',
      id: id,
    );
  }

  Future<void> notifyMilestoneApproaching({
    required String milestoneName,
    required String projectName,
    required int daysRemaining,
    int? id,
  }) async {
    await showNotification(
      type: NotificationType.milestoneApproaching,
      title: '🎯 Milestone Approaching',
      body: 'Milestone "$milestoneName" in "$projectName" is due in $daysRemaining days',
      payload: 'milestone_approaching',
      id: id,
    );
  }

  Future<void> notifyDailySummary({
    required int activeProjects,
    required int tasksCompleted,
    required int upcomingDeadlines,
    int? id,
  }) async {
    await showNotification(
      type: NotificationType.dailySummary,
      title: '📊 Daily Summary',
      body: 'Active Projects: $activeProjects | Tasks Completed: $tasksCompleted | Upcoming Deadlines: $upcomingDeadlines',
      payload: 'daily_summary',
      id: id,
    );
  }

  Future<void> notifyWeeklyReport({
    required int projectsCompleted,
    required int totalTasksCompleted,
    required double totalEarnings,
    int? id,
  }) async {
    await showNotification(
      type: NotificationType.weeklyReport,
      title: '📈 Weekly Report',
      body: 'This week: $projectsCompleted projects completed, $totalTasksCompleted tasks done, TSh ${totalEarnings.toInt()} earned',
      payload: 'weekly_report',
      id: id,
    );
  }

  Future<void> notifySyncCompleted({int? id}) async {
    await showNotification(
      type: NotificationType.syncCompleted,
      title: '🔄 Sync Completed',
      body: 'Your data has been synced successfully',
      payload: 'sync_completed',
      id: id,
    );
  }

  Future<void> notifyBackupCompleted({int? id}) async {
    await showNotification(
      type: NotificationType.backupCompleted,
      title: '💾 Backup Completed',
      body: 'Your data has been backed up successfully',
      payload: 'backup_completed',
      id: id,
    );
  }

  Future<void> notifyPartialPayment({
    required String projectName,
    required double amountPaid,
    required double amountRemaining,
    int? id,
  }) async {
    await showNotification(
      type: NotificationType.paymentPartial,
      title: '💰 Partial Payment Received',
      body: 'TSh ${amountPaid.toInt()} received for "$projectName". Remaining: TSh ${amountRemaining.toInt()}',
      payload: 'partial_payment',
      id: id,
    );
  }

  Future<void> notifyProjectUpdated({
    required String projectName,
    required String updateType,
    int? id,
  }) async {
    await showNotification(
      type: NotificationType.projectUpdated,
      title: '📝 Project Updated',
      body: 'Project "$projectName" has been updated: $updateType',
      payload: 'project_updated',
      id: id,
    );
  }

  // ─── UTILITY METHODS ────────────────────────────────────────────────────────

  Future<void> schedulePaymentReminder({
    required String projectName,
    required double amount,
    required DateTime dueDate,
    int daysBeforeDue = 3,
    int? id,
  }) async {
    final reminderDate = dueDate.subtract(Duration(days: daysBeforeDue));
    await scheduleNotification(
      type: NotificationType.paymentDue,
      title: '💰 Upcoming Payment',
      body: 'Payment of \$$amount for "$projectName" is due in $daysBeforeDue days',
      scheduledDate: reminderDate,
      payload: 'payment_reminder',
      id: id,
    );
  }

  Future<void> scheduleProjectStartReminder({
    required String projectName,
    required DateTime startDate,
    int? id,
  }) async {
    await scheduleNotification(
      type: NotificationType.projectStart,
      title: '🚀 Project Starting Soon',
      body: 'Project "$projectName" starts today!',
      scheduledDate: startDate,
      payload: 'project_start_reminder',
      id: id,
    );
  }

  Future<void> scheduleProjectDeadlineReminder({
    required String projectName,
    required DateTime deadline,
    int daysBeforeDeadline = 3,
    int? id,
  }) async {
    final reminderDate = deadline.subtract(Duration(days: daysBeforeDeadline));
    await scheduleNotification(
      type: NotificationType.projectDeadline,
      title: '⏰ Project Deadline Approaching',
      body: 'Project "$projectName" is due in $daysBeforeDeadline days',
      scheduledDate: reminderDate,
      payload: 'project_deadline_reminder',
      id: id,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _plugin.pendingNotificationRequests();
  }
}

// Aliases for compatibility
typedef NotificationService = AppNotificationService;
typedef EnhancedNotificationService = AppNotificationService;

// ─── NOTIFICATION TYPE ENUM ─────────────────────────────────────────────────

enum NotificationType {
  paymentDue,
  paymentOverdue,
  paymentReceived,
  paymentPartial,
  projectOverdue,
  projectDeadline,
  projectStart,
  projectCompleted,
  projectCreated,
  projectUpdated,
  taskReminder,
  taskOverdue,
  taskCompleted,
  subtaskReminder,
  budgetExceeded,
  budgetWarning,
  savingsReminder,
  expenseAdded,
  milestoneReached,
  milestoneApproaching,
  dailySummary,
  weeklyReport,
  dataSaved,
  syncCompleted,
  backupCompleted,
  general,
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
}

extension DateTimeExtension on DateTime {
  DateTime copyWith({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? millisecond,
    int? microsecond,
  }) {
    return DateTime(
      year ?? this.year,
      month ?? this.month,
      day ?? this.day,
      hour ?? this.hour,
      minute ?? this.minute,
      second ?? this.second,
      millisecond ?? this.millisecond,
      microsecond ?? this.microsecond,
    );
  }
}
