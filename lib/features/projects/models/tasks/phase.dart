import '../common/project_enums.dart';
import '../common/model_utils.dart';
import '../common/attachment.dart';
import 'task.dart';

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
    return tasks.fold(0.0, (sum, task) => sum + task.progressPercent) / tasks.length;
  }

  bool get isCompleted => status == TaskStatus.done || progressPercent >= 1.0;
}
