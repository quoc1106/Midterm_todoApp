# 🤝 SHARED PROJECT SYSTEM - Hệ Thống Chia Sẻ Dự Án

## ⚠️ **LƯU Ý CẤU TRÚC & LOGIC QUAN TRỌNG**

### **📁 Cấu Trúc File Hiện Tại (TUÂN THỦ):**
- **Models**: `lib/models/` - Data structures với Hive
- **Providers**: `lib/providers/` - Riverpod state management
- **Features**: `lib/features/` - UI components theo feature
- **Main**: `lib/main.dart` - Entry point

### **🔄 Logic Riverpod Bắt Buộc Áp Dụng:**
- **Level 1**: `StateProvider` cho simple states
- **Level 2**: `StateNotifierProvider` cho complex business logic
- **Level 3**: `FutureProvider` cho async operations
- **Level 4**: `Provider.family` cho parameterized data

### **📝 Quyền Hạn Đơn Giản:**
- **Tất cả members** có quyền hạn như owner: thêm, xóa, sửa, assign tasks
- **Không có phân quyền phức tạp** - chỉ cần là member là có full access

---

## 📊 **PHÂN TÍCH LUỒNG HOẠT ĐỘNG HIỆN TẠI**

### **🔐 Authentication Flow**

#### **Models Liên Quan:**
```
lib/models/user.dart (EXISTING)
├── @HiveType(typeId: 10)
├── String id (unique user identifier)
├── String username (for login)
├── String? displayName (tên hiển thị - dùng để mời)
├── String hashedPassword
└── String? email
```

#### **Providers Liên Quan:**
```
lib/providers/auth_providers.dart (EXISTING)
├── authStateProvider (StateNotifierProvider Level 2)
├── currentUserProvider (Provider Level 1)
├── isAuthenticatedProvider (Provider Level 1)
└── authInitializationProvider (FutureProvider Level 3)
```

#### **Screens & Components:**
```
lib/features/auth/ (EXISTING)
├── auth_screen.dart - Login/Register UI
├── auth_wrapper.dart - Route guard
└── auth_service.dart - Business logic
```

### **🏗️ Project & Section Flow (Current)**

#### **Models Hiện Tại:**
```
lib/models/project_model.dart (EXISTING)
├── @HiveType(typeId: 1)  
├── String id
├── String name
└── String? ownerId (single owner - CẦN MỞ RỘNG)

lib/models/section_model.dart (EXISTING)
├── @HiveType(typeId: 2)
├── String id
├── String name
├── String projectId
└── String? ownerId (single owner)

lib/models/todo_model.dart (EXISTING)
├── @HiveType(typeId: 0)
├── String id
├── String description
├── bool completed
├── DateTime? dueDate
├── String? projectId
├── String? sectionId
├── String? ownerId (task creator)
└── String? assignedToId (CẦN THÊM - WHO executes task)
```

#### **Providers Hiện Tại:**
```
lib/providers/project_providers.dart (EXISTING)
├── projectsProvider (StateNotifierProvider Level 2)
├── projectBoxProvider (Provider Level 1)
└── UserProjectListNotifier (filters by ownerId)

lib/providers/section_providers.dart (EXISTING)
├── sectionsByProjectProvider (Provider.family Level 4)
├── sectionListNotifierProvider (StateNotifierProvider Level 2)
└── UserSectionListNotifier (filters by ownerId + projectId)

lib/providers/todo_providers.dart (EXISTING)
├── todosProvider (StateNotifierProvider Level 2)
├── todoBoxProvider (Provider Level 1)
└── UserTodoListNotifier (filters by ownerId)
```

#### **UI Components Hiện Tại:**
```
lib/features/todo/ (EXISTING)
├── add_task_widget.dart - Add new tasks
├── todo_list_widget.dart - Display tasks
├── project_dropdown.dart - Select project
└── section_dropdown.dart - Select section
```

---

## 🚀 **THIẾT KẾ HỆ THỐNG SHARED PROJECT**

### **📁 CẤU TRÚC FILE MỚI CẦN TẠO**

