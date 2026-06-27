import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/notification_service.dart';
import '../../projects/models/models.dart';
import '../widgets/notification_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Stream<List<AppNotification>> _getNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AppNotification(
          id: doc.id,
          title: data['title'] ?? '',
          body: data['body'] ?? '',
          type: NotifType.values.firstWhere(
            (e) => e.name == (data['type'] ?? 'upcoming'),
            orElse: () => NotifType.upcoming,
          ),
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isRead: data['isRead'] ?? false,
          projectId: data['projectId'], // Ensure project ID is mapped
        );
      }).toList();
    });
  }

  void _onNotificationTap(AppNotification notification) {
    // 1. Mark as read in Firestore
    AppNotificationService.instance.markAsRead(notification.id);
    
    // 2. Handle Deep Linking if projectId exists
    if (notification.projectId != null && notification.projectId!.isNotEmpty) {
      Navigator.pushNamed(
        context, 
        '/project-detail', 
        arguments: notification.projectId
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded, 
            color: isDark ? Colors.white : AppColors.textPrimary, 
            size: 20
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications', 
          style: AppTextStyles.titleLarge.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          StreamBuilder<List<AppNotification>>(
            stream: _getNotifications(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data?.where((n) => !n.isRead).length ?? 0;
              if (unreadCount == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => AppNotificationService.instance.markAllAsRead(),
                child: const Text(
                  'Mark All Read',
                  style: TextStyle(
                    color: AppColors.indigo, 
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: _getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.indigo));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return _buildEmptyState(isDark);
          }

          // Group notifications by date
          final today = <AppNotification>[];
          final yesterday = <AppNotification>[];
          final older = <AppNotification>[];
          
          final now = DateTime.now();
          for (final n in notifications) {
            final diff = now.difference(n.timestamp).inDays;
            if (diff == 0) {
              today.add(n);
            } else if (diff == 1) {
              yesterday.add(n);
            } else {
              older.add(n);
            }
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
            physics: const BouncingScrollPhysics(),
            children: [
              if (today.isNotEmpty) ...[
                _buildSectionHeader('Today', isDark),
                const SizedBox(height: 12),
                ...today.map((n) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: NotificationCard(
                    notification: n,
                    onTap: () => _onNotificationTap(n),
                    onDismiss: () => FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .collection('notifications')
                        .doc(n.id)
                        .delete(),
                  ),
                )),
                const SizedBox(height: 12),
              ],
              if (yesterday.isNotEmpty) ...[
                _buildSectionHeader('Yesterday', isDark),
                const SizedBox(height: 12),
                ...yesterday.map((n) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: NotificationCard(
                    notification: n,
                    onTap: () => _onNotificationTap(n),
                    onDismiss: () => FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .collection('notifications')
                        .doc(n.id)
                        .delete(),
                  ),
                )),
                const SizedBox(height: 12),
              ],
              if (older.isNotEmpty) ...[
                _buildSectionHeader('Earlier', isDark),
                const SizedBox(height: 12),
                ...older.map((n) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: NotificationCard(
                    notification: n,
                    onTap: () => _onNotificationTap(n),
                    onDismiss: () => FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .collection('notifications')
                        .doc(n.id)
                        .delete(),
                  ),
                )),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: isDark ? Colors.white38 : AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded, 
              size: 64, 
              color: isDark ? Colors.white12 : AppColors.textMuted.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'All caught up!', 
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No new notifications at the moment.',
            style: TextStyle(
              color: isDark ? Colors.white38 : AppColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
