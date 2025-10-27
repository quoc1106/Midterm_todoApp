/// 🔧 BACKEND - Project Member Data Model
///
/// Quản lý thành viên trong shared projects
import 'package:hive/hive.dart';
part 'project_member.g.dart';

@HiveType(typeId: 11)
class ProjectMember {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String projectId;
  @HiveField(2)
  final String userId;
  @HiveField(3)
  final String userDisplayName; // Cache tên hiển thị
  @HiveField(4)
  final DateTime joinedAt;

  ProjectMember({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.userDisplayName,
    required this.joinedAt,
  });

  /// Business logic methods
  bool belongsToProject(String projectId) => this.projectId == projectId;
  bool isUser(String userId) => this.userId == userId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectMember &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ProjectMember(id: $id, projectId: $projectId, userId: $userId, userDisplayName: $userDisplayName)';
}
