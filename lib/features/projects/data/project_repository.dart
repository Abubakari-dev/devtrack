import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:devtrack/features/projects/models/project_model.dart';
import 'package:devtrack/features/projects/data/activity_log_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class DatabaseFailure implements Exception {
  final String message;
  const DatabaseFailure(this.message);
  @override
  String toString() => message;
}

class AuthFailure implements Exception {
  const AuthFailure();
  @override
  String toString() => 'Authentication failed. Please log in again.';
}

class ProjectRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ActivityLogRepository _activityLogRepository = ActivityLogRepository();
  final _uuid = const Uuid();
  
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // Optimized converter for seamless Firestore integration
  CollectionReference<Project> get _projectsCollection => 
    _db.collection('projects').withConverter<Project>(
      fromFirestore: (snapshot, _) {
        final data = snapshot.data();
        if (data == null) throw Exception('Project data is null');
        return Project.fromMap({...data, 'id': snapshot.id});
      },
      toFirestore: (project, _) => project.toMap(),
    );

  /// Streams all projects owned by the current user
  Stream<List<Project>> getProjectsStream() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    
    return _projectsCollection
        .where('ownerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList())
        .handleError((error) {
          debugPrint('❌ Error fetching projects stream: $error');
          return <Project>[];
        });
  }

  /// Streams a single project by ID
  Stream<Project?> getProjectStream(String projectId) {
    if (_uid == null) return Stream.value(null);
    
    return _projectsCollection.doc(projectId).snapshots().map((doc) {
      if (!doc.exists) {
        debugPrint('⚠️ Project document does not exist: $projectId');
        return null;
      }
      return doc.data();
    }).handleError((error) {
      debugPrint('❌ Error fetching project stream ($projectId): $error');
      return null;
    });
  }

  /// Fetches a single project once
  Future<Project?> getProject(String projectId) async {
    final uid = _uid;
    if (uid == null) return null;
    
    try {
      final doc = await _projectsCollection.doc(projectId).get();
      return doc.data();
    } catch (e) {
      debugPrint('❌ Error getting project ($projectId): $e');
      return null;
    }
  }

  /// Saves or updates a project document
  Future<void> saveProject(Project project) async {
    final uid = _uid;
    if (uid == null) throw const AuthFailure();
    
    try {
      // Validate project before saving
      project.validate();

      final isNew = project.id.isEmpty;
      final docRef = isNew ? _projectsCollection.doc() : _projectsCollection.doc(project.id);
      
      // Calculate progress and totals automatically before saving
      final totalTasks = project.totalTasksCount;
      final completedTasks = project.completedTasksCount;
      final progress = project.progressPercent; // Use the smarter getter from the model
      final totalPrice = project.calculateTotalPriceFromTasks();

      // Auto-update project status based on progress
      ProjectStatus currentStatus = project.status;
      if (progress > 0 && progress < 1.0 && currentStatus == ProjectStatus.planned) {
        currentStatus = ProjectStatus.active;
      } else if (progress >= 1.0 && currentStatus != ProjectStatus.completed) {
        currentStatus = ProjectStatus.completed;
      } else if (progress < 1.0 && currentStatus == ProjectStatus.completed) {
        currentStatus = ProjectStatus.active;
      }

      final finalProject = project.copyWith(
        id: docRef.id,
        ownerId: uid,
        progress: progress,
        status: currentStatus,
        totalTasks: totalTasks,
        completedTasks: completedTasks,
        totalPrice: totalPrice > 0 ? totalPrice : project.totalPrice,
      );
      
      await docRef.set(finalProject, SetOptions(merge: true));
      
      await _activityLogRepository.logActivity(
        finalProject.id, 
        'Project "${finalProject.name}" ${isNew ? "created" : "updated"}'
      );
      
      debugPrint('✅ Project saved successfully: ${finalProject.id}');
    } catch (e) {
      debugPrint('❌ Failed to save project: $e');
      throw DatabaseFailure('Failed to save project: $e');
    }
  }

  Future<void> createProject(Project project) async => saveProject(project);
  Future<void> updateProject(Project project) async => saveProject(project);

  /// Deletes a project
  Future<void> deleteProject(String projectId) async {
    final uid = _uid;
    if (uid == null) throw const AuthFailure();
    try {
      await _projectsCollection.doc(projectId).delete();
      debugPrint('🗑️ Project deleted: $projectId');
    } catch (e) {
       throw DatabaseFailure('Failed to delete project: $e');
    }
  }

  /// Adds a new phase to a project
  Future<void> addPhase(String projectId, String phaseName) async {
    try {
      final project = await getProject(projectId);
      if (project == null) return;

      final newPhase = Phase(
        id: _uuid.v4(),
        projectId: projectId,
        name: phaseName.toUpperCase(),
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
        orderIndex: project.phases.length,
        status: TaskStatus.todo,
      );

      final updatedProject = project.copyWith(
        phases: [...project.phases, newPhase],
      );

      await saveProject(updatedProject);
      await _activityLogRepository.logActivity(projectId, 'Module "$phaseName" added');
    } catch (e) {
      debugPrint('❌ Error adding phase: $e');
    }
  }

  /// Adds a new task to a specific phase
  Future<void> addTask(String projectId, String phaseId, String taskName) async {
    try {
      final project = await getProject(projectId);
      if (project == null) return;

      final updatedPhases = project.phases.map((phase) {
        if (phase.id == phaseId) {
          final newTask = ProjectTask(
            id: _uuid.v4(),
            phaseId: phaseId,
            name: taskName.toUpperCase(),
            priority: TaskPriority.medium,
            status: TaskStatus.todo,
            startDate: phase.startDate,
            endDate: phase.endDate,
          );
          return phase.copyWith(tasks: [...phase.tasks, newTask]);
        }
        return phase;
      }).toList();

      await saveProject(project.copyWith(phases: updatedPhases));
      await _activityLogRepository.logActivity(projectId, 'Task "$taskName" added to module');
    } catch (e) {
      debugPrint('❌ Error adding task: $e');
    }
  }

  /// Specialized method to update status of a subtask and auto-calculate parent statuses
  Future<void> updateSubtaskStatus({
    required String projectId, 
    required String phaseId, 
    required String taskId, 
    required String subtaskId, 
    required bool isDone, 
    required String subtaskName
  }) async {
    try {
      final project = await getProject(projectId);
      if (project == null) return;

      final updatedPhases = project.phases.map((phase) {
        if (phase.id == phaseId) {
          final updatedTasks = phase.tasks.map((task) {
            if (task.id == taskId) {
              // 1. Update the subtask
              final updatedSubtasks = task.subtasks.map((subtask) {
                if (subtask.id == subtaskId) {
                  return subtask.copyWith(isDone: isDone);
                }
                return subtask;
              }).toList();

              // 2. Auto-determine task status
              TaskStatus tStatus = task.status;
              if (updatedSubtasks.isNotEmpty) {
                if (updatedSubtasks.every((s) => s.isDone)) {
                  tStatus = TaskStatus.done;
                } else if (updatedSubtasks.any((s) => s.isDone)) {
                  tStatus = TaskStatus.inProgress;
                } else {
                  tStatus = TaskStatus.todo;
                }
              }

              return task.copyWith(subtasks: updatedSubtasks, status: tStatus);
            }
            return task;
          }).toList();

          // 3. Auto-determine phase status
          TaskStatus pStatus = phase.status;
          if (updatedTasks.every((t) => t.status == TaskStatus.done)) {
            pStatus = TaskStatus.done;
          } else if (updatedTasks.any((t) => t.status != TaskStatus.todo)) {
            pStatus = TaskStatus.inProgress;
          } else {
            pStatus = TaskStatus.todo;
          }

          return phase.copyWith(tasks: updatedTasks, status: pStatus);
        }
        return phase;
      }).toList();

      final updatedProject = project.copyWith(phases: updatedPhases);
      await saveProject(updatedProject);
      await _activityLogRepository.logActivity(projectId, 'Subtask "$subtaskName" ${isDone ? "completed" : "unmarked"}');
    } catch (e) {
      debugPrint('❌ Error updating subtask status: $e');
    }
  }

  /// Updates the status of an entire phase
  Future<void> updatePhaseStatus({
    required String projectId,
    required String phaseId,
    required TaskStatus newStatus,
  }) async {
    try {
      final project = await getProject(projectId);
      if (project == null) return;

      final updatedPhases = project.phases.map((phase) {
        if (phase.id == phaseId) {
          // If phase is marked done, mark all tasks and subtasks done too
          final updatedTasks = newStatus == TaskStatus.done 
              ? phase.tasks.map((t) => t.copyWith(
                  status: TaskStatus.done,
                  subtasks: t.subtasks.map((s) => s.copyWith(isDone: true)).toList()
                )).toList()
              : (newStatus == TaskStatus.todo 
                  ? phase.tasks.map((t) => t.copyWith(
                      status: TaskStatus.todo,
                      subtasks: t.subtasks.map((s) => s.copyWith(isDone: false)).toList()
                    )).toList()
                  : phase.tasks);
          
          return phase.copyWith(status: newStatus, tasks: updatedTasks);
        }
        return phase;
      }).toList();

      await saveProject(project.copyWith(phases: updatedPhases));
      await _activityLogRepository.logActivity(projectId, 'Phase status updated to ${newStatus.name}');
    } catch (e) {
      debugPrint('❌ Error updating phase status: $e');
    }
  }

  /// Updates the status of an entire task
  Future<void> updateTaskStatus({
    required String projectId,
    required String phaseId,
    required String taskId,
    required TaskStatus newStatus,
  }) async {
    try {
      final project = await getProject(projectId);
      if (project == null) return;

      final updatedPhases = project.phases.map((phase) {
        if (phase.id == phaseId) {
          final updatedTasks = phase.tasks.map((task) {
            if (task.id == taskId) {
              // If task is marked done, mark all subtasks done too
              final updatedSubtasks = newStatus == TaskStatus.done 
                  ? task.subtasks.map((s) => s.copyWith(isDone: true)).toList() 
                  : task.subtasks;
              
              return task.copyWith(status: newStatus, subtasks: updatedSubtasks);
            }
            return task;
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
        }
        return phase;
      }).toList();

      await saveProject(project.copyWith(phases: updatedPhases));
    } catch (e) {
      debugPrint('❌ Error updating task status: $e');
    }
  }
}
