import '../common/model_utils.dart';

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
