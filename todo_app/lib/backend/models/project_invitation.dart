/// 🔧 BACKEND - Project Invitation Data Model
///
/// Quản lý lời mời tham gia shared projects
import 'package:hive/hive.dart';
part 'project_invitation.g.dart';

@HiveType(typeId: 12)
class ProjectInvitation {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String projectId;
  @HiveField(2)
  final String projectName; // Cache tên project
  @HiveField(3)
  final String fromUserId;
  @HiveField(4)
  final String fromUserDisplayName; // Người gửi lời mời
  @HiveField(5)
  final String toUserId;
  @HiveField(6)
  final String toUserDisplayName; // Người nhận lời mời
  @HiveField(7)
  final InvitationStatus status;
  @HiveField(8)
  final DateTime createdAt;
  @HiveField(9)
  final DateTime? respondedAt;

  ProjectInvitation({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.fromUserId,
    required this.fromUserDisplayName,
    required this.toUserId,
    required this.toUserDisplayName,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  /// Business logic methods
  bool get isPending => status == InvitationStatus.pending;
  bool get isAccepted => status == InvitationStatus.accepted;
  bool get isDeclined => status == InvitationStatus.declined;
  bool get isResponded => respondedAt != null;

  bool canRespond(String userId) => toUserId == userId && isPending;
  bool belongsToUser(String userId) => toUserId == userId;
  bool sentByUser(String userId) => fromUserId == userId;

  ProjectInvitation copyWith({
    InvitationStatus? status,
    DateTime? respondedAt,
  }) {
    return ProjectInvitation(
      id: id,
      projectId: projectId,
      projectName: projectName,
      fromUserId: fromUserId,
      fromUserDisplayName: fromUserDisplayName,
      toUserId: toUserId,
      toUserDisplayName: toUserDisplayName,
      status: status ?? this.status,
      createdAt: createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectInvitation &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ProjectInvitation(id: $id, projectId: $projectId, status: $status)';
}

@HiveType(typeId: 13)
enum InvitationStatus {
  @HiveField(0)
  pending,   // Đang chờ
  @HiveField(1)
  accepted,  // Đã chấp nhận
  @HiveField(2)
  declined,  // Đã từ chối
}
