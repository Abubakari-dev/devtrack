import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/failures.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

// ── ENUMS ───────────────────────────────────────────────────────────────────
enum ProjectCategory { mobile, website, desktop, other }
enum ProjectStatus { planned, active, onHold, completed, overdue }
enum TaskPriority { high, medium, low, critical }
enum TaskStatus { todo, inProgress, done }
enum MemberRole { owner, admin, editor, viewer }
enum AttachmentType { file, image, link }
enum NotifType { risk, overdue, payment, completed, upcoming }
enum PaymentStatus { unpaid, partial, paid }

// ── UTILS ────────────────────────────────────────────────────────────────────
class ModelUtils {
  static double toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static DateTime toDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}

// ── PROJECT MEMBER MODEL ─────────────────────────────────────────────────────
class ProjectMember {
  final String uid;
  final String email;
  final MemberRole role;
  final DateTime joinedAt;

  const ProjectMember({
    required this.uid,
    required this.email,
    required this.role,
    required this.joinedAt,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'role': role.name,
    'joinedAt': joinedAt.toIso8601String(),
  };

  factory ProjectMember.fromMap(Map<String, dynamic> map) => ProjectMember(
    uid: map['uid'] ?? '',
    email: map['email'] ?? '',
    role: MemberRole.values.firstWhere((e) => e.name == map['role'], orElse: () => MemberRole.viewer),
    joinedAt: ModelUtils.toDateTime(map['joinedAt']),
  );
}

// ── PROJECT MODEL ────────────────────────────────────────────────────────────
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
  });

  bool canEdit(String uid) {
    if (uid == ownerId) return true;
    final member = members.firstWhere((m) => m.uid == uid, orElse: () => ProjectMember(uid: '', email: '', role: MemberRole.viewer, joinedAt: DateTime.now()));
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
      totalTasks: map['totalTasks'] ?? 0,
      completedTasks: map['completedTasks'] ?? 0,
      savingsPercentage: ModelUtils.toDouble(map['savingsPercentage']),
      createdAt: ModelUtils.toDateTime(map['createdAt']),
    );
  }

  int get totalTasksCount => phases.fold(0, (sum, phase) => sum + phase.tasks.length);
  int get completedTasksCount => phases.fold(0, (sum, phase) => sum + phase.tasks.where((t) => t.status == TaskStatus.done).length);

  double get progressPercent {
    if (phases.isEmpty) return progress;
    // Calculate average progress across all phases
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

  String get categoryLabel {
    switch (category) {
      case ProjectCategory.mobile: return '📱 Mobile';
      case ProjectCategory.website: return '🌐 Website';
      case ProjectCategory.desktop: return '💻 Desktop';
      case ProjectCategory.other: return '🔧 Other';
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

// ── PHASE MODEL ──────────────────────────────────────────────────────────────
class Phase {
  final String id;
  final String projectId;
  final String name;
  final String? description;
  final double price;
  final DateTime startDate;
  final DateTime endDate;
  final List<ProjectTask> tasks;
  final List<ProjectAttachment> attachments;
  final int orderIndex;
  final TaskStatus status;

  const Phase({
    required this.id,
    required this.projectId,
    required this.name,
    this.description,
    this.price = 0,
    required this.startDate,
    required this.endDate,
    this.tasks = const [],
    this.attachments = const [],
    required this.orderIndex,
    this.status = TaskStatus.todo,
  });

  Phase copyWith({
    String? id,
    String? projectId,
    String? name,
    String? description,
    double? price,
    DateTime? startDate,
    DateTime? endDate,
    List<ProjectTask>? tasks,
    List<ProjectAttachment>? attachments,
    int? orderIndex,
    TaskStatus? status,
  }) {
    return Phase(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      tasks: tasks ?? this.tasks,
      attachments: attachments ?? this.attachments,
      orderIndex: orderIndex ?? this.orderIndex,
      status: status ?? this.status,
    );
  }

  double get totalPhasePrice => price + tasks.fold(0.0, (sum, item) => sum + item.price);

  Map<String, dynamic> toMap() => {
    'id': id,
    'projectId': projectId,
    'name': name,
    'description': description,
    'price': price,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'orderIndex': orderIndex,
    'status': status.name,
    'attachments': attachments.map((x) => x.toMap()).toList(),
    'tasks': tasks.map((t) => t.toMap()).toList(),
  };

  factory Phase.fromMap(Map<String, dynamic> map, {List<ProjectTask>? tasks}) => Phase(
    id: map['id'] ?? '',
    projectId: map['projectId'] ?? '',
    name: map['name'] ?? '',
    description: map['description'],
    price: ModelUtils.toDouble(map['price']),
    startDate: ModelUtils.toDateTime(map['startDate']),
    endDate: ModelUtils.toDateTime(map['endDate']),
    orderIndex: map['orderIndex'] ?? 0,
    status: TaskStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => TaskStatus.todo),
    tasks: tasks ?? (map['tasks'] as List?)?.map((t) => ProjectTask.fromMap(Map<String, dynamic>.from(t))).toList() ?? [],
    attachments: (map['attachments'] as List?)?.map((x) => ProjectAttachment.fromMap(Map<String, dynamic>.from(x))).toList() ?? [],
  );

  double get progressPercent {
    if (status == TaskStatus.done) return 1.0;
    if (tasks.isEmpty) return status == TaskStatus.inProgress ? 0.5 : 0.0;
    // Calculate average progress across all tasks in this phase
    return tasks.fold(0.0, (sum, task) => sum + task.progressPercent) / tasks.length;
  }

  bool get isCompleted => status == TaskStatus.done || progressPercent >= 1.0;
}

// ── TASK MODEL ───────────────────────────────────────────────────────────────
class ProjectTask {
  final String id;
  final String phaseId;
  final String name;
  final String? description;
  final TaskPriority priority;
  final TaskStatus status;
  final double customProgress;
  final DateTime startDate;
  final DateTime endDate;
  final double price;
  final List<Subtask> subtasks;

  const ProjectTask({
    required this.id,
    required this.phaseId,
    required this.name,
    this.description,
    required this.priority,
    this.status = TaskStatus.todo,
    this.customProgress = 0,
    required this.startDate,
    required this.endDate,
    this.price = 0,
    this.subtasks = const [],
  });

  ProjectTask copyWith({
    String? id,
    String? phaseId,
    String? name,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    double? customProgress,
    DateTime? startDate,
    DateTime? endDate,
    double? price,
    List<Subtask>? subtasks,
  }) {
    return ProjectTask(
      id: id ?? this.id,
      phaseId: phaseId ?? this.phaseId,
      name: name ?? this.name,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      customProgress: customProgress ?? this.customProgress,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      price: price ?? this.price,
      subtasks: subtasks ?? this.subtasks,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'phaseId': phaseId,
    'name': name,
    'description': description,
    'priority': priority.name,
    'status': status.name,
    'customProgress': customProgress,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'price': price,
    'subtasks': subtasks.map((s) => s.toMap()).toList(),
  };

  factory ProjectTask.fromMap(Map<String, dynamic> map, {List<Subtask>? subtasks}) => ProjectTask(
    id: map['id'] ?? '',
    phaseId: map['phaseId'] ?? '',
    name: map['name'] ?? '',
    description: map['description'],
    priority: TaskPriority.values.firstWhere((e) => e.name == map['priority'], orElse: () => TaskPriority.medium),
    status: TaskStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => TaskStatus.todo),
    customProgress: ModelUtils.toDouble(map['customProgress']),
    startDate: ModelUtils.toDateTime(map['startDate']),
    endDate: ModelUtils.toDateTime(map['endDate']),
    price: ModelUtils.toDouble(map['price']),
    subtasks: subtasks ?? (map['subtasks'] as List?)?.map((s) => Subtask.fromMap(Map<String, dynamic>.from(s))).toList() ?? [],
  );

  double get progressPercent {
    if (status == TaskStatus.done) return 1.0;
    if (subtasks.isNotEmpty) return subtasks.where((s) => s.isDone).length / subtasks.length;
    return status == TaskStatus.inProgress ? 0.5 : 0.0;
  }
}

// ── SUBTASK MODEL ────────────────────────────────────────────────────────────
class Subtask {
  final String id;
  final String taskId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool isDone;
  final DateTime? reminderDate;

  const Subtask({
    required this.id,
    required this.taskId,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.isDone = false,
    this.reminderDate,
  });

  Subtask copyWith({
    String? id,
    String? taskId,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    bool? isDone,
    DateTime? reminderDate,
  }) {
    return Subtask(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isDone: isDone ?? this.isDone,
      reminderDate: reminderDate ?? this.reminderDate,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'taskId': taskId,
    'name': name,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'isDone': isDone,
    'reminderDate': reminderDate?.toIso8601String(),
  };

  factory Subtask.fromMap(Map<String, dynamic> map) => Subtask(
    id: map['id'] ?? '',
    taskId: map['taskId'] ?? '',
    name: map['name'] ?? '',
    startDate: ModelUtils.toDateTime(map['startDate']),
    endDate: ModelUtils.toDateTime(map['endDate']),
    isDone: map['isDone'] ?? false,
    reminderDate: map['reminderDate'] != null ? ModelUtils.toDateTime(map['reminderDate']) : null,
  );
}

// ── CLIENT MODEL ─────────────────────────────────────────────────────────────
class Client {
  final String id;
  final String name;
  final String company;
  final String email;
  final String phone;
  final String location;
  final int projectCount;
  final int completedCount;

  const Client({
    required this.id,
    required this.name,
    required this.company,
    required this.email,
    required this.phone,
    required this.location,
    this.projectCount = 0,
    this.completedCount = 0,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name.substring(0, name.length > 1 ? 2 : 1).toUpperCase() : '??';
  }
}

// ── ATTACHMENT MODEL ──────────────────────────────────────────────────────────
class ProjectAttachment {
  final String id;
  final String name;
  final AttachmentType type;
  final String? path;
  final String? url;
  final DateTime addedAt;

  const ProjectAttachment({
    required this.id,
    required this.name,
    required this.type,
    this.path,
    this.url,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type.name,
    'path': path,
    'url': url,
    'addedAt': addedAt.toIso8601String(),
  };

  factory ProjectAttachment.fromMap(Map<String, dynamic> map) => ProjectAttachment(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    type: AttachmentType.values.firstWhere((e) => e.name == map['type'], orElse: () => AttachmentType.file),
    path: map['path'],
    url: map['url'],
    addedAt: ModelUtils.toDateTime(map['addedAt']),
  );
}

// ── PAYMENT & EXPENSE MODELS ────────────────────────────────────────────────
class Payment {
  final String id;
  final String projectId;
  final String label;
  final double amount;
  final DateTime date;
  final bool isReceived;

  const Payment({
    required this.id,
    required this.projectId,
    required this.label,
    required this.amount,
    required this.date,
    this.isReceived = true,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'projectId': projectId,
    'label': label,
    'amount': amount,
    'date': date.toIso8601String(),
    'isReceived': isReceived,
  };

  factory Payment.fromMap(Map<String, dynamic> map) => Payment(
    id: map['id'] ?? '',
    projectId: map['projectId'] ?? '',
    label: map['label'] ?? '',
    amount: ModelUtils.toDouble(map['amount']),
    date: ModelUtils.toDateTime(map['date']),
    isReceived: map['isReceived'] ?? true,
  );
}

class Expense {
  final String id;
  final String projectId;
  final String name;
  final double amount;
  final DateTime date;
  final String category;

  const Expense({
    required this.id,
    required this.projectId,
    required this.name,
    required this.amount,
    required this.date,
    required this.category,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'projectId': projectId,
    'name': name,
    'amount': amount,
    'date': date.toIso8601String(),
    'category': category,
  };

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
    id: map['id'] ?? '',
    projectId: map['projectId'] ?? '',
    name: map['name'] ?? '',
    amount: ModelUtils.toDouble(map['amount']),
    date: ModelUtils.toDateTime(map['date']),
    category: map['category'] ?? '',
  );
}

class SavingsRecord {
  final String id;
  final String projectId;
  final double amount;
  final DateTime date;
  final String accountName; 
  final String? notes;

  const SavingsRecord({
    required this.id,
    required this.projectId,
    required this.amount,
    required this.date,
    required this.accountName,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'projectId': projectId,
    'amount': amount,
    'date': date.toIso8601String(),
    'accountName': accountName,
    'notes': notes,
  };

  factory SavingsRecord.fromMap(Map<String, dynamic> map) {
    return SavingsRecord(
      id: map['id'] ?? '',
      projectId: map['projectId'] ?? '',
      amount: ModelUtils.toDouble(map['amount']),
      date: ModelUtils.toDateTime(map['date']),
      accountName: map['accountName'] ?? '',
      notes: map['notes'],
    );
  }
}

// ── NOTIFICATION MODEL ───────────────────────────────────────────────────────
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
