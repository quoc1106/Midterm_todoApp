/// 🎨 FRONTEND - Edit Todo Dialog Component
///
/// ⭐ RIVERPOD LEVEL 2-3 DEMONSTRATION ⭐
/// Edit dialog với date picker và project/section selection
/// Bao gồm rename task, change date, change project/section

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../backend/models/todo_model.dart';
import '../../../providers/todo_providers.dart';
import '../../../providers/performance_initialization_providers.dart';
import '../../../providers/shared_project_providers.dart'; // ✅ NEW: Import for assignment
import '../../../backend/models/project_model.dart';
import '../../../backend/models/section_model.dart';
import '../task_assignment/assign_user_dropdown.dart'; // ✅ NEW: Import assignment dropdown
import '../task_assignment/assigned_user_avatar.dart'; // ✅ NEW: Import avatar component

class EditTodoDialog extends ConsumerStatefulWidget {
  final Todo todo;

  const EditTodoDialog({super.key, required this.todo});

  @override
  ConsumerState<EditTodoDialog> createState() => _EditTodoDialogState();
}

class _EditTodoDialogState extends ConsumerState<EditTodoDialog> {
  late TextEditingController _titleController;
  late DateTime? _selectedDate;
  late String? _selectedProjectId;
  late String? _selectedSectionId;
  late String? _assignedUserId; // ✅ NEW: Assignment state

