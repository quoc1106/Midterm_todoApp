import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../backend/models/section_model.dart';
import '../backend/models/todo_model.dart';
import '../backend/models/project_model.dart'; // ✅ NEW: Import project model
import 'todo_providers.dart';
import 'performance_initialization_providers.dart';
import 'auth_providers.dart'; // 🔧 USER SEPARATION: Import auth providers

// 🔧 USER SEPARATION: Provider lấy danh sách task theo sectionId với user filtering
final tasksBySectionProvider = Provider.family<List<Todo>, String>((
  ref,
  sectionId,
) {
  final todos = ref.watch(todoListProvider);
  final currentUserId = ref.watch(currentUserProvider)?.id;

  return todos
      .where((todo) =>
          todo.sectionId == sectionId &&
          !todo.completed &&
          todo.ownerId == currentUserId) // 🔧 USER SEPARATION: Filter by owner
      .toList();
});

// 🔧 USER SEPARATION: Provider lấy tất cả sections của current user (for search)
final allSectionsProvider = Provider<List<SectionModel>>((ref) {
  final box = ref.watch(enhancedSectionBoxProvider);
  final projectBox = ref.watch(enhancedProjectBoxProvider); // ✅ NEW: Watch project box
  final currentUserId = ref.watch(currentUserProvider)?.id;

  if (currentUserId == null) {
    return box.values.toList(); // Guest mode
  }

  // ✅ FIXED: Include sections from shared projects
  return box.values
      .where((section) {
        // Always include own sections
        if (section.ownerId == currentUserId) return true;

        // Include sections from shared projects where user has access
        final project = projectBox.get(section.projectId);
        if (project != null && project.canUserAccess(currentUserId)) {
          return true;
        }

        return false;
      })
      .toList();
});

// 🔧 SHARED PROJECT LOGIC: Provider lấy danh sách sections theo projectId với shared project support
final sectionsByProjectProvider = Provider.family<List<SectionModel>, String>((
  ref,
  projectId,
) {
  final box = ref.watch(enhancedSectionBoxProvider);
  final projectBox = ref.watch(enhancedProjectBoxProvider); // ✅ NEW: Watch project box
  final currentUserId = ref.watch(currentUserProvider)?.id;

  if (currentUserId == null) {
    return box.values.where((s) => s.projectId == projectId).toList(); // Guest mode
  }

  // ✅ FIXED: Check if user has access to this project
  final project = projectBox.get(projectId);
  if (project == null || !project.canUserAccess(currentUserId)) {
    return []; // No access to project
  }

  // ✅ FIXED: Return ALL sections in the project that user has access to
  return box.values
      .where((s) => s.projectId == projectId)
      .toList();
});

class SectionListNotifier extends StateNotifier<List<SectionModel>> {
  final Box<SectionModel> _box;
  final Box<ProjectModel> _projectBox; // ✅ NEW: Add project box
  final String _projectId;
  final Ref _ref;
  String? _currentUserId;

  SectionListNotifier(this._box, this._projectBox, this._projectId, this._ref) : super([]) {
    // 🔧 USER SEPARATION: Initialize với current user
    _currentUserId = _ref.read(currentUserProvider)?.id;
    print('🔍 SectionListNotifier initialized for project: $_projectId, user: $_currentUserId');
    _filterByProjectAccess();
  }

  // ✅ FIXED: Filter sections theo project access (bao gồm shared projects)
  void _filterByProjectAccess() {
    if (_currentUserId == null) {
      final sections = _box.values.where((s) => s.projectId == _projectId).toList();
      print('🔍 _filterByProjectAccess: ownerId=null, found ${sections.length} sections');
      state = sections; // Guest mode
    } else {
      // ✅ FIXED: Check if user has access to this project
      final project = _projectBox.get(_projectId);
      if (project == null || !project.canUserAccess(_currentUserId!)) {
        print('🔍 _filterByProjectAccess: User has no access to project $_projectId');
        state = [];
        return;
      }

      // ✅ FIXED: Return ALL sections in the project that user has access to
      final projectSections = _box.values
          .where((s) => s.projectId == _projectId)
          .toList();
      print('🔍 _filterByProjectAccess: User has access to project $_projectId, found ${projectSections.length} sections');
      state = projectSections;
    }
  }

