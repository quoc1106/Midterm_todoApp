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
import '../../providers/todo_providers.dart' show GroupedTodos, SidebarItem, upcomingGroupedTodosProvider, filteredTodosProvider, appBarTitleProvider, upcomingSelectedDateProvider, selectedProjectIdProvider, overdueTodosProvider, todayOnlyTodosProvider, overdueTodoCountProvider, overdueCollapsedProvider, enhancedUpcomingGroupedTodosProvider, upcomingOverdueTodosProvider, upcomingOverdueCollapsedProvider, upcomingGroupCollapsedProvider, addTaskGroupDateProvider, shouldShowAddTaskProvider, newTodoDateProvider, emptyDateMessageProvider, sidebarItemProvider, CompletedFilterType, completedFilterTypeProvider, completedSelectedProjectIdProvider, filteredCompletedTodosProvider;
import '../../providers/todo_providers.dart' as TodoProviders show DateUtils;
import '../../backend/models/todo_model.dart';
import '../../backend/models/project_model.dart'; // ✅ ADDED: Import ProjectModel
import '../../providers/task_filtering_providers.dart'; // ✅ NEW: Import for shared project completed tasks
import '../../providers/project_providers.dart' show accessibleProjectsProvider; // ✅ NEW: For completed filter

// Frontend component imports
import '../components/todo/index.dart';
import '../components/project/index.dart';
import '../components/theme/index.dart';
import '../components/navigation/app_drawer.dart';
import '../components/navigation/date_selector_widget.dart';
import '../components/app/performance_floating_indicator.dart';
import '../components/todo/todo_item.dart' as LegacyTodoItem;
import '../components/todo/todo_item.dart';
import '../components/completed/completed_filter_bar.dart'; // ✅ NEW: Import completed filter bar

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

    // ✅ NEW: Watch overdue and today-only todos for Today view
    final overdueTodos = ref.watch(overdueTodosProvider);
    final todayOnlyTodos = ref.watch(todayOnlyTodosProvider);
    final overdueCount = ref.watch(overdueTodoCountProvider);
    final isOverdueCollapsed = ref.watch(overdueCollapsedProvider);

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

              // Main content area with updated Today view logic
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
                    : selectedItem == SidebarItem.today
                    ? _buildTodayViewWithOverdue(
                        context,
                        ref,
                        overdueTodos,
                        todayOnlyTodos,
                        overdueCount,
                        isOverdueCollapsed,
                      )
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
    // ✅ NEW: Use enhanced providers for better upcoming view
    final enhancedGroupedUpcoming = ref.watch(enhancedUpcomingGroupedTodosProvider);
    final upcomingOverdueTodos = ref.watch(upcomingOverdueTodosProvider);
    final isUpcomingOverdueCollapsed = ref.watch(upcomingOverdueCollapsedProvider);

    if (selectedUpcomingDate.year == 9999) {
      // ✅ ENHANCED: "All" view with Overdue section and collapsible groups
      if (enhancedGroupedUpcoming.isEmpty && upcomingOverdueTodos.isEmpty) {
        return _buildEmptyStateView(context, ref, SidebarItem.upcoming);
      }

      return ListView(
        children: [
          // ✅ NEW: Overdue section for Upcoming view
          if (upcomingOverdueTodos.isNotEmpty) ...[
            _buildUpcomingOverdueSection(
              context,
              ref,
              upcomingOverdueTodos,
              isUpcomingOverdueCollapsed,
            ),
            // ✅ FIXED: Hiển thị tasks trong overdue section khi không collapsed
            if (!isUpcomingOverdueCollapsed)
              ...upcomingOverdueTodos.map((todo) => TodoItem(todo: todo)),
            const SizedBox(height: 16),
          ],

          // ✅ NEW: Collapsible date groups
          for (final group in enhancedGroupedUpcoming)
            _buildCollapsibleDateGroup(
              context,
              ref,
              group,
            ),
        ],
      );
    }

    // Logic cũ cho khi chọn ngày cụ thể (giữ nguyên)
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

  /// ✅ NEW: Overdue section cho Upcoming view
  Widget _buildUpcomingOverdueSection(
    BuildContext context,
    WidgetRef ref,
    List<Todo> overdueTodos,
    bool isCollapsed,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1), // ✅ FIXED: Giống Today view
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red, width: 1),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          ref.read(upcomingOverdueCollapsedProvider.notifier).state = !isCollapsed;
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning, // ✅ FIXED: Giống Today view
                    color: Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Overdue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // ✅ FIXED: Item count badge giống Today view
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${overdueTodos.length}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isCollapsed ? Icons.expand_more : Icons.expand_less,
                    color: Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ FIXED: Collapsible date groups cho Upcoming view - Sửa styling cho Today
  Widget _buildCollapsibleDateGroup(
    BuildContext context,
    WidgetRef ref,
    GroupedTodos group,
  ) {
    final dateKey = '${group.date.year}-${group.date.month}-${group.date.day}';
    final isCollapsed = ref.watch(upcomingGroupCollapsedProvider(dateKey));
    final isToday = TodoProviders.DateUtils.isToday(group.date);

    // Format ngày hiển thị
    String getDateLabel(DateTime date) {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));

      if (TodoProviders.DateUtils.isToday(date)) {
        return 'Today';
      } else if (date.year == tomorrow.year &&
                 date.month == tomorrow.month &&
                 date.day == tomorrow.day) {
        return 'Tomorrow';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    }

    // ✅ FIXED: Sử dụng Column để hiển thị header + tasks khi expanded
    return Column(
      children: [
        // Header section
        Container(
          decoration: BoxDecoration(
            color: isToday
                ? Theme.of(context).colorScheme.primaryContainer  // ✅ FIXED: Màu xanh như Today view
                : null,
            borderRadius: BorderRadius.circular(12),
            border: isToday
                ? null  // ✅ FIXED: Không có border cho Today (giống Today view)
                : Border.all(color: Colors.grey.shade300, width: 1),
          ),
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () {
              ref.read(upcomingGroupCollapsedProvider(dateKey).notifier).state = !isCollapsed;
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isToday ? Icons.today : Icons.calendar_today,
                        color: isToday
                            ? Theme.of(context).colorScheme.onPrimaryContainer  // ✅ FIXED: Màu icon giống Today view
                            : Colors.grey.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        getDateLabel(group.date),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isToday
                              ? Theme.of(context).colorScheme.onPrimaryContainer  // ✅ FIXED: Màu text giống Today view
                              : null,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // ✅ FIXED: Item count badge - hiển thị số lượng tasks
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: isToday
                              ? Theme.of(context).colorScheme.secondary  // ✅ FIXED: Màu badge giống Today view
                              : Colors.grey.shade600,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${group.todos.length}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isToday
                                ? Theme.of(context).colorScheme.onSecondary  // ✅ FIXED: Màu text badge giống Today view
                                : Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isCollapsed ? Icons.expand_more : Icons.expand_less,
                        color: isToday
                            ? Theme.of(context).colorScheme.onPrimaryContainer  // ✅ FIXED: Màu expand icon giống Today view
                            : Colors.grey.shade600,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // ✅ FIXED: Tasks content when expanded
        if (!isCollapsed) ...[
          ...group.todos.map((todo) => TodoItem(todo: todo)),

          // Add task button cho nhóm này
          Consumer(
            builder: (context, ref, _) {
              final isOpen = ref.watch(addTaskGroupDateProvider) == group.date;
              final shouldShowAddTask = !TodoProviders.DateUtils.isPastDate(group.date);

              if (isOpen) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AddTaskWidget(
                    showCancel: true,
                    presetDate: group.date,
                    onCancel: () {
                      ref.read(addTaskGroupDateProvider.notifier).state = null;
                    },
                    onTaskAdded: () {
                      ref.read(addTaskGroupDateProvider.notifier).state = null;
                    },
                  ),
                );
              }

              if (shouldShowAddTask) {
                return ListTile(
                  leading: Icon(
                    Icons.add,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    'Add task to ${getDateLabel(group.date)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  onTap: () {
                    ref.read(addTaskGroupDateProvider.notifier).state = group.date;
                  },
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ],
      ],
    );
  }

  /// ⭐ COMPLETED VIEW: Show completed tasks with advanced filtering
  Widget _buildCompletedView(
    BuildContext context,
    WidgetRef ref,
    List<Todo> todos,
  ) {
    final filteredCompletedTodos = ref.watch(filteredCompletedTodosProvider);
    final filterType = ref.watch(completedFilterTypeProvider);
    final selectedProjectId = ref.watch(completedSelectedProjectIdProvider);

    return Column(
      children: [
        // ✅ NEW: Filter bar at the top
        const CompletedFilterBar(),

        // ✅ NEW: Filter result summary
        if (filterType != CompletedFilterType.all) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Text(
              _getFilterSummaryText(filterType, selectedProjectId, ref),
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],

        // ✅ Task list
        Expanded(
          child: filteredCompletedTodos.isEmpty
              ? _buildCompletedEmptyState(context, filterType)
              : ListView.builder(
                  itemCount: filteredCompletedTodos.length,
                  itemBuilder: (context, index) {
                    return TodoItem(todo: filteredCompletedTodos[index]);
                  },
                ),
        ),
      ],
    );
  }

  /// Helper method to get filter summary text
  String _getFilterSummaryText(
    CompletedFilterType filterType,
    String? selectedProjectId,
    WidgetRef ref,
  ) {
    switch (filterType) {
      case CompletedFilterType.dailyTasks:
        return 'Showing completed daily tasks';
      case CompletedFilterType.projects:
        if (selectedProjectId != null) {
          final projects = ref.watch(accessibleProjectsProvider);
          final project = projects.cast<ProjectModel>().firstWhere(
            (p) => p.id == selectedProjectId,
            orElse: () => ProjectModel(
              id: '',
              name: 'Unknown Project',
              ownerId: '',
              createdAt: DateTime.now(), // ✅ FIXED: Add required createdAt parameter
            ),
          );
          return 'Showing completed tasks from: ${project.name}';
        } else {
          return 'Showing completed tasks from all projects';
        }
      default:
        return '';
    }
  }

  /// Helper method for empty state based on filter type
  Widget _buildCompletedEmptyState(BuildContext context, CompletedFilterType filterType) {
    String message;
    IconData icon;

    switch (filterType) {
      case CompletedFilterType.dailyTasks:
        message = 'No completed daily tasks yet!';
        icon = Icons.today;
        break;
      case CompletedFilterType.projects:
        message = 'No completed project tasks yet!';
        icon = Icons.folder;
        break;
      default:
        message = 'No completed tasks yet!';
        icon = Icons.check_circle_outline;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Theme.of(context).hintColor,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).hintColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// ⭐ TODAY VIEW WITH OVERDUE: Combined view for Today with Overdue section
  Widget _buildTodayViewWithOverdue(
    BuildContext context,
    WidgetRef ref,
    List<Todo> overdueTodos,
    List<Todo> todayOnlyTodos,
    int overdueCount,
    bool isOverdueCollapsed,
  ) {
    return ListView(
      children: [
        // Overdue section
        if (overdueTodos.isNotEmpty) ...[
          _buildSectionHeader(
            context,
            title: 'Overdue', // ✅ FIXED: Changed from Vietnamese to English
            itemCount: overdueCount,
            isCollapsed: isOverdueCollapsed,
            onToggleCollapse: () {
              ref.read(overdueCollapsedProvider.notifier).state =
                  !isOverdueCollapsed;
            },
            isOverdue: true,
          ),
          if (!isOverdueCollapsed)
            ...overdueTodos.map(
              (todo) => LegacyTodoItem.TodoItem(todo: todo),
            ),
          const SizedBox(height: 16), // Add spacing between sections
        ],

        // Today's tasks section
        _buildSectionHeader(
          context,
          title: 'Today', // ✅ FIXED: Changed from Vietnamese to English
          itemCount: todayOnlyTodos.length,
        ),
        ...todayOnlyTodos.map(
          (todo) => LegacyTodoItem.TodoItem(todo: todo),
        ),

        const SizedBox(height: 80), // Space for floating action button
      ],
    );
  }

  /// ⭐ SECTION HEADER: Reusable header for sections in Today view
  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required int itemCount,
    bool isCollapsed = false,
    VoidCallback? onToggleCollapse,
    bool isOverdue = false,
  }) {
    final bool isCollapsible = onToggleCollapse != null;

    return Container(
      decoration: BoxDecoration(
        color: isOverdue
            ? Colors.red.withOpacity(0.1)
            : Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: isOverdue
            ? Border.all(color: Colors.red, width: 1)
            : null,
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: isCollapsible ? onToggleCollapse : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (isOverdue)
                    Icon(
                      Icons.warning,
                      color: Colors.red,
                      size: 20,
                    ),
                  if (isOverdue) const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isOverdue
                          ? Colors.red
                          : Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // Item count badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: isOverdue
                          ? Colors.red
                          : Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$itemCount',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isOverdue
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSecondary,
                      ),
                    ),
                  ),
                  if (isCollapsible) ...[
                    const SizedBox(width: 8),
                    Icon(
                      isCollapsed ? Icons.expand_more : Icons.expand_less,
                      color: isOverdue
                          ? Colors.red
                          : Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
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
