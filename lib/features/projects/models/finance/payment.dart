import '../common/model_utils.dart';

class Payment {
  final String id;
  final String projectId;
  final String label;
  final double amount;
  final DateTime date;
  final bool isReceived;
  final String? walletId;

  const Payment({
    required this.id,
    required this.projectId,
    required this.label,
    required this.amount,
    required this.date,
    this.isReceived = true,
    this.walletId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'projectId': projectId,
    'label': label,
    'amount': amount,
    'date': date.toIso8601String(),
    'isReceived': isReceived,
    'walletId': walletId,
  };

  factory Payment.fromMap(Map<String, dynamic> map) => Payment(
    id: map['id'] ?? '',
    projectId: map['projectId'] ?? '',
    label: map['label'] ?? '',
    amount: ModelUtils.toDouble(map['amount']),
    date: ModelUtils.toDateTime(map['date']),
    isReceived: map['isReceived'] ?? true,
    walletId: map['walletId'],
  );
}
