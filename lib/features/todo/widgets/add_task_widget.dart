// Widget thêm công việc mới cho todo app.
// - Hiển thị ô nhập nội dung, chọn ngày, chọn project/section.
// - Lưu công việc vào provider, hỗ trợ logic cho Today, Upcoming, Completed.
// - Tích hợp các widget chọn project/section, chọn ngày, xử lý UI/UX thêm task.
// - Ẩn ô thêm công việc khi ở view Completed.
// - Sử dụng Riverpod để quản lý state và tương tác dữ liệu.
//
// Sử dụng trong các màn hình chính để thêm task mới vào hệ thống.
//
//
// -----------------------------

import 'project_section_picker_row.dart';
import 'package:flutter/material.dart' hide DateUtils;
// Sử dụng Riverpod để quản lý state cho widget thêm công việc
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
// Import các provider liên quan đến todo (Riverpod)
import '../../../providers/todo_providers.dart';
import '../../../providers/section_providers.dart';
import '../../../providers/project_providers.dart';

// Sử dụng provider newTodoDateProvider từ todo_providers.dart

class AddTaskWidget extends ConsumerStatefulWidget {
  final bool showCancel;
  final DateTime? initialDate;
  final VoidCallback? onCancel;
  final String? projectId;
  final String? sectionId;
  final String? projectName;
  final String? sectionName;
  const AddTaskWidget({
    super.key,
    this.showCancel = false,
    this.initialDate,
    this.onCancel,
    this.projectId,
    this.sectionId,
    this.projectName,
    this.sectionName,
  });

  @override
  ConsumerState<AddTaskWidget> createState() => _AddTaskWidgetState();
}

class _AddTaskWidgetState extends ConsumerState<AddTaskWidget> {
  String? _selectedProjectId;
  String? _selectedProjectName;
  String? _selectedSectionId;
  String? _selectedSectionName;
  // Không cần _expandedProjects nữa, dùng ExpansionTile
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    if (widget.initialDate != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(newTodoDateProvider.notifier).state = widget.initialDate!;
      });
    }
    _selectedProjectId = widget.projectId;
    _selectedProjectName = widget.projectName;
    _selectedSectionId = widget.sectionId;
    _selectedSectionName = widget.sectionName;

    // Nếu có id mà chưa có tên, tự động lấy tên từ provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedProjectId != null &&
          (_selectedProjectName == null || _selectedProjectName!.isEmpty)) {
        final box = ref.read(projectBoxProvider);
        final project = box.get(_selectedProjectId!);
        if (project != null) {
          setState(() {
            _selectedProjectName = project.name;
          });
        }
      }
      if (_selectedSectionId != null &&
          (_selectedSectionName == null || _selectedSectionName!.isEmpty)) {
        final box = ref.read(sectionBoxProvider);
        final section = box.get(_selectedSectionId!);
        if (section != null) {
          setState(() {
            _selectedSectionName = section.name;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submitData() {
    if (_textController.text.isEmpty) {
      return;
    }
    final selectedDate = ref.read(newTodoDateProvider);
    final currentView = ref.read(sidebarItemProvider);
    if (currentView == SidebarItem.upcoming) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (selectedDate.isBefore(today)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Vui lòng chọn ngày từ hôm nay trở đi cho mục Upcoming.',
            ),
          ),
        );
        return;
      }
    }
    // Nếu chọn Everyday Task thì projectId và sectionId phải là null
    final isEverydayTask =
        _selectedProjectId == null && _selectedSectionId == null;
    ref
        .read(todoListProvider.notifier)
        .add(
          _textController.text,
          dueDate: selectedDate,
          projectId: isEverydayTask
              ? null
              : (_selectedProjectId ?? widget.projectId),
          sectionId: isEverydayTask
              ? null
              : (_selectedSectionId ?? widget.sectionId),
        );
    _textController.clear();
    ref.invalidate(newTodoDateProvider);
    // Không reset lựa chọn project/section sau khi thêm task
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final selectedItem = ref.watch(sidebarItemProvider);
    if (selectedItem == SidebarItem.completed) {
      return const SizedBox.shrink();
    }
    // Sử dụng các provider Riverpod để lấy ngày và trạng thái sidebar
    final selectedDate = ref.watch(newTodoDateProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    String hintText = 'Thêm công việc...';
    if (selectedItem == SidebarItem.today) {
      hintText = 'Thêm công việc cho hôm nay...';
    } else if (selectedItem == SidebarItem.upcoming) {
      hintText = 'Thêm công việc mới...';
    }
    final currentView = selectedItem;
    // final projects = ref.watch(projectsProvider); // Không dùng, xoá để hết lỗi lint
    // Nếu có sectionId, lấy tên section từ provider
    // Xoá biến sectionName không dùng nữa
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _submitData(),
            ),
            if (currentView == SidebarItem.today)
              Row(
                children: [
                  ProjectSectionPickerRow(
                    projectId: _selectedProjectId,
                    projectName: _selectedProjectName,
                    sectionId: _selectedSectionId,
                    sectionName: _selectedSectionName,
                    onSelected:
                        (projectId, projectName, sectionId, sectionName) {
                          setState(() {
                            _selectedProjectId = projectId;
                            _selectedProjectName = projectName;
                            _selectedSectionId = sectionId;
                            _selectedSectionName = sectionName;
                          });
                        },
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.add_circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: _submitData,
                  ),
                  if (widget.showCancel)
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        if (widget.onCancel != null) {
                          widget.onCancel!();
                        } else {
                          ref.read(addTaskGroupDateProvider.notifier).state =
                              null;
                        }
                      },
                    ),
                ],
              ),
            if (currentView != SidebarItem.today)
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final newDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: today,
                        lastDate: DateTime(2030),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.dark(
                                primary: Colors.white,
                                onPrimary: Colors.white,
                                surface: Colors.grey[900]!,
                                onSurface: Colors.white,
                              ),
                              dialogBackgroundColor: Colors.grey[900],
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (newDate != null) {
                        ref.read(newTodoDateProvider.notifier).state = newDate;
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 4.0,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateUtils.isToday(selectedDate)
                                ? 'Today'
                                : DateFormat.yMMMd().format(selectedDate),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ProjectSectionPickerRow(
                    projectId: _selectedProjectId,
                    projectName: _selectedProjectName,
                    sectionId: _selectedSectionId,
                    sectionName: _selectedSectionName,
                    onSelected:
                        (projectId, projectName, sectionId, sectionName) {
                          setState(() {
                            _selectedProjectId = projectId;
                            _selectedProjectName = projectName;
                            _selectedSectionId = sectionId;
                            _selectedSectionName = sectionName;
                          });
                        },
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.add_circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: _submitData,
                  ),
                  if (widget.showCancel)
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        if (widget.onCancel != null) {
                          widget.onCancel!();
                        } else {
                          ref.read(addTaskGroupDateProvider.notifier).state =
                              null;
                        }
                      },
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
