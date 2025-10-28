/// 🔧 SHARED PROJECT PROVIDERS - Quản lý shared project logic
///
/// Level 2: StateNotifierProvider cho complex business logic
/// Level 4: Provider.family cho parameterized data
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../backend/models/project_member.dart';
import '../backend/models/project_model.dart';
import '../backend/models/user.dart';
import 'auth_providers.dart';
import 'performance_initialization_providers.dart';
import 'invitation_providers.dart';
import 'project_providers.dart'; // ✅ NEW: Import project_providers

// ✅ LEVEL 2: StateNotifierProvider cho quản lý shared projects
class SharedProjectNotifier extends StateNotifier<List<ProjectMember>> {
  final Box<ProjectMember> _memberBox;
  final Box<ProjectModel> _projectBox;
  final Box<User> _userBox;
  final String projectId;
  final Ref ref;

  SharedProjectNotifier(
    this._memberBox,
    this._projectBox,
    this._userBox,
    this.projectId,
    this.ref
  ) : super([]) {
    _loadProjectMembers();
  }

  void _loadProjectMembers() {
    final members = _memberBox.values
        .where((member) => member.projectId == projectId)
        .toList();
    state = members;
  }

  Future<void> addMemberByDisplayName(String displayName) async {
    try {
      // Tìm user theo displayName
      final targetUser = _userBox.values.firstWhere(
        (user) => user.displayName == displayName || user.username == displayName,
        orElse: () => throw Exception('Không tìm thấy người dùng với tên: $displayName'),
      );

      // Kiểm tra user đã là member chưa
      final project = _projectBox.get(projectId);
      if (project != null && project.canUserAccess(targetUser.id)) {
        throw Exception('Người dùng đã là thành viên của dự án');
      }

      // Gửi lời mời
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        final invitationNotifier = ref.read(invitationNotifierProvider.notifier);
        await invitationNotifier.sendInvitation(
          projectId: projectId,
          projectName: project?.name ?? '',
          toUserId: targetUser.id,
          toUserDisplayName: targetUser.displayName ?? targetUser.username,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeMember(String userId) async {
    // Xóa khỏi project.sharedUserIds
    final project = _projectBox.get(projectId);
    if (project != null) {
      final updatedSharedUserIds = project.sharedUserIds.where((id) => id != userId).toList();
      final updatedProject = project.copyWith(
        sharedUserIds: updatedSharedUserIds,
        lastModified: DateTime.now(),
      );
      await _projectBox.put(projectId, updatedProject);
    }

    // Xóa ProjectMember record
    final memberToRemove = state.firstWhere((member) => member.userId == userId);
    await _memberBox.delete(memberToRemove.id);

    _loadProjectMembers();
  }

  Future<void> addMemberDirectly(String userId, String userDisplayName) async {
    // Thêm user vào project.sharedUserIds
    final project = _projectBox.get(projectId);
    if (project != null) {
      final updatedSharedUserIds = [...project.sharedUserIds, userId];
      final updatedProject = project.copyWith(
        sharedUserIds: updatedSharedUserIds,
        lastModified: DateTime.now(),
      );
      await _projectBox.put(projectId, updatedProject);
    }

    // Tạo ProjectMember record
    final member = ProjectMember(
      id: const Uuid().v4(),
      projectId: projectId,
      userId: userId,
      userDisplayName: userDisplayName,
      joinedAt: DateTime.now(),
    );
    await _memberBox.put(member.id, member);

    _loadProjectMembers();
  }

  /// ✅ NEW: inviteUser method for invite_user_widget.dart compatibility
  Future<void> inviteUser(String userId, String userDisplayName, String projectName) async {
    try {
      // Check if user already has access to the project
      final project = _projectBox.get(projectId);
      if (project != null && project.canUserAccess(userId)) {
        throw Exception('User is already a member of this project');
      }

      // Send invitation using invitation notifier
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        final invitationNotifier = ref.read(invitationNotifierProvider.notifier);
        await invitationNotifier.sendInvitation(
          projectId: projectId,
          projectName: projectName,
          toUserId: userId,
          toUserDisplayName: userDisplayName,
        );
      } else {
        throw Exception('Current user not found');
      }
    } catch (e) {
      rethrow;
    }
  }
}

// Provider cho project member box
final projectMemberBoxProvider = Provider<Box<ProjectMember>>((ref) {
  return Hive.box<ProjectMember>('project_members');
});

// ✅ LEVEL 2: StateNotifierProvider.family cho shared project management
final sharedProjectProvider = StateNotifierProvider.family<
  SharedProjectNotifier,
  List<ProjectMember>,
  String
>((ref, projectId) {
  final memberBox = ref.watch(projectMemberBoxProvider);
  final projectBox = ref.watch(enhancedProjectBoxProvider);
  final userBox = ref.watch(enhancedUserBoxProvider);
  return SharedProjectNotifier(memberBox, projectBox, userBox, projectId, ref);
});

// ✅ LEVEL 4: Provider.family cho project members
final projectMembersProvider = Provider.family<List<ProjectMember>, String>((ref, projectId) {
  final members = ref.watch(sharedProjectProvider(projectId));
  final projects = ref.watch(projectsProvider);
  final userBox = ref.watch(enhancedUserBoxProvider);

  // ✅ CRITICAL FIX: Include project owner in members list
  final project = projects.where((p) => p.id == projectId).firstOrNull;
  if (project == null) return members;

  // ✅ FIXED: Check if owner is already in members list to prevent duplication
  final hasOwnerInMembers = members.any((m) => m.userId == project.ownerId);

  if (!hasOwnerInMembers) {
    // Add project owner as first member only if not already present
    final owner = userBox.get(project.ownerId);
    if (owner != null) {
      final ownerMember = ProjectMember(
        id: 'owner_${project.ownerId}_${projectId}', // Unique ID for owner
        projectId: projectId,
        userId: project.ownerId,
        userDisplayName: owner.displayName,
        joinedAt: project.createdAt ?? DateTime.now(),
      );

      // Return owner + other members
      return [ownerMember, ...members];
    }
  }

  // ✅ FIXED: If owner is already in members list, return as-is without duplication
  return members;
});

// ✅ LEVEL 4: Provider.family cho assignable users in project
final assignableUsersInProjectProvider = Provider.family<List<User>, String>((ref, projectId) {
  final members = ref.watch(projectMembersProvider(projectId));
  final userBox = ref.watch(enhancedUserBoxProvider);
  final projects = ref.watch(projectsProvider);
  final project = projects.where((p) => p.id == projectId).firstOrNull;

  if (project == null) return [];

  // Combine owner + members
  final allUserIds = [
    project.ownerId,
    ...members.map((m) => m.userId),
  ];

  return allUserIds
      .map((userId) => userBox.get(userId))
      .where((user) => user != null)
      .cast<User>()
      .toList();
});

// ✅ LEVEL 1: Provider cho user display name by ID
final userDisplayNameProvider = Provider.family<String, String>((ref, userId) {
  final userBox = ref.watch(enhancedUserBoxProvider);
  final user = userBox.get(userId);
  return user?.displayName ?? user?.username ?? 'Unknown User';
});
