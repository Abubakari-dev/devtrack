import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../projects/models/models.dart';

class NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.rose,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 24),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161B22) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: notification.isRead 
                ? (isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.5))
                : notification.color.withOpacity(0.3),
              width: notification.isRead ? 1 : 2,
            ),
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: notification.isRead 
                  ? Colors.black.withOpacity(0.02)
                  : notification.color.withOpacity(0.08),
                blurRadius: notification.isRead ? 8 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: notification.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: notification.color.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  _getIcon(notification.type),
                  color: notification.color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: notification.isRead 
                                ? (isDark ? Colors.white54 : AppColors.textSecondary)
                                : (isDark ? Colors.white : AppColors.textPrimary),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            margin: const EdgeInsets.only(left: 8, top: 2),
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: notification.color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: notification.color.withOpacity(0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.body,
                      style: TextStyle(
                        color: isDark ? Colors.white54 : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: isDark ? Colors.white24 : AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(notification.timestamp),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white24 : AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(NotifType type) {
    switch (type) {
      case NotifType.risk:
        return Icons.warning_amber_rounded;
      case NotifType.overdue:
        return Icons.timer_outlined;
      case NotifType.payment:
        return Icons.payments_outlined;
      case NotifType.completed:
        return Icons.check_circle_outline_rounded;
      case NotifType.upcoming:
        return Icons.event_note_rounded;
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}';
  }
}
