import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/auth_service.dart';
import '../../projects/models/project_model.dart';
import '../models/savings_goal_model.dart';

class FinanceRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  String? get _uid => _authService.currentUser?.uid;
  String? get currentUserId => _uid;

  // Root collections
  CollectionReference get _paymentsCollection => _db.collection('payments');
  CollectionReference get _expensesCollection => _db.collection('expenses');
  CollectionReference get _savingsCollection => _db.collection('savings');
  CollectionReference get _savingsGoalsCollection => _db.collection('savingsGoals');

  // ── PAYMENT OPERATIONS ──────────────────────────────────────────────────────
  Future<void> recordPayment(Payment payment) async {
    if (_uid == null) throw Exception('User not authenticated');

    await _paymentsCollection.doc(payment.id).set({
      'userId': _uid,
      'projectId': payment.projectId,
      'label': payment.label,
      'amount': payment.amount,
      'date': payment.date.toIso8601String(),
      'isReceived': payment.isReceived,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePayment(Payment payment) async {
    if (_uid == null) throw Exception('User not authenticated');

    await _paymentsCollection.doc(payment.id).update({
      'userId': _uid,
      'projectId': payment.projectId,
      'label': payment.label,
      'amount': payment.amount,
      'date': payment.date.toIso8601String(),
      'isReceived': payment.isReceived,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePayment(String paymentId) async {
    if (_uid == null) throw Exception('User not authenticated');
    await _paymentsCollection.doc(paymentId).delete();
  }

  Stream<List<Payment>> getPaymentsForProject(String projectId) {
    if (_uid == null) return Stream.value([]);

    return _paymentsCollection
        .where('userId', isEqualTo: _uid)
        .where('projectId', isEqualTo: projectId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Payment(
          id: doc.id,
          projectId: data['projectId'] ?? '',
          label: data['label'] ?? '',
          amount: (data['amount'] as num?)?.toDouble() ?? 0,
          date: DateTime.parse(data['date'] ?? DateTime.now().toIso8601String()),
          isReceived: data['isReceived'] ?? false,
        );
      }).toList();
    });
  }

  Stream<List<Payment>> getAllPayments() {
    if (_uid == null) return Stream.value([]);

    return _paymentsCollection
        .where('userId', isEqualTo: _uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Payment(
          id: doc.id,
          projectId: data['projectId'] ?? '',
          label: data['label'] ?? '',
          amount: (data['amount'] as num?)?.toDouble() ?? 0,
          date: DateTime.parse(data['date'] ?? DateTime.now().toIso8601String()),
          isReceived: data['isReceived'] ?? false,
        );
      }).toList();
    });
  }

  // ── EXPENSE OPERATIONS ──────────────────────────────────────────────────────
  Future<void> recordExpense(Expense expense) async {
    if (_uid == null) throw Exception('User not authenticated');

    await _expensesCollection.doc(expense.id).set({
      'userId': _uid,
      'projectId': expense.projectId,
      'name': expense.name,
      'amount': expense.amount,
      'date': expense.date.toIso8601String(),
      'category': expense.category,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateExpense(Expense expense) async {
    if (_uid == null) throw Exception('User not authenticated');

    await _expensesCollection.doc(expense.id).update({
      'userId': _uid,
      'projectId': expense.projectId,
      'name': expense.name,
      'amount': expense.amount,
      'date': expense.date.toIso8601String(),
      'category': expense.category,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteExpense(String expenseId) async {
    if (_uid == null) throw Exception('User not authenticated');
    await _expensesCollection.doc(expenseId).delete();
  }

  Stream<List<Expense>> getExpensesForProject(String projectId) {
    if (_uid == null) return Stream.value([]);

    return _expensesCollection
        .where('userId', isEqualTo: _uid)
        .where('projectId', isEqualTo: projectId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Expense(
          id: doc.id,
          projectId: data['projectId'] ?? '',
          name: data['name'] ?? '',
          amount: (data['amount'] as num?)?.toDouble() ?? 0,
          date: DateTime.parse(data['date'] ?? DateTime.now().toIso8601String()),
          category: data['category'] ?? '',
        );
      }).toList();
    });
  }

  Stream<List<Expense>> getAllExpenses() {
    if (_uid == null) return Stream.value([]);

    return _expensesCollection
        .where('userId', isEqualTo: _uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Expense(
          id: doc.id,
          projectId: data['projectId'] ?? '',
          name: data['name'] ?? '',
          amount: (data['amount'] as num?)?.toDouble() ?? 0,
          date: DateTime.parse(data['date'] ?? DateTime.now().toIso8601String()),
          category: data['category'] ?? '',
        );
      }).toList();
    });
  }

  // ── SAVINGS OPERATIONS ──────────────────────────────────────────────────────
  Future<void> recordSavings(SavingsRecord savings) async {
    if (_uid == null) throw Exception('User not authenticated');

    await _savingsCollection.doc(savings.id).set({
      'userId': _uid,
      'projectId': savings.projectId,
      'amount': savings.amount,
      'date': savings.date.toIso8601String(),
      'accountName': savings.accountName,
      'notes': savings.notes,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateSavings(SavingsRecord savings) async {
    if (_uid == null) throw Exception('User not authenticated');

    await _savingsCollection.doc(savings.id).update({
      'userId': _uid,
      'projectId': savings.projectId,
      'amount': savings.amount,
      'date': savings.date.toIso8601String(),
      'accountName': savings.accountName,
      'notes': savings.notes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteSavings(String savingsId) async {
    if (_uid == null) throw Exception('User not authenticated');
    await _savingsCollection.doc(savingsId).delete();
  }

  Stream<List<SavingsRecord>> getSavingsForProject(String projectId) {
    if (_uid == null) return Stream.value([]);

    return _savingsCollection
        .where('userId', isEqualTo: _uid)
        .where('projectId', isEqualTo: projectId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return SavingsRecord.fromMap({...data, 'id': doc.id});
      }).toList()..sort((a, b) => b.date.compareTo(a.date));
    });
  }

  Stream<List<SavingsRecord>> getAllSavings() {
    if (_uid == null) return Stream.value([]);

    // Using Filter.or to handle both correct key 'userId' and typo 'serId'
    // This satisfies security rules while avoiding naked queries.
    return _savingsCollection
        .where(Filter.or(
          Filter('userId', isEqualTo: _uid),
          Filter('serId', isEqualTo: _uid),
        ))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return SavingsRecord.fromMap({...data, 'id': doc.id});
      }).toList()..sort((a, b) => b.date.compareTo(a.date));
    });
  }

  // ── SAVINGS GOAL OPERATIONS ─────────────────────────────────────────────────
  Future<void> setSavingsGoal(SavingsGoal goal) async {
    if (_uid == null) throw Exception('User not authenticated');

    await _savingsGoalsCollection.doc(_uid).set({
      'id': _uid,
      'userId': _uid,
      'monthlyGoal': goal.monthlyGoal,
      'semiAnnualGoal': goal.semiAnnualGoal,
      'annualGoal': goal.annualGoal,
      'createdAt': goal.createdAt.toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<SavingsGoal?> getSavingsGoal() {
    if (_uid == null) return Stream.value(null);

    return _savingsGoalsCollection
        .doc(_uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      final data = snapshot.data() as Map<String, dynamic>;
      return SavingsGoal.fromMap(data);
    });
  }

  Future<SavingsGoal?> getSavingsGoalOnce() async {
    if (_uid == null) return null;

    final doc = await _savingsGoalsCollection.doc(_uid).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    return SavingsGoal.fromMap(data);
  }
}
