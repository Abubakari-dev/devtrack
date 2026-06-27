import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/projects/models/models.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid;

  FirestoreService({required this.uid});

  // --- Collection References ---
  DocumentReference get _userDoc {
    if (uid.isEmpty) throw Exception('AUTHENTICATION_REQUIRED');
    return _db.collection('users').doc(uid);
  }
  
  CollectionReference get _clients => _userDoc.collection('clients');
  CollectionReference get _payments => _userDoc.collection('payments');
  CollectionReference get _expenses => _userDoc.collection('expenses');

  // ─── CLIENTS ──────────────────────────────────────────────────────────────

  Stream<List<Client>> getClients() {
    if (uid.isEmpty) return Stream.value([]);
    return _clients.snapshots().map((s) => s.docs.map((d) => _mapDocToClient(d)).toList());
  }

  Client _mapDocToClient(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Client(
      id: doc.id, 
      name: data['name'] ?? '', 
      company: data['company'] ?? '', 
      email: data['email'] ?? '', 
      phone: data['phone'] ?? '', 
      location: data['location'] ?? ''
    );
  }

  // ─── PAYMENTS ─────────────────────────────────────────────────────────────

  Stream<List<Payment>> getAllPayments() {
    if (uid.isEmpty) return Stream.value([]);
    return _payments.orderBy('date', descending: true).snapshots().map((s) => s.docs.map((d) => _mapDocToPayment(d)).toList());
  }

  Payment _mapDocToPayment(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Payment(
      id: doc.id, 
      projectId: data['projectId'] ?? '', 
      amount: (data['amount'] as num?)?.toDouble() ?? 0, 
      date: DateTime.parse(data['date'] ?? DateTime.now().toIso8601String()), 
      isReceived: data['isReceived'] ?? false, 
      label: data['label'] ?? ''
    );
  }

  // ─── EXPENSES ─────────────────────────────────────────────────────────────

  Stream<List<Expense>> getAllExpenses() {
    if (uid.isEmpty) return Stream.value([]);
    return _expenses.orderBy('date', descending: true).snapshots().map((s) => s.docs.map((d) => _mapDocToExpense(d)).toList());
  }

  Expense _mapDocToExpense(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Expense(
      id: doc.id, 
      projectId: data['projectId'] ?? '', 
      name: data['name'] ?? '', 
      amount: (data['amount'] as num?)?.toDouble() ?? 0, 
      date: DateTime.parse(data['date'] ?? DateTime.now().toIso8601String()), 
      category: data['category'] ?? ''
    );
  }
}