#### **Models (Mở Rộng - Tối Thiểu):**
```
lib/models/
├── project_model.dart (UPDATE - thêm sharedUserIds field)
├── project_member.dart (NEW - quản lý members)
└── project_invitation.dart (NEW - quản lý lời mời)
```

#### **Providers (Mở Rộng):**
```
lib/providers/
├── project_providers.dart (UPDATE - thêm shared logic)
├── shared_project_providers.dart (NEW - quản lý shared projects)
└── invitation_providers.dart (NEW - quản lý invitations)
```

#### **UI Components (Thêm Mới):**
```
lib/features/todo/
├── components/
│   ├── project_team_button.dart (NEW - nút nhóm kế bên tên project)
│   ├── team_management_dialog.dart (NEW - dialog quản lý team)
│   ├── invitation_notification_button.dart (NEW - nút thông báo trong drawer)
│   ├── user_assignment_dropdown.dart (NEW - dropdown assign user)
│   └── add_member_dialog.dart (NEW - dialog thêm member)
```

---

## 🏗️ **DATA MODEL UPDATES**

### **1. 📋 Updated ProjectModel**
```dart
@HiveType(typeId: 1)
class ProjectModel {
  @HiveField(0) final String id;
  @HiveField(1) String name;
  @HiveField(2) final String? ownerId; // Chủ project ban đầu
  @HiveField(3) final List<String> sharedUserIds; // ✅ NEW: Danh sách user được share
  @HiveField(4) final DateTime createdAt;
  @HiveField(5) final DateTime? lastModified;
  
  ProjectModel({
    required this.id,
    required this.name,
    this.ownerId,
    this.sharedUserIds = const [], // ✅ NEW: Default empty
    required this.createdAt,
    this.lastModified,
  });
  
  // ✅ NEW: Business logic methods
  bool get isSharedProject => sharedUserIds.isNotEmpty;
  bool canUserAccess(String userId) => ownerId == userId || sharedUserIds.contains(userId);
  List<String> get allMembers => [if (ownerId != null) ownerId!, ...sharedUserIds];
  
  // ✅ NEW: Copy method for updates
  ProjectModel copyWith({
    String? name,
    List<String>? sharedUserIds,
    DateTime? lastModified,
  }) {
    return ProjectModel(
      id: id,
      name: name ?? this.name,
      ownerId: ownerId,
      sharedUserIds: sharedUserIds ?? this.sharedUserIds,
      createdAt: createdAt,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}
```

### **2. 👥 NEW: ProjectMember Model (Đơn Giản)**
```dart
@HiveType(typeId: 11)
class ProjectMember {
  @HiveField(0) final String id;
  @HiveField(1) final String projectId;
  @HiveField(2) final String userId;
  @HiveField(3) final String userDisplayName; // Cache tên hiển thị
  @HiveField(4) final DateTime joinedAt;
  
  ProjectMember({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.userDisplayName,
    required this.joinedAt,
  });
}
```

### **3. 📩 NEW: ProjectInvitation Model**  
```dart
@HiveType(typeId: 12)
class ProjectInvitation {
  @HiveField(0) final String id;
  @HiveField(1) final String projectId;
  @HiveField(2) final String projectName; // Cache tên project
  @HiveField(3) final String fromUserId;
  @HiveField(4) final String fromUserDisplayName; // Người gửi lời mời
  @HiveField(5) final String toUserId;
  @HiveField(6) final String toUserDisplayName; // Người nhận lời mời
  @HiveField(7) final InvitationStatus status;
  @HiveField(8) final DateTime createdAt;
  @HiveField(9) final DateTime? respondedAt;
  
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
}

@HiveType(typeId: 13)
enum InvitationStatus {
  @HiveField(0) pending,   // Đang chờ
  @HiveField(1) accepted,  // Đã chấp nhận
  @HiveField(2) declined,  // Đã từ chối
}
```

