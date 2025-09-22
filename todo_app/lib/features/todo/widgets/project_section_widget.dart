/// File: project_section_widget.dart
/// Purpose: Hiển thị các section (phân nhóm) trong một project, kèm danh sách task của từng section.
/// - Cho phép thêm section mới, xem/chỉnh sửa/xóa task trong từng section.
/// - Có tab Today tasks để xem các task của hôm nay trong project.
/// Sử dụng khi chọn một project ở sidebar.
/// Team: Đọc phần này để hiểu logic hiển thị section và task theo project.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/section_providers.dart';
import 'package:todo_app/features/todo/widgets/add_task_widget.dart';
import 'package:todo_app/features/todo/widgets/todo_item.dart';

class ProjectSectionWidget extends ConsumerStatefulWidget {
  final String projectId;
  const ProjectSectionWidget({super.key, required this.projectId});

  @override
  ConsumerState<ProjectSectionWidget> createState() =>
      _ProjectSectionWidgetState();
}

class _ProjectSectionWidgetState extends ConsumerState<ProjectSectionWidget> {
  // Track which section is showing the add task form
  String? _openAddTaskSectionId;

  void _toggleAddTask(String sectionId, [bool? value]) {
    setState(() {
      if (value == true) {
        _openAddTaskSectionId = sectionId;
      } else {
        if (_openAddTaskSectionId == sectionId) {
          _openAddTaskSectionId = null;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sections = ref.watch(sectionListNotifierProvider(widget.projectId));
    final today = DateTime.now();
    final todayTasks = [
      for (final section in sections)
        ...ref
            .watch(tasksBySectionProvider(section.id))
            .where(
              (task) =>
                  task.dueDate != null &&
                  task.dueDate!.year == today.year &&
                  task.dueDate!.month == today.month &&
                  task.dueDate!.day == today.day,
            ),
    ];
    bool showTodayTasks = false;
    Color backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    Color textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    return SingleChildScrollView(
      child: StatefulBuilder(
        builder: (context, setState) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          showTodayTasks = false;
                        });
                      },
                      child: Text(
                        'Sections',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: !showTodayTasks
                              ? Colors.indigoAccent
                              : textColor.withOpacity(0.7),
                          decoration: !showTodayTasks
                              ? TextDecoration.underline
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          showTodayTasks = true;
                        });
                      },
                      child: Text(
                        'Today tasks',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: showTodayTasks
                              ? Colors.indigoAccent
                              : textColor.withOpacity(0.7),
                          decoration: showTodayTasks
                              ? TextDecoration.underline
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    final name = await _showSectionDialog(context);
                    if (name != null && name.isNotEmpty) {
                      ref
                          .read(
                            sectionListNotifierProvider(
                              widget.projectId,
                            ).notifier,
                          )
                          .addSection(name);
                    }
                  },
                ),
              ],
            ),
            if (showTodayTasks)
              Card(
                color: backgroundColor,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today tasks',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor,
                        ),
                      ),
                      if (todayTasks.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Không có công việc nào hôm nay!',
                            style: TextStyle(color: textColor.withOpacity(0.7)),
                          ),
                        ),
                      ...todayTasks.map((task) => TodoItem(todo: task)),
                    ],
                  ),
                ),
              ),
            if (!showTodayTasks)
              ...sections.map((section) {
                final tasks = ref.watch(tasksBySectionProvider(section.id));
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              section.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () async {
                                    final newName = await _showSectionDialog(
                                      context,
                                      oldName: section.name,
                                    );
                                    if (newName != null && newName.isNotEmpty) {
                                      ref
                                          .read(
                                            sectionListNotifierProvider(
                                              widget.projectId,
                                            ).notifier,
                                          )
                                          .updateSection(section.id, newName);
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    ref
                                        .read(
                                          sectionListNotifierProvider(
                                            widget.projectId,
                                          ).notifier,
                                        )
                                        .deleteSection(section.id);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        ...tasks.map((task) => TodoItem(todo: task)),
                        if (_openAddTaskSectionId != section.id)
                          Align(
                            alignment: Alignment.center,
                            child: TextButton.icon(
                              icon: const Icon(
                                Icons.add_circle,
                                color: Colors.red,
                              ),
                              label: const Text(
                                'Add task',
                                style: TextStyle(color: Colors.red),
                              ),
                              onPressed: () => _toggleAddTask(section.id, true),
                            ),
                          ),
                        if (_openAddTaskSectionId == section.id)
                          AddTaskWidget(
                            showCancel: true,
                            key: ValueKey(
                              'add_task_${widget.projectId}_${section.id}',
                            ),
                            initialDate: null,
                            onCancel: () => _toggleAddTask(section.id, false),
                            projectId: widget.projectId,
                            sectionId: section.id,
                          ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Future<String?> _showSectionDialog(
    BuildContext context, {
    String oldName = '',
  }) async {
    String value = oldName;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(oldName.isEmpty ? 'Add Section' : 'Edit Section'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Section name'),
          controller: TextEditingController(text: oldName),
          onChanged: (v) => value = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, value),
            child: Text(oldName.isEmpty ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }
}
