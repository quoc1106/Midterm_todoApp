///
/// ⭐ RIVERPOD LEVEL 2 DEMONSTRATION ⭐
/// Đây là PURE FRONTEND - task addition form với Riverpod patterns
/// Simplified version for frontend demonstration
///
/// LEVEL 2: State management với form handling và validation

import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../providers/todo_providers.dart';
import '../../../providers/project_providers.dart'; // ✅ ADD: Import project providers
import '../../../providers/section_providers.dart'; // ✅ ADD: Import section providers
import '../../../providers/shared_project_providers.dart'; // ✅ NEW: Import shared project providers
import '../../../providers/auth_providers.dart'; // ✅ NEW: Import auth providers cho currentUserProvider
import '../../../providers/performance_initialization_providers.dart';
import '../../../backend/utils/date_utils.dart' as AppDateUtils;
import '../../../backend/models/user.dart'; // ✅ NEW: Import User model
import '../task_assignment/assign_user_dropdown.dart'; // ✅ NEW: Import assignment components

class AddTaskWidget extends ConsumerStatefulWidget {
  final DateTime? presetDate;
  final String? presetProjectId;
  final String? presetSectionId;
  final VoidCallback? onClose;
  final VoidCallback? onTaskAdded;
  final VoidCallback? onCancel;
  final bool showCancel;
  final String? hintText;

  const AddTaskWidget({
    super.key,
    this.presetDate,
    this.presetProjectId,
    this.presetSectionId,
    this.onClose,
    this.onTaskAdded,
    this.onCancel,
    this.showCancel = true,
    this.hintText,
  });

  @override
  ConsumerState<AddTaskWidget> createState() => _AddTaskWidgetState();
}

class _AddTaskWidgetState extends ConsumerState<AddTaskWidget> {
  late final TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();

  // Local state for project/section when preset values exist
  String? _localProjectId;
  String? _localSectionId;
  bool _useLocalState = false;

  // ✅ NEW: Local state for task assignment
  String? _assignedUserId;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();

    // If widget has preset project/section, use local state to avoid affecting global state
    if (widget.presetProjectId != null || widget.presetSectionId != null) {
      _useLocalState = true;
      _localProjectId = widget.presetProjectId;
      _localSectionId = widget.presetSectionId;
    }

