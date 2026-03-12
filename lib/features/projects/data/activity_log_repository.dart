import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/auth_service.dart';

class ActivityLog {
  final String id;
  final String projectId;
  final String action;
  final DateTime timestamp;
  final String? userId;
  final String? userName;

  const ActivityLog({
    required this.id,
    required this.projectId,
    required this.action,
    required this.timestamp,
    this.userId,
    this.userName,
  });

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'action': action,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'userName': userName,
    };
  }

  factory ActivityLog.fromMap(String id, Map<String, dynamic> map) {
    return ActivityLog(
      id: id,
      projectId: map['projectId'] as String,
      action: map['action'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      userId: map['userId'] as String?,
      userName: map['userName'] as String?,
    );
  }
}

class ActivityLogRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  String? get _uid => _authService.currentUser?.uid;

  CollectionReference get _activityLogsCollection =>
      _db.collection('users').doc(_uid).collection('activityLogs');

  // ── LOG ACTIVITY ────────────────────────────────────────────────────────────
  Future<void> logActivity(String projectId, String action) async {
    if (_uid == null) throw Exception('User not authenticated');

    await _activityLogsCollection.add({
      'projectId': projectId,
      'action': action,
      'timestamp': FieldValue.serverTimestamp(),
      'userId': _uid,
    });
  }

  // ── GET ACTIVITY LOGS FOR PROJECT ───────────────────────────────────────────
  Stream<List<ActivityLog>> getActivityLogsForProject(String projectId) {
    if (_uid == null) return Stream.value([]);

    return _activityLogsCollection
        .where('projectId', isEqualTo: projectId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ActivityLog(
          id: doc.id,
          projectId: data['projectId'] ?? '',
          action: data['action'] ?? '',
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          userId: data['userId'] as String?,
          userName: data['userName'] as String?,
        );
      }).toList();
    });
  }
}