### **4. 📝 Updated TodoModel (Assignment)**
```dart
@HiveType(typeId: 0)
class Todo {
  @HiveField(0) final String id;
  @HiveField(1) final String description;
  @HiveField(2) final bool completed;
  @HiveField(3) final DateTime? dueDate;
  @HiveField(4) final String? projectId;
  @HiveField(5) final String? sectionId;
  @HiveField(6) final String? ownerId; // Người tạo task
  @HiveField(7) final String? assignedToId; // ✅ NEW: Người thực hiện task
  @HiveField(8) final String? assignedToDisplayName; // ✅ NEW: Cache tên người được assign
  
  Todo({
    required this.id,
    required this.description,
    this.completed = false,
    this.dueDate,
    this.projectId,
    this.sectionId,
    this.ownerId,
    this.assignedToId, // ✅ NEW
    this.assignedToDisplayName, // ✅ NEW
  });
  
  // ✅ NEW: Business logic
  bool get isAssigned => assignedToId != null;
  bool isAssignedTo(String userId) => assignedToId == userId;
  
  // ✅ NEW: Copy method
  Todo copyWith({
    String? description,
    bool? completed,
    DateTime? dueDate,
    String? assignedToId,
    String? assignedToDisplayName,
  }) {
    return Todo(
      id: id,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      dueDate: dueDate ?? this.dueDate,
      projectId: projectId,
      sectionId: sectionId,
      ownerId: ownerId,
      assignedToId: assignedToId ?? this.assignedToId,
      assignedToDisplayName: assignedToDisplayName ?? this.assignedToDisplayName,
    );
  }
}
```

---

## 🔄 **RIVERPOD PROVIDERS DESIGN**

### **1. 🏗️ Updated Project Providers**
```dart
// lib/providers/project_providers.dart (UPDATE)

// ✅ LEVEL 1: Provider cho accessible projects (own + shared)
final accessibleProjectsProvider = Provider<List<ProjectModel>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  final allProjects = ref.watch(projectsProvider);
  
  if (currentUser == null) return [];
  
  return allProjects.where((project) => 
    project.canUserAccess(currentUser.id)
  ).toList();
});

// ✅ LEVEL 1: Provider cho owned projects only
final ownedProjectsProvider = Provider<List<ProjectModel>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  final allProjects = ref.watch(projectsProvider);
  
  if (currentUser == null) return [];
  
  return allProjects.where((project) => project.ownerId == currentUser.id).toList();
});

// ✅ LEVEL 1: Provider cho shared projects only
final sharedWithMeProjectsProvider = Provider<List<ProjectModel>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  final allProjects = ref.watch(projectsProvider);
  
  if (currentUser == null) return [];
  
  return allProjects.where((project) => 
    project.sharedUserIds.contains(currentUser.id)
  ).toList();
});
```

### **2. 🤝 NEW: Shared Project Providers**
```dart
// lib/providers/shared_project_providers.dart (NEW)

// ✅ LEVEL 2: StateNotifierProvider cho quản lý shared projects
class SharedProjectNotifier extends StateNotifier<List<ProjectMember>> {
  final Box<ProjectMember> _memberBox;
  final Box<ProjectModel> _projectBox;
  final String projectId;
  final Ref ref;
  
  SharedProjectNotifier(this._memberBox, this._projectBox, this.projectId, this.ref) : super([]) {
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
      final userBox = Hive.box<User>('users');
      final targetUser = userBox.values.firstWhere(
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
}

final sharedProjectProvider = StateNotifierProvider.family<
  SharedProjectNotifier, 
  List<ProjectMember>, 
  String
>((ref, projectId) {
  final memberBox = Hive.box<ProjectMember>('project_members');
  final projectBox = Hive.box<ProjectModel>('projects');
  return SharedProjectNotifier(memberBox, projectBox, projectId, ref);
});

// ✅ LEVEL 4: Provider.family cho project members
final projectMembersProvider = Provider.family<List<ProjectMember>, String>((ref, projectId) {
  return ref.watch(sharedProjectProvider(projectId));
});

// ✅ LEVEL 4: Provider.family cho assignable users in project
final assignableUsersInProjectProvider = Provider.family<List<User>, String>((ref, projectId) {
  final members = ref.watch(projectMembersProvider(projectId));
  final userBox = Hive.box<User>('users');
  
  // Get project to include owner
  final projects = ref.watch(projectsProvider);
  final project = projects.firstWhere((p) => p.id == projectId);
  
  // Combine owner + members
  final allUserIds = [
    if (project.ownerId != null) project.ownerId!,
    ...members.map((m) => m.userId),
  ];
  
  return allUserIds
      .map((userId) => userBox.get(userId))
      .where((user) => user != null)
      .cast<User>()
      .toList();
});
```