  /// ⭐ RIVERPOD LEVEL 2: Initialize with Todo Data
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo.description);
    _selectedDate = widget.todo.dueDate;

    // ⭐ LOAD EXISTING PROJECT/SECTION FROM TODO
    // Properly initialize with todo's project and section
    _selectedProjectId = widget.todo.projectId;
    _selectedSectionId = widget.todo.sectionId;
    _assignedUserId = widget.todo.assignedToId; // ✅ NEW: Initialize assignment
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectBox = ref.watch(projectBoxProvider);
    final sectionBox = ref.watch(sectionBoxProvider);

    return AlertDialog(
      title: const Text('Edit Task'), // ✅ CHANGED: English
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title field
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Task name', // ✅ CHANGED: English
                border: OutlineInputBorder(),
              ),
              maxLines: null,
            ),
            const SizedBox(height: 16),

            // Date picker
            _buildDatePicker(),
            const SizedBox(height: 16),

            // Project picker
            _buildProjectPicker(projectBox),
            const SizedBox(height: 16),

            // Section picker
            if (_selectedProjectId != null) _buildSectionPicker(sectionBox),
            const SizedBox(height: 16), // Add spacing between fields

            // Assigned user (assignment) section
            _buildAssignedUserSection(),
          ],
        ),
      ),
      actions: [
        // ✅ NEW: Delete button (icon thùng rác đỏ)
        IconButton(
          onPressed: _showDeleteConfirmation,
          icon: const Icon(Icons.delete),
          color: Colors.red,
          tooltip: 'Delete task', // ✅ CHANGED: English
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'), // ✅ CHANGED: English
        ),
        ElevatedButton(onPressed: _saveChanges, child: const Text('Save')), // ✅ CHANGED: English
      ],
    );
  }

  Widget _buildDatePicker() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_today),
        title: Text(
          _selectedDate != null
              ? '${_formatDate(_selectedDate!)}' // ✅ CHANGED: Only show date
              : 'Select date', // ✅ CHANGED: English
        ),
        trailing: _selectedDate != null
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => setState(() => _selectedDate = null),
              )
            : null,
        onTap: _pickDate,
      ),
    );
  }

  Widget _buildProjectPicker(dynamic projectBox) {
    final projects = projectBox.values.cast<ProjectModel>().toList();

    return Card(
      child: ListTile(
        leading: const Icon(Icons.folder),
        title: Text(
          _selectedProjectId != null
              ? 'Project: ${_getProjectName(projects, _selectedProjectId!)}'
              : 'Daily Tasks', // Changed from 'Chọn project' to 'Daily Tasks'
        ),
        trailing: _selectedProjectId != null
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => setState(() {
                  _selectedProjectId = null;
                  _selectedSectionId = null;
                }),
              )
            : null,
        onTap: () => _showProjectPicker(projects),
      ),
    );
  }

  Widget _buildSectionPicker(dynamic sectionBox) {
    final sections = sectionBox.values
        .cast<SectionModel>()
        .where((s) => s.projectId == _selectedProjectId)
        .toList();

    if (sections.isEmpty) return const SizedBox.shrink();

    return Card(
      child: ListTile(
        leading: const Icon(Icons.label),
        title: Text(
          _selectedSectionId != null
              ? 'Section: ${_getSectionName(sections, _selectedSectionId!)}'
              : 'Chọn section',
        ),
        trailing: _selectedSectionId != null
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => setState(() => _selectedSectionId = null),
              )
            : null,
        onTap: () => _showSectionPicker(sections),
      ),
    );
  }

  /// ✅ ENHANCED: Assignment section với avatar và proper project members
  Widget _buildAssignedUserSection() {
    // Get assigned user display name for better UI
    String assignedDisplayName = 'Unassigned'; // ✅ CHANGED: English
    if (_assignedUserId != null) {
      assignedDisplayName = ref.watch(userDisplayNameProvider(_assignedUserId!));
    }

    return Card(
      child: ListTile(
        leading: AssignedUserAvatar(
          assignedToId: _assignedUserId,
          assignedToDisplayName: assignedDisplayName == 'Unassigned' ? null : assignedDisplayName,
          size: 28,
        ),
        title: Text(
          _assignedUserId != null
              ? 'Assigned to: $assignedDisplayName' // ✅ CHANGED: English
              : 'Unassigned task', // ✅ CHANGED: English as requested
        ),
        trailing: _assignedUserId != null
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => setState(() => _assignedUserId = null),
              )
            : null,
        onTap: _showAssignUserDialog,
      ),
    );
  }

  /// ✅ ENHANCED: Assignment dialog với real project members
  void _showAssignUserDialog() {
    if (_selectedProjectId == null) {
      // No project selected - show message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a project first')), // ✅ CHANGED: English
      );
      return;
    }

    // Get assignable users from the selected project
    final assignableUsers = ref.read(assignableUsersInProjectProvider(_selectedProjectId!));

    if (assignableUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No members in this project')), // ✅ CHANGED: English
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Assignee'), // ✅ CHANGED: English
        content: SizedBox(
          width: 300,
          height: 400,
          child: Column(
            children: [
              // Option to unassign
              ListTile(
                leading: const AssignedUserAvatar(
                  assignedToId: null,
                  size: 28,
                ),
                title: const Text('Unassigned'), // ✅ CHANGED: English
                subtitle: const Text('No assignee'),
                onTap: () {
                  setState(() {
                    _assignedUserId = null;
                  });
                  Navigator.of(context).pop();
                },
              ),
              const Divider(),
              // Project members
              Expanded(
                child: ListView.builder(
                  itemCount: assignableUsers.length,
                  itemBuilder: (context, index) {
                    final user = assignableUsers[index];
                    return ListTile(
                      leading: AssignedUserAvatar(
                        assignedToId: user.id,
                        assignedToDisplayName: user.displayName,
                        size: 28,
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
            child: const Text('Cancel'), // ✅ CHANGED: English
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  void _showProjectPicker(List<ProjectModel> projects) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Project'), // ✅ CHANGED: English
        content: SizedBox(
          width: 250,
          height: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return ListTile(
                dense: true,
                title: Text(
                  project.name,
                  style: const TextStyle(fontSize: 14),
                ),
                onTap: () {
                  setState(() {
                    _selectedProjectId = project.id;
                    _selectedSectionId = null; // Reset section
                  });
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'), // ✅ CHANGED: English
          ),
        ],
      ),
    );
  }

  void _showSectionPicker(List<SectionModel> sections) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Section'), // ✅ CHANGED: English
        content: SizedBox(
          width: 250,
          height: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sections.length,
            itemBuilder: (context, index) {
              final section = sections[index];
              return ListTile(
                dense: true,
                title: Text(
                  section.name,
                  style: const TextStyle(fontSize: 14),
                ),
                onTap: () {
                  setState(() => _selectedSectionId = section.id);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'), // ✅ CHANGED: English
          ),
        ],
      ),
    );
  }

  void _saveChanges() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task name cannot be empty')), // ✅ CHANGED: English
      );
      return;
    }

    ref
        .read(todoListProvider.notifier)
        .edit(
          id: widget.todo.id,
          description: _titleController.text.trim(),
          dueDate: _selectedDate,
          projectId: _selectedProjectId,
          sectionId: _selectedSectionId,
          assignedToId: _assignedUserId, // ✅ NEW: Save assignment change
        );
    Navigator.of(context).pop();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Task updated successfully')));
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(todoListProvider.notifier).delete(widget.todo.id);
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Close the dialog and the edit screen
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Task deleted successfully')));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _getProjectName(List<ProjectModel> projects, String projectId) {
    try {
      return projects.firstWhere((p) => p.id == projectId).name;
    } catch (e) {
      return 'Unknown Project';
    }
  }

  String _getSectionName(List<SectionModel> sections, String sectionId) {
    try {
      return sections.firstWhere((s) => s.id == sectionId).name;
    } catch (e) {
      return 'Unknown Section';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
