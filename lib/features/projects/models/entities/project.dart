import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/failures.dart';
import '../common/project_enums.dart';
import '../common/model_utils.dart';
import '../common/attachment.dart';
import '../tasks/phase.dart';
import '../tasks/task.dart';
import 'project_member.dart';

class Project {
  final String id;
  final String name;
  final String? ownerId;
  final List<ProjectMember> members;
  final ProjectCategory category;
  final ProjectStatus status;
  final double totalPrice;
  final double advanceAmount;
  final DateTime startDate;
  final DateTime endDate;
  final List<Phase> phases;
  final bool isPinned;
  final List<String> tags;
  final String? description;
  final TaskPriority priority;
  final PaymentStatus paymentStatus;
  final List<ProjectAttachment> attachments;
  final bool deadlineReminder;
  final bool dailyProgressReminder;
  final String projectEmoji;
  final Color projectColor;
  final double progress;
  final int totalTasks;
  final int completedTasks;
  final double savingsPercentage;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Project({
    required this.id,
    required this.name,
    this.ownerId,
    this.members = const [],
    required this.category,
    required this.status,
    required this.totalPrice,
    required this.advanceAmount,
    required this.startDate,
    required this.endDate,
    this.phases = const [],
    this.isPinned = false,
    this.tags = const [],
    this.description,
    this.priority = TaskPriority.medium,
    this.paymentStatus = PaymentStatus.unpaid,
    this.attachments = const [],
    this.deadlineReminder = true,
    this.dailyProgressReminder = false,
    this.projectEmoji = '🚀',
    this.projectColor = AppColors.blue,
    this.progress = 0,
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.savingsPercentage = 10.0,
    required this.createdAt,
    this.updatedAt,
  });

  bool canEdit(String uid) {
    if (uid == ownerId) return true;
    final member = members.firstWhere(
      (m) => m.uid == uid,
      orElse: () => ProjectMember(uid: '', email: '', role: MemberRole.viewer, joinedAt: DateTime.now()),
    );
    return member.role == MemberRole.admin || member.role == MemberRole.editor;
  }

  void validate() {
    if (name.trim().isEmpty) throw const ValidationFailure('Project name cannot be empty.');
    if (endDate.isBefore(startDate)) throw const ValidationFailure('End date cannot be before start date.');
    if (totalPrice < 0) throw const ValidationFailure('Total price cannot be negative.');
  }