### **3. 📩 NEW: Invitation Providers**
```dart
// lib/providers/invitation_providers.dart (NEW)

// ✅ LEVEL 2: StateNotifierProvider cho invitation management
class InvitationNotifier extends StateNotifier<List<ProjectInvitation>> {
  final Box<ProjectInvitation> _invitationBox;
  final Box<ProjectModel> _projectBox;
  final Box<ProjectMember> _memberBox;
  final String userId;
  
  InvitationNotifier(this._invitationBox, this._projectBox, this._memberBox, this.userId) : super([]) {
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
    final currentUser = Hive.box<User>('users').get(userId);
    if (currentUser == null) return;
    
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
  }
  
  Future<void> acceptInvitation(String invitationId) async {
    final invitation = state.firstWhere((inv) => inv.id == invitationId);
    
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
  }
  
  Future<void> declineInvitation(String invitationId) async {
    final invitation = state.firstWhere((inv) => inv.id == invitationId);
    final updatedInvitation = invitation.copyWith(
      status: InvitationStatus.declined,
      respondedAt: DateTime.now(),
    );
    await _invitationBox.put(invitationId, updatedInvitation);
    _loadUserInvitations();
  }
}

final invitationNotifierProvider = StateNotifierProvider<InvitationNotifier, List<ProjectInvitation>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  final invitationBox = Hive.box<ProjectInvitation>('project_invitations');
  final projectBox = Hive.box<ProjectModel>('projects');
  final memberBox = Hive.box<ProjectMember>('project_members');
  return InvitationNotifier(invitationBox, projectBox, memberBox, currentUser?.id ?? '');
});

// ✅ LEVEL 1: Provider cho pending invitation count
final pendingInvitationCountProvider = Provider<int>((ref) {
  final invitations = ref.watch(invitationNotifierProvider);
  return invitations.length;
});
```

---

## 🎨 **UI COMPONENT DESIGN**

### **1. 👥 Project Team Button (NEW)**
```dart
// lib/features/todo/components/project_team_button.dart
class ProjectTeamButton extends ConsumerWidget {
  final String projectId;
  final String projectName;
  
  const ProjectTeamButton({
    super.key, 
    required this.projectId,
    required this.projectName,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(projectMembersProvider(projectId));
    final project = ref.watch(projectsProvider).firstWhere((p) => p.id == projectId);
    
    // Chỉ hiển thị nếu là shared project hoặc user là owner
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null || 
        (!project.isSharedProject && project.ownerId != currentUser.id)) {
      return const SizedBox.shrink();
    }
    
    return IconButton(
      icon: Icon(
        Icons.group,
        color: project.isSharedProject ? Colors.blue : Colors.grey,
        size: 20,
      ),
      onPressed: () => _showTeamManagementDialog(context, ref),
      tooltip: 'Quản lý nhóm (${members.length + 1} thành viên)',
    );
  }
  
  void _showTeamManagementDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => TeamManagementDialog(
        projectId: projectId,
        projectName: projectName,
      ),
    );
  }
}
```

