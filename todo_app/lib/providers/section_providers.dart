import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../backend/models/section_model.dart';
import '../backend/models/todo_model.dart';
import 'todo_providers.dart';
import 'performance_initialization_providers.dart';

// Provider lấy danh sách task theo sectionId với auto-refresh
// Cải thiện: Đảm bảo UI rebuild khi có todo changes
final tasksBySectionProvider = Provider.family<List<Todo>, String>((
  ref,
  sectionId,
) {
  final todos = ref.watch(todoListProvider);
  return todos
      .where((todo) => todo.sectionId == sectionId && !todo.completed)
      .toList();
});

// Updated to use initialization provider - sectionBoxProvider now comes from performance_initialization_providers.dart

// Provider lấy tất cả sections (for search)
final allSectionsProvider = Provider<List<SectionModel>>((ref) {
  final box = ref.watch(enhancedSectionBoxProvider);
  return box.values.toList();
});

// Provider lấy danh sách sections theo projectId với auto-refresh
// Cải thiện: Listen đến cả sectionListNotifierProvider để UI rebuild khi có thay đổi
final sectionsByProjectProvider = Provider.family<List<SectionModel>, String>((
  ref,
  projectId,
) {
  // Watch both the box and the notifier to ensure UI rebuilds
  final box = ref.watch(enhancedSectionBoxProvider);
  final notifierState = ref.watch(sectionListNotifierProvider(projectId));

  // Use notifier state if available, otherwise fall back to box data
  // This ensures UI rebuilds when sections are added/modified/deleted
  return notifierState.isNotEmpty
      ? notifierState
      : box.values.where((s) => s.projectId == projectId).toList();
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
      final box = ref.watch(enhancedSectionBoxProvider);
      return SectionListNotifier(box, projectId);
    });
