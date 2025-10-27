/// 🎨 FRONTEND - Todo Item Component
///
/// ⭐ RIVERPOD LEVEL 1-2 DEMONSTRATION ⭐
/// Đây là PURE FRONTEND - chỉ UI logic và Riverpod consumption
/// Không có business logic hay backend operations
///
/// LEVEL 1: Basic state consumption từ providers
/// LEVEL 2: Combined state consumption từ multiple providers

import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../backend/models/todo_model.dart';
import '../../../providers/todo_providers.dart';
import '../../../providers/performance_initialization_providers.dart';
import '../../../backend/utils/date_utils.dart' as app_date_utils;
import '../task_assignment/assigned_user_avatar.dart'; // ✅ NEW: Import avatar component
import 'edit_todo_dialog.dart';

class TodoItem extends ConsumerWidget {
  final Todo todo;

  const TodoItem({super.key, required this.todo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// ⭐ RIVERPOD LEVEL 1: Basic State Watching
    /// Đây là cách simplest để consume state từ một provider
    // Không cần state nào khác, chỉ hiển thị todo

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        leading: _buildCheckbox(context, ref),
        title: _buildTitle(context),
        subtitle: _buildSubtitle(context, ref),
        trailing: _buildTrailing(context, ref),
        onTap: () => _showEditDialog(context, ref), // Single tap to edit
      ),
    );
  }

  /// ⭐ LEVEL 1: Basic State Interaction
  Widget _buildCheckbox(BuildContext context, WidgetRef ref) {
    return Checkbox(
      value: todo.completed,
      onChanged: (value) async {
        /// ⭐ LEVEL 1: Simple State Update with animation delay
        ref.read(todoListProvider.notifier).toggle(todo.id);

        // If completing the task, add a delay for UI feedback
        if (value == true) {
          await Future.delayed(const Duration(milliseconds: 800));
          // Task will automatically move to completed view due to filtering
        }
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    );
  }

  /// ⭐ FRONTEND UI LOGIC: Title Display
  Widget _buildTitle(BuildContext context) {
    return Text(
      todo.description,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        // Remove strikethrough decoration
        color: todo.completed
            ? Theme.of(context).colorScheme.onSurfaceVariant
            : Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  /// ⭐ FRONTEND UI LOGIC: Subtitle with Business Logic Data
  Widget _buildSubtitle(BuildContext context, WidgetRef ref) {
    final subtitleParts = <String>[];

    // Add date if available
    if (todo.dueDate != null) {
      subtitleParts.add(_getDateDisplayText());
    }

    // Add project info if available
    if (todo.projectId != null) {
      final projectBox = ref.read(projectBoxProvider);
      final project = projectBox.get(todo.projectId!);
      if (project != null) {
        subtitleParts.add('Project: ${project.name}');
      }
    }

    // Add section info if available
    if (todo.sectionId != null) {
      final sectionBox = ref.read(sectionBoxProvider);
      final section = sectionBox.get(todo.sectionId!);
      if (section != null) {
        subtitleParts.add('Section: ${section.name}');
      }
    }

    if (subtitleParts.isEmpty) return const SizedBox.shrink();

    final isOverdue = todo.isOverdue;
    final isToday = todo.isDueToday;

    return Text(
      subtitleParts.join(' • '),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: isOverdue
            ? Theme.of(context).colorScheme.error
            : isToday
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: isToday ? FontWeight.w600 : null,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
    );
  }

  /// ⭐ LEVEL 1: Simple Action Button
  Widget _buildTrailing(BuildContext context, WidgetRef ref) {
    /// ✅ FIXED: Show Assignee Avatar (correct business logic)
    /// Display the avatar of the person who should work on this task
    /// If unassigned, show the owner avatar as fallback

    final displayUserId = todo.assignedToId ?? todo.ownerId;
    final displayUserName = todo.assignedToDisplayName;

    return AssignedUserAvatar(
      assignedToId: displayUserId, // Show assignee if assigned, otherwise owner
      assignedToDisplayName: displayUserName,
      size: 32,
    );
  }

  /// ⭐ LEVEL 1: Simple Delete Action
  void _handleDelete(BuildContext context, WidgetRef ref) {
    ref.read(todoListProvider.notifier).remove(todo);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted "${todo.description}"'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            /// ⭐ LEVEL 2: Recreate todo for undo functionality
            ref
                .read(todoListProvider.notifier)
                .add(
                  todo.description,
                  dueDate: todo.dueDate,
                  projectId: todo.projectId,
                  sectionId: todo.sectionId,
                );
          },
        ),
      ),
    );
  }

  /// ⭐ LEVEL 2: Edit Dialog Handler
  void _showEditDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => EditTodoDialog(todo: todo),
    );
  }

  /// ⭐ FRONTEND HELPER METHODS ⭐
  /// Pure UI logic methods

  String _getDateDisplayText() {
    if (todo.dueDate == null) return '';

    if (app_date_utils.DateUtils.isToday(todo.dueDate!)) {
      return 'Today';
    } else if (app_date_utils.DateUtils.isTomorrow(todo.dueDate!)) {
      return 'Tomorrow';
    } else if (todo.isOverdue) {
      return 'Overdue • ${app_date_utils.DateUtils.formatDate(todo.dueDate!)}';
    } else {
      // Always show actual date instead of relative date like "In 4 days"
      return app_date_utils.DateUtils.formatDate(todo.dueDate!);
    }
  }
}

