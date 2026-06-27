import 'project_enums.dart';
import 'model_utils.dart';

class ProjectAttachment {
  final String id;
  final String name;
  final AttachmentType type;
  final String? path;
  final String? url;
  final String? mimeType;
  final int? fileSize;
  final Duration? duration; 
  final DateTime addedAt;
  final Map<String, dynamic>? metadata; 

  const ProjectAttachment({
    required this.id,
    required this.name,
    required this.type,
    this.path,
    this.url,
    this.mimeType,
    this.fileSize,
    this.duration,
    required this.addedAt,
    this.metadata,
  });

  bool get isRecording => type == AttachmentType.recording;
  bool get isImage => type == AttachmentType.image;
  bool get isVideo => type == AttachmentType.video;
  bool get isLink => type == AttachmentType.link;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type.name,
    'path': path,
    'url': url,
    'mimeType': mimeType,
    'fileSize': fileSize,
    'durationMs': duration?.inMilliseconds,
    'addedAt': addedAt.toIso8601String(),
    'metadata': metadata,
  };

  factory ProjectAttachment.fromMap(Map<String, dynamic> map) => ProjectAttachment(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    type: AttachmentType.values.firstWhere(
      (e) => e.name == map['type'], 
      orElse: () => AttachmentType.file
    ),
    path: map['path'],
    url: map['url'],
    mimeType: map['mimeType'],
    fileSize: map['fileSize'],
    duration: map['durationMs'] != null ? Duration(milliseconds: map['durationMs']) : null,
    addedAt: ModelUtils.toDateTime(map['addedAt']),
    metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : null,
  );

  ProjectAttachment copyWith({
    String? id,
    String? name,
    AttachmentType? type,
    String? path,
    String? url,
    String? mimeType,
    int? fileSize,
    Duration? duration,
    DateTime? addedAt,
    Map<String, dynamic>? metadata,
  }) {
    return ProjectAttachment(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      path: path ?? this.path,
      url: url ?? this.url,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      duration: duration ?? this.duration,
      addedAt: addedAt ?? this.addedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
