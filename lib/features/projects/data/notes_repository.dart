import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/auth_service.dart';

class ProjectNote {
  final String id;
  final String projectId;
  final String content;
  final DateTime createdAt;

  const ProjectNote({
    required this.id,
    required this.projectId,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ProjectNote.fromMap(String id, Map<String, dynamic> map) {
    return ProjectNote(
      id: id,
      projectId: map['projectId'] as String,
      content: map['content'] as String,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] as String),
    );
  }
}

class NotesRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  String? get _uid => _authService.currentUser?.uid;

  CollectionReference get _notesCollection =>
      _db.collection('users').doc(_uid).collection('notes');

  // ── CREATE NOTE ─────────────────────────────────────────────────────────────
  Future<void> createNote(ProjectNote note) async {
    if (_uid == null) throw Exception('User not authenticated');

    await _notesCollection.doc(note.id).set({
      'projectId': note.projectId,
      'content': note.content,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ── UPDATE NOTE ─────────────────────────────────────────────────────────────
  Future<void> updateNote(ProjectNote note) async {
    if (_uid == null) throw Exception('User not authenticated');

    await _notesCollection.doc(note.id).update({
      'content': note.content,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── DELETE NOTE ─────────────────────────────────────────────────────────────
  Future<void> deleteNote(String noteId) async {
    if (_uid == null) throw Exception('User not authenticated');
    await _notesCollection.doc(noteId).delete();
  }

  // ── GET NOTES FOR PROJECT ───────────────────────────────────────────────────
  Stream<List<ProjectNote>> getNotesForProject(String projectId) {
    if (_uid == null) return Stream.value([]);

    return _notesCollection
        .where('projectId', isEqualTo: projectId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ProjectNote.fromMap(doc.id, data);
      }).toList();
    });
  }
}
