import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../features/projects/models/models.dart';
import '../../features/projects/models/common/model_utils.dart';

class ProjectService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid;

  ProjectService({required this.uid});

  // Root collection reference
  CollectionReference get _projects => _db.collection('projects');

  // ─── CREATE/UPDATE PROJECT (ATOMIC BATCH) ──────────────────────────────────
  
  Future<void> saveProject(Project project) async {
    if (uid.isEmpty) throw Exception('AUTHENTICATION_REQUIRED');

    final batch = _db.batch();
    final docRef = _projects.doc(project.id);

    // Calculate progress and status before saving
    final progress = project.progressPercent;
    
    ProjectStatus currentStatus = project.status;
    if (progress > 0 && progress < 1.0 && currentStatus == ProjectStatus.planned) {
      currentStatus = ProjectStatus.active;
    } else if (progress >= 1.0 && currentStatus != ProjectStatus.completed) {
      currentStatus = ProjectStatus.completed;
    } else if (progress < 1.0 && currentStatus == ProjectStatus.completed) {
      currentStatus = ProjectStatus.active;
    }

    // 1. Project Root Data
    batch.set(docRef, {
      'id': project.id,
      'ownerId': uid,
      'name': project.name,
      'category': project.category.name,
      'status': currentStatus.name,
      'totalPrice': project.totalPrice,
      'advanceAmount': project.advanceAmount,
      'startDate': project.startDate.toIso8601String(),
      'endDate': project.endDate.toIso8601String(),
      'description': project.description,
      'isPinned': project.isPinned,
      'tags': project.tags,
      'progress': progress,
      'updatedAt': FieldValue.serverTimestamp(),
      'projectEmoji': project.projectEmoji,
      'projectColor': project.projectColor.toARGB32(),
      'priority': project.priority.name,
      'phases': project.phases.map((p) => p.toMap()).toList(), // Including phases in root for dashboard efficiency
    }, SetOptions(merge: true));

    await batch.commit();
  }

  // ─── FETCHING ─────────────────────────────────────────────────────────────

  Stream<List<Project>> getProjectsStream() {
    if (uid.isEmpty) return Stream.value([]);
    
    return _projects
        .where('ownerId', isEqualTo: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => _mapDocToProject(doc)).toList();
    });
  }

  Future<Project?> getProjectById(String projectId) async {
    final doc = await _projects.doc(projectId).get();
    if (!doc.exists) return null;
    return _mapDocToProject(doc);
  }

  // ─── DELETION ─────────────────────────────────────────────────────────────

  Future<void> deleteProject(String projectId) async {
    final batch = _db.batch();
    final docRef = _projects.doc(projectId);
    batch.delete(docRef);
    await batch.commit();
  }

  // ─── MAPPING ──────────────────────────────────────────────────────────────

  Project _mapDocToProject(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse phases if they exist in the document
    List<Phase> phases = [];
    if (data['phases'] != null) {
      phases = (data['phases'] as List).map((p) => Phase.fromMap(Map<String, dynamic>.from(p))).toList();
    }

    return Project(
      id: doc.id,
      ownerId: data['ownerId'],
      name: data['name'] ?? '',
      category: ProjectCategory.values.firstWhere(
        (e) => e.name == data['category'], 
        orElse: () => ProjectCategory.other
      ),
      status: ProjectStatus.values.firstWhere(
        (e) => e.name == data['status'], 
        orElse: () => ProjectStatus.active
      ),
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0,
      advanceAmount: (data['advanceAmount'] as num?)?.toDouble() ?? 0,
      startDate: DateTime.parse(data['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(data['endDate'] ?? DateTime.now().toIso8601String()),
      description: data['description'],
      isPinned: data['isPinned'] ?? false,
      tags: List<String>.from(data['tags'] ?? []),
      progress: (data['progress'] as num?)?.toDouble() ?? 0.0,
      projectEmoji: data['projectEmoji'] ?? '🚀',
      projectColor: data['projectColor'] != null ? Color(data['projectColor']) : const Color(0xFF6366F1),
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == data['priority'], 
        orElse: () => TaskPriority.medium
      ),
      phases: phases,
      createdAt: ModelUtils.toDateTime(data['createdAt']),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] is Timestamp 
              ? (data['updatedAt'] as Timestamp).toDate() 
              : ModelUtils.toDateTime(data['updatedAt']))
          : null,
    );
  }
}
