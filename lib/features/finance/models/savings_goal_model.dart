import 'package:cloud_firestore/cloud_firestore.dart';

class SavingsGoal {
  final String id;
  final String userId;
  final double monthlyGoal;
  final double semiAnnualGoal;
  final double annualGoal;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SavingsGoal({
    required this.id,
    required this.userId,
    required this.monthlyGoal,
    required this.semiAnnualGoal,
    required this.annualGoal,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'monthlyGoal': monthlyGoal,
      'semiAnnualGoal': semiAnnualGoal,
      'annualGoal': annualGoal,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SavingsGoal.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic d) {
      if (d == null) return DateTime.now();
      if (d is Timestamp) return d.toDate();
      if (d is String) return DateTime.tryParse(d) ?? DateTime.now();
      return DateTime.now();
    }

    // Be resilient to typos like userIduserId mentioned by user
    final actualUserId = map['userId'] ?? map['userIduserId'] ?? '';

    return SavingsGoal(
      id: map['id'] ?? '',
      userId: actualUserId,
      monthlyGoal: (map['monthlyGoal'] as num?)?.toDouble() ?? 0.0,
      semiAnnualGoal: (map['semiAnnualGoal'] as num?)?.toDouble() ?? 0.0,
      annualGoal: (map['annualGoal'] as num?)?.toDouble() ?? 0.0,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  SavingsGoal copyWith({
    String? id,
    String? userId,
    double? monthlyGoal,
    double? semiAnnualGoal,
    double? annualGoal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      monthlyGoal: monthlyGoal ?? this.monthlyGoal,
      semiAnnualGoal: semiAnnualGoal ?? this.semiAnnualGoal,
      annualGoal: annualGoal ?? this.annualGoal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
