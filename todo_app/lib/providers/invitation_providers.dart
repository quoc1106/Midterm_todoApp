/// 🔧 INVITATION PROVIDERS - Quản lý invitation logic
///
/// Level 2: StateNotifierProvider cho invitation management
/// Level 1: Provider cho computed data
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../backend/models/project_invitation.dart';
import '../backend/models/project_member.dart';
import '../backend/models/project_model.dart';
import '../backend/models/user.dart';
import 'auth_providers.dart';
import 'performance_initialization_providers.dart';
import 'shared_project_providers.dart';
import 'project_providers.dart'; // ✅ ADD: Import để access projectListProvider và accessibleProjectsProvider

// ✅ LEVEL 2: StateNotifierProvider cho invitation management
class InvitationNotifier extends StateNotifier<List<ProjectInvitation>> {
  final Box<ProjectInvitation> _invitationBox;
  final Box<ProjectModel> _projectBox;
  final Box<ProjectMember> _memberBox;
  final Box<User> _userBox;
  final String userId;
  final Ref _ref; // ✅ ADD: Ref để invalidate providers

  InvitationNotifier(
    this._invitationBox,
    this._projectBox,
    this._memberBox,
    this._userBox,
    this.userId,
    this._ref, // ✅ ADD: Inject Ref
  ) : super([]) {
    _loadUserInvitations();
  }

  void _loadUserInvitations() {
    final invitations = _invitationBox.values
        .where((inv) => inv.toUserId == userId && inv.status == InvitationStatus.pending)
        .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = invitations;
  }

  Future<void> sendInvitation({
    required String projectId,
    required String projectName,
    required String toUserId,
    required String toUserDisplayName,
  }) async {
    final currentUser = _userBox.get(userId);
    if (currentUser == null) return;

    // Check if invitation already exists
    ProjectInvitation? existingInvitation;
    try {
      existingInvitation = _invitationBox.values.firstWhere(
        (inv) => inv.projectId == projectId &&
                 inv.toUserId == toUserId &&
                 inv.status == InvitationStatus.pending,
      );
    } catch (e) {
      // No existing invitation found, this is fine
      existingInvitation = null;
    }

    if (existingInvitation != null) {
      throw Exception('Lời mời đã được gửi cho người dùng này');
    }

    // Create new invitation
    final invitation = ProjectInvitation(
      id: const Uuid().v4(),
      projectId: projectId,
      projectName: projectName,
      fromUserId: userId,
      fromUserDisplayName: currentUser.displayName ?? currentUser.username,
      toUserId: toUserId,
      toUserDisplayName: toUserDisplayName,
      status: InvitationStatus.pending,
      createdAt: DateTime.now(),
    );

    await _invitationBox.put(invitation.id, invitation);
    print('✅ Invitation sent successfully to $toUserDisplayName');
  }

  Future<void> acceptInvitation(String invitationId) async {
    final invitation = _invitationBox.get(invitationId);
    if (invitation == null || invitation.toUserId != userId) return;

    // Update invitation status
    final updatedInvitation = invitation.copyWith(
      status: InvitationStatus.accepted,
      respondedAt: DateTime.now(),
    );
    await _invitationBox.put(invitationId, updatedInvitation);

    // Add user to project.sharedUserIds
    final project = _projectBox.get(invitation.projectId);
    if (project != null) {
      final updatedSharedUserIds = [...project.sharedUserIds, invitation.toUserId];
      final updatedProject = project.copyWith(
        sharedUserIds: updatedSharedUserIds,
        lastModified: DateTime.now(),
      );
      await _projectBox.put(project.id, updatedProject);
    }

    // Create ProjectMember record
    final member = ProjectMember(
      id: const Uuid().v4(),
      projectId: invitation.projectId,
      userId: invitation.toUserId,
      userDisplayName: invitation.toUserDisplayName,
      joinedAt: DateTime.now(),
    );
    await _memberBox.put(member.id, member);

    _loadUserInvitations();

    // ✅ RIVERPOD FIX: Invalidate related providers để force refresh
    try {
      // Force refresh project list để hiển thị shared project mới
      _ref.invalidate(projectsProvider);
      _ref.invalidate(accessibleProjectsProvider);

      // Force refresh shared project providers
      _ref.invalidate(sharedProjectProvider(invitation.projectId));
      _ref.invalidate(projectMembersProvider(invitation.projectId));

      print('🔄 Invalidated providers after accepting invitation');
    } catch (e) {
      print('⚠️ Error invalidating providers: $e');
    }
  }

  Future<void> declineInvitation(String invitationId) async {
    final invitation = _invitationBox.get(invitationId);
    if (invitation == null || invitation.toUserId != userId) return;

    final updatedInvitation = invitation.copyWith(
      status: InvitationStatus.declined,
      respondedAt: DateTime.now(),
    );
    await _invitationBox.put(invitationId, updatedInvitation);
    _loadUserInvitations();
  }
}

// Provider cho invitation box - Updated to use enhanced provider
final projectInvitationBoxProvider = Provider<Box<ProjectInvitation>>((ref) {
  return ref.watch(enhancedProjectInvitationBoxProvider);
});

// Provider cho project member box - Updated to use enhanced provider
final projectMemberBoxProvider = Provider<Box<ProjectMember>>((ref) {
  return ref.watch(enhancedProjectMemberBoxProvider);
});

// ✅ LEVEL 2: StateNotifierProvider cho invitation management - UPDATED with Ref injection
final invitationNotifierProvider = StateNotifierProvider<InvitationNotifier, List<ProjectInvitation>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  final invitationBox = ref.watch(projectInvitationBoxProvider);
  final projectBox = ref.watch(enhancedProjectBoxProvider);
  final memberBox = ref.watch(projectMemberBoxProvider);
  final userBox = ref.watch(enhancedUserBoxProvider);
  return InvitationNotifier(
    invitationBox,
    projectBox,
    memberBox,
    userBox,
    currentUser?.id ?? '',
    ref, // ✅ Inject ref để có thể invalidate providers
  );
});

// ✅ LEVEL 1: Provider cho pending invitation count
final pendingInvitationCountProvider = Provider<int>((ref) {
  final invitations = ref.watch(invitationNotifierProvider);
  return invitations.length;
});

// ✅ LEVEL 1: Provider cho all invitations (including responded ones)
final allUserInvitationsProvider = Provider<List<ProjectInvitation>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  final invitationBox = ref.watch(projectInvitationBoxProvider);

  if (currentUser == null) return [];

  return invitationBox.values
      .where((inv) => inv.toUserId == currentUser.id)
      .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});
