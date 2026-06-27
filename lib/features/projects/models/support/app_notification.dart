import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../common/project_enums.dart';
import '../common/model_utils.dart';

class AppNotification {
  final String id;
  final String? projectId;
  final String title;
  final String body;
  final NotifType type;
  final DateTime timestamp;
  final bool isRead;

  const AppNotification({
    required this.id,
    this.projectId,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'projectId': projectId,
    'title': title,
    'body': body,
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
  };

  factory AppNotification.fromMap(Map<String, dynamic> map) => AppNotification(
    id: map['id'] ?? '',
    projectId: map['projectId'],
    title: map['title'] ?? '',
    body: map['body'] ?? '',
    type: NotifType.values.firstWhere((e) => e.name == map['type'], orElse: () => NotifType.upcoming),
    timestamp: ModelUtils.toDateTime(map['timestamp']),
    isRead: map['isRead'] ?? false,
  );

  Color get color {
    switch (type) {
      case NotifType.risk: return AppColors.rose;
      case NotifType.overdue: return AppColors.amber;
      case NotifType.payment: return AppColors.indigo;
      case NotifType.completed: return AppColors.emerald;
      case NotifType.upcoming: return AppColors.blue;
    }
  }
}
