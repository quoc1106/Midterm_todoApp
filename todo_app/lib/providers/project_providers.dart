import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../backend/models/project_model.dart';
import 'performance_initialization_providers.dart';
import 'todo_providers.dart'; // Import để access todoListProvider
import 'selection_validation_providers.dart'; // Import validation providers

// Updated to use enhanced initialization provider với performance monitoring

class ProjectListNotifier extends StateNotifier<List<ProjectModel>> {
  final Box<ProjectModel> box;
  final Ref ref;

  ProjectListNotifier(this.box, this.ref) : super(box.values.toList());

  void addProject(String name) {
    final project = ProjectModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
    );
    box.put(project.id, project);
    state = box.values.toList();
  }

  void updateProject(String id, String name) {
    final project = box.get(id);
    if (project != null) {
      project.name = name;
      box.put(id, project);
      state = box.values.toList();
    }
  }

  void deleteProject(String id) {
    // Cascade delete: Xóa tất cả tasks thuộc project này
    final todoBox = ref.read(enhancedTodoBoxProvider);
    final todosToDelete = todoBox.values
        .where((todo) => todo.projectId == id)
        .toList();

    // Xóa todos bằng key thay vì index để tránh lỗi
    for (final todo in todosToDelete) {
      final todoKeys = todoBox.keys.toList();
      for (final key in todoKeys) {
        final todoValue = todoBox.get(key);
        if (todoValue?.id == todo.id) {
          todoBox.delete(key);
        }
      }
    }

    // Cascade delete: Xóa tất cả sections thuộc project này
    final sectionBox = ref.read(enhancedSectionBoxProvider);
    final sectionsToDelete = sectionBox.values
        .where((section) => section.projectId == id)
        .toList();

    // Xóa sections bằng key thay vì index
    for (final section in sectionsToDelete) {
      final sectionKeys = sectionBox.keys.toList();
      for (final key in sectionKeys) {
        final sectionValue = sectionBox.get(key);
        if (sectionValue?.id == section.id) {
          sectionBox.delete(key);
        }
      }
    }

    // Cuối cùng xóa project
    box.delete(id);
    state = box.values.toList();

    // Force refresh các providers khác
    ref.invalidate(enhancedTodoBoxProvider);
    ref.invalidate(enhancedSectionBoxProvider);

    // Force validation để auto-reset selection nếu cần
    try {
      ref.read(validatedProjectSelectionProvider.notifier).forceReset();
      ref.read(validatedSectionSelectionProvider.notifier).forceReset();
    } catch (e) {
      // Validation providers chưa được import
    }

    // Force refresh todo list provider để UI update
    try {
      final todoNotifier = ref.read(todoListProvider.notifier);
      todoNotifier.refreshFromBox();
    } catch (e) {
      // Could not refresh todo provider
    }

    // Invalidate tất cả providers liên quan
    ref.invalidate(todoListProvider);
  }
}

final projectsProvider =
    StateNotifierProvider<ProjectListNotifier, List<ProjectModel>>((ref) {
      final box = ref.watch(enhancedProjectBoxProvider);
      return ProjectListNotifier(box, ref);
    });
