import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../../main.dart';
import '../../features/projects/models/project_model.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  bool _initialized = false;
  
  static const String _tokenBoxName = 'notification_settings';
  static const String _lastTokenKey = 'last_fcm_token';

  // ─── NOTIFICATION CHANNELS ───────────────────────────────────────────────
  
  static const AndroidNotificationChannel _alertsChannel = AndroidNotificationChannel(
    'devtrack_high_importance_channel',
    'Critical Alerts',
    description: 'This channel is used for important project and payment alerts.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
    enableLights: true,
  );

  Future<void> init() async {
    if (_initialized) return;

    // 1. Initialize Local Timezones
    tz_data.initializeTimeZones();
    try {
      final dynamic timezoneResult = await FlutterTimezone.getLocalTimezone();
      String timeZoneName = timezoneResult is String ? timezoneResult : timezoneResult.name.toString();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('NotificationService: Timezone setup failed: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // 2. Android Channel Registration
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_alertsChannel);
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
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response.payload);
      },
    );

    // 4. Request Push Permissions
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // 5. Handle Messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showInstantNotification(
          id: message.hashCode,
          title: message.notification!.title ?? 'DevTrack',
          body: message.notification!.body ?? '',
          payload: message.data['projectId'], // Pass project ID if available
        );
      }
    });

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

  void _handleNotificationTap(String? payload) {
    if (payload != null && payload.isNotEmpty) {
      debugPrint('Notification tapped with payload: $payload');
      // Deep Link to project detail if payload is a project ID
      navigatorKey.currentState?.pushNamed('/project_detail', arguments: payload);
    } else {
      // Go to notification center if no specific project ID
      navigatorKey.currentState?.pushNamed('/notifications');
    }
  }

  // --- FCM TOKEN MANAGEMENT ---
  
  Future<void> _saveDeviceToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      String? token = await _fcm.getToken();
      if (token == null) return;

      // Check if token changed (Idempotent)
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
        debugPrint('NotificationService: New FCM Token saved');
      }
    } catch (e) {
      debugPrint('NotificationService: Error saving token: $e');
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
            showInstantNotification(
              id: change.doc.id.hashCode,
              title: data['title'] ?? 'DevTrack Alert',
              body: data['body'] ?? '',
              payload: data['projectId'] ?? change.doc.id,
            );
          }
        }
      }
    });
  }

  // ─── ACTIONS ──────────────────────────────────────────────────────────────

  Future<void> markAllAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final batch = FirebaseFirestore.instance.batch();
    final notifications = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in notifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  Future<void> markAsRead(String notificationId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  // ─── INSTANT NOTIFICATION ──────────────────────────────────────────────────

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _alertsChannel.id,
        _alertsChannel.name,
        channelDescription: _alertsChannel.description,
        importance: _alertsChannel.importance,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(body),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true, 
        presentBadge: true, 
        presentSound: true,
      ),
    );

    await _plugin.show(id, title, body, details, payload: payload);
  }

  // ─── SCHEDULING & CLOUD SYNC ───────────────────────────────────────────────

  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String? payload,
  }) async {
    if (when.isBefore(DateTime.now())) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'devtrack_reminders',
        'Reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(presentSound: true),
    );

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(when, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      debugPrint('NotificationService: Failed to schedule: $e');
    }
  }

  Future<void> sendNotificationToCloud({
    required String title,
    required String body,
    required NotifType type,
    String? projectId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .add({
      'title': title,
      'body': body,
      'type': type.name,
      'projectId': projectId,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  Future<void> cancel(int id) async => await _plugin.cancel(id);
  Future<void> cancelAll() async => await _plugin.cancelAll();
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (message.notification != null) {
    await NotificationService.instance.showInstantNotification(
      id: message.hashCode,
      title: message.notification!.title ?? 'DevTrack',
      body: message.notification!.body ?? '',
      payload: message.data['projectId'],
    );
  }
}