/// ⭐ RIVERPOD LEVEL 2: Enhanced Todo Item
/// More complex version demonstrating advanced patterns
class EnhancedTodoItem extends ConsumerStatefulWidget {
  final Todo todo;
  final bool showProjectInfo;
  final VoidCallback? onEdit;

  const EnhancedTodoItem({
    super.key,
    required this.todo,
    this.showProjectInfo = false,
    this.onEdit,
  });

  @override
  ConsumerState<EnhancedTodoItem> createState() => _EnhancedTodoItemState();
}

class _EnhancedTodoItemState extends ConsumerState<EnhancedTodoItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    /// ⭐ RIVERPOD LEVEL 2: Multiple Provider Watching
    /// Combining different providers for complex UI state

    // Just watch for demonstration, even if not used
    ref.watch(sidebarItemProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: _isExpanded ? 4 : 1,
      child: Column(
        children: [
          /// Main todo item
          ListTile(
            leading: _buildEnhancedCheckbox(context),
            title: _buildEnhancedTitle(context),
            subtitle: _buildEnhancedSubtitle(context),
            trailing: _buildEnhancedTrailing(context),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),

          /// ⭐ LEVEL 2: Expandable Content
          if (_isExpanded) _buildExpandedContent(context),
        ],
      ),
    );
  }

  /// ⭐ LEVEL 2: Enhanced Checkbox with Animation
  Widget _buildEnhancedCheckbox(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Checkbox(
        value: widget.todo.completed,
        onChanged: (value) {
          ref.read(todoListProvider.notifier).toggle(widget.todo.id);
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  /// ⭐ LEVEL 2: Enhanced Title with Priority Display
  Widget _buildEnhancedTitle(BuildContext context) {
    return Row(
      children: [
        /// Priority indicator - show for overdue or today items
        if (widget.todo.isOverdue || widget.todo.isDueToday)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getPriorityColor(context),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              widget.todo.priority,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        /// Title text
        Expanded(
          child: Text(
            widget.todo.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              decoration: widget.todo.completed
                  ? TextDecoration.lineThrough
                  : null,
              color: widget.todo.completed
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  /// ⭐ LEVEL 2: Enhanced Subtitle with Multiple Data Points
  Widget _buildEnhancedSubtitle(BuildContext context) {
    final subtitleParts = <String>[];

    // Date information
    if (widget.todo.dueDate != null) {
      if (widget.todo.isDueToday) {
        subtitleParts.add('Today');
      } else if (widget.todo.isOverdue) {
        subtitleParts.add('Overdue');
      } else {
        subtitleParts.add(
          app_date_utils.DateUtils.getRelativeDate(widget.todo.dueDate!),
        );
      }
    }

    // Project information (if available and enabled)
    if (widget.showProjectInfo && widget.todo.projectId != null) {
      subtitleParts.add('Project Task');
    }

    if (subtitleParts.isEmpty) return const SizedBox.shrink();

    return Text(
      subtitleParts.join(' • '),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: widget.todo.isOverdue
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// ⭐ LEVEL 2: Enhanced Trailing with Multiple Actions
  Widget _buildEnhancedTrailing(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        /// Edit button
        if (widget.onEdit != null)
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: widget.onEdit,
            iconSize: 20,
            color: Theme.of(context).colorScheme.primary,
          ),

        /// Delete button
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _handleEnhancedDelete(context),
          iconSize: 20,
          color: Theme.of(context).colorScheme.error,
        ),
      ],
    );
  }

  /// ⭐ LEVEL 2: Expandable Content
  Widget _buildExpandedContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Full date and time
          if (widget.todo.dueDate != null)
            _buildInfoRow(
              context,
              Icons.schedule,
              'Due Date',
              app_date_utils.DateUtils.formatDateTime(widget.todo.dueDate!),
            ),

          /// Priority level
          _buildInfoRow(
            context,
            Icons.priority_high,
            'Priority',
            widget.todo.priority,
          ),
        ],
      ),
    );
  }

  /// ⭐ FRONTEND HELPER: Info Row Builder
  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(value, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  /// ⭐ LEVEL 2: Enhanced Delete with Confirmation
  void _handleEnhancedDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text(
          'Are you sure you want to delete "${widget.todo.description}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(todoListProvider.notifier).remove(widget.todo);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// ⭐ FRONTEND HELPER METHODS ⭐

  Color _getPriorityColor(BuildContext context) {
    switch (widget.todo.priority) {
      case 'Overdue':
        return Colors.red;
      case 'Today':
        return Colors.orange;
      case 'This Week':
        return Colors.blue;
      case 'Completed':
        return Colors.green;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }
}
