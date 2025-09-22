import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/project_model.dart';

final projectBoxProvider = Provider<Box<ProjectModel>>(
  (ref) => Hive.box<ProjectModel>('projects'),
);

class ProjectListNotifier extends StateNotifier<List<ProjectModel>> {
  final Box<ProjectModel> box;
  ProjectListNotifier(this.box) : super(box.values.toList());

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
    box.delete(id);
    state = box.values.toList();
  }
}

final projectsProvider =
    StateNotifierProvider<ProjectListNotifier, List<ProjectModel>>((ref) {
      final box = ref.watch(projectBoxProvider);
      return ProjectListNotifier(box);
    });
