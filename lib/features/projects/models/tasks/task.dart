import '../common/project_enums.dart';
import '../common/model_utils.dart';
import 'subtask.dart';

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
