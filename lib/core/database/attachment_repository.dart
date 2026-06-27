import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';
import '../../features/projects/models/models.dart';
import '../../features/projects/models/common/project_enums.dart';

/// Unified model for project attachments (Local SQLite Storage)
class AttachmentModel {
  final String id;
  final String projectId;
  final String? phaseId;
  final String? taskId;
  final String? subtaskId;
  final String fileName;
  final String fileType;
  final AttachmentType type; // From project_enums.dart
  final Uint8List? fileData;
  final String? fileUrl;
  final String? filePath;
  final int fileSize;
  final DateTime uploadedAt;
  final Duration? duration; // For recordings
  final String? notes;

  const AttachmentModel({
    required this.id,
    required this.projectId,
    this.phaseId,
    this.taskId,
    this.subtaskId,
    required this.fileName,
    required this.fileType,
    required this.type,
    this.fileData,
    this.fileUrl,
    this.filePath,
    required this.fileSize,
    required this.uploadedAt,
    this.duration,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'phase_id': phaseId,
      'task_id': taskId,
      'subtask_id': subtaskId,
      'file_name': fileName,
      'file_type': fileType,
      'type': type.name,
      'file_data': fileData,
      'file_url': fileUrl,
      'file_path': filePath,
      'file_size': fileSize,
      'uploaded_at': uploadedAt.toIso8601String(),
      'duration_ms': duration?.inMilliseconds,
      'notes': notes,
    };
  }

  factory AttachmentModel.fromMap(Map<String, dynamic> map) {
    return AttachmentModel(
      id: map['id'] as String,
      projectId: map['project_id'] as String,
      phaseId: map['phase_id'] as String?,
      taskId: map['task_id'] as String?,
      subtaskId: map['subtask_id'] as String?,
      fileName: map['file_name'] as String,
      fileType: map['file_type'] as String,
      type: AttachmentType.values.firstWhere(
        (e) => e.name == map['type'], 
        orElse: () => AttachmentType.file
      ),
      fileData: map['file_data'] as Uint8List?,
      fileUrl: map['file_url'] as String?,
      filePath: map['file_path'] as String?,
      fileSize: map['file_size'] as int,
      uploadedAt: DateTime.parse(map['uploaded_at'] as String),
      duration: map['duration_ms'] != null ? Duration(milliseconds: map['duration_ms'] as int) : null,
      notes: map['notes'] as String?,
    );
  }
}

class AttachmentRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  // ── SAVE ATTACHMENT ─────────────────────────────────────────────────────────
  Future<void> saveAttachment(AttachmentModel attachment) async {
    final db = await _dbService.database;
    
    // Validate file size (20 MB max for recordings/videos)
    final limit = (attachment.type == AttachmentType.recording || attachment.type == AttachmentType.video) 
        ? 50 * 1024 * 1024 
        : 10 * 1024 * 1024;
        
    if (attachment.fileSize > limit) {
      throw Exception('File size exceeds limit for this attachment type');
    }

    await db.insert(
      'attachments',
      attachment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── GET ATTACHMENTS FOR PROJECT ─────────────────────────────────────────────
  Future<List<AttachmentModel>> getAttachmentsForProject(String projectId) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'attachments',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'uploaded_at DESC',
    );
    return maps.map((map) => AttachmentModel.fromMap(map)).toList();
  }

  // ── GET RECORDINGS FOR PROJECT ──────────────────────────────────────────────
  Future<List<AttachmentModel>> getRecordingsForProject(String projectId) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'attachments',
      where: 'project_id = ? AND type = ?',
      whereArgs: [projectId, AttachmentType.recording.name],
      orderBy: 'uploaded_at DESC',
    );
    return maps.map((map) => AttachmentModel.fromMap(map)).toList();
  }

  // ── DELETE ATTACHMENT ───────────────────────────────────────────────────────
  Future<void> deleteAttachment(String attachmentId) async {
    final db = await _dbService.database;
    await db.delete('attachments', where: 'id = ?', whereArgs: [attachmentId]);
  }

  // ── GET TOTAL STORAGE USED ──────────────────────────────────────────────────
  Future<int> getTotalStorageUsed() async {
    final db = await _dbService.database;
    final result = await db.rawQuery('SELECT SUM(file_size) as total FROM attachments');
    return (result.first['total'] as int?) ?? 0;
  }
}
