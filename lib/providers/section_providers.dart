import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/section_model.dart';
import '../models/todo_model.dart';
import 'todo_providers.dart';

// Provider lấy danh sách task theo sectionId
final tasksBySectionProvider = Provider.family<List<Todo>, String>((
  ref,
  sectionId,
) {
  final todos = ref.watch(todoListProvider);
  return todos
      .where((todo) => todo.sectionId == sectionId && !todo.completed)
      .toList();
});

final sectionBoxProvider = Provider<Box<SectionModel>>(
  (ref) => Hive.box<SectionModel>('sections'),
);

final sectionsByProjectProvider = Provider.family<List<SectionModel>, String>((
  ref,
  projectId,
) {
  final box = ref.watch(sectionBoxProvider);
  return box.values.where((s) => s.projectId == projectId).toList();
});

class SectionListNotifier extends StateNotifier<List<SectionModel>> {
  SectionListNotifier(this.box, this.projectId)
    : super(box.values.where((s) => s.projectId == projectId).toList());
  final Box<SectionModel> box;
  final String projectId;

  void addSection(String name) {
    final section = SectionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      projectId: projectId,
    );
    box.put(section.id, section);
    state = box.values.where((s) => s.projectId == projectId).toList();
  }

  void updateSection(String id, String name) {
    final section = box.get(id);
    if (section != null) {
      section.name = name;
      box.put(id, section);
      state = box.values.where((s) => s.projectId == projectId).toList();
    }
  }

  void deleteSection(String id) {
    box.delete(id);
    // Xóa tất cả các task liên kết với section này
    final todoBox = Hive.box<Todo>('todos');
    final toDelete = todoBox.values
        .where((todo) => todo.sectionId == id)
        .toList();
    for (final todo in toDelete) {
      final idx = todoBox.values.toList().indexWhere((t) => t.id == todo.id);
      if (idx != -1) {
        todoBox.deleteAt(idx);
      }
    }
    state = box.values.where((s) => s.projectId == projectId).toList();
  }
}

final sectionListNotifierProvider =
    StateNotifierProvider.family<
      SectionListNotifier,
      List<SectionModel>,
      String
    >((ref, projectId) {
      final box = ref.watch(sectionBoxProvider);
      return SectionListNotifier(box, projectId);
    });
