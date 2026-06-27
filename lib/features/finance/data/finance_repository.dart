import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/notification_service.dart';
import '../../projects/models/models.dart';

class FinanceRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  String? get _uid => _authService.currentUser?.uid;
  String? get currentUserId => _uid;

  // Root collections
  CollectionReference get _paymentsCollection => _db.collection('payments');
  CollectionReference get _expensesCollection => _db.collection('expenses');
  CollectionReference get _budgetsCollection => _db.collection('budgets');
  CollectionReference get _transactionsCollection => _db.collection('transactions');
  CollectionReference get _debtsCollection => _db.collection('debts');
  CollectionReference get _walletsCollection => _db.collection('wallets');
  CollectionReference get _transfersCollection => _db.collection('transfers');

  // ── WALLET OPERATIONS ───────────────────────────────────────────────────────
  Future<void> saveWallet(Map<String, dynamic> walletData) async {
    if (_uid == null) throw Exception('User not authenticated');
    final id = walletData['id'] ?? _db.collection('wallets').doc().id;
    await _walletsCollection.doc(id).set({
      ...walletData,
      'userId': _uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<Map<String, dynamic>>> getWallets() {
    if (_uid == null) return Stream.value([]);
    return _walletsCollection
        .where('userId', isEqualTo: _uid)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id}).toList());
  }

  // ── TRANSFER OPERATIONS ─────────────────────────────────────────────────────
  Future<void> saveTransfer(Map<String, dynamic> transferData) async {
    if (_uid == null) throw Exception('User not authenticated');
    final id = transferData['id'] ?? _db.collection('transfers').doc().id;
    await _transfersCollection.doc(id).set({
      ...transferData,
      'userId': _uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ── BUDGET OPERATIONS ───────────────────────────────────────────────────────
  Future<void> saveBudget(Map<String, dynamic> budgetData) async {
    if (_uid == null) throw Exception('User not authenticated');
    final id = budgetData['id'] ?? _db.collection('budgets').doc().id;
    await _budgetsCollection.doc(id).set({
      ...budgetData,
      'userId': _uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<Map<String, dynamic>>> getBudgets() {
    if (_uid == null) return Stream.value([]);
    return _budgetsCollection
        .where('userId', isEqualTo: _uid)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id}).toList());
  }

  // ── TRANSACTION OPERATIONS ──────────────────────────────────────────────────
  Future<void> saveTransaction(Map<String, dynamic> txData) async {
    if (_uid == null) throw Exception('User not authenticated');
    final id = txData['id'] ?? _db.collection('transactions').doc().id;
    await _transactionsCollection.doc(id).set({
      ...txData,
      'userId': _uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<Map<String, dynamic>>> getTransactions() {
    if (_uid == null) return Stream.value([]);
    return _transactionsCollection
        .where('userId', isEqualTo: _uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id}).toList());
  }

  // ── DEBT OPERATIONS ─────────────────────────────────────────────────────────
  Future<void> saveDebt(Map<String, dynamic> debtData) async {
    if (_uid == null) throw Exception('User not authenticated');
    final id = debtData['id'] ?? _db.collection('debts').doc().id;
    await _debtsCollection.doc(id).set({
      ...debtData,
      'userId': _uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<Map<String, dynamic>>> getDebts() {
    if (_uid == null) return Stream.value([]);
    return _debtsCollection
        .where('userId', isEqualTo: _uid)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id}).toList());
  }

  Future<Map<String, dynamic>?> getProjectById(String projectId) async {
    final doc = await _db.collection('projects').doc(projectId).get();
    if (doc.exists) {
      return {...doc.data() as Map<String, dynamic>, 'id': doc.id};
    }
    return null;
  }

  // ── DEBT PAYMENT OPERATIONS ────────────────────────────────────────────────
  Future<void> saveDebtPayment(Map<String, dynamic> paymentData) async {
    if (_uid == null) throw Exception('User not authenticated');
    final id = paymentData['id'] ?? _db.collection('debt_payments').doc().id;
    await _db.collection('debt_payments').doc(id).set({
      ...paymentData,
      'userId': _uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteDebtPayment(String paymentId) async {
    if (_uid == null) throw Exception('User not authenticated');
    await _db.collection('debt_payments').doc(paymentId).delete();
  }

  Stream<List<Map<String, dynamic>>> getDebtPayments(String debtId) {
    if (_uid == null) return Stream.value([]);
    return _db.collection('debt_payments')
        .where('userId', isEqualTo: _uid)
        .where('debtId', isEqualTo: debtId)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id}).toList());
  }

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
      'walletId': payment.walletId,
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
          isReceived: data['isReceived'] ?? true,
          walletId: data['walletId'],
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
          isReceived: data['isReceived'] ?? true,
          walletId: data['walletId'],
        );
      }).toList();
    });
  }

  // ── EXPENSE OPERATIONS ──────────────────────────────────────────────────────
  Future<void> recordExpense(Expense expense) async {
    if (_uid == null) throw Exception('User not authenticated');

    await _expensesCollection.doc(expense.id).set({
      'userId': _uid,
      'name': expense.name,
      'projectId': expense.projectId,
      'amount': expense.amount,
      'date': expense.date.toIso8601String(),
      'category': expense.category,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // If linked to a project, check budget
    if (expense.projectId.isNotEmpty) {
      _checkProjectBudget(expense.projectId);
    }
  }

  Future<void> _checkProjectBudget(String projectId) async {
    try {
      final projectDoc = await _db.collection('projects').doc(projectId).get();
      if (!projectDoc.exists) return;

      final data = projectDoc.data()!;
      final double budget = (data['totalPrice'] as num?)?.toDouble() ?? 0;
      
      if (budget <= 0) return;

      final expensesSnap = await _expensesCollection
          .where('projectId', isEqualTo: projectId)
          .get();
      
      double totalSpent = 0;
      for (var doc in expensesSnap.docs) {
        totalSpent += (doc.data() as Map<String, dynamic>)['amount'] ?? 0;
      }

      await AppNotificationService.instance.checkBudgetStatus(
        data['name'] ?? 'Project',
        budget,
        totalSpent,
      );
    } catch (e) {
      debugPrint('Error checking budget: $e');
    }
  }

  Future<void> updateExpense(Expense expense) async {
    if (_uid == null) throw Exception('User not authenticated');

    await _expensesCollection.doc(expense.id).update({
      'userId': _uid,
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

  Future<void> clearAllFinanceData() async {
    if (_uid == null) throw Exception('User not authenticated');
    
    final collections = [
      _paymentsCollection,
      _expensesCollection,
      _budgetsCollection,
      _transactionsCollection,
      _debtsCollection,
      _walletsCollection
    ];

    final batch = _db.batch();
    
    for (var collection in collections) {
      final snapshot = await collection.where('userId', isEqualTo: _uid).get();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
    }

    await batch.commit();
  }

  Future<void> deleteProjectPayments(String projectId) async {
    if (_uid == null) throw Exception('User not authenticated');
    
    final payments = await _paymentsCollection
        .where('userId', isEqualTo: _uid)
        .where('projectId', isEqualTo: projectId)
        .get();
        
    final batch = _db.batch();
    for (var doc in payments.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
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
          projectId: '', // No longer linked to project
          name: data['name'] ?? '',
          amount: (data['amount'] as num?)?.toDouble() ?? 0,
          date: DateTime.parse(data['date'] ?? DateTime.now().toIso8601String()),
          category: data['category'] ?? '',
        );
      }).toList();
    });
  }
}
