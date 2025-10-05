// Widget hiển thị một công việc (task) trong todo app.
// - Hiển thị nội dung, ngày, trạng thái hoàn thành, project/section nếu có.
// - Xử lý sửa, xóa, đánh dấu hoàn thành cho từng task.
// - Tích hợp với Riverpod để cập nhật trạng thái và dữ liệu.
// - Sử dụng trong danh sách công việc ở các màn hình chính (Today, Upcoming, Section, Project, Completed).
//
// -----------------------------

import 'package:flutter/material.dart'
    hide DateUtils; // Thêm 'hide DateUtils' vào đây
// Sử dụng Riverpod để quản lý state cho từng item công việc
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/todo_model.dart';
// Import các provider liên quan đến todo (Riverpod)
import '../../../providers/todo_providers.dart';
import '../../../providers/project_providers.dart';
import '../../../providers/section_providers.dart';

class TodoItem extends ConsumerWidget {
  final Todo todo;

  const TodoItem({super.key, required this.todo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String? projectName;
    String? sectionName;
    if (todo.projectId != null) {
      final box = ref.read(projectBoxProvider);
      final project = box.get(todo.projectId!);
      projectName = project?.name;
    }
    if (todo.sectionId != null) {
      final box = ref.read(sectionBoxProvider);
      final section = box.get(todo.sectionId!);
      sectionName = section?.name;
    }
    String? subtitleText;
    if (todo.dueDate != null) {
      subtitleText =
          '${todo.dueDate!.day}/${todo.dueDate!.month}/${todo.dueDate!.year}';
    }
    if (projectName != null || sectionName != null) {
      final projectPart = projectName != null ? 'Project: $projectName' : '';
      final sectionPart = sectionName != null ? 'Section: $sectionName' : '';
      final parts = [
        projectPart,
        sectionPart,
      ].where((e) => e.isNotEmpty).join(' / ');
      subtitleText = subtitleText != null ? '$subtitleText • $parts' : parts;
    }
    return ListTile(
      leading: Checkbox(
        value: todo.completed,
        onChanged: (val) {
          ref.read(todoListProvider.notifier).toggle(todo.id);
        },
      ),
      title: Text(
        todo.description,
        // Add strike-through and gray color for completed tasks to visually indicate status.
        // This enhances UX without changing any logic.
        style: TextStyle(
          decoration: todo.completed ? TextDecoration.lineThrough : null,
          color: todo.completed ? Colors.grey : null,
        ),
      ),
      subtitle: subtitleText != null ? Text(subtitleText) : null,
      onTap: () async {
        final newDesc = await showDialog<String>(
          context: context,
          builder: (ctx) {
            final controller = TextEditingController(text: todo.description);
            return AlertDialog(
              title: const Text('Chỉnh sửa công việc'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(labelText: 'Mô tả'),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      todo.dueDate != null
                          ? '${todo.dueDate!.day}/${todo.dueDate!.month}/${todo.dueDate!.year}'
                          : 'Chọn ngày',
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: todo.dueDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        Navigator.of(
                          ctx,
                        ).pop(controller.text + '|${picked.toIso8601String()}');
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(controller.text),
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
        if (newDesc != null && newDesc.isNotEmpty) {
          if (newDesc.contains('|')) {
            final parts = newDesc.split('|');
            ref
                .read(todoListProvider.notifier)
                .edit(
                  id: todo.id,
                  description: parts[0],
                  dueDate: DateTime.parse(parts[1]),
                );
          } else {
            ref
                .read(todoListProvider.notifier)
                .edit(id: todo.id, description: newDesc);
          }
        }
      },
      trailing: Consumer(  // NEW: Wrap in Consumer to watch sidebarItemProvider inside TodoItem
        builder: (context, ref, child) {
          final selectedItem = ref.watch(sidebarItemProvider);  // Watch the current sidebar view
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selectedItem != SidebarItem.completed)  // NEW: Only show pin if NOT in Completed view
                IconButton(
                  icon: Icon(
                    todo.isPinned ? Icons.star : Icons.star_border,
                    color: todo.isPinned ? Colors.yellow : null,
                  ),
                  tooltip: 'Pin task',
                  onPressed: () {
                    ref.read(todoListProvider.notifier).togglePin(todo.id);
                  },
                ),
              // Keep delete button always visible (in all views)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Xóa',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Xóa công việc'),
                      content: const Text('Bạn có chắc muốn xóa công việc này?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Xóa'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    ref.read(todoListProvider.notifier).remove(todo);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}