/// File: todo_group_widget.dart
/// Purpose: Hiển thị nhóm các công việc (Todo) theo ngày, gồm danh sách các task chưa hoàn thành và nút/thành phần thêm task mới cho từng ngày.
/// - TodoGroupWidget: Hiển thị các task theo từng ngày, cho phép thêm task mới vào ngày đó.
/// - TodoItem: Hiển thị, chỉnh sửa, xóa từng task, kèm thông tin project/section liên quan.
/// Sử dụng trong màn hình Upcoming và các view nhóm theo ngày.
/// Team: Đọc phần này để hiểu logic nhóm task theo ngày và cách thêm/chỉnh sửa/xóa task.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/todo_providers.dart';
import '../../../models/todo_model.dart';
// import '../../../providers/project_providers.dart';
// import '../../../providers/section_providers.dart';
import 'add_task_widget.dart';
import 'todo_item.dart';

// --- WIDGET THỨ NHẤT ---
class TodoGroupWidget extends ConsumerWidget {
  final DateTime groupDate;
  final List<Todo> todos;
  const TodoGroupWidget({
    Key? key,
    required this.groupDate,
    required this.todos,
  }) : super(key: key);

  bool _isPast(DateTime date) {
    final now = DateTime.now();
    return date.isBefore(DateTime(now.year, now.month, now.day));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTodos = todos.where((todo) => !todo.completed).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            '${groupDate.day}/${groupDate.month}/${groupDate.year}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        // Hiển thị danh sách các TodoItem chưa completed
        ...activeTodos.map((todo) => TodoItem(todo: todo)).toList(),

        // Hiển thị nút "Add task" hoặc widget để thêm task mới
        Consumer(
          builder: (context, ref, _) {
            final isOpen = ref.watch(addTaskGroupDateProvider) == groupDate;
            return Column(
              children: [
                if (!isOpen && !_isPast(groupDate))
                  TextButton.icon(
                    icon: const Icon(Icons.add_circle, color: Colors.red),
                    label: const Text(
                      'Add task',
                      style: TextStyle(color: Colors.red),
                    ),
                    onPressed: () {
                      ref.read(newTodoDateProvider.notifier).state = groupDate;
                      ref.read(addTaskGroupDateProvider.notifier).state =
                          groupDate;
                    },
                  ),
                if (isOpen)
                  AddTaskWidget(showCancel: true, initialDate: groupDate),
              ],
            );
          },
        ),
      ],
    );
  }
}

// --- WIDGET THỨ HAI --- (Tách biệt hoàn toàn với class ở trên)
// class TodoItem extends ConsumerWidget {
//   final Todo todo;
//   const TodoItem({Key? key, required this.todo}) : super(key: key);

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     String? projectName;
//     String? sectionName;
//     if (todo.projectId != null) {
//       final box = ref.read(projectBoxProvider);
//       final project = box.get(todo.projectId!);
//       projectName = project?.name;
//     }
//     if (todo.sectionId != null) {
//       final box = ref.read(sectionBoxProvider);
//       final section = box.get(todo.sectionId!);
//       sectionName = section?.name;
//     }
//     String? subtitleText;
//     if (todo.dueDate != null) {
//       subtitleText =
//           '${todo.dueDate!.day}/${todo.dueDate!.month}/${todo.dueDate!.year}';
//     }
//     if (projectName != null || sectionName != null) {
//       final projectPart = projectName != null ? 'Project: $projectName' : '';
//       final sectionPart = sectionName != null ? 'Section: $sectionName' : '';
//       final parts = [
//         projectPart,
//         sectionPart,
//       ].where((e) => e.isNotEmpty).join(' / ');
//       subtitleText = subtitleText != null ? '$subtitleText • $parts' : parts;
//     }
//     return ListTile(
//       leading: Checkbox(
//         value: todo.completed,
//         onChanged: (val) {
//           ref.read(todoListProvider.notifier).toggle(todo.id);
//         },
//       ),
//       title: Text(todo.description),
//       subtitle: subtitleText != null ? Text(subtitleText) : null,
//       onTap: () async {
//         final newDesc = await showDialog<String>(
//           context: context,
//           builder: (ctx) {
//             final controller = TextEditingController(text: todo.description);
//             return AlertDialog(
//               title: const Text('Chỉnh sửa công việc'),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   TextField(
//                     controller: controller,
//                     decoration: const InputDecoration(labelText: 'Mô tả'),
//                   ),
//                   const SizedBox(height: 12),
//                   TextButton.icon(
//                     icon: const Icon(Icons.calendar_today),
//                     label: Text(
//                       todo.dueDate != null
//                           ? '${todo.dueDate!.day}/${todo.dueDate!.month}/${todo.dueDate!.year}'
//                           : 'Chọn ngày',
//                     ),
//                     onPressed: () async {
//                       final picked = await showDatePicker(
//                         context: ctx,
//                         initialDate: todo.dueDate ?? DateTime.now(),
//                         firstDate: DateTime.now(),
//                         lastDate: DateTime(2030),
//                       );
//                       if (picked != null) {
//                         Navigator.of(
//                           ctx,
//                         ).pop(controller.text + '|${picked.toIso8601String()}');
//                       }
//                     },
//                   ),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.of(ctx).pop(),
//                   child: const Text('Hủy'),
//                 ),
//                 TextButton(
//                   onPressed: () => Navigator.of(ctx).pop(controller.text),
//                   child: const Text('Lưu'),
//                 ),
//               ],
//             );
//           },
//         );
//         if (newDesc != null && newDesc.isNotEmpty) {
//           if (newDesc.contains('|')) {
//             final parts = newDesc.split('|');
//             ref
//                 .read(todoListProvider.notifier)
//                 .edit(
//                   id: todo.id,
//                   description: parts[0],
//                   dueDate: DateTime.parse(parts[1]),
//                 );
//           } else {
//             ref
//                 .read(todoListProvider.notifier)
//                 .edit(id: todo.id, description: newDesc);
//           }
//         }
//       },
//       trailing: IconButton(
//         icon: const Icon(Icons.delete, color: Colors.red),
//         tooltip: 'Xóa',
//         onPressed: () async {
//           final confirm = await showDialog<bool>(
//             context: context,
//             builder: (ctx) => AlertDialog(
//               title: const Text('Xóa công việc'),
//               content: const Text('Bạn có chắc muốn xóa công việc này?'),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.of(ctx).pop(false),
//                   child: const Text('Hủy'),
//                 ),
//                 TextButton(
//                   onPressed: () => Navigator.of(ctx).pop(true),
//                   child: const Text('Xóa'),
//                 ),
//               ],
//             ),
//           );
//           if (confirm == true) {
//             ref.read(todoListProvider.notifier).remove(todo);
//           }
//         },
//       ),
//     );
//   }
// }
