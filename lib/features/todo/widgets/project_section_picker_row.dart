// Widget hiển thị và xử lý chọn project/section cho todo app.
// - Hiển thị tên project/section hiện tại, mở hộp thoại chọn khi nhấn.
// - Nhận props về id, tên, callback khi chọn mới.
// - Tái sử dụng cho nhiều view (Today, Upcoming, Section, Project).
// - Tích hợp với Riverpod qua ConsumerWidget.
//
// Sử dụng trong AddTaskWidget và các widget liên quan để chọn project/section cho task.
//
// -----------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'project_section_picker_dialog.dart';

class ProjectSectionPickerRow extends ConsumerWidget {
  final String? projectId;
  final String? projectName;
  final String? sectionId;
  final String? sectionName;
  final void Function(
    String? projectId,
    String? projectName,
    String? sectionId,
    String? sectionName,
  )
  onSelected;
  final bool enabled;
  const ProjectSectionPickerRow({
    Key? key,
    this.projectId,
    this.projectName,
    this.sectionId,
    this.sectionName,
    required this.onSelected,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IntrinsicWidth(
      child: GestureDetector(
        onTap: enabled
            ? () async {
                final result = await showProjectSectionPickerDialog(
                  context,
                  ref,
                );
                if (result != null) {
                  onSelected(
                    result['projectId'],
                    result['projectName'],
                    result['sectionId'],
                    result['sectionName'],
                  );
                }
              }
            : null,
        child: IntrinsicWidth(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 350),
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 12.0,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    projectId == null
                        ? 'Everyday Task'
                        : sectionId == null
                        ? '# ${projectName ?? projectId}'
                        : sectionName != null
                        ? '# ${projectName ?? projectId} / $sectionName'
                        : '# ${projectName ?? projectId} / $sectionId',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.expand_more, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
