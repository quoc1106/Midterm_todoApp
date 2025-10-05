// Hàm hiển thị hộp thoại chọn project/section cho todo app.
// - Trả về id và tên project/section được chọn.
// - Dùng cho UI chọn project/section khi thêm hoặc sửa task.
// - Tích hợp với Riverpod để lấy danh sách project/section từ provider.
// - Hỗ trợ chọn Everyday Task (không gắn với project/section nào).
//
// Sử dụng trong các widget thêm/sửa task để chọn project/section.
//
//
// -----------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/project_providers.dart';
import '../../../providers/section_providers.dart';

/// Hiển thị hộp thoại chọn project/section, trả về Map chứa id và name
Future<Map<String, String?>?> showProjectSectionPickerDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  return showDialog<Map<String, String?>>(
    context: context,
    builder: (context) {
      return Consumer(
        builder: (context, ref, _) {
          final projects = ref.watch(projectsProvider);
          return AlertDialog(
            title: const Text('Chọn Project & Section'),
            content: SizedBox(
              width: 300,
              height: 350,
              child: ListView(
                children: [
                  ListTile(
                    leading: const Icon(Icons.star_border),
                    title: const Text(
                      'Everyday Task',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      Navigator.of(context).pop({
                        'projectId': null,
                        'projectName': null,
                        'sectionId': null,
                        'sectionName': null,
                      });
                    },
                  ),
                  ...projects.map((project) {
                    final sections = ref.watch(
                      sectionsByProjectProvider(project.id),
                    );
                    return ExpansionTile(
                      title: Text(
                        project.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      children: [
                        ...sections.map(
                          (section) => ListTile(
                            title: Text(section.name),
                            onTap: () {
                              Navigator.of(context).pop({
                                'projectId': project.id,
                                'projectName': project.name,
                                'sectionId': section.id,
                                'sectionName': section.name,
                              });
                            },
                          ),
                        ),
                        ListTile(
                          title: const Text('Không chọn section'),
                          onTap: () {
                            Navigator.of(context).pop({
                              'projectId': project.id,
                              'projectName': project.name,
                              'sectionId': null,
                              'sectionName': null,
                            });
                          },
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
