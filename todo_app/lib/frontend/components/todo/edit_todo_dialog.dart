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
import '../../../backend/models/project_model.dart';
import '../../../backend/models/section_model.dart';

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
      title: const Text('Chỉnh sửa Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title field
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tên task',
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(onPressed: _saveChanges, child: const Text('Lưu')),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_today),
        title: Text(
          _selectedDate != null
              ? 'Ngày: ${_formatDate(_selectedDate!)}'
              : 'Chọn ngày',
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
        title: const Text('Chọn Project'),
        content: SizedBox(
          width: 250, // Reduced from 300
          height: 300, // Reduced from 400
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return ListTile(
                dense: true, // Make list items more compact
                title: Text(
                  project.name,
                  style: const TextStyle(fontSize: 14), // Smaller text
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
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  void _showSectionPicker(List<SectionModel> sections) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn Section'),
        content: SizedBox(
          width: 250, // Reduced from 300
          height: 300, // Reduced from 400
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sections.length,
            itemBuilder: (context, index) {
              final section = sections[index];
              return ListTile(
                dense: true, // Make list items more compact
                title: Text(
                  section.name,
                  style: const TextStyle(fontSize: 14), // Smaller text
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
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  void _saveChanges() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tên task không được để trống')),
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
        );
    Navigator.of(context).pop();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã cập nhật task')));
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
