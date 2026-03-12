import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../features/projects/models/project_model.dart';
import 'enhanced_notification_service.dart';

/// Automatically schedules and manages notifications for projects and payments.
/// Optimized for Tanzanian time conventions (Saa 2, Saa 6, Saa 10).
class NotificationScheduler {
  NotificationScheduler._();
  static final NotificationScheduler instance = NotificationScheduler._();

  final List<Timer> _timers = [];
  final _notificationService = EnhancedNotificationService.instance;

  // ─── CONFIGURATION ──────────────────────────────────────────────────────────

  // Tanzanian time to 24h mapping
  static const int _saa2Asubuhi = 8;
  static const int _saa6Mchana = 12;
  static const int _saa10Jioni = 16;
  static const int _saa2Usiku = 20;

  /// Start the notification scheduler
  void start() {
    // Stop any existing timers to avoid duplicates
    stop();

    // Run an immediate check on startup
    _checkAndScheduleNotifications();

    // Schedule periodic checks throughout the day
    _scheduleCheckAt(_saa2Asubuhi, 0, label: 'Morning Check (Saa 2 Asubuhi)');
    _scheduleCheckAt(_saa6Mchana, 0, label: 'Mid-day Check (Saa 6 Mchana)');
    _scheduleCheckAt(_saa10Jioni, 0, label: 'Evening Check (Saa 10 Jioni)');
    _scheduleCheckAt(_saa2Usiku, 0, label: 'Nightly Review (Saa 2 Usiku)');
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
        _checkPayments(user.uid),
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
        .collection('users')
        .doc(userId)
        .collection('projects')
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
      final startDateTimestamp = data['startDate'] as Timestamp?;
      if (startDateTimestamp != null) {
        final startDate = startDateTimestamp.toDate();
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
      final deadlineTimestamp = data['deadline'] as Timestamp?;
      if (deadlineTimestamp != null) {
        final deadline = deadlineTimestamp.toDate();
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

  /// Inspect milestones for pending or overdue payments
  Future<void> _checkPayments(String userId) async {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    final projectsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('projects')
        .get();

    for (var projectDoc in projectsSnapshot.docs) {
      final projectName = projectDoc.data()['name'] as String? ?? 'Unnamed Project';

      final milestonesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('projects')
          .doc(projectDoc.id)
          .collection('milestones')
          .where('paymentStatus', whereIn: [PaymentStatus.unpaid.name, PaymentStatus.partial.name])
          .get();

      for (var milestoneDoc in milestonesSnapshot.docs) {
        final data = milestoneDoc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        final dueDateTimestamp = data['dueDate'] as Timestamp?;

        if (dueDateTimestamp != null && amount > 0) {
          final dueDate = dueDateTimestamp.toDate();
          final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
          final daysDiff = dueDateOnly.difference(today).inDays;

          if (daysDiff < 0) {
            // Payment overdue
            await _notificationService.notifyPaymentOverdue(
              projectName: projectName,
              amount: amount,
              daysOverdue: -daysDiff,
              id: milestoneDoc.id.hashCode,
            );
          } else if (daysDiff >= 0 && daysDiff <= 3) {
            // Payment approaching
            await _notificationService.notifyPaymentDue(
              projectName: projectName,
              amount: amount,
              dueDate: dueDate,
              id: milestoneDoc.id.hashCode + 400,
            );
          }
        }
      }
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
