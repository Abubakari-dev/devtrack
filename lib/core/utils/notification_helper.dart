import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

/// Helper class for checking notification preferences before sending
class NotificationHelper {
  static final AppNotificationService _service = AppNotificationService.instance;

  /// Check if a specific notification category is enabled
  static Future<bool> isNotificationEnabled(String category) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notif_$category') ?? true;
  }

  /// Send project notification if enabled
  static Future<void> sendProjectNotification({
    required NotificationType type,
    required String title,
    required String body,
    String? payload,
    int? id,
  }) async {
    if (await isNotificationEnabled('projects')) {
      await _service.showNotification(
        type: type,
        title: title,
        body: body,
        payload: payload,
        id: id,
      );
    }
  }

  /// Send payment notification if enabled
  static Future<void> sendPaymentNotification({
    required NotificationType type,
    required String title,
    required String body,
    String? payload,
    int? id,
  }) async {
    if (await isNotificationEnabled('payments')) {
      await _service.showNotification(
        type: type,
        title: title,
        body: body,
        payload: payload,
        id: id,
      );
    }
  }

  /// Send task notification if enabled
  static Future<void> sendTaskNotification({
    required NotificationType type,
    required String title,
    required String body,
    String? payload,
    int? id,
  }) async {
    if (await isNotificationEnabled('tasks')) {
      await _service.showNotification(
        type: type,
        title: title,
        body: body,
        payload: payload,
        id: id,
      );
    }
  }

  /// Send budget notification if enabled
  static Future<void> sendBudgetNotification({
    required NotificationType type,
    required String title,
    required String body,
    String? payload,
    int? id,
  }) async {
    if (await isNotificationEnabled('budget')) {
      await _service.showNotification(
        type: type,
        title: title,
        body: body,
        payload: payload,
        id: id,
      );
    }
  }

  /// Send milestone notification if enabled
  static Future<void> sendMilestoneNotification({
    required NotificationType type,
    required String title,
    required String body,
    String? payload,
    int? id,
  }) async {
    if (await isNotificationEnabled('milestones')) {
      await _service.showNotification(
        type: type,
        title: title,
        body: body,
        payload: payload,
        id: id,
      );
    }
  }

  /// Send overdue notification (always enabled - critical)
  static Future<void> sendOverdueNotification({
    required NotificationType type,
    required String title,
    required String body,
    String? payload,
    int? id,
  }) async {
    // Overdue alerts are always sent regardless of settings
    await _service.showNotification(
      type: type,
      title: title,
      body: body,
      payload: payload,
      id: id,
    );
  }

  /// Send daily summary if enabled
  static Future<void> sendDailySummary({
    required int activeProjects,
    required int tasksCompleted,
    required int upcomingDeadlines,
  }) async {
    if (await isNotificationEnabled('daily_summary')) {
      await _service.notifyDailySummary(
        activeProjects: activeProjects,
        tasksCompleted: tasksCompleted,
        upcomingDeadlines: upcomingDeadlines,
      );
    }
  }

  /// Send success notification if enabled
  static Future<void> sendSuccessNotification({
    required NotificationType type,
    required String title,
    required String body,
    String? payload,
    int? id,
  }) async {
    if (await isNotificationEnabled('success')) {
      await _service.showNotification(
        type: type,
        title: title,
        body: body,
        payload: payload,
        id: id,
      );
    }
  }

  /// Get all notification preferences
  static Future<Map<String, bool>> getAllPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'projects': prefs.getBool('notif_projects') ?? true,
      'payments': prefs.getBool('notif_payments') ?? true,
      'tasks': prefs.getBool('notif_tasks') ?? true,
      'budget': prefs.getBool('notif_budget') ?? true,
      'milestones': prefs.getBool('notif_milestones') ?? true,
      'overdue': prefs.getBool('notif_overdue') ?? true,
      'daily_summary': prefs.getBool('notif_daily_summary') ?? true,
      'success': prefs.getBool('notif_success') ?? true,
    };
  }

  /// Reset all notification preferences to default (enabled)
  static Future<void> resetPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_projects', true);
    await prefs.setBool('notif_payments', true);
    await prefs.setBool('notif_tasks', true);
    await prefs.setBool('notif_budget', true);
    await prefs.setBool('notif_milestones', true);
    await prefs.setBool('notif_overdue', true);
    await prefs.setBool('notif_daily_summary', true);
    await prefs.setBool('notif_success', true);
  }
}