  // 🔧 USER SEPARATION: Update user khi auth state thay đổi
  void updateCurrentUser(String? userId) {
    print('🔍 SectionListNotifier updateCurrentUser: $_currentUserId -> $userId');
    _currentUserId = userId;
    _filterByProjectAccess();
  }

  void addSection(String name) {
    if (_currentUserId == null) {
      print('❌ Cannot add section: No current user');
      return;
    }

    // ✅ FIXED: Check if user can add sections to this project
    final project = _projectBox.get(_projectId);
    if (project == null || !project.canUserAccess(_currentUserId!)) {
      print('❌ Cannot add section: User has no access to project $_projectId');
      return;
    }

    final section = SectionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      projectId: _projectId,
      ownerId: _currentUserId!, // 🔧 USER SEPARATION: Set owner
    );
    _box.put(section.id, section);
    print('🔍 Adding section for user: $_currentUserId, project: $_projectId');
    _filterByProjectAccess(); // ✅ FIXED: Use new filter method

    // ✅ RIVERPOD FIX: Invalidate related providers để force refresh UI
    try {
      // Force refresh section-related providers
      _ref.invalidate(sectionsByProjectProvider(_projectId));
      _ref.invalidate(allSectionsProvider);

      print('🔄 Invalidated section providers after adding section');
    } catch (e) {
      print('⚠️ Error invalidating section providers: $e');
    }
  }

  void updateSection(String id, String name) {
    final section = _box.get(id);
    if (section != null &&
        section.projectId == _projectId &&
        section.ownerId == _currentUserId) { // 🔧 USER SEPARATION: Check owner
      section.name = name;
      _box.put(id, section);
      _filterByProjectAccess(); // ✅ FIXED: Use new filter method

      // ✅ RIVERPOD FIX: Invalidate providers after update
      try {
        _ref.invalidate(sectionsByProjectProvider(_projectId));
        _ref.invalidate(allSectionsProvider);
        print('🔄 Invalidated section providers after updating section');
      } catch (e) {
        print('⚠️ Error invalidating section providers: $e');
      }
    } else {
      print('❌ Cannot update section: Not owned by current user or wrong project');
    }
  }

  void deleteSection(String id) {
    final section = _box.get(id);
    if (section == null ||
        section.projectId != _projectId ||
        section.ownerId != _currentUserId) { // 🔧 USER SEPARATION: Check owner
      print('❌ Cannot delete section: Not owned by current user or wrong project');
      return;
    }

    // 🔧 USER SEPARATION: Delete only todos belonging to current user in this section
    print('🔍 Deleting section $id and associated todos for user: $_currentUserId');
    final todoBox = _ref.read(enhancedTodoBoxProvider);

    final todosToDelete = todoBox.values
        .where((todo) =>
            todo.sectionId == id &&
            todo.ownerId == _currentUserId) // 🔧 USER SEPARATION: Only current user's todos
        .toList();

    print('🔍 Found ${todosToDelete.length} todos to delete in section $id for user: $_currentUserId');

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

    // Xóa section
    _box.delete(id);
    _filterByProjectAccess(); // ✅ FIXED: Use new filter method

    // ✅ RIVERPOD FIX: Invalidate providers after delete
    try {
      _ref.invalidate(sectionsByProjectProvider(_projectId));
      _ref.invalidate(allSectionsProvider);
      _ref.invalidate(todoListProvider); // Also refresh todos since we deleted some
      print('🔄 Invalidated providers after deleting section');
    } catch (e) {
      print('⚠️ Error invalidating providers: $e');
    }
  }
}

// ✅ FIXED: Updated provider với project box support
final sectionListNotifierProvider = StateNotifierProvider.family<SectionListNotifier, List<SectionModel>, String>((ref, projectId) {
  final box = ref.watch(enhancedSectionBoxProvider);
  final projectBox = ref.watch(enhancedProjectBoxProvider); // ✅ NEW: Watch project box
  return SectionListNotifier(box, projectBox, projectId, ref);
});