### **2. 🏢 Team Management Dialog (NEW)**
```dart
// lib/features/todo/components/team_management_dialog.dart
class TeamManagementDialog extends ConsumerStatefulWidget {
  final String projectId;
  final String projectName;
  
  const TeamManagementDialog({
    super.key,
    required this.projectId,
    required this.projectName,
  });
  
  @override
  ConsumerState<TeamManagementDialog> createState() => _TeamManagementDialogState();
}

class _TeamManagementDialogState extends ConsumerState<TeamManagementDialog> {
  final _displayNameController = TextEditingController();
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    final members = ref.watch(projectMembersProvider(widget.projectId));
    final currentUser = ref.watch(currentUserProvider);
    final project = ref.watch(projectsProvider).firstWhere((p) => p.id == widget.projectId);
    
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quản lý nhóm: ${widget.projectName}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Thêm thành viên mới
            Text('Mời thành viên mới:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      hintText: 'Nhập tên hiển thị của người dùng',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _inviteMember,
                  child: _isLoading 
                      ? const SizedBox(
                          width: 16, 
                          height: 16, 
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Mời'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Danh sách thành viên hiện tại
            Text('Thành viên hiện tại:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView(
                children: [
                  // Owner
                  if (project.ownerId != null)
                    _buildMemberTile(
                      userId: project.ownerId!,
                      displayName: _getUserDisplayName(project.ownerId!),
                      isOwner: true,
                      canRemove: false,
                    ),
                  
                  // Members
                  ...members.map((member) => _buildMemberTile(
                    userId: member.userId,
                    displayName: member.userDisplayName,
                    isOwner: false,
                    canRemove: true,
                  )),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMemberTile({
    required String userId,
    required String displayName,
    required bool isOwner,
    required bool canRemove,
  }) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(displayName.substring(0, 1).toUpperCase()),
      ),
      title: Text(displayName),
      subtitle: Text(isOwner ? 'Chủ dự án' : 'Thành viên'),
      trailing: canRemove
          ? IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: () => _removeMember(userId, displayName),
            )
          : null,
    );
  }
  
  String _getUserDisplayName(String userId) {
    final userBox = Hive.box<User>('users');
    final user = userBox.get(userId);
    return user?.displayName ?? user?.username ?? 'Unknown';
  }
  
  Future<void> _inviteMember() async {
    if (_displayNameController.text.trim().isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      await ref.read(sharedProjectProvider(widget.projectId).notifier)
          .addMemberByDisplayName(_displayNameController.text.trim());
      
      _displayNameController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi lời mời thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<void> _removeMember(String userId, String displayName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text('Bạn có chắc muốn xóa $displayName khỏi dự án?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await ref.read(sharedProjectProvider(widget.projectId).notifier)
            .removeMember(userId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã xóa $displayName khỏi dự án')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${e.toString()}')),
          );
        }
      }
    }
  }
  
  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }
}
```

### **3. 🔔 Invitation Notification Button (NEW)**
```dart
// lib/features/todo/components/invitation_notification_button.dart
class InvitationNotificationButton extends ConsumerWidget {
  const InvitationNotificationButton({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(pendingInvitationCountProvider);
    
    return IconButton(
      icon: Badge(
        isLabelVisible: pendingCount > 0,
        label: Text('$pendingCount'),
        child: const Icon(Icons.notifications),
      ),
      onPressed: () => _showInvitationsDialog(context, ref),
      tooltip: pendingCount > 0 
          ? '$pendingCount lời mời đang chờ'
          : 'Không có lời mời nào',
    );
  }
  
  void _showInvitationsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const InvitationListDialog(),
    );
  }
}

class InvitationListDialog extends ConsumerWidget {
  const InvitationListDialog({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitations = ref.watch(invitationNotifierProvider);
    
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lời mời tham gia dự án',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            if (invitations.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text('Không có lời mời nào'),
                ),
              )
            else
              Container(
                height: 300,
                child: ListView.builder(
                  itemCount: invitations.length,
                  itemBuilder: (context, index) {
                    final invitation = invitations[index];
                    return _buildInvitationTile(context, ref, invitation);
                  },
                ),
              ),
            
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInvitationTile(BuildContext context, WidgetRef ref, ProjectInvitation invitation) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              invitation.projectName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text('Từ: ${invitation.fromUserDisplayName}'),
            Text('Thời gian: ${_formatDateTime(invitation.createdAt)}'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _declineInvitation(context, ref, invitation.id),
                  child: const Text('Từ chối'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _acceptInvitation(context, ref, invitation.id),
                  child: const Text('Chấp nhận'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  Future<void> _acceptInvitation(BuildContext context, WidgetRef ref, String invitationId) async {
    try {
      await ref.read(invitationNotifierProvider.notifier).acceptInvitation(invitationId);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã chấp nhận lời mời!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }
  
  Future<void> _declineInvitation(BuildContext context, WidgetRef ref, String invitationId) async {
    try {
      await ref.read(invitationNotifierProvider.notifier).declineInvitation(invitationId);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã từ chối lời mời!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }
}
```

