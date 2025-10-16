/// 🎨 FRONTEND - Todo Group Component
///
/// ⭐ RIVERPOD LEVEL 2 DEMONSTRATION ⭐
/// Đây là PURE FRONTEND - group display logic với Riverpod patterns
/// Không có business logic, chỉ UI organization và state consumption
///
/// LEVEL 2: Complex state combinations và conditional rendering

import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/todo_providers.dart';
import '../../../backend/models/todo_model.dart';
import '../../../backend/utils/date_utils.dart' as AppDateUtils;
import 'todo_item.dart';
import 'add_task_widget.dart';

class TodoGroupWidget extends ConsumerWidget {
  final DateTime groupDate;
  final List<Todo> todos;
  final String? groupTitle;
  final bool showAddButton;

  const TodoGroupWidget({
    super.key,
    required this.groupDate,
    required this.todos,
    this.groupTitle,
    this.showAddButton = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// ⭐ RIVERPOD LEVEL 2: Smart State Filtering
    /// Combining provider state với local filtering logic

    final addTaskGroupDate = ref.watch(addTaskGroupDateProvider);
    final activeTodos = todos.where((todo) => !todo.completed).toList();
    final completedTodos = todos.where((todo) => todo.completed).toList();

    /// ⭐ LEVEL 2: Computed UI States
    final isExpanded = addTaskGroupDate == groupDate;
    final isPastDate = AppDateUtils.DateUtils.isOverdue(groupDate);
    final isToday = AppDateUtils.DateUtils.isToday(groupDate);
    final isTomorrow = AppDateUtils.DateUtils.isTomorrow(groupDate);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: isToday ? 3 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ⭐ LEVEL 2: Dynamic Header with State Integration
          _buildGroupHeader(context, ref, isPastDate, isToday, isTomorrow),

          /// ⭐ LEVEL 2: Conditional Content Rendering
          if (activeTodos.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildActiveTodos(activeTodos),
          ],

          /// ⭐ LEVEL 2: State-Dependent Add Widget
          if (showAddButton) _buildAddTaskSection(context, ref, isExpanded),

          /// ⭐ LEVEL 2: Collapsible Completed Section
          if (completedTodos.isNotEmpty)
            _buildCompletedSection(context, completedTodos),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// ⭐ LEVEL 2: Complex Header Building
  Widget _buildGroupHeader(
    BuildContext context,
    WidgetRef ref,
    bool isPastDate,
    bool isToday,
    bool isTomorrow,
  ) {
    final theme = Theme.of(context);
    final displayTitle =
        groupTitle ?? _getDateDisplayText(isPastDate, isToday, isTomorrow);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getHeaderColor(theme, isPastDate, isToday),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          /// Date status icon
          Icon(
            _getDateIcon(isPastDate, isToday, isTomorrow),
            color: _getIconColor(theme, isPastDate, isToday),
            size: 20,
          ),
          const SizedBox(width: 12),

          /// Title với state-dependent styling
          Expanded(
            child: Text(
              displayTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                color: _getTextColor(theme, isPastDate, isToday),
              ),
            ),
          ),

          /// Todo count badge
          if (todos.isNotEmpty) _buildTodoCountBadge(theme),
        ],
      ),
    );
  }

  /// ⭐ LEVEL 2: Active Todos Rendering
  Widget _buildActiveTodos(List<Todo> activeTodos) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < activeTodos.length; i++) ...[
            if (i > 0) const SizedBox(height: 4),
            TodoItem(todo: activeTodos[i]),
          ],
        ],
      ),
    );
  }

  /// ⭐ LEVEL 2: State-Dependent Add Task Section
  Widget _buildAddTaskSection(
    BuildContext context,
    WidgetRef ref,
    bool isExpanded,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          /// Add button hoặc expanded form
          if (!isExpanded)
            _buildAddButton(context, ref)
          else
            _buildExpandedAddForm(context, ref),
        ],
      ),
    );
  }

  /// ⭐ LEVEL 1: Simple Add Button
  Widget _buildAddButton(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        /// Level 1: Simple state toggle
        ref.read(addTaskGroupDateProvider.notifier).state = groupDate;
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.add,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Add task for ${AppDateUtils.DateUtils.getRelativeDate(groupDate)}',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }

  /// ⭐ LEVEL 2: Complex Form Integration
  Widget _buildExpandedAddForm(BuildContext context, WidgetRef ref) {
    return AddTaskWidget(
      presetDate: groupDate,
      onClose: () {
        /// Level 1: State reset
        ref.read(addTaskGroupDateProvider.notifier).state = null;
      },
      onTaskAdded: () {
        /// Level 1: State reset after action
        ref.read(addTaskGroupDateProvider.notifier).state = null;
      },
    );
  }

  /// ⭐ LEVEL 2: Collapsible Completed Section
  Widget _buildCompletedSection(
    BuildContext context,
    List<Todo> completedTodos,
  ) {
    return ExpansionTile(
      title: Text(
        'Completed (${completedTodos.length})',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      leading: Icon(
        Icons.check_circle_outline,
        color: Theme.of(context).colorScheme.primary,
        size: 20,
      ),
      children: [for (final todo in completedTodos) TodoItem(todo: todo)],
    );
  }

  /// ⭐ LEVEL 2: Smart Count Badge
  Widget _buildTodoCountBadge(ThemeData theme) {
    final activeTodos = todos.where((t) => !t.completed).toList();
    final completedTodos = todos.where((t) => t.completed).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${activeTodos.length}${completedTodos.isNotEmpty ? ' (+${completedTodos.length})' : ''}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// ⭐ FRONTEND HELPER METHODS ⭐
  /// Pure UI logic methods

  String _getDateDisplayText(bool isPastDate, bool isToday, bool isTomorrow) {
    if (isToday) return 'Today';
    if (isTomorrow) return 'Tomorrow';
    if (isPastDate)
      return 'Overdue (${AppDateUtils.DateUtils.formatDate(groupDate)})';
    return AppDateUtils.DateUtils.getRelativeDate(groupDate);
  }

  IconData _getDateIcon(bool isPastDate, bool isToday, bool isTomorrow) {
    if (isPastDate) return Icons.warning_outlined;
    if (isToday) return Icons.today_outlined;
    if (isTomorrow) return Icons.event_outlined;
    return Icons.calendar_today_outlined;
  }

  Color _getHeaderColor(ThemeData theme, bool isPastDate, bool isToday) {
    if (isPastDate) return theme.colorScheme.errorContainer;
    if (isToday) return theme.colorScheme.primaryContainer;
    return theme.colorScheme.surfaceContainerHighest;
  }

  Color _getIconColor(ThemeData theme, bool isPastDate, bool isToday) {
    if (isPastDate) return theme.colorScheme.error;
    if (isToday) return theme.colorScheme.primary;
    return theme.colorScheme.onSurfaceVariant;
  }

  Color _getTextColor(ThemeData theme, bool isPastDate, bool isToday) {
    if (isPastDate) return theme.colorScheme.onErrorContainer;
    if (isToday) return theme.colorScheme.onPrimaryContainer;
    return theme.colorScheme.onSurface;
  }
}

/// ⭐ RIVERPOD LEVEL 2: Smart Todo Group
/// Enhanced version với more advanced patterns
class SmartTodoGroup extends ConsumerWidget {
  final DateTime groupDate;
  final String? customTitle;

  const SmartTodoGroup({super.key, required this.groupDate, this.customTitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// ⭐ LEVEL 2: Provider-Based Data Fetching
    /// Automatically fetch todos for this date từ providers

    final allTodos = ref.watch(todoListProvider);
    final groupTodos = allTodos.where((todo) {
      if (todo.dueDate == null) return false;
      return AppDateUtils.DateUtils.isToday(groupDate)
          ? todo.isDueToday
          : todo.dueDate!.day == groupDate.day &&
                todo.dueDate!.month == groupDate.month &&
                todo.dueDate!.year == groupDate.year;
    }).toList();

    /// ⭐ LEVEL 2: Smart Empty State
    if (groupTodos.isEmpty) {
      return _buildEmptyState(context, ref);
    }

    return TodoGroupWidget(
      groupDate: groupDate,
      todos: groupTodos,
      groupTitle: customTitle,
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'No tasks for ${AppDateUtils.DateUtils.getRelativeDate(groupDate)}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                ref.read(addTaskGroupDateProvider.notifier).state = groupDate;
              },
              icon: const Icon(Icons.add),
              label: const Text('Add first task'),
            ),
          ],
        ),
      ),
    );
  }
}
