import '../common/model_utils.dart';

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
