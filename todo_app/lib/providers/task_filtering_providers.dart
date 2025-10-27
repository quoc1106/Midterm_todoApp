/// 🎯 TASK FILTERING PROVIDERS - Providers cho member-based task filtering
///
/// ⭐ RIVERPOD LEVEL 2-4 DEMONSTRATION ⭐
/// Providers để filter tasks theo assigned member, count tasks, và unassigned tasks

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../backend/models/todo_model.dart';
import '../backend/models/user.dart';
import 'todo_providers.dart';
import 'shared_project_providers.dart';

/// ✅ LEVEL 1: StateProvider - Track selected member for filtering
final selectedMemberFilterProvider = StateProvider<String?>((ref) => null);

/// ✅ LEVEL 4: Provider.family - Count tasks per user in a project
final userTaskCountProvider = Provider.family<int, String>((ref, userId) {
  final todos = ref.watch(todoListProvider);
  return todos.where((todo) => todo.assignedToId == userId).length;
});

/// ✅ LEVEL 4: Provider.family - Count unassigned tasks in a project
final unassignedTaskCountProvider = Provider.family<int, String>((ref, projectId) {
  final todos = ref.watch(todoListProvider);
  return todos.where((todo) =>
    todo.projectId == projectId && todo.assignedToId == null
  ).length;
});

/// ✅ LEVEL 4: Provider.family - Filter tasks by selected member in project
final filteredTasksByMemberProvider = Provider.family<List<Todo>, String>((ref, projectId) {
  final allTodos = ref.watch(todoListProvider);
  final selectedFilter = ref.watch(selectedMemberFilterProvider);

  // Base filter: tasks in the specified project
  final projectTodos = allTodos.where((todo) => todo.projectId == projectId).toList();

  // If no filter selected, return all project tasks
  if (selectedFilter == null) {
    return projectTodos;
  }

  // Filter by unassigned tasks
  if (selectedFilter == 'unassigned') {
    return projectTodos.where((todo) => todo.assignedToId == null).toList();
  }

  // Filter by specific user
  return projectTodos.where((todo) => todo.assignedToId == selectedFilter).toList();
});

/// ✅ LEVEL 4: Provider.family - Get task count for specific user in project
final userTaskCountInProjectProvider = Provider.family<int, Map<String, String>>((ref, params) {
  final projectId = params['projectId']!;
  final userId = params['userId']!;

  final todos = ref.watch(todoListProvider);
  return todos.where((todo) =>
    todo.projectId == projectId &&
    todo.assignedToId == userId
  ).length;
});

/// ✅ LEVEL 1: Helper provider for clearing member filter
final clearMemberFilterProvider = Provider<void Function()>((ref) {
  return () {
    ref.read(selectedMemberFilterProvider.notifier).state = null;
  };
});

/// ✅ LEVEL 1: Helper provider for setting member filter
final setMemberFilterProvider = Provider<void Function(String?)>((ref) {
  return (String? memberId) {
    ref.read(selectedMemberFilterProvider.notifier).state = memberId;
  };
});