    /// ⭐ LEVEL 1: Initialize preset values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.presetDate != null) {
        ref.read(newTodoDateProvider.notifier).state = widget.presetDate!;
      }

      // Only set global providers if not using local state
      if (!_useLocalState) {
        // Set preset project and section if provided
        if (widget.presetProjectId != null) {
          ref.read(newTodoProjectIdProvider.notifier).state =
              widget.presetProjectId;
        }
        if (widget.presetSectionId != null) {
          ref.read(newTodoSectionIdProvider.notifier).state =
              widget.presetSectionId;
        }
      }
    });

    /// Auto-focus for better UX
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// ⭐ LEVEL 2: Smart Submit Logic với Assignment Support
  void _submitTask() {
    final content = _textController.text.trim();
    if (content.isEmpty) return;

    /// ⭐ LEVEL 2: Provider Integration
    final selectedDate = ref.read(newTodoDateProvider);
    // Use local state if this is a preset context, otherwise use global providers
    final selectedProjectId = _useLocalState
        ? _localProjectId
        : ref.read(newTodoProjectIdProvider);
    final selectedSectionId = _useLocalState
        ? _localSectionId
        : ref.read(newTodoSectionIdProvider);
    final currentView = ref.read(sidebarItemProvider);

    /// ⭐ LEVEL 2: Validation Logic
    if (currentView == SidebarItem.upcoming) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (selectedDate.isBefore(today)) {
        _showError(
          'Please select a date from today onwards for Upcoming view.',
        );
        return;
      }
    }

    /// ✅ NEW: Get assigned user display name for caching
    String? assignedToDisplayName;
    if (_assignedUserId != null) {
      assignedToDisplayName = ref.read(userDisplayNameProvider(_assignedUserId!));
    }

    /// ⭐ LEVEL 2: Add Task Through Provider với assignment support
    ref
        .read(todoListProvider.notifier)
        .addWithAssignment(
          content,
          dueDate: selectedDate,
          projectId: selectedProjectId,
          sectionId: selectedSectionId,
          assignedToId: _assignedUserId,
          assignedToDisplayName: assignedToDisplayName,
        );

    /// ✅ FIXED: Invalidate providers để cập nhật UI ngay lập tức
    if (selectedProjectId != null) {
      ref.invalidate(projectTodosProvider);
      if (selectedSectionId != null) {
        ref.invalidate(sectionsByProjectProvider(selectedProjectId));
      }
    }
    // Force refresh todo list
    ref.invalidate(todoListProvider);

    /// ✅ FIXED: Hiển thị thông báo "Task added successfully"
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Task added successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    /// ⭐ LEVEL 1: Reset and Cleanup - CHỈ CLEAR TEXT, KHÔNG TẮT WIDGET
    _textController.clear();
    // ✅ NEW: Reset assignment
    setState(() {
      _assignedUserId = null;
    });

    // Reset focus to text field for next task
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });


    /// Callbacks - Gọi callback nhưng KHÔNG đóng widget
    if (widget.onTaskAdded != null) {
      widget.onTaskAdded!();
    }
  }

  /// ⭐ FRONTEND HELPER: Error Display
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    /// ⭐ LEVEL 1: Basic State Watching
    final selectedDate = ref.watch(newTodoDateProvider);
    final currentView = ref.watch(sidebarItemProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// ⭐ LEVEL 2: Smart Input Field
          _buildTaskInput(context, currentView),

          const SizedBox(height: 12),

          /// ⭐ LEVEL 2: Conditional Controls
          /// Responsive Layout for Mobile
          LayoutBuilder(
            builder: (context, constraints) {
              // Check if screen is narrow (mobile)
              final isNarrow = constraints.maxWidth < 500;

              if (isNarrow) {
                // Stack vertically on narrow screens with better overflow handling
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // First row: Date and Project/Section with better flex
                    Row(
                      children: [
                        /// Date picker for non-today views OR when presetDate is provided (overlay context)
                        if (currentView != SidebarItem.today || widget.presetDate != null) ...[
                          Flexible(
                            flex: 1,
                            child: _buildDatePicker(context, selectedDate),
                          ),
                          const SizedBox(width: 8),
                        ],

                        /// Project/Section picker with flexible sizing
                        Flexible(
                          flex: 2,
                          child: _buildProjectSectionPicker(context),
                        ),
                      ],
                    ),

                    // ✅ NEW: Assignment section for shared projects
                    _buildAssignmentSection(context),

                    const SizedBox(height: 12),

                    // Second row: Action buttons
                    Align(
                      alignment: Alignment.centerRight,
                      child: _buildActionButtons(context),
                    ),
                  ],
                );
              } else {
                // ✅ FIXED: Horizontal layout with Assignment section for wider screens
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // First row: Date, Project/Section, and Action buttons
                    Row(
                      children: [
                        /// Date picker for non-today views OR when presetDate is provided (overlay context)
                        if (currentView != SidebarItem.today || widget.presetDate != null) ...[
                          _buildDatePicker(context, selectedDate),
                          const SizedBox(width: 8),
                        ],

                        /// Project/Section picker with intrinsic width
                        IntrinsicWidth(child: _buildProjectSectionPicker(context)),

                        const Spacer(),

                        /// Action buttons
                        _buildActionButtons(context),
                      ],
                    ),

                    // ✅ NEW: Assignment section for desktop layout too
                    _buildAssignmentSection(context),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// ⭐ LEVEL 2: Smart Input Building
  Widget _buildTaskInput(BuildContext context, SidebarItem currentView) {
    final hintText = widget.hintText ?? _getSmartHintText(currentView);

    return TextField(
      controller: _textController,
      focusNode: _focusNode,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        prefixIcon: Icon(
          Icons.add_task,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      onSubmitted: (_) => _submitTask(),
      textInputAction: TextInputAction.done,
    );
  }

  /// ⭐ LEVEL 2: Smart Date Picker
  Widget _buildDatePicker(BuildContext context, DateTime selectedDate) {
    return InkWell(
      onTap: () => _showDatePicker(context),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                _getDateDisplayText(selectedDate),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ⭐ LEVEL 1: Action Buttons
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        /// Cancel button with smart logic
        if (widget.showCancel) ...[
          TextButton(onPressed: _handleCancel, child: const Text('Cancel')),
          const SizedBox(width: 8),
        ],

        /// Add button
        ElevatedButton.icon(
          onPressed: _submitTask,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  /// ⭐ LEVEL 2: Smart Cancel Logic with confirmation
  void _handleCancel() {
    // Check if user has entered any content
    final hasContent = _textController.text.trim().isNotEmpty;

    if (hasContent) {
      // Show confirmation dialog if user has entered content
      _showCancelConfirmationDialog();
    } else {
      // Proceed with cancel if no content
      _performCancel();
    }
  }

  /// ⭐ CANCEL CONFIRMATION DIALOG
  void _showCancelConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Task?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard this task?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              _performCancel(); // Perform cancel
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  /// ⭐ PERFORM CANCEL ACTION
  void _performCancel() {
    if (widget.onCancel != null) {
      // Case 1: Section/Date specific add task - close the form
      widget.onCancel!();
    } else {
      // Case 2: Main add task (Today/Upcoming) - clear input only
      _clearInput();
    }
  }

  /// ⭐ LEVEL 1: Clear Input Helper
  void _clearInput() {
    _textController.clear();
    // Reset project/section selection to default if no preset values
    if (widget.presetProjectId == null) {
      ref.read(newTodoProjectIdProvider.notifier).state = null;
    }
    if (widget.presetSectionId == null) {
      ref.read(newTodoSectionIdProvider.notifier).state = null;
    }
    // Reset date to today for main add task
    ref.read(newTodoDateProvider.notifier).state = DateTime.now();
  }

  /// ⭐ LEVEL 2: Smart Date Picker Dialog
  Future<void> _showDatePicker(BuildContext context) async {
    final selectedDate = ref.read(newTodoDateProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final newDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: today,
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: Theme.of(context).colorScheme),
          child: child!,
        );
      },
    );

    if (newDate != null) {
      ref.read(newTodoDateProvider.notifier).state = newDate;
    }
  }

  /// ⭐ FRONTEND HELPER METHODS ⭐

  String _getSmartHintText(SidebarItem currentView) {
    switch (currentView) {
      case SidebarItem.today:
        return 'Add task for today...';
      case SidebarItem.upcoming:
        return 'Add upcoming task...';
      default:
        return 'Add new task...';
    }
  }

  String _getDateDisplayText(DateTime date) {
    if (AppDateUtils.DateUtils.isToday(date)) {
      return 'Today';
    } else if (AppDateUtils.DateUtils.isTomorrow(date)) {
      return 'Tomorrow';
    } else {
      return DateFormat.yMMMd().format(date);
    }
  }

  /// ⭐ LEVEL 2: Project/Section Picker
  Widget _buildProjectSectionPicker(BuildContext context) {
    // Use local state if this is a preset context, otherwise use global providers
    final selectedProjectId = _useLocalState
        ? _localProjectId
        : ref.watch(newTodoProjectIdProvider);
    final selectedSectionId = _useLocalState
        ? _localSectionId
        : ref.watch(newTodoSectionIdProvider);
    final projectBox = ref.watch(projectBoxProvider);
    final sectionBox = ref.watch(enhancedSectionBoxProvider);

    // Get project name
    String projectDisplayText = 'Daily Tasks';
    if (selectedProjectId != null) {
      final project = projectBox.get(selectedProjectId);
      if (project != null) {
        // Use displayName property to ensure proper name display
        projectDisplayText = project.displayName;

        // If section is selected, show section name too
        if (selectedSectionId != null) {
          final section = sectionBox.get(selectedSectionId);
          if (section != null) {
            projectDisplayText = '${project.displayName} / ${section.name}';
          }
        }
      }
    }

    return IntrinsicWidth(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 80, // Minimum width for short text
          maxWidth: 200, // Maximum width to prevent overflow
        ),
        child: InkWell(
          onTap: () => _showProjectSectionDialog(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selectedProjectId != null ? Icons.folder : Icons.inbox,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    projectDisplayText,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  size: 16,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ⭐ LEVEL 2: Show Project/Section Selection Dialog
  void _showProjectSectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Project & Section'),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.6, // Limit height
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.inbox),
                title: const Text('Daily Tasks'),
                subtitle: const Text('Tasks not assigned to any project'),
                onTap: () {
                  if (_useLocalState) {
                    setState(() {
                      _localProjectId = null;
                      _localSectionId = null;
                    });
                  } else {
                    ref.read(newTodoProjectIdProvider.notifier).state = null;
                    ref.read(newTodoSectionIdProvider.notifier).state = null;
                  }
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              Expanded(
                // Make the projects list scrollable
                child: SingleChildScrollView(
                  child: Consumer(
                    builder: (context, ref, child) {
                      // ✅ FIX: Use filtered provider instead of direct box access
                      final projects = ref.watch(projectsProvider);

                      if (projects.isEmpty) {
                        return const ListTile(
                          title: Text('No projects available'),
                          subtitle: Text('Create a project first'),
                        );
                      }

                      return Column(
                        children: projects.map((project) {
                          return ExpansionTile(
                            leading: const Icon(Icons.folder),
                            title: Text(project.displayName),
                            children: [
                              Consumer(
                                builder: (context, ref, child) {
                                  // ✅ FIX: Use filtered provider instead of direct box access
                                  final sections = ref.watch(sectionsByProjectProvider(project.id));

                                  if (sections.isEmpty) {
                                    return const ListTile(
                                      contentPadding: EdgeInsets.only(left: 56),
                                      title: Text('No sections available'),
                                      subtitle: Text('Create a section first'),
                                    );
                                  }

                                  return Column(
                                    children: sections.map((section) {
                                      return ListTile(
                                        contentPadding: const EdgeInsets.only(
                                          left: 56,
                                        ),
                                        leading: const Icon(
                                          Icons.subdirectory_arrow_right,
                                        ),
                                        title: Text(section.name),
                                        onTap: () {
                                          if (_useLocalState) {
                                            setState(() {
                                              _localProjectId = project.id;
                                              _localSectionId = section.id;
                                            });
                                          } else {
                                            ref
                                                    .read(
                                                      newTodoProjectIdProvider
                                                          .notifier,
                                                    )
                                                    .state =
                                                project.id;
                                            ref
                                                    .read(
                                                      newTodoSectionIdProvider
                                                          .notifier,
                                                    )
                                                    .state =
                                                section.id;
                                          }
                                          Navigator.pop(context);
                                        },
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            ],
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// ⭐ LEVEL 2: Assignment Section Builder - COMPACT DESIGN LIKE PROJECT/DATE SELECTOR
  Widget _buildAssignmentSection(BuildContext context) {
    // Get current project ID to check if it's a shared project
    final selectedProjectId = _useLocalState
        ? _localProjectId
        : ref.watch(newTodoProjectIdProvider);

    // Only show assignment section if we have a project selected
    if (selectedProjectId == null) {
      return const SizedBox.shrink();
    }

    // Check if project is shared OR has potential for assignment
    final isShared = ref.watch(isSharedProjectProvider(selectedProjectId));
    final assignableUsers = ref.watch(assignableUsersInProjectProvider(selectedProjectId));

    // Show assignment section if project is shared OR has assignable users
    final shouldShowAssignment = isShared || assignableUsers.isNotEmpty;

    if (!shouldShowAssignment) {
      return const SizedBox.shrink();
    }

    // Get current assigned user for display
    String assigneeDisplay = 'Unassigned';
    if (_assignedUserId != null) {
      final assignedUser = assignableUsers.cast<User?>().firstWhere(
        (user) => user?.id == _assignedUserId,
        orElse: () => null,
      );
      if (assignedUser != null) {
        assigneeDisplay = assignedUser.displayName;
      }
    }

    // ✅ NEW: Compact assignment selector like project/date picker
    return Container(
      margin: const EdgeInsets.only(top: 8),
      height: 48,
      child: InkWell(
        onTap: () => _showAssignmentDialog(context, assignableUsers),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  assigneeDisplay,
                  style: TextStyle(
                    fontSize: 14,
                    color: _assignedUserId != null
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (isShared) ...[
                Icon(
                  Icons.group,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '(${assignableUsers.length})',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              Icon(
                Icons.arrow_drop_down,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ NEW: Show assignment dialog with user list
  void _showAssignmentDialog(BuildContext context, List<dynamic> assignableUsers) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Assignee'),
        content: SizedBox(
          width: 300,
          height: 400,
          child: Column(
            children: [
              // Unassigned option
              ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'UN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                title: const Text('Unassigned'),
                selected: _assignedUserId == null,
                onTap: () {
                  setState(() {
                    _assignedUserId = null;
                  });
                  Navigator.of(context).pop();
                },
              ),
              const Divider(),
              // User list
              Expanded(
                child: ListView.builder(
                  itemCount: assignableUsers.length,
                  itemBuilder: (context, index) {
                    final user = assignableUsers[index];
                    return ListTile(
                      leading: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _generateAvatarColor(user.id),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(user.displayName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      title: Text(user.displayName),
                      subtitle: Text('@${user.username}'),
                      selected: _assignedUserId == user.id,
                      onTap: () {
                        setState(() {
                          _assignedUserId = user.id;
                        });
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Helper methods for avatar generation
  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    List<String> nameParts = name.trim().split(' ');
    if (nameParts.length == 1) {
      return nameParts[0].substring(0, 1).toUpperCase();
    } else {
      return (nameParts[0].substring(0, 1) + nameParts[1].substring(0, 1)).toUpperCase();
    }
  }

  Color _generateAvatarColor(String input) {
    int hash = input.hashCode;
    List<Color> colors = [
      Colors.blue[600]!,
      Colors.green[600]!,
      Colors.orange[600]!,
      Colors.purple[600]!,
      Colors.teal[600]!,
      Colors.indigo[600]!,
      Colors.pink[600]!,
      Colors.cyan[600]!,
    ];
    return colors[hash.abs() % colors.length];
  }
}

/// ⭐ RIVERPOD LEVEL 2: Quick Add Widget
/// Simplified version for inline adding
class QuickAddTaskWidget extends ConsumerWidget {
  final DateTime? presetDate;
  final VoidCallback? onAdded;
  final String placeholder;

  const QuickAddTaskWidget({
    super.key,
    this.presetDate,
    this.onAdded,
    this.placeholder = 'Quick add task...',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          /// ⭐ LEVEL 1: Simple State Toggle
          if (presetDate != null) {
            ref.read(newTodoDateProvider.notifier).state = presetDate!;
          }
          ref.read(addTaskGroupDateProvider.notifier).state = presetDate;
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.3),
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
              const SizedBox(width: 12),
              Text(
                placeholder,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
