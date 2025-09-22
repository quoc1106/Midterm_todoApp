/// File: todo_screen.dart
/// Purpose: Màn hình chính quản lý các công việc (Todo) của app.
/// - Hiển thị các view Today, Upcoming, Completed, Project/Section.
/// - Tích hợp các widget: AppDrawer (sidebar), AddTaskWidget, DateSelectorWidget, ProjectSectionWidget, TodoGroupWidget.
/// - Quản lý logic chuyển view, lọc và nhóm task, hiển thị task theo ngày/dự án/section.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/todo_providers.dart';
import '../widgets/project_section_widget.dart';
import '../widgets/app_drawer.dart';
import '../widgets/todo_group_widget.dart';
import '../widgets/add_task_widget.dart';
import '../widgets/date_selector_widget.dart';

class TodoScreen extends ConsumerWidget {
  bool _isPast(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    return d.isBefore(today);
  }

  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(filteredTodosProvider);
    final title = ref.watch(appBarTitleProvider);
    final groupedUpcoming = ref.watch(upcomingGroupedTodosProvider);
    final selectedItem = ref.watch(sidebarItemProvider);
    final selectedUpcomingDate = ref.watch(upcomingSelectedDateProvider);
    final selectedProjectId = ref.watch(selectedProjectIdProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              const AddTaskWidget(),
              const SizedBox(height: 12),
              if (selectedItem == SidebarItem.upcoming)
                const DateSelectorWidget(),
              const SizedBox(height: 12),
              Expanded(
                child: selectedItem == SidebarItem.upcoming
                    ? (() {
                        // ...existing code...
                        // (giữ nguyên logic Upcoming)
                        if (selectedUpcomingDate.year == 9999) {
                          if (groupedUpcoming.isEmpty) {
                            return const Center(
                              child: Text('Không có công việc nào!'),
                            );
                          }
                          return ListView(
                            children: [
                              for (final group in groupedUpcoming)
                                TodoGroupWidget(
                                  groupDate: group.date,
                                  todos: group.todos,
                                ),
                            ],
                          );
                        }
                        final group = groupedUpcoming.firstWhere(
                          (g) =>
                              g.date.year == selectedUpcomingDate.year &&
                              g.date.month == selectedUpcomingDate.month &&
                              g.date.day == selectedUpcomingDate.day,
                          orElse: () => GroupedTodos(selectedUpcomingDate, []),
                        );
                        return group.todos.isEmpty
                            ? const Center(
                                child: Text(
                                  'Không có công việc nào cho ngày này!',
                                ),
                              )
                            : Consumer(
                                builder: (context, ref, _) {
                                  final isOpen =
                                      ref.watch(addTaskGroupDateProvider) ==
                                      group.date;
                                  return ListView(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8.0,
                                        ),
                                        child: Text(
                                          '${group.date.day}/${group.date.month}/${group.date.year}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      ...group.todos.map(
                                        (todo) => TodoItem(todo: todo),
                                      ),
                                      if (!isOpen && !_isPast(group.date))
                                        TextButton.icon(
                                          icon: const Icon(
                                            Icons.add_circle,
                                            color: Colors.red,
                                          ),
                                          label: const Text(
                                            'Add task',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                          onPressed: () {
                                            ref
                                                    .read(
                                                      addTaskGroupDateProvider
                                                          .notifier,
                                                    )
                                                    .state =
                                                group.date;
                                          },
                                        ),
                                      if (isOpen)
                                        AddTaskWidget(
                                          showCancel: true,
                                          initialDate: group.date,
                                        ),
                                    ],
                                  );
                                },
                              );
                      })()
                    : (selectedItem == SidebarItem.myProject &&
                              selectedProjectId != null
                          ? ProjectSectionWidget(projectId: selectedProjectId)
                          : (todos.isEmpty
                                ? const Center(
                                    child: Text(
                                      'Tuyệt vời, không có công việc nào!',
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: todos.length,
                                    itemBuilder: (context, index) {
                                      return TodoItem(todo: todos[index]);
                                    },
                                  ))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
