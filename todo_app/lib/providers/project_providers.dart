import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../backend/models/project_model.dart';
import 'performance_initialization_providers.dart';
import 'todo_providers.dart'; // Import để access todoListProvider
import 'selection_validation_providers.dart'; // Import validation providers
import 'auth_providers.dart'; // 🔧 USER SEPARATION: Import auth providers

// Updated to use enhanced initialization provider với performance monitoring

class ProjectListNotifier extends StateNotifier<List<ProjectModel>> {
  final Box<ProjectModel> _box;
  final Ref _ref;
  String? _currentUserId;

  ProjectListNotifier(this._box, this._ref) : super([]) {
    // 🔧 USER SEPARATION: Initialize với current user
    _currentUserId = _ref.read(currentUserProvider)?.id;
    print('🔍 ProjectListNotifier initialized for user: $_currentUserId');
    print('🔍 Total projects in box: ${_box.length}');
    _filterByOwner();
  }

  // 🔧 USER SEPARATION: Filter projects theo owner và shared access
  void _filterByOwner() {
    if (_currentUserId == null) {
      print('🔍 _filterByOwner: ownerId=null, found ${_box.length} projects');
      state = _box.values.toList(); // Guest mode - hiện tất cả (legacy support)
    } else {
      // ✅ NEW: Include both owned và shared projects
      final accessibleProjects = _box.values
          .where((project) => project.canUserAccess(_currentUserId!))
          .toList();
      print('🔍 _filterByOwner: userId=$_currentUserId, found ${accessibleProjects.length} accessible projects');
      state = accessibleProjects;
    }
  }

  // 🔧 USER SEPARATION: Update user khi auth state thay đổi
  void updateCurrentUser(String? userId) {
    print('🔍 ProjectListNotifier updateCurrentUser: $_currentUserId -> $userId');
    _currentUserId = userId;
    _filterByOwner();
  }

  void addProject(String name) {
    if (_currentUserId == null) {
      print('❌ Cannot add project: No current user');
      return;
    }

    final project = ProjectModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      ownerId: _currentUserId!, // 🔧 USER SEPARATION: Set owner
      createdAt: DateTime.now(), // ✅ NEW: Add required createdAt parameter
    );
    _box.put(project.id, project);
    print('🔍 Adding project for user: $_currentUserId');
    _filterByOwner(); // Update state với filtering
  }

  void updateProject(String id, String name) {
    final project = _box.get(id);
    if (project != null && project.ownerId == _currentUserId) { // 🔧 USER SEPARATION: Check owner
      project.name = name;
      _box.put(id, project);
      _filterByOwner(); // Update state với filtering
    } else {
      print('❌ Cannot update project: Not owned by current user');
    }
  }

  void deleteProject(String id) {
    final project = _box.get(id);
    if (project == null || project.ownerId != _currentUserId) { // 🔧 USER SEPARATION: Check owner
      print('❌ Cannot delete project: Not owned by current user');
      return;
    }

    // 🔧 USER SEPARATION: Cascade delete - chỉ xóa data của current user
    final todoBox = _ref.read(enhancedTodoBoxProvider);
    final todosToDelete = todoBox.values
        .where((todo) => todo.projectId == id && todo.ownerId == _currentUserId)
        .toList();

    print('🔍 Deleting project $id and ${todosToDelete.length} related todos for user: $_currentUserId');

    // Xóa todos bằng key để tránh lỗi
    for (final todo in todosToDelete) {
      final todoKeys = todoBox.keys.toList();
      for (final key in todoKeys) {
        final todoValue = todoBox.get(key);
        if (todoValue?.id == todo.id && todoValue?.ownerId == _currentUserId) {
          todoBox.delete(key);
        }
      }
    }

    // Xóa project
    _box.delete(id);
    _filterByOwner(); // Update state với filtering
  }
}

final projectsProvider =
    StateNotifierProvider<ProjectListNotifier, List<ProjectModel>>((ref) {
      final box = ref.watch(enhancedProjectBoxProvider);
      return ProjectListNotifier(box, ref);
    });

// ✅ NEW: Provider cho accessible projects (own + shared)
final accessibleProjectsProvider = Provider<List<ProjectModel>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  final allProjects = ref.watch(projectsProvider);

  if (currentUser == null) return [];

  return allProjects.where((project) =>
    project.canUserAccess(currentUser.id)
  ).toList();
});

// ✅ NEW: Provider cho owned projects only
final ownedProjectsProvider = Provider<List<ProjectModel>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  final allProjects = ref.watch(projectsProvider);

  if (currentUser == null) return [];

  return allProjects.where((project) => project.ownerId == currentUser.id).toList();
});

// ✅ NEW: Provider cho shared projects only
final sharedWithMeProjectsProvider = Provider<List<ProjectModel>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  final allProjects = ref.watch(projectsProvider);

  if (currentUser == null) return [];

  return allProjects.where((project) =>
    project.sharedUserIds.contains(currentUser.id)
  ).toList();
});

// ✅ NEW: Provider.family để check if project is shared
final isSharedProjectProvider = Provider.family<bool, String>((ref, projectId) {
  final projects = ref.watch(projectsProvider);
  final project = projects.where((p) => p.id == projectId).firstOrNull;
  return project?.isSharedProject ?? false;
});

// ✅ NEW: Provider.family để check if current user can invite
final canCurrentUserInviteProvider = Provider.family<bool, String>((ref, projectId) {
  final currentUser = ref.watch(currentUserProvider);
  final projects = ref.watch(projectsProvider);
  final project = projects.where((p) => p.id == projectId).firstOrNull;

  return currentUser != null &&
         project != null &&
         project.canUserInvite(currentUser.id);
});
