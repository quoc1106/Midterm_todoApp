/// 🔧 BACKEND - Data Service Layer
///
/// Đây là PURE BACKEND - centralized data operations
/// Không có UI logic hay Riverpod dependency
/// Provides clean interface cho tất cả database operations
import 'package:hive/hive.dart';
import '../models/todo_model.dart';
import '../models/project_model.dart';
import '../models/section_model.dart';
import '../core/hive_adapters.dart';

class DataService {
  /// ✅ BACKEND SERVICE LOGIC - Singleton Pattern

  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  /// ✅ BACKEND SERVICE LOGIC - Todo Operations

  /// Get all todos with optional filtering
  List<Todo> getAllTodos({
    bool? completed,
    String? projectId,
    String? sectionId,
  }) {
    try {
      final box = Hive.box<Todo>('todos');
      List<Todo> todos = box.values.toList();

      // Apply filters
      if (completed != null) {
        todos = todos.where((todo) => todo.completed == completed).toList();
      }

      if (projectId != null) {
        todos = todos.where((todo) => todo.projectId == projectId).toList();
      }

      if (sectionId != null) {
        todos = todos.where((todo) => todo.sectionId == sectionId).toList();
      }

      return todos;
    } catch (e) {
      print('❌ Error getting todos: $e');
      return [];
    }
  }

  /// Add new todo
  Future<bool> addTodo(Todo todo) async {
    try {
      final box = Hive.box<Todo>('todos');
      await box.put(todo.id, todo);
      print('✅ Added todo: ${todo.description}');
      return true;
    } catch (e) {
      print('❌ Error adding todo: $e');
      return false;
    }
  }

  /// Update existing todo
  Future<bool> updateTodo(Todo todo) async {
    try {
      final box = Hive.box<Todo>('todos');
      await box.put(todo.id, todo);
      print('✅ Updated todo: ${todo.description}');
      return true;
    } catch (e) {
      print('❌ Error updating todo: $e');
      return false;
    }
  }

  /// Delete todo by ID
  Future<bool> deleteTodo(String todoId) async {
    try {
      final box = Hive.box<Todo>('todos');
      await box.delete(todoId);
      print('✅ Deleted todo: $todoId');
      return true;
    } catch (e) {
      print('❌ Error deleting todo: $e');
      return false;
    }
  }

  /// ✅ BACKEND SERVICE LOGIC - Project Operations

  /// Get all projects
  List<ProjectModel> getAllProjects() {
    try {
      final box = Hive.box<ProjectModel>('projects');
      return box.values.toList();
    } catch (e) {
      print('❌ Error getting projects: $e');
      return [];
    }
  }

  /// Add new project
  Future<bool> addProject(ProjectModel project) async {
    try {
      final box = Hive.box<ProjectModel>('projects');
      await box.put(project.id, project);
      print('✅ Added project: ${project.name}');
      return true;
    } catch (e) {
      print('❌ Error adding project: $e');
      return false;
    }
  }

  /// Update existing project
  Future<bool> updateProject(ProjectModel project) async {
    try {
      final box = Hive.box<ProjectModel>('projects');
      await box.put(project.id, project);
      print('✅ Updated project: ${project.name}');
      return true;
    } catch (e) {
      print('❌ Error updating project: $e');
      return false;
    }
  }

  /// Delete project and handle cascade deletion
  Future<bool> deleteProject(String projectId) async {
    try {
      // First delete all todos in this project
      final todosToDelete = getAllTodos(projectId: projectId);
      for (final todo in todosToDelete) {
        await deleteTodo(todo.id);
      }

      // Delete all sections in this project
      final sectionsToDelete = getAllSections(projectId: projectId);
      for (final section in sectionsToDelete) {
        await deleteSection(section.id);
      }

      // Finally delete the project
      final box = Hive.box<ProjectModel>('projects');
      await box.delete(projectId);
      print('✅ Deleted project with cascade: $projectId');
      return true;
    } catch (e) {
      print('❌ Error deleting project: $e');
      return false;
    }
  }

  /// ✅ BACKEND SERVICE LOGIC - Section Operations

  /// Get all sections with optional project filtering
  List<SectionModel> getAllSections({String? projectId}) {
    try {
      final box = Hive.box<SectionModel>('sections');
      List<SectionModel> sections = box.values.toList();

      if (projectId != null) {
        sections = sections
            .where((section) => section.projectId == projectId)
            .toList();
      }

      return sections;
    } catch (e) {
      print('❌ Error getting sections: $e');
      return [];
    }
  }

  /// Add new section
  Future<bool> addSection(SectionModel section) async {
    try {
      final box = Hive.box<SectionModel>('sections');
      await box.put(section.id, section);
      print('✅ Added section: ${section.name}');
      return true;
    } catch (e) {
      print('❌ Error adding section: $e');
      return false;
    }
  }

  /// Update existing section
  Future<bool> updateSection(SectionModel section) async {
    try {
      final box = Hive.box<SectionModel>('sections');
      await box.put(section.id, section);
      print('✅ Updated section: ${section.name}');
      return true;
    } catch (e) {
      print('❌ Error updating section: $e');
      return false;
    }
  }

  /// Delete section and handle cascade deletion
  Future<bool> deleteSection(String sectionId) async {
    try {
      // First delete all todos in this section
      final todosToDelete = getAllTodos(sectionId: sectionId);
      for (final todo in todosToDelete) {
        await deleteTodo(todo.id);
      }

      // Then delete the section
      final box = Hive.box<SectionModel>('sections');
      await box.delete(sectionId);
      print('✅ Deleted section with cascade: $sectionId');
      return true;
    } catch (e) {
      print('❌ Error deleting section: $e');
      return false;
    }
  }

  /// ✅ BACKEND SERVICE LOGIC - Search Operations

  /// Search todos by query
  Future<List<Todo>> searchTodos(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final allTodos = getAllTodos();
      final results = allTodos
          .where((todo) => todo.getSearchRelevance(query) > 0.0)
          .toList();

      // Sort by relevance score
      results.sort(
        (a, b) =>
            b.getSearchRelevance(query).compareTo(a.getSearchRelevance(query)),
      );

      print('✅ Search found ${results.length} todos for: $query');
      return results;
    } catch (e) {
      print('❌ Error searching todos: $e');
      return [];
    }
  }

  /// Search projects by query
  Future<List<ProjectModel>> searchProjects(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final allProjects = getAllProjects();
      final results = allProjects
          .where((project) => project.getSearchRelevance(query) > 0.0)
          .toList();

      // Sort by relevance score
      results.sort(
        (a, b) =>
            b.getSearchRelevance(query).compareTo(a.getSearchRelevance(query)),
      );

      print('✅ Search found ${results.length} projects for: $query');
      return results;
    } catch (e) {
      print('❌ Error searching projects: $e');
      return [];
    }
  }

  /// ✅ BACKEND SERVICE LOGIC - Analytics & Performance

  /// Get performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    try {
      final dbMetrics = HiveAdapterManager.getDatabaseMetrics();
      final todos = getAllTodos();
      final projects = getAllProjects();
      final sections = getAllSections();

      return {
        ...dbMetrics,
        'completedTodos': todos.where((t) => t.completed).length,
        'pendingTodos': todos.where((t) => !t.completed).length,
        'overdueTodos': todos.where((t) => t.isOverdue).length,
        'todayTodos': todos.where((t) => t.isDueToday).length,
        'averageProjectSize': projects.isEmpty
            ? 0
            : todos.length / projects.length,
      };
    } catch (e) {
      print('❌ Error getting performance metrics: $e');
      return {'error': e.toString()};
    }
  }
}
