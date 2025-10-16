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
              // Add task widget - Hide for completed view
              if (selectedItem != SidebarItem.completed) ...[
                const AddTaskWidget(),
                const SizedBox(height: 12),
              ],

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
                                ? const Center(
                                    child: Text(
                                      'Tuyệt vời, không có công việc nào!',
                                    ),
                                  )
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
        return const Center(child: Text('Không có công việc nào!'));
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
        ? const Center(child: Text('Không có công việc nào cho ngày này!'))
        : Consumer(
            builder: (context, ref, _) {
              final isOpen = ref.watch(addTaskGroupDateProvider) == group.date;
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
                  if (!isOpen && !_isPast(group.date))
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
                      presetDate: group.date,
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

  /// ⭐ HELPER METHODS: Date utilities
  bool _isPast(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    return d.isBefore(today);
  }
}
