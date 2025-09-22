/// File: project_sidebar_widget.dart
/// Purpose: Hiển thị sidebar quản lý các project (dự án) của người dùng.
/// - Cho phép thêm, sửa, xóa project.
/// - Chọn project để xem các section/task liên quan.
/// Sử dụng trong AppDrawer (sidebar chính).
/// Team: Đọc phần này để hiểu logic sidebar project và thao tác với project.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/todo_providers.dart';
import '../../../providers/project_providers.dart';

class ProjectSidebarWidget extends ConsumerWidget {
  const ProjectSidebarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider); // List<ProjectModel>
    return ExpansionTile(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('My Projects'),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Project',
            onPressed: () async {
              final name = await _showAddDialog(context);
              if (name != null && name.isNotEmpty) {
                ref.read(projectsProvider.notifier).addProject(name);
              }
            },
          ),
        ],
      ),
      children: [
        for (final project in projects)
          ListTile(
            title: Text(project.name),
            onTap: () {
              ref.read(sidebarItemProvider.notifier).state =
                  SidebarItem.myProject;
              ref.read(selectedProjectIdProvider.notifier).state = project.id;
              Navigator.pop(context);
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final newName = await _showRenameDialog(
                      context,
                      project.name,
                    );
                    if (newName != null && newName.isNotEmpty) {
                      ref
                          .read(projectsProvider.notifier)
                          .updateProject(project.id, newName);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    ref
                        .read(projectsProvider.notifier)
                        .deleteProject(project.id);
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<String?> _showAddDialog(BuildContext context) async {
    String value = '';
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Project'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Project name'),
          onChanged: (v) => value = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, value),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showRenameDialog(
    BuildContext context,
    String oldName,
  ) async {
    String value = oldName;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Project'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: 'New name'),
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
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }
}
