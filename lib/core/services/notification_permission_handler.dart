import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles notification permissions for Android 13+ and iOS
class NotificationPermissionHandler {
  NotificationPermissionHandler._();
  static final NotificationPermissionHandler instance = NotificationPermissionHandler._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  /// Request notification permissions with user-friendly dialog
  Future<bool> requestPermissions({
    BuildContext? context,
    bool showRationale = true,
  }) async {
    // Check current permission status
    final currentStatus = await checkPermissionStatus();
    
    if (currentStatus == NotificationPermissionStatus.granted) {
      debugPrint('Notification permissions already granted');
      return true;
    }

    // Show rationale dialog if requested and context is available
    if (showRationale && context != null && context.mounted) {
      final shouldRequest = await _showPermissionRationale(context);
      if (!shouldRequest) {
        return false;
      }
    }

    // Request permissions based on platform
    if (Platform.isAndroid) {
      return await _requestAndroidPermissions();
    } else if (Platform.isIOS) {
      return await _requestIOSPermissions();
    }

    return false;
  }

  /// Request Android notification permissions (Android 13+)
  Future<bool> _requestAndroidPermissions() async {
    try {
      // 1. Request FCM permissions
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      // 2. Request Local Notification Permission (Critical for Android 13+)
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      final bool? grantedLocal = await androidPlugin?.requestNotificationsPermission();
      
      // 3. Request exact alarm permission for scheduled notifications
      final bool? exactAlarmPermission = await androidPlugin?.requestExactAlarmsPermission();
      
      debugPrint('Android Permissions: FCM=${settings.authorizationStatus}, Local=$grantedLocal, ExactAlarm=$exactAlarmPermission');

      return settings.authorizationStatus == AuthorizationStatus.authorized || (grantedLocal ?? false);
    } catch (e) {
      debugPrint('Error requesting Android permissions: $e');
      return false;
    }
  }

  /// Request iOS notification permissions
  Future<bool> _requestIOSPermissions() async {
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: true, // For critical alerts
        announcement: false,
      );

      final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
                     settings.authorizationStatus == AuthorizationStatus.provisional;

      if (granted) {
        debugPrint('iOS notification permissions granted');
      } else {
        debugPrint('iOS notification permissions denied');
      }

      return granted;
    } catch (e) {
      debugPrint('Error requesting iOS permissions: $e');
      return false;
    }
  }

  /// Check current notification permission status
  Future<NotificationPermissionStatus> checkPermissionStatus() async {
    try {
      final settings = await _fcm.getNotificationSettings();
      
      switch (settings.authorizationStatus) {
        case AuthorizationStatus.authorized:
        case AuthorizationStatus.provisional:
          return NotificationPermissionStatus.granted;
        case AuthorizationStatus.denied:
          return NotificationPermissionStatus.denied;
        case AuthorizationStatus.notDetermined:
          return NotificationPermissionStatus.notDetermined;
      }
    } catch (e) {
      debugPrint('Error checking permission status: $e');
      return NotificationPermissionStatus.notDetermined;
    }
  }

  /// Show permission rationale dialog
  Future<bool> _showPermissionRationale(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.notifications_active, color: Color(0xFF6366F1)),
            SizedBox(width: 12),
            Text('Enable Notifications'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stay on top of your projects with timely notifications:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16),
            _PermissionBenefit(
              icon: Icons.alarm,
              text: 'Project deadlines and reminders',
            ),
            SizedBox(height: 8),
            _PermissionBenefit(
              icon: Icons.payment,
              text: 'Payment due dates and alerts',
            ),
            SizedBox(height: 8),
            _PermissionBenefit(
              icon: Icons.task_alt,
              text: 'Task and milestone updates',
            ),
            SizedBox(height: 8),
            _PermissionBenefit(
              icon: Icons.account_balance_wallet,
              text: 'Budget warnings and savings reminders',
            ),
            SizedBox(height: 16),
            Text(
              'You can change this anytime in Settings.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            child: const Text('Enable'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Show settings dialog when permissions are permanently denied
  Future<void> showSettingsDialog(BuildContext context) async {
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Permission Required'),
        content: const Text(
          'Notifications are disabled. To receive important project updates, '
          'please enable notifications in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Note: Opening app settings requires additional package
              // like app_settings or permission_handler
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Request permission on app first launch
  Future<bool> requestOnFirstLaunch(BuildContext context) async {
    final status = await checkPermissionStatus();
    
    if (!context.mounted) return false;

    if (status == NotificationPermissionStatus.notDetermined) {
      return await requestPermissions(
        context: context,
        showRationale: true,
      );
    }
    
    return status == NotificationPermissionStatus.granted;
  }
}

/// Permission benefit widget for rationale dialog
class _PermissionBenefit extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PermissionBenefit({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF6366F1)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }
}

/// Notification permission status enum
enum NotificationPermissionStatus {
  granted,
  denied,
  notDetermined,
}
