/// 🔐 AUTHENTICATION SERVICE - Business Logic Layer
///
/// ⭐ RIVERPOD LEVEL 2 BUSINESS LOGIC ⭐
/// AuthService handles all authentication operations
/// Integrates with Hive for user data persistence
/// Supports username-based multi-user data separation

import 'package:hive_flutter/hive_flutter.dart';
import '../models/user.dart';

class AuthService {
  static const String _usersBoxName = 'users';
  static const String _currentUserKey = 'current_user_id';

  late Box<User> _usersBox;
  late Box _prefsBox;

  /// Initialize authentication service
  Future<void> initialize() async {
    _usersBox = await Hive.openBox<User>(_usersBoxName);
    _prefsBox = await Hive.openBox('preferences');
  }

  /// Register new user
  /// ⭐ RIVERPOD LEVEL 2 PATTERN: Complex validation & persistence
  Future<AuthResult> register({
    required String username,
    required String password,
    required String email,
    required String displayName,
  }) async {
    try {
      // Validation
      final validationResult = _validateRegistration(username, password, email, displayName);
      if (!validationResult.isSuccess) {
        return validationResult;
      }

      // Check if username exists
      if (await _usernameExists(username)) {
        return AuthResult.error('Username already exists');
      }

      // Check if email exists
      if (await _emailExists(email)) {
        return AuthResult.error('Email already registered');
      }

      // Create new user
      final user = User.register(
        username: username,
        password: password,
        email: email,
        displayName: displayName,
      );

      // Save to Hive
      await _usersBox.put(user.id, user);

      // Set as current user
      await _setCurrentUser(user);

      return AuthResult.success(user);
    } catch (e) {
      return AuthResult.error('Registration failed: ${e.toString()}');
    }
  }

  /// Login user
  /// ⭐ RIVERPOD LEVEL 2 PATTERN: Authentication flow with state updates
  Future<AuthResult> login({
    required String username,
    required String password,
  }) async {
    try {
      // Find user by username
      final user = await _findUserByUsername(username);
      if (user == null) {
        return AuthResult.error('Username not found');
      }

      // Verify password
      if (!user.verifyPassword(password)) {
        return AuthResult.error('Invalid password');
      }

      // Update last login
      final updatedUser = user.updateLastLogin();
      await _usersBox.put(updatedUser.id, updatedUser);

      // Set as current user
      await _setCurrentUser(updatedUser);

      return AuthResult.success(updatedUser);
    } catch (e) {
      return AuthResult.error('Login failed: ${e.toString()}');
    }
  }

  /// Logout current user
  /// ⭐ RIVERPOD LEVEL 1 PATTERN: Simple state clear
  Future<void> logout() async {
    await _prefsBox.delete(_currentUserKey);
  }

  /// Get current authenticated user
  /// ⭐ RIVERPOD LEVEL 2 PATTERN: Persistent session management
  Future<User?> getCurrentUser() async {
    final userId = _prefsBox.get(_currentUserKey);
    if (userId == null) return null;

    return _usersBox.get(userId);
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final user = await getCurrentUser();
    return user != null;
  }

  /// Get all users (for debugging/admin)
  List<User> getAllUsers() {
    return _usersBox.values.toList();
  }

  /// Delete user account
  Future<bool> deleteAccount(String userId) async {
    try {
      await _usersBox.delete(userId);

      // If deleting current user, logout
      final currentUserId = _prefsBox.get(_currentUserKey);
      if (currentUserId == userId) {
        await logout();
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Count unowned (guest) todos in the 'todos' box
  Future<int> countUnownedTodos() async {
    try {
      final todoBox = await Hive.openBox('todos') as Box;
      int count = 0;
      for (final value in todoBox.values) {
        try {
          if (value is Map || value is dynamic) {
            // If using Hive TypeAdapters, cast to have ownerId field
            final owner = (value as dynamic).ownerId;
            if (owner == null) count++;
          }
        } catch (_) {
          // ignore
        }
      }
      return count;
    } catch (e) {
      return 0;
    }
  }

  /// Migrate unowned todos (ownerId == null) to the specified userId.
  /// Returns the number of migrated records.
  Future<int> migrateUnownedTodosToUser(String userId) async {
    try {
      final todoBox = await Hive.openBox('todos');
      int migrated = 0;
      for (int i = 0; i < todoBox.length; i++) {
        final todo = todoBox.getAt(i);
        if (todo == null) continue;
        try {
          final owner = (todo as dynamic).ownerId;
          if (owner == null) {
            final updated = (todo as dynamic).copyWith(ownerId: userId);
            await todoBox.putAt(i, updated);
            migrated++;
          }
        } catch (_) {
          // ignore items that don't support ownerId
        }
      }
      return migrated;
    } catch (e) {
      return 0;
    }
  }

  // Private helper methods

  Future<void> _setCurrentUser(User user) async {
    await _prefsBox.put(_currentUserKey, user.id);
  }

  Future<User?> _findUserByUsername(String username) async {
    final normalizedUsername = username.toLowerCase().trim();
    return _usersBox.values
        .cast<User?>()
        .firstWhere(
          (user) => user?.username == normalizedUsername,
          orElse: () => null,
        );
  }

  Future<bool> _usernameExists(String username) async {
    final user = await _findUserByUsername(username);
    return user != null;
  }

  Future<bool> _emailExists(String email) async {
    final normalizedEmail = email.toLowerCase().trim();
    return _usersBox.values.any((user) => user.email == normalizedEmail);
  }

  AuthResult _validateRegistration(String username, String password, String email, String displayName) {
    // Username validation
    if (username.isEmpty || username.length < 3) {
      return AuthResult.error('Username must be at least 3 characters');
    }
    if (username.length > 20) {
      return AuthResult.error('Username must be less than 20 characters');
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      return AuthResult.error('Username can only contain letters, numbers and underscore');
    }

    // Password validation
    if (password.isEmpty || password.length < 6) {
      return AuthResult.error('Password must be at least 6 characters');
    }
    if (password.length > 50) {
      return AuthResult.error('Password must be less than 50 characters');
    }

    // Email validation
    if (email.isEmpty) {
      return AuthResult.error('Email is required');
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return AuthResult.error('Invalid email format');
    }

    // Display name validation
    if (displayName.isEmpty || displayName.length < 2) {
      return AuthResult.error('Display name must be at least 2 characters');
    }
    if (displayName.length > 30) {
      return AuthResult.error('Display name must be less than 30 characters');
    }

    return AuthResult.success(null);
  }
}

/// 🔐 AUTHENTICATION RESULT - Operation Response
///
/// ⭐ RIVERPOD LEVEL 1 PATTERN: Simple result wrapper
/// Standardized response for all auth operations
class AuthResult {
  final bool isSuccess;
  final User? user;
  final String? errorMessage;

  const AuthResult._({
    required this.isSuccess,
    this.user,
    this.errorMessage,
  });

  factory AuthResult.success(User? user) {
    return AuthResult._(isSuccess: true, user: user);
  }

  factory AuthResult.error(String message) {
    return AuthResult._(isSuccess: false, errorMessage: message);
  }

  @override
  String toString() {
    return isSuccess
        ? 'AuthResult.success(user: ${user?.username})'
        : 'AuthResult.error($errorMessage)';
  }
}