### **4. 👤 User Assignment Dropdown (NEW)**
```dart
// lib/features/todo/components/user_assignment_dropdown.dart
class UserAssignmentDropdown extends ConsumerWidget {
  final String? projectId;
  final String? currentAssigneeId;
  final void Function(String? userId, String? displayName) onAssignmentChanged;
  
  const UserAssignmentDropdown({
    super.key,
    this.projectId,
    this.currentAssigneeId,
    required this.onAssignmentChanged,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (projectId == null) return const SizedBox.shrink();
    
    final assignableUsers = ref.watch(assignableUsersInProjectProvider(projectId!));
    
    // Chỉ hiển thị nếu có ít nhất 2 users (để có thể assign)
    if (assignableUsers.length < 2) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Giao việc cho:',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String?>(
          value: currentAssigneeId,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          hint: const Text('Chọn người thực hiện'),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Không giao cho ai'),
            ),
            ...assignableUsers.map((user) => DropdownMenuItem(
              value: user.id,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    child: Text(
                      (user.displayName ?? user.username).substring(0, 1).toUpperCase(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(user.displayName ?? user.username),
                  ),
                ],
              ),
            )),
          ],
          onChanged: (userId) {
            final selectedUser = userId != null 
                ? assignableUsers.firstWhere((u) => u.id == userId)
                : null;
            onAssignmentChanged(userId, selectedUser?.displayName ?? selectedUser?.username);
          },
        ),
      ],
    );
  }
}
```

---

## 📱 **UI INTEGRATION POINTS**

### **1. 🔧 App Drawer Updates**
```dart
// lib/main.dart hoặc app_drawer.dart (UPDATE)
class AppDrawer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    
    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(currentUser?.displayName ?? currentUser?.username ?? 'Guest'),
            accountEmail: Text(currentUser?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              child: Text(
                (currentUser?.displayName ?? currentUser?.username ?? 'G')
                    .substring(0, 1).toUpperCase(),
              ),
            ),
            // ✅ NEW: Thêm notification button
            otherAccountsPictures: [
              const InvitationNotificationButton(),
            ],
          ),
          // ... rest of drawer items
        ],
      ),
    );
  }
}
```

### **2. 🏗️ Project Display Updates** 
```dart
// lib/features/todo/project_dropdown.dart hoặc project list widgets (UPDATE)
class ProjectListTile extends ConsumerWidget {
  final ProjectModel project;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final isSharedWithMe = project.sharedUserIds.contains(currentUser?.id);
    
    return ListTile(
      title: Row(
        children: [
          Expanded(child: Text(project.name)),
          
          // ✅ NEW: Shared project indicator
          if (isSharedWithMe)
            const Icon(Icons.share, size: 16, color: Colors.green),
          
          // ✅ NEW: Team management button
          ProjectTeamButton(
            projectId: project.id,
            projectName: project.name,
          ),
        ],
      ),
      subtitle: isSharedWithMe 
          ? Text('Được chia sẻ bởi: ${_getOwnerDisplayName(project.ownerId)}')
          : null,
      // ... rest of tile content
    );
  }
  
  String _getOwnerDisplayName(String? ownerId) {
    if (ownerId == null) return 'Unknown';
    final userBox = Hive.box<User>('users');
    final owner = userBox.get(ownerId);
    return owner?.displayName ?? owner?.username ?? 'Unknown';
  }
}
```

