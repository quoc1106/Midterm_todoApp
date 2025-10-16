/// 🔧 BACKEND - Hive Adapter Manager với Error Handling
///
/// Đây là PURE BACKEND - centralized database adapter registration
/// Không có UI logic hay Riverpod dependency
/// Handles potential duplicate registration errors và box management
import 'package:hive_flutter/hive_flutter.dart';
import '../models/todo_model.dart';
import '../models/project_model.dart';
import '../models/section_model.dart';

class HiveAdapterManager {
  /// ✅ BACKEND DATABASE LOGIC - Adapter Registration

  /// Registers all required Hive adapters safely
  /// Handles potential duplicate registration errors
  static void registerAllAdapters() {
    try {
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(TodoAdapter());
        print('✅ Registered TodoAdapter (typeId: 0)');
      }
    } catch (e) {
      print('❌ Failed to register TodoAdapter: $e');
    }

    try {
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(SectionModelAdapter());
        print('✅ Registered SectionModelAdapter (typeId: 2)');
      }
    } catch (e) {
      print('❌ Failed to register SectionModelAdapter: $e');
    }

    try {
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(ProjectModelAdapter());
        print('✅ Registered ProjectModelAdapter (typeId: 3)');
      }
    } catch (e) {
      print('❌ Failed to register ProjectModelAdapter: $e');
    }
  }

  /// ✅ BACKEND DATABASE LOGIC - Box Management

  /// Opens all required Hive boxes concurrently
  /// If corruption detected, clears data and retries
  static Future<(Box<Todo>, Box<ProjectModel>, Box<SectionModel>)>
  openAllBoxes() async {
    try {
      final results = await Future.wait([
        Hive.openBox<Todo>('todos'),
        Hive.openBox<ProjectModel>('projects'),
        Hive.openBox<SectionModel>('sections'),
      ]);

      return (
        results[0] as Box<Todo>,
        results[1] as Box<ProjectModel>,
        results[2] as Box<SectionModel>,
      );
    } catch (e) {
      print('❌ Error opening boxes: $e');
      // 🔧 FIXED: Avoid infinite recursion by limiting retry attempts
      return await _openAllBoxesWithRetry(maxRetries: 2);
    }
  }

  /// 🔧 FIXED: Safe box opening with limited retry attempts
  static Future<(Box<Todo>, Box<ProjectModel>, Box<SectionModel>)>
  _openAllBoxesWithRetry({int maxRetries = 2}) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        if (attempt > 0) {
          print('🔄 Retry attempt $attempt of $maxRetries...');
          // Clear potentially corrupted data on retry
          await clearCorruptedData();
          // Wait a bit before retry
          await Future.delayed(Duration(milliseconds: 500));
        }

        final results = await Future.wait([
          Hive.openBox<Todo>('todos'),
          Hive.openBox<ProjectModel>('projects'),
          Hive.openBox<SectionModel>('sections'),
        ]);

        return (
          results[0] as Box<Todo>,
          results[1] as Box<ProjectModel>,
          results[2] as Box<SectionModel>,
        );
      } catch (e) {
        print('❌ Attempt ${attempt + 1} failed: $e');
        if (attempt == maxRetries - 1) {
          // Last attempt failed, throw error to be handled by provider
          throw Exception(
            'Failed to open Hive boxes after $maxRetries attempts: $e',
          );
        }
      }
    }

    // This should never be reached due to throw above, but for type safety
    throw Exception('Failed to open Hive boxes');
  }

  /// ✅ BACKEND DATABASE LOGIC - Data Recovery (FIXED)

  /// 🔧 FIXED: Safely clears potentially corrupted data with better error handling
  static Future<void> clearCorruptedData() async {
    try {
      print('🔄 Clearing potentially corrupted data...');

      // Try to close any open boxes first to release file locks
      try {
        await Hive.close();
        print('🔄 Closed all Hive boxes');
      } catch (e) {
        print('⚠️ Warning closing boxes: $e');
      }

      // Wait a bit for file locks to be released
      await Future.delayed(Duration(milliseconds: 1000));

      // Try to delete box files with individual error handling
      final boxNames = ['todos', 'projects', 'sections'];
      for (final boxName in boxNames) {
        try {
          await Hive.deleteBoxFromDisk(boxName);
          print('✅ Cleared $boxName box');
        } catch (e) {
          print('⚠️ Could not clear $boxName box: $e (will continue anyway)');
        }
      }

      // Re-initialize Hive after clearing with custom path
      await Hive.initFlutter('todo_app_data');
      registerAllAdapters();

      print('✅ Data clearing process completed');
    } catch (e) {
      print('❌ Error during data clearing process: $e');
      // Don't throw here - let the caller handle this gracefully
    }
  }

  /// ✅ BACKEND DATABASE LOGIC - Box Status

  /// Check if all boxes are properly opened
  static bool areAllBoxesOpen() {
    try {
      return Hive.isBoxOpen('todos') &&
          Hive.isBoxOpen('projects') &&
          Hive.isBoxOpen('sections');
    } catch (e) {
      print('❌ Error checking box status: $e');
      return false;
    }
  }

  /// ✅ BACKEND DATABASE LOGIC - Performance Monitoring

  /// Get database performance metrics
  static Map<String, dynamic> getDatabaseMetrics() {
    try {
      final todosBox = Hive.box<Todo>('todos');
      final projectsBox = Hive.box<ProjectModel>('projects');
      final sectionsBox = Hive.box<SectionModel>('sections');

      return {
        'todosCount': todosBox.length,
        'projectsCount': projectsBox.length,
        'sectionsCount': sectionsBox.length,
        'totalRecords':
            todosBox.length + projectsBox.length + sectionsBox.length,
        'isAllBoxesOpen': areAllBoxesOpen(),
      };
    } catch (e) {
      print('❌ Error getting database metrics: $e');
      return {
        'todosCount': 0,
        'projectsCount': 0,
        'sectionsCount': 0,
        'totalRecords': 0,
        'isAllBoxesOpen': false,
        'error': e.toString(),
      };
    }
  }

  /// ✅ BACKEND DATABASE LOGIC - Cleanup

  /// Close all boxes safely
  static Future<void> closeAllBoxes() async {
    try {
      if (Hive.isBoxOpen('todos')) await Hive.box('todos').close();
      if (Hive.isBoxOpen('projects')) await Hive.box('projects').close();
      if (Hive.isBoxOpen('sections')) await Hive.box('sections').close();
      print('✅ All boxes closed successfully');
    } catch (e) {
      print('❌ Error closing boxes: $e');
    }
  }
}