  Project copyWith({
    String? id,
    String? name,
    String? ownerId,
    List<ProjectMember>? members,
    ProjectCategory? category,
    ProjectStatus? status,
    double? totalPrice,
    double? advanceAmount,
    DateTime? startDate,
    DateTime? endDate,
    List<Phase>? phases,
    bool? isPinned,
    List<String>? tags,
    String? description,
    TaskPriority? priority,
    PaymentStatus? paymentStatus,
    List<ProjectAttachment>? attachments,
    bool? deadlineReminder,
    bool? dailyProgressReminder,
    String? projectEmoji,
    Color? projectColor,
    double? progress,
    int? totalTasks,
    int? completedTasks,
    double? savingsPercentage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      members: members ?? this.members,
      category: category ?? this.category,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
      advanceAmount: advanceAmount ?? this.advanceAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      phases: phases ?? this.phases,
      isPinned: isPinned ?? this.isPinned,
      tags: tags ?? this.tags,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      attachments: attachments ?? this.attachments,
      deadlineReminder: deadlineReminder ?? this.deadlineReminder,
      dailyProgressReminder: dailyProgressReminder ?? this.dailyProgressReminder,
      projectEmoji: projectEmoji ?? this.projectEmoji,
      projectColor: projectColor ?? this.projectColor,
      progress: progress ?? this.progress,
      totalTasks: totalTasks ?? this.totalTasks,
      completedTasks: completedTasks ?? this.completedTasks,
      savingsPercentage: savingsPercentage ?? this.savingsPercentage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ownerId': ownerId,
      'memberIds': members.map((m) => m.uid).toList(),
      'members': members.map((m) => m.toMap()).toList(),
      'category': category.name,
      'status': status.name,
      'totalPrice': totalPrice,
      'advanceAmount': advanceAmount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isPinned': isPinned,
      'tags': tags,
      'description': description,
      'priority': priority.name,
      'paymentStatus': paymentStatus.name,
      'deadlineReminder': deadlineReminder,
      'dailyProgressReminder': dailyProgressReminder,
      'projectEmoji': projectEmoji,
      'projectColor': projectColor.toARGB32(),
      'progress': progressPercent,
      'totalTasks': totalTasksCount,
      'completedTasks': completedTasksCount,
      'savingsPercentage': savingsPercentage,
      'attachments': attachments.map((x) => x.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String() ?? FieldValue.serverTimestamp(),
      'phases': phases.map((p) => p.toMap()).toList(),
    };
  }

  factory Project.fromMap(Map<String, dynamic> map, {List<Phase>? phases}) {
    return Project(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      ownerId: map['ownerId'],
      members: (map['members'] as List?)?.map((m) => ProjectMember.fromMap(Map<String, dynamic>.from(m))).toList() ?? [],
      category: ProjectCategory.values.firstWhere((e) => e.name == map['category'], orElse: () => ProjectCategory.other),
      status: ProjectStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => ProjectStatus.active),
      totalPrice: ModelUtils.toDouble(map['totalPrice']),
      advanceAmount: ModelUtils.toDouble(map['advanceAmount']),
      startDate: ModelUtils.toDateTime(map['startDate']),
      endDate: ModelUtils.toDateTime(map['endDate']),
      phases: phases ?? (map['phases'] as List?)?.map((p) => Phase.fromMap(Map<String, dynamic>.from(p))).toList() ?? [],
      isPinned: map['isPinned'] ?? false,
      tags: List<String>.from(map['tags'] ?? []),
      description: map['description'],
      priority: TaskPriority.values.firstWhere((e) => e.name == map['priority'], orElse: () => TaskPriority.medium),
      paymentStatus: PaymentStatus.values.firstWhere((e) => e.name == map['paymentStatus'], orElse: () => PaymentStatus.unpaid),
      attachments: (map['attachments'] as List?)?.map((x) => ProjectAttachment.fromMap(Map<String, dynamic>.from(x))).toList() ?? [],
      deadlineReminder: map['deadlineReminder'] ?? true,
      dailyProgressReminder: map['dailyProgressReminder'] ?? false,
      projectEmoji: map['projectEmoji'] ?? '🚀',
      projectColor: Color(map['projectColor'] ?? 0xFF0969DA),
      progress: ModelUtils.toDouble(map['progress']),
      totalTasks: ModelUtils.farmInt(map['totalTasks']),
      completedTasks: ModelUtils.farmInt(map['completedTasks']),
      savingsPercentage: ModelUtils.toDouble(map['savingsPercentage']),
      createdAt: ModelUtils.toDateTime(map['createdAt']),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] is Timestamp 
              ? (map['updatedAt'] as Timestamp).toDate() 
              : ModelUtils.toDateTime(map['updatedAt']))
          : null,
    );
  }

  int get totalTasksCount => phases.fold(0, (sum, phase) => sum + phase.tasks.length);
  
  int get completedTasksCount => phases.fold(0, (sum, phase) => 
    sum + phase.tasks.where((t) => t.status == TaskStatus.done).length);

  int get totalPhasesCount => phases.length;
  int get completedPhasesCount => phases.where((p) => p.status == TaskStatus.done).length;

  int get displayTotalTasks => phases.isNotEmpty ? totalPhasesCount : totalTasks;
  int get displayCompletedTasks => phases.isNotEmpty ? completedPhasesCount : completedTasks;

  double get progressPercent {
    if (phases.isEmpty) return progress;
    return phases.fold(0.0, (sum, phase) => sum + phase.progressPercent) / phases.length;
  }

  double calculateTotalPriceFromTasks() {
    double total = 0;
    for (var phase in phases) {
      total += phase.price;
      for (var task in phase.tasks) {
        total += task.price;
      }
    }
    return total;
  }

  double get remainingAmount => totalPrice - advanceAmount;
  int get daysRemaining => endDate.difference(DateTime.now()).inDays;

  Color get categoryColor {
    switch (category) {
      case ProjectCategory.mobile: return AppColors.indigo;
      case ProjectCategory.website: return AppColors.amber;
      case ProjectCategory.desktop: return AppColors.emerald;
      case ProjectCategory.other: return AppColors.blue;
    }
  }

  Color get statusColor {
    switch (status) {
      case ProjectStatus.planned: return AppColors.blue;
      case ProjectStatus.active: return AppColors.emerald;
      case ProjectStatus.onHold: return AppColors.amber;
      case ProjectStatus.completed: return AppColors.indigo;
      case ProjectStatus.overdue: return AppColors.rose;
    }
  }

  String getCategoryLabel(BuildContext context) {
    switch (category) {
      case ProjectCategory.mobile: return '📱 ${context.tr('cat_mobile')}';
      case ProjectCategory.website: return '🌐 ${context.tr('cat_website')}';
      case ProjectCategory.desktop: return '💻 ${context.tr('cat_desktop')}';
      case ProjectCategory.other: return '🔧 ${context.tr('cat_other')}';
    }
  }

  String getStatusLabel(BuildContext context) {
    switch (status) {
      case ProjectStatus.planned: return context.tr('status_planned');
      case ProjectStatus.active: return context.tr('status_active');
      case ProjectStatus.onHold: return context.tr('status_on_hold');
      case ProjectStatus.completed: return context.tr('status_completed');
      case ProjectStatus.overdue: return context.tr('status_overdue');
    }
  }

  String get categoryLabel {
    switch (category) {
      case ProjectCategory.mobile: return '📱 Mobile';
      case ProjectCategory.website: return '🌐 Website';
      case ProjectCategory.desktop: return '💻 Desktop';
      case ProjectCategory.other: return '🔧 Other';
    }
  }

  String get statusLabel {
    switch (status) {
      case ProjectStatus.planned: return 'Planned';
      case ProjectStatus.active: return 'Active';
      case ProjectStatus.onHold: return 'On Hold';
      case ProjectStatus.completed: return 'Completed';
      case ProjectStatus.overdue: return 'Overdue';
    }
  }
}
