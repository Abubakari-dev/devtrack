import '../common/model_utils.dart';

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
