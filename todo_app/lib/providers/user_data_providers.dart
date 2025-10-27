/// 🔐 USER DATA SEPARATION - Multi-User Data Management
///
/// ⭐ RIVERPOD LEVEL 2: StateNotifierProvider ⭐
/// User-based data separation system cho multi-user support
/// Integrates với existing todo/project/section providers
/// Ensures complete data isolation between users

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../backend/models/user.dart';
import '../backend/models/todo_model.dart';
import '../backend/models/project_model.dart';
import '../backend/models/section_model.dart';
import 'auth_providers.dart';

/// 🔐 USER-SCOPED BOX PROVIDERS
/// ⭐ RIVERPOD LEVEL 1: Provider.family ⭐
/// Dynamic box creation based on username - Specific implementations

/// User-scoped Todo box provider
final userTodoBoxProvider = Provider<Box<Todo>?>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  final username = currentUser?.username ?? 'guest';
  final userBoxName = '${username}_todos';

  try {
    if (Hive.isBoxOpen(userBoxName)) {
      return Hive.box<Todo>(userBoxName);
    }
    return null;
  } catch (e) {
    print('❌ Failed to get user todo box: $e');
    return null;
  }
});

/// User-scoped Project box provider
final userProjectBoxProvider = Provider<Box<ProjectModel>?>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  final username = currentUser?.username ?? 'guest';
  final userBoxName = '${username}_projects';

  try {
    if (Hive.isBoxOpen(userBoxName)) {
      return Hive.box<ProjectModel>(userBoxName);
    }
    return null;
  } catch (e) {
    print('❌ Failed to get user project box: $e');
    return null;
  }
});

/// User-scoped Section box provider
final userSectionBoxProvider = Provider<Box<SectionModel>?>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  final username = currentUser?.username ?? 'guest';
  final userBoxName = '${username}_sections';

  try {
    if (Hive.isBoxOpen(userBoxName)) {
      return Hive.box<SectionModel>(userBoxName);
    }
    return null;
  } catch (e) {
    print('❌ Failed to get user section box: $e');
    return null;
  }
});

/// 🔐 USER DATA INITIALIZATION SERVICE
/// ⭐ RIVERPOD LEVEL 2: Complex Business Logic ⭐
/// Handles user-specific data initialization và cleanup
class UserDataManager {
  /// Initialize user-specific boxes
  /// ⭐ RIVERPOD LEVEL 3 PATTERN: Async initialization
  static Future<void> initializeUserBoxes(String username) async {
    final boxNames = ['todos', 'projects', 'sections'];

    for (final boxName in boxNames) {
      final userBoxName = '${username}_$boxName';

      try {
        // Check if box is already open
        if (Hive.isBoxOpen(userBoxName)) {
          continue;
        }

        // Open user-specific box
        switch (boxName) {
          case 'todos':
            await Hive.openBox<Todo>(userBoxName);
            break;
          case 'projects':
            await Hive.openBox<ProjectModel>(userBoxName);
            break;
          case 'sections':
            await Hive.openBox<SectionModel>(userBoxName);
            break;
        }

        print('✅ Opened user box: $userBoxName');
      } catch (e) {
        print('❌ Failed to open user box $userBoxName: $e');
        rethrow;
      }
    }
  }

  /// Close user-specific boxes
  /// ⭐ RIVERPOD LEVEL 1 PATTERN: Simple cleanup
  static Future<void> closeUserBoxes(String username) async {
    final boxNames = ['todos', 'projects', 'sections'];

    for (final boxName in boxNames) {
      final userBoxName = '${username}_$boxName';

      try {
        if (Hive.isBoxOpen(userBoxName)) {
          await Hive.box(userBoxName).close();
          print('✅ Closed user box: $userBoxName');
        }
      } catch (e) {
        print('❌ Failed to close user box $userBoxName: $e');
      }
    }
  }

  /// Transfer data when user logs in
  /// ⭐ RIVERPOD LEVEL 2 PATTERN: Complex data migration
  static Future<void> switchToUser(String newUsername, String? oldUsername) async {
    try {
      // Close old user boxes if any
      if (oldUsername != null && oldUsername != newUsername) {
        await closeUserBoxes(oldUsername);
      }

      // Initialize new user boxes
      await initializeUserBoxes(newUsername);

      print('✅ Switched to user: $newUsername');
    } catch (e) {
      print('❌ Failed to switch user: $e');
      rethrow;
    }
  }

  /// Delete all user data
  /// ⭐ RIVERPOD LEVEL 2 PATTERN: Complete data cleanup
  static Future<void> deleteUserData(String username) async {
    final boxNames = ['todos', 'projects', 'sections'];

    for (final boxName in boxNames) {
      final userBoxName = '${username}_$boxName';

      try {
        if (Hive.isBoxOpen(userBoxName)) {
          await Hive.box(userBoxName).clear();
          await Hive.box(userBoxName).close();
        }

        // Delete box file completely
        await Hive.deleteBoxFromDisk(userBoxName);
        print('✅ Deleted user data: $userBoxName');
      } catch (e) {
        print('❌ Failed to delete user data $userBoxName: $e');
      }
    }
  }

  /// Get statistics về user data
  /// ⭐ RIVERPOD LEVEL 1 PATTERN: Simple computation
  static Map<String, int> getUserDataStats(String username) {
    final stats = <String, int>{};
    final boxNames = ['todos', 'projects', 'sections'];

    for (final boxName in boxNames) {
      final userBoxName = '${username}_$boxName';

      try {
        if (Hive.isBoxOpen(userBoxName)) {
          final box = Hive.box(userBoxName);
          stats[boxName] = box.length;
        } else {
          stats[boxName] = 0;
        }
      } catch (e) {
        stats[boxName] = 0;
      }
    }

    return stats;
  }
}

/// 🔐 USER DATA INITIALIZATION PROVIDER
/// ⭐ RIVERPOD LEVEL 3: FutureProvider ⭐
/// Async user data initialization khi user đăng nhập
final userDataInitializationProvider = FutureProvider.family<void, String>((ref, username) async {
  await UserDataManager.initializeUserBoxes(username);
});

/// 🔐 USER DATA STATS PROVIDER
/// ⭐ RIVERPOD LEVEL 1: Provider ⭐
/// Real-time user data statistics
final userDataStatsProvider = Provider<Map<String, int>>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return {};

  return UserDataManager.getUserDataStats(currentUser.username);
});

/// 🔐 CURRENT USER BOXES PROVIDER
/// ⭐ RIVERPOD LEVEL 1: Provider ⭐
/// Easy access to current user's data boxes
class CurrentUserBoxes {
  final Box<Todo> todos;
  final Box<ProjectModel> projects;
  final Box<SectionModel> sections;

  CurrentUserBoxes({
    required this.todos,
    required this.projects,
    required this.sections,
  });
}

final currentUserBoxesProvider = Provider<CurrentUserBoxes?>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return null;

  final username = currentUser.username;

  try {
    return CurrentUserBoxes(
      todos: Hive.box<Todo>('${username}_todos'),
      projects: Hive.box<ProjectModel>('${username}_projects'),
      sections: Hive.box<SectionModel>('${username}_sections'),
    );
  } catch (e) {
    print('❌ Failed to get current user boxes: $e');
    return null;
  }
});
