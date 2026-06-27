import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:devtrack/features/projects/models/models.dart';
import 'package:devtrack/features/projects/data/activity_log_repository.dart';
import 'package:devtrack/core/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Repository for handling Project data in Firestore.
/// Implements business rules for project status and progress auto-calculation.
class ProjectRepository {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  final ActivityLogRepository _activityLogRepository = ActivityLogRepository();
  final _uuid = const Uuid();
  
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Project> get _projectsCollection => 
    _db.collection('projects').withConverter<Project>(
      fromFirestore: (snapshot, _) {
        final data = snapshot.data();
        if (data == null) throw Exception('Project data is null');
        return Project.fromMap({...data, 'id': snapshot.id});
      },
      toFirestore: (project, _) => project.toMap(),
    );

  // ── READ OPERATIONS ─────────────────────────────────────────────────────────

  Stream<List<Project>> getProjectsStream() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    
    return _projectsCollection
        .where('ownerId', isEqualTo: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<Project?> getProjectStream(String projectId) {
    if (_uid == null) return Stream.value(null);
    return _projectsCollection.doc(projectId).snapshots().map((doc) => doc.data());
  }

  Future<Project?> getProject(String projectId) async {
    final uid = _uid;
    if (uid == null) return null;
    final doc = await _projectsCollection.doc(projectId).get();
    return doc.data();
  }

  // ── WRITE OPERATIONS ────────────────────────────────────────────────────────

  Future<void> saveProject(Project project) async {
    final uid = _uid;
    if (uid == null) throw Exception('Authentication failed');
    
    try {
      project.validate();
      final isNew = project.id.isEmpty;
      final docRef = isNew ? _projectsCollection.doc() : _projectsCollection.doc(project.id);
      
      // Auto-calculate progress and status before saving
      final progress = project.progressPercent;
      ProjectStatus currentStatus = project.status;
      
      if (progress > 0 && progress < 1.0 && currentStatus == ProjectStatus.planned) {
        currentStatus = ProjectStatus.active;
      } else if (progress >= 1.0 && currentStatus != ProjectStatus.completed) {
        currentStatus = ProjectStatus.completed;
      }

      final finalProject = project.copyWith(
        id: docRef.id,
        ownerId: uid,
        progress: progress,
        status: currentStatus,
        totalTasks: project.totalTasksCount,
        completedTasks: project.completedTasksCount,
        totalPrice: project.totalPrice,
      );
      
      await docRef.set(finalProject, SetOptions(merge: true));
      
      // Schedule notifications
      await AppNotificationService.instance.scheduleProjectReminders(finalProject);

      await _activityLogRepository.logActivity(
        finalProject.id, 
        'Project "${finalProject.name}" ${isNew ? "created" : "updated"}'
      );
    } catch (e) {
      debugPrint('❌ Project Save Error: $e');
      rethrow;
    }
  }

  Future<void> deleteProject(String projectId) async {
    if (_uid == null) return;
    await _projectsCollection.doc(projectId).delete();
  }

  // ── HIERARCHICAL UPDATES ───────────────────────────────────────────────────

  /// Updates status of a subtask and propagates changes up to task, phase, and project levels.
  Future<void> updateSubtaskStatus({
    required String projectId, 
    required String phaseId, 
    required String taskId, 
    required String subtaskId, 
    required bool isDone, 
    required String subtaskName
  }) async {
    final project = await getProject(projectId);
    if (project == null) return;

    final updatedPhases = project.phases.map((phase) {
      if (phase.id != phaseId) return phase;

      final updatedTasks = phase.tasks.map((task) {
        if (task.id != taskId) return task;

        final updatedSubtasks = task.subtasks.map((st) => 
          st.id == subtaskId ? st.copyWith(isDone: isDone) : st
        ).toList();

        // Task auto-status
        TaskStatus tStatus = task.status;
        if (updatedSubtasks.every((s) => s.isDone)) {
          tStatus = TaskStatus.done;
        } else if (updatedSubtasks.any((s) => s.isDone)) {
          tStatus = TaskStatus.inProgress;
        } else {
          tStatus = TaskStatus.todo;
        }

        return task.copyWith(subtasks: updatedSubtasks, status: tStatus);
      }).toList();

      // Phase auto-status
      TaskStatus pStatus = phase.status;
      if (updatedTasks.every((t) => t.status == TaskStatus.done)) {
        pStatus = TaskStatus.done;
      } else if (updatedTasks.any((t) => t.status != TaskStatus.todo)) {
        pStatus = TaskStatus.inProgress;
      } else {
        pStatus = TaskStatus.todo;
      }

      return phase.copyWith(tasks: updatedTasks, status: pStatus);
    }).toList();

    await saveProject(project.copyWith(phases: updatedPhases));
    await _activityLogRepository.logActivity(projectId, 'Subtask "$subtaskName" updated');
  }

  Future<void> updatePhaseStatus({
    required String projectId,
    required String phaseId,
    required TaskStatus newStatus,
  }) async {
    final project = await getProject(projectId);
    if (project == null) return;

    final updatedPhases = project.phases.map((phase) {
      if (phase.id != phaseId) return phase;
      
      // Cascade status change to tasks and subtasks
      final updatedTasks = phase.tasks.map((task) {
        if (newStatus == TaskStatus.done) {
          return task.copyWith(
            status: TaskStatus.done,
            subtasks: task.subtasks.map((s) => s.copyWith(isDone: true)).toList()
          );
        } else if (newStatus == TaskStatus.todo) {
          return task.copyWith(
            status: TaskStatus.todo,
            subtasks: task.subtasks.map((s) => s.copyWith(isDone: false)).toList()
          );
        }
        return task;
      }).toList();

      return phase.copyWith(status: newStatus, tasks: updatedTasks);
    }).toList();

    await saveProject(project.copyWith(phases: updatedPhases));
  }

  Future<void> updateTaskStatus({
    required String projectId,
    required String phaseId,
    required String taskId,
    required TaskStatus newStatus,
  }) async {
    final project = await getProject(projectId);
    if (project == null) return;

    final updatedPhases = project.phases.map((phase) {
      if (phase.id != phaseId) return phase;
      
      final updatedTasks = phase.tasks.map((task) {
        if (task.id != taskId) return task;

        // If task is marked done, mark all subtasks done too
        final updatedSubtasks = newStatus == TaskStatus.done 
            ? task.subtasks.map((s) => s.copyWith(isDone: true)).toList() 
            : task.subtasks;
        
        return task.copyWith(status: newStatus, subtasks: updatedSubtasks);
      }).toList();

      // Re-calculate phase status
      TaskStatus pStatus = phase.status;
      if (updatedTasks.every((t) => t.status == TaskStatus.done)) {
        pStatus = TaskStatus.done;
      } else if (updatedTasks.any((t) => t.status != TaskStatus.todo)) {
        pStatus = TaskStatus.inProgress;
      } else {
        pStatus = TaskStatus.todo;
      }

      return phase.copyWith(tasks: updatedTasks, status: pStatus);
    }).toList();

    await saveProject(project.copyWith(phases: updatedPhases));
  }

  Future<void> updateProject(Project project) async => saveProject(project);
}