### **3. 📝 Add Task Widget Updates**
```dart
// lib/features/todo/add_task_widget.dart (UPDATE)
class AddTaskWidget extends ConsumerStatefulWidget {
  // ... existing fields
  String? _selectedAssigneeId;
  String? _selectedAssigneeDisplayName;
  
  @override
  Widget build(BuildContext context) {
    final selectedProjectId = _useLocalState 
        ? _localProjectId 
        : ref.watch(newTodoProjectIdProvider);
    
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ... existing task description field
            
            // ... existing project dropdown
            
            // ... existing section dropdown
            
            // ✅ NEW: Assignment dropdown (chỉ hiển thị trong shared projects)
            if (selectedProjectId != null)
              UserAssignmentDropdown(
                projectId: selectedProjectId,
                currentAssigneeId: _selectedAssigneeId,
                onAssignmentChanged: (userId, displayName) {
                  setState(() {
                    _selectedAssigneeId = userId;
                    _selectedAssigneeDisplayName = displayName;
                  });
                },
              ),
            
            const SizedBox(height: 16),
            
            // ... existing save/cancel buttons
          ],
        ),
      ),
    );
  }
  
  void _saveTodo() {
    // ... existing validation
    
    final newTodo = Todo(
      id: const Uuid().v4(),
      description: _taskController.text,
      // ... existing fields
      assignedToId: _selectedAssigneeId, // ✅ NEW
      assignedToDisplayName: _selectedAssigneeDisplayName, // ✅ NEW
    );
    
    ref.read(todosProvider.notifier).addTodo(newTodo);
    Navigator.of(context).pop();
  }
}
```

---

## 🔄 **IMPLEMENTATION ROADMAP**

### **Phase 1: Models & Providers (Tuần 1)**
- [ ] Update `ProjectModel` với `sharedUserIds` field
- [ ] Create `ProjectMember` và `ProjectInvitation` models
- [ ] Update `Todo` model với assignment fields
- [ ] Run `build_runner` để generate Hive adapters
- [ ] Create shared project providers

### **Phase 2: Core Features (Tuần 2)**  
- [ ] Implement invitation system providers
- [ ] Create team management UI components
- [ ] Add notification button to app drawer
- [ ] Update project display với team indicators

### **Phase 3: Integration (Tuần 3)**
- [ ] Update Add Task Widget với assignment dropdown
- [ ] Implement invitation acceptance/decline flow
- [ ] Add user search và invite functionality
- [ ] Test full collaboration workflow

### **Phase 4: Polish (Tuần 4)**
- [ ] Add error handling và edge cases
- [ ] Optimize performance cho shared projects
- [ ] Add loading states và user feedback
- [ ] Testing và bug fixes

---

## 🧪 **TESTING WORKFLOW**

### **Collaboration Flow Test:**
1. **User A** (owner) tạo project "Dự án chung"
2. **User A** click nút team button và nhập displayName của **User B**
3. **User B** thấy notification badge và accept invitation
4. **User A** tạo task trong section và assign cho **User B**
5. **User B** thấy task được assign trong shared project

### **Permission Test:**
1. **Owner** và **Members** đều có quyền như nhau (full access)
2. **Members** có thể invite thêm users khác
3. **Members** có thể assign tasks cho nhau
4. **Members** có thể xóa nhau khỏi project

### **Data Separation Test:**
1. Shared project data chỉ visible cho members
2. Private projects không appear cho non-members
3. User assignment chỉ show project members
4. Invitations chỉ gửi cho relevant users

---

## 📋 **SUCCESS CRITERIA**

✅ **User có thể mời others bằng displayName**  
✅ **Project hiển thị team icon khi có members**  
✅ **App drawer có notification badge cho invitations**  
✅ **Add Task Widget có assignment dropdown trong shared projects**  
✅ **Tất cả members có quyền hạn như owner**  
✅ **Data separation được maintained giữa users**  
✅ **UI/UX đơn giản và dễ sử dụng**

---

*Đây là thiết kế **đơn giản** cho Shared Project System tuân thủ cấu trúc file và Riverpod patterns hiện tại. System này cho phép chia sẻ projects một cách dễ dàng với quyền hạn đều nhau cho tất cả members.*