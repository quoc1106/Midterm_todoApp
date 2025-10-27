/// 🎨 FRONTEND SCREENS - Todo Screen
///
/// ⭐ MAIN APPLICATION SCREEN ⭐
/// Central Todo Management with Complete Frontend/Backend Separation
///
/// EDUCATIONAL VALUE:
/// - Complete integration of frontend components with backend services
/// - Demonstration of clean architecture with separated concerns
/// - LEVEL 1-4 Riverpod patterns coordinated in main application flow
/// - Modern Flutter UI patterns with provider-driven state management
///
/// ARCHITECTURE INTEGRATION:
/// 1. Backend services for data management
/// 2. Frontend components for UI presentation
/// 3. Provider bridge for state coordination
/// 4. Complete separation of concerns

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Backend imports
import '../../providers/todo_providers.dart';
import '../../backend/models/todo_model.dart';

// Frontend component imports
import '../components/todo/index.dart';
import '../components/project/index.dart';
import '../components/theme/index.dart';
import '../components/navigation/app_drawer.dart';
import '../components/navigation/date_selector_widget.dart';
import '../components/app/performance_floating_indicator.dart';
import '../components/todo/todo_item.dart' as LegacyTodoItem;
import '../components/todo/todo_item.dart';

/// ⭐ MAIN TODO SCREEN: Frontend/Backend Integration Demo
///
/// DEMONSTRATES:
/// - Complete frontend component integration
/// - Backend service coordination through providers
/// - Clean architecture with separated UI and business logic
/// - LEVEL 1-4 Riverpod patterns working together
class TodoScreen extends ConsumerWidget {
  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// ⭐ PROVIDER COORDINATION: Backend data through provider bridge
    final todos = ref.watch(filteredTodosProvider);
    final title = ref.watch(appBarTitleProvider);
    final groupedUpcoming = ref.watch(upcomingGroupedTodosProvider);
    final selectedItem = ref.watch(sidebarItemProvider);
    final selectedUpcomingDate = ref.watch(upcomingSelectedDateProvider);
    final selectedProjectId = ref.watch(selectedProjectIdProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,

      /// ⭐ APP BAR: Integration with theme - keeping original style
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        actions: [
          // Performance indicator in header (compact version)
          const PerformanceFloatingIndicator(isCompact: true),
          const SizedBox(width: 8),
          // Theme toggle button - using original SimpleThemeToggle style
          const ThemeToggleWidget(),
        ],
      ),

      /// ⭐ DRAWER: Navigation with project management
      drawer: const AppDrawer(),

      /// ⭐ BODY: Dynamic content based on selected view - original layout
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              // Date selector for upcoming view
              if (selectedItem == SidebarItem.upcoming)
                const DateSelectorWidget(),
              if (selectedItem == SidebarItem.upcoming)
                const SizedBox(height: 12),

              // Main content area with original logic
              Expanded(
                child: selectedItem == SidebarItem.upcoming
                    ? _buildUpcomingViewOriginal(
                        context,
                        ref,
                        groupedUpcoming,
                        selectedUpcomingDate,
                      )
                    : selectedItem == SidebarItem.completed
                    ? _buildCompletedView(context, ref, todos)
                    : (selectedItem == SidebarItem.myProject &&
                              selectedProjectId != null
                          ? ProjectSectionWidget(projectId: selectedProjectId)
                          : (todos.isEmpty
                                ? _buildEmptyStateView(context, ref, selectedItem)
                                : ListView.builder(
                                    itemCount: todos.length,
                                    itemBuilder: (context, index) {
                                      return LegacyTodoItem.TodoItem(
                                        todo: todos[index],
                                      );
                                    },
                                  ))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ⭐ UPCOMING VIEW: Original logic from legacy TodoScreen
  Widget _buildUpcomingViewOriginal(
    BuildContext context,
    WidgetRef ref,
    List<GroupedTodos> groupedUpcoming,
    DateTime selectedUpcomingDate,
  ) {
    if (selectedUpcomingDate.year == 9999) {
      if (groupedUpcoming.isEmpty) {
        return _buildEmptyStateView(context, ref, SidebarItem.upcoming);
      }
      return ListView(
        children: [
          for (final group in groupedUpcoming)
            TodoGroupWidget(groupDate: group.date, todos: group.todos),
        ],
      );
    }

    final group = groupedUpcoming.firstWhere(
      (g) =>
          g.date.year == selectedUpcomingDate.year &&
          g.date.month == selectedUpcomingDate.month &&
          g.date.day == selectedUpcomingDate.day,
      orElse: () => GroupedTodos(selectedUpcomingDate, []),
    );

    return group.todos.isEmpty
        ? _buildEmptyStateView(context, ref, SidebarItem.upcoming)
        : Consumer(
            builder: (context, ref, _) {
              final isOpen = ref.watch(addTaskGroupDateProvider) == group.date;
              // ⭐ RIVERPOD LEVEL 2: Use shouldShowAddTaskProvider for smart button display
              final shouldShowAddTask = ref.watch(shouldShowAddTaskProvider);
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      '${group.date.day}/${group.date.month}/${group.date.year}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ...group.todos.map(
                    (todo) => LegacyTodoItem.TodoItem(todo: todo),
                  ),
                  // ⭐ RIVERPOD LEVEL 2: Smart Add Task button - only show for today/future
                  if (!isOpen && shouldShowAddTask)
                    TextButton.icon(
                      icon: const Icon(Icons.add_circle, color: Colors.red),
                      label: const Text(
                        'Add task',
                        style: TextStyle(color: Colors.red),
                      ),
                      onPressed: () {
                        ref.read(addTaskGroupDateProvider.notifier).state =
                            group.date;
                      },
                    ),
                  if (isOpen)
                    AddTaskWidget(
                      showCancel: true,
                      // ⭐ RIVERPOD LEVEL 2: Use newTodoDateProvider for smart date handling
                      presetDate: ref.watch(newTodoDateProvider),
                      onCancel: () {
                        ref.read(addTaskGroupDateProvider.notifier).state =
                            null;
                      },
                    ),
                ],
              );
            },
          );
  }

  /// ⭐ COMPLETED VIEW: Show completed tasks without strikethrough
  Widget _buildCompletedView(
    BuildContext context,
    WidgetRef ref,
    List<Todo> todos,
  ) {
    final completedTodos = todos.where((todo) => todo.completed).toList();

    if (completedTodos.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có công việc nào hoàn thành!',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: completedTodos.length,
      itemBuilder: (context, index) {
        return TodoItem(todo: completedTodos[index]);
      },
    );
  }

  /// ⭐ EMPTY STATE VIEW: Custom view for empty state with Add Task button
  Widget _buildEmptyStateView(
    BuildContext context,
    WidgetRef ref,
    SidebarItem selectedItem,
  ) {
    String message;
    String subtitle;
    IconData icon;

    switch (selectedItem) {
      case SidebarItem.today:
        message = 'Great! No tasks for today';
        subtitle = 'You have completed all your tasks or haven\'t added any yet';
        icon = Icons.check_circle_outline;
        break;
      case SidebarItem.upcoming:
        // ⭐ RIVERPOD LEVEL 1: Use provider for contextual messages
        message = ref.watch(emptyDateMessageProvider);
        subtitle = 'Start planning your future by adding some tasks';
        icon = Icons.schedule_outlined;
        break;
      default:
        message = 'No tasks found';
        subtitle = 'Add some tasks to get started';
        icon = Icons.task_outlined;
    }

    // ⭐ RIVERPOD LEVEL 2: Smart Add Task button visibility for upcoming dates
    final shouldShowAddTask = selectedItem == SidebarItem.upcoming
        ? ref.watch(shouldShowAddTaskProvider)
        : true; // Always show for today and other sections

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Empty state icon
            Icon(
              icon,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),

            // Main message
            Text(
              message,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // ⭐ RIVERPOD LEVEL 2: Conditional Add Task button based on date logic
            if (shouldShowAddTask)
              ElevatedButton.icon(
                onPressed: () => _openAddTaskForEmptyState(context, ref, selectedItem),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Add Task'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// ⭐ OPEN ADD TASK FOR EMPTY STATE: Handle add task from empty state
  void _openAddTaskForEmptyState(
    BuildContext context,
    WidgetRef ref,
    SidebarItem selectedItem,
  ) {
    // ⭐ RIVERPOD LEVEL 2: Use provider for smart date handling
    DateTime? presetDate;
    switch (selectedItem) {
      case SidebarItem.today:
        presetDate = DateTime.now();
        break;
      case SidebarItem.upcoming:
        // Use newTodoDateProvider for smart date selection based on selected date
        presetDate = ref.read(newTodoDateProvider);
        break;
      default:
        presetDate = DateTime.now();
    }

    // Show AddTaskWidget in a modal
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.add_task_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add New Task',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // AddTaskWidget
              AddTaskWidget(
                presetDate: presetDate,
                onTaskAdded: () {
                  // Close dialog after adding task
                  Navigator.of(context).pop();
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Task added successfully!'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                onCancel: () => Navigator.of(context).pop(),
                showCancel: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ⭐ HELPER METHODS: Date utilities
  bool _isPast(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    return d.isBefore(today);
  }
}
