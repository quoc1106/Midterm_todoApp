/// 🎯 TASK FILTERING PROVIDERS - Providers cho member-based task filtering
///
/// ⭐ RIVERPOD LEVEL 2-4 DEMONSTRATION ⭐
/// Providers để filter tasks theo assigned member, count tasks, và unassigned tasks

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../backend/models/todo_model.dart';
import '../backend/models/user.dart';
import 'todo_providers.dart';
import 'shared_project_providers.dart';
import 'task_update_notification_providers.dart'; // ✅ NEW: Import notification system

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

  final projectTodos = ref.watch(projectTodosProvider);
  return projectTodos.where((todo) =>
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

/// ✅ NEW: Provider.family - Project tasks with optional member filtering for shared projects
/// This provider shows ALL tasks in project for collaboration, with optional member filtering
final projectTasksWithFilterProvider = Provider.family<List<Todo>, String>((ref, projectId) {
  // Use projectTodosProvider to get ALL tasks in accessible projects
  final allProjectTodos = ref.watch(projectTodosProvider);
  final selectedFilter = ref.watch(selectedMemberFilterProvider);

  // Base filter: tasks in the specified project
  final projectTodos = allProjectTodos.where((todo) => todo.projectId == projectId).toList();

  // If no filter selected, return all project tasks (for shared workspace collaboration)
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

/// ✅ ENHANCED: Provider to get unassigned task count in project with reactive updates
final reactiveUnassignedTaskCountProvider = Provider.family<int, String>((ref, projectId) {
  // Use projectTodosProvider to ensure we see ALL tasks in shared projects
  final allProjectTodos = ref.watch(projectTodosProvider);
  return allProjectTodos.where((todo) =>
    todo.projectId == projectId &&
    todo.assignedToId == null &&
    !todo.completed
  ).length;
});

/// ✅ ENHANCED: Provider to get task count for user in project with reactive updates
final reactiveUserTaskCountInProjectProvider = Provider.family<int, Map<String, String>>((ref, params) {
  final projectId = params['projectId']!;
  final userId = params['userId']!;

  // Use projectTodosProvider to ensure we see ALL tasks in shared projects
  final allProjectTodos = ref.watch(projectTodosProvider);
  return allProjectTodos.where((todo) =>
    todo.projectId == projectId &&
    todo.assignedToId == userId &&
    !todo.completed
  ).length;
});

/// ✅ NEW: Provider for project section Today view filtering
final projectSectionTodayFilterProvider = StateProvider<String?>((ref) => null);

/// ✅ NEW: Provider to get today's tasks in a specific project with filtering
final projectSectionTodayTasksProvider = Provider.family<List<Todo>, String>((ref, projectId) {
  // ✅ CRITICAL FIX: Watch projectTodosProvider instead of todoListProvider for shared projects
  final projectTodos = ref.watch(projectTodosProvider);
  final selectedFilter = ref.watch(projectSectionTodayFilterProvider);

  // First filter by project and today's date
  final todayTasks = projectTodos.where((todo) {
    if (todo.projectId != projectId || todo.completed) return false;
    if (todo.dueDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todoDate = DateTime(todo.dueDate!.year, todo.dueDate!.month, todo.dueDate!.day);

    return todoDate.isAtSameMomentAs(today);
  }).toList();

  // Then apply member filter if selected
  if (selectedFilter == null) {
    return todayTasks; // Show all today tasks
  }

  if (selectedFilter == 'unassigned') {
    return todayTasks.where((todo) => todo.assignedToId == null).toList();
  }

  // Filter by specific member
  return todayTasks.where((todo) => todo.assignedToId == selectedFilter).toList();
});

/// ✅ ENHANCED: Provider to count today's unassigned tasks in project with real-time updates
final projectSectionTodayUnassignedCountProvider = Provider.family<int, String>((ref, projectId) {
  // ✅ CRITICAL FIX: Use projectTodosProvider for real-time updates
  final projectTodos = ref.watch(projectTodosProvider);

  // Filter for today's unassigned tasks in this project
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  return projectTodos.where((todo) {
    if (todo.projectId != projectId || todo.completed) return false;
    if (todo.dueDate == null || todo.assignedToId != null) return false;

    final todoDate = DateTime(todo.dueDate!.year, todo.dueDate!.month, todo.dueDate!.day);
    return todoDate.isAtSameMomentAs(today);
  }).length;
});

/// ✅ ENHANCED: Provider to count today's tasks for specific member in project with real-time updates
final projectSectionTodayMemberCountProvider = Provider.family<int, Map<String, String>>((ref, params) {
  final projectId = params['projectId']!;
  final memberId = params['memberId']!;

  // ✅ CRITICAL FIX: Use projectTodosProvider for real-time updates
  final projectTodos = ref.watch(projectTodosProvider);

  // Filter for today's tasks assigned to this member in this project
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  return projectTodos.where((todo) {
    if (todo.projectId != projectId || todo.completed) return false;
    if (todo.dueDate == null || todo.assignedToId != memberId) return false;

    final todoDate = DateTime(todo.dueDate!.year, todo.dueDate!.month, todo.dueDate!.day);
    return todoDate.isAtSameMomentAs(today);
  }).length;
});
