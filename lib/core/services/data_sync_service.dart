import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../database/attachment_repository.dart';
import '../database/profile_cache_repository.dart';
import '../database/payment_receipt_repository.dart';
import '../../features/projects/data/project_repository.dart';
import '../../features/projects/data/activity_log_repository.dart';
import '../../features/projects/data/notes_repository.dart';
import '../../features/projects/models/project_model.dart';

class DataSyncService {
  // ─── CACHED REPOSITORY ACCESS (SINGLETON) ───────────────────────────────
  static final DataSyncService _instance = DataSyncService._internal();
  factory DataSyncService() => _instance;
  DataSyncService._internal();

  final ProjectRepository projectRepo = ProjectRepository();
  final ActivityLogRepository activityLogRepo = ActivityLogRepository();
  final NotesRepository notesRepo = NotesRepository();
  final AttachmentRepository attachmentRepo = AttachmentRepository();
  final ProfileCacheRepository profileCacheRepo = ProfileCacheRepository();
  final PaymentReceiptRepository receiptRepo = PaymentReceiptRepository();

  final Connectivity _connectivity = Connectivity();

  // ─── AUTOMATIC ERROR RECOVERY HELPER ──────────────────────────────────
  Future<T> _safeExecute<T>(Future<T> Function() action, String errorLabel) async {
    try {
      return await action();
    } catch (e) {
      debugPrint('DataSyncService Error [$errorLabel]: $e');
      // Here you could implement a retry mechanism or local queuing
      rethrow; 
    }
  }

  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Stream<bool> get connectivityStream {
    return _connectivity.onConnectivityChanged.map((result) {
      return result != ConnectivityResult.none;
    });
  }

  Future<void> createProjectWithLog(Project project, String userName) async {
    await _safeExecute(() async {
      await projectRepo.createProject(project);
      // Specific detailed log for the service layer
      await activityLogRepo.logActivity(project.id, 'Project created by $userName');
    }, 'CreateProject');
  }

  Future<void> toggleSubtaskWithProgressUpdate({
    required String projectId,
    required String phaseId,
    required String taskId,
    required String subtaskId,
    required bool isDone,
    required String subtaskName,
  }) async {
    await _safeExecute(() async {
      await projectRepo.updateSubtaskStatus(
        projectId: projectId, 
        phaseId: phaseId, 
        taskId: taskId, 
        subtaskId: subtaskId, 
        isDone: isDone, 
        subtaskName: subtaskName
      );
    }, 'ToggleSubtask');
  }

  Future<void> attachFileToProject({
    required String projectId,
    String? phaseId,
    String? taskId,
    String? subtaskId,
    required String fileName,
    required String fileType,
    required Uint8List fileData,
    String? notes,
  }) async {
    await _safeExecute(() async {
      final attachment = AttachmentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        projectId: projectId,
        phaseId: phaseId,
        taskId: taskId,
        subtaskId: subtaskId,
        fileName: fileName,
        fileType: fileType,
        fileData: fileData,
        fileSize: fileData.length,
        uploadedAt: DateTime.now(),
        notes: notes,
      );

      await attachmentRepo.saveAttachment(attachment);
      await activityLogRepo.logActivity(projectId, 'Attached file: $fileName');
    }, 'AttachFile');
  }

  Future<void> attachUrlToProject({
    required String projectId,
    String? phaseId,
    String? taskId,
    String? subtaskId,
    required String fileName,
    required String url,
    String? notes,
  }) async {
    await _safeExecute(() async {
      final attachment = AttachmentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        projectId: projectId,
        phaseId: phaseId,
        taskId: taskId,
        subtaskId: subtaskId,
        fileName: fileName,
        fileType: 'url',
        fileUrl: url,
        fileSize: 0,
        uploadedAt: DateTime.now(),
        notes: notes,
      );

      await attachmentRepo.saveAttachment(attachment);
      await activityLogRepo.logActivity(projectId, 'Added link: $fileName');
    }, 'AttachUrl');
  }

  Future<void> saveProfileWithAvatar({
    required String uid,
    required String displayName,
    required String email,
    String? phone,
    Uint8List? avatarData,
  }) async {
    await _safeExecute(() async {
      final profile = ProfileCache(
        uid: uid,
        displayName: displayName,
        email: email,
        phone: phone,
        avatarData: avatarData,
        lastSynced: DateTime.now(),
      );

      await profileCacheRepo.saveProfile(profile);
    }, 'SaveProfile');
  }

  Future<String> getTotalStorageUsedFormatted() async {
    return await _safeExecute(() async {
      final bytes = await attachmentRepo.getTotalStorageUsed();
      return _formatBytes(bytes);
    }, 'GetStorageUsed');
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
