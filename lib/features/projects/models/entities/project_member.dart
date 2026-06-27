import '../common/project_enums.dart';
import '../common/model_utils.dart';

class ProjectMember {
  final String uid;
  final String email;
  final MemberRole role;
  final DateTime joinedAt;

  const ProjectMember({
    required this.uid,
    required this.email,
    required this.role,
    required this.joinedAt,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'role': role.name,
    'joinedAt': joinedAt.toIso8601String(),
  };

  factory ProjectMember.fromMap(Map<String, dynamic> map) => ProjectMember(
    uid: map['uid'] ?? '',
    email: map['email'] ?? '',
    role: MemberRole.values.firstWhere((e) => e.name == map['role'], orElse: () => MemberRole.viewer),
    joinedAt: ModelUtils.toDateTime(map['joinedAt']),
  );
}
