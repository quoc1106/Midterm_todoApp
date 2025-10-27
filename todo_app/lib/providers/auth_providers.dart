/// 🔐 AUTHENTICATION PROVIDERS - Riverpod State Management
///
/// ⭐ RIVERPOD LEVEL 2: StateNotifierProvider ⭐
/// Authentication state management với complex business logic
/// Integrates với AuthService for persistent user sessions
///
/// ⭐ RIVERPOD LEVEL 3: FutureProvider ⭐
/// Async authentication initialization và session restoration
///
/// PATTERNS APPLIED:
/// - Level 1: StateProvider for simple UI state
/// - Level 2: StateNotifierProvider for auth flow management
/// - Level 3: FutureProvider for async initialization

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../backend/models/user.dart';
import '../backend/services/auth_service.dart';
import 'todo_providers.dart'; // to invalidate todoListProvider
import 'project_providers.dart'; // 🔧 USER SEPARATION: Import project providers
import 'section_providers.dart'; // 🔧 USER SEPARATION: Import section providers

/// 🔐 AUTHENTICATION STATE - Current Session
///
/// ⭐ RIVERPOD LEVEL 1 STATE ⭐
/// Simple state container for current authenticated user
class AuthState {
  final User? currentUser;
  final bool isLoading;
  final String? errorMessage;
  final bool isAuthenticated;
  final bool isInitialized;

  const AuthState({
    this.currentUser,
    this.isLoading = false,
    this.errorMessage,
    this.isInitialized = false,
  }) : isAuthenticated = currentUser != null;

  const AuthState.initial() : this();

  const AuthState.loading() : this(isLoading: true);

  const AuthState.initialized({User? user}) : this(currentUser: user, isInitialized: true);

  const AuthState.authenticated(User user) : this(currentUser: user, isInitialized: true);

  const AuthState.error(String message) : this(errorMessage: message, isInitialized: true);

  AuthState copyWith({
    User? currentUser,
    bool? isLoading,
    String? errorMessage,
    bool? isInitialized,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      currentUser: clearUser ? null : (currentUser ?? this.currentUser),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  @override
  String toString() {
    return 'AuthState(isAuthenticated: $isAuthenticated, isLoading: $isLoading, isInitialized: $isInitialized, error: $errorMessage)';
  }
}

/// 🔐 AUTH SERVICE PROVIDER
/// ⭐ RIVERPOD LEVEL 1: Provider ⭐
/// Singleton service instance for dependency injection
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// 🔐 AUTH STATE NOTIFIER
/// ⭐ RIVERPOD LEVEL 2: StateNotifierProvider ⭐
/// Complex authentication flow management với immutable state updates
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final Ref _ref;

  AuthNotifier(this._authService, this._ref) : super(const AuthState.initial());

  /// Register new user
  /// ⭐ RIVERPOD LEVEL 2 PATTERN: Complex validation flow
  Future<void> register({
    required String username,
    required String password,
    required String email,
    required String displayName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _authService.register(
      username: username,
      password: password,
      email: email,
      displayName: displayName,
    );

    if (result.isSuccess && result.user != null) {
      state = AuthState.authenticated(result.user!);
      // Ensure todo list refreshes under new user context
      try {
        _ref.invalidate(todoListProvider);
      } catch (_) {}
    } else {
      state = AuthState.error(result.errorMessage ?? 'Registration failed');
    }
  }

  /// Login user
  /// ⭐ RIVERPOD LEVEL 2 PATTERN: Authentication flow
  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _authService.login(
      username: username,
      password: password,
    );

    if (result.isSuccess && result.user != null) {
      print('🔍 User logged in: ${result.user!.username} (ID: ${result.user!.id})');
      state = AuthState.authenticated(result.user!);

      try {
        // 🔧 USER SEPARATION: Update all providers with new user
        print('🔄 Updating providers for user: ${result.user!.id}');

        // Update project provider với new user
        try {
          final projectNotifier = _ref.read(projectsProvider.notifier);
          if (projectNotifier is ProjectListNotifier) {
            projectNotifier.updateCurrentUser(result.user!.id);
          }
        } catch (e) {
          print('⚠️ Error updating project provider: $e');
        }

        // 🔧 NAVIGATION FIX: Reset sidebar to Today view để tránh user ở trang project của user cũ
        try {
          // Reset sidebar selection to Today - tìm provider quản lý sidebar navigation
          print('🔄 Resetting navigation to Today view');
          _ref.read(sidebarItemProvider.notifier).state = SidebarItem.today;
        } catch (e) {
          print('⚠️ Error resetting navigation: $e');
        }

        // Optionally migrate guest todos into this user automatically
        final unownedCount = await _authService.countUnownedTodos();
        print('🔍 Found $unownedCount unowned todos');
        if (unownedCount > 0) {
          // Auto-migrate unowned todos so user keeps previously created tasks
          final migrated = await _authService.migrateUnownedTodosToUser(result.user!.id);
          print('🔄 Migrated $migrated unowned todos to user ${result.user!.username}');
        }

        print('🔍 Login completed - All providers updated with new user');
      } catch (e) {
        print('⚠️ Error updating providers after login: $e');
      }
    } else {
      state = AuthState.error(result.errorMessage ?? 'Login failed');
    }
  }

  /// Logout current user
  /// ⭐ RIVERPOD LEVEL 1 PATTERN: Simple state clear
  Future<void> logout() async {
    print('🔍 Logging out user: ${state.currentUser?.username}');
    state = state.copyWith(isLoading: true);
    await _authService.logout();
    state = state.copyWith(isLoading: false, clearUser: true);

    try {
      // 🔧 USER SEPARATION: Update all providers với null user (guest mode)
      print('🔄 Updating providers for logout (guest mode)');

      // Update project provider với null user
      try {
        final projectNotifier = _ref.read(projectsProvider.notifier);
        if (projectNotifier is ProjectListNotifier) {
          projectNotifier.updateCurrentUser(null);
        }
      } catch (e) {
        print('⚠️ Error updating project provider on logout: $e');
      }

      // 🔧 NAVIGATION FIX: Reset sidebar to Today view khi logout
      try {
        print('🔄 Resetting navigation to Today view on logout');
        _ref.read(sidebarItemProvider.notifier).state = SidebarItem.today;
      } catch (e) {
        print('⚠️ Error resetting navigation on logout: $e');
      }

      print('🔍 Logout completed - All providers updated for guest mode');
    } catch (e) {
      print('⚠️ Error updating providers after logout: $e');
    }
  }

  /// Clear error message
  /// ⭐ RIVERPOD LEVEL 1 PATTERN: Simple state update
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Set user from initialization
  /// ⭐ RIVERPOD LEVEL 1 PATTERN: Simple state update
  void setInitializedUser(User? user) {
    if (user != null) {
      state = AuthState.authenticated(user);
    } else {
      state = const AuthState.initialized();
    }
  }

  /// Delete current user account
  /// ⭐ RIVERPOD LEVEL 2 PATTERN: Complex operation with confirmation
  Future<bool> deleteAccount() async {
    if (state.currentUser == null) return false;

    state = state.copyWith(isLoading: true);

    final success = await _authService.deleteAccount(state.currentUser!.id);
    if (success) {
      state = const AuthState.initial();
    } else {
      state = state.copyWith(isLoading: false);
    }

    return success;
  }
}

/// 🔐 AUTH STATE PROVIDER
/// ⭐ RIVERPOD LEVEL 2: StateNotifierProvider ⭐
/// Main authentication state management
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.read(authServiceProvider);
  return AuthNotifier(authService, ref);
});

/// 🔐 AUTH INITIALIZATION PROVIDER - SEPARATED
/// ⭐ RIVERPOD LEVEL 3: FutureProvider ⭐
/// Async authentication system initialization - separate from authProvider
final authInitializationProvider = FutureProvider<User?>((ref) async {
  final authService = ref.read(authServiceProvider);

  try {
    await authService.initialize();
    final currentUser = await authService.getCurrentUser();

    // Don't modify authProvider directly here to avoid circular dependency
    // The result will be used by AuthWrapper to set initial state
    return currentUser;
  } catch (e) {
    throw Exception('Authentication initialization failed: ${e.toString()}');
  }
});

/// 🔐 CURRENT USER PROVIDER
/// ⭐ RIVERPOD LEVEL 1: Provider ⭐
/// Computed provider for current authenticated user
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.currentUser;
});

/// 🔐 IS AUTHENTICATED PROVIDER
/// ⭐ RIVERPOD LEVEL 1: Provider ⭐
/// Simple boolean state for authentication status
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.isAuthenticated;
});

/// 🔐 USER NAMESPACE PROVIDER
/// ⭐ RIVERPOD LEVEL 1: Provider ⭐
/// Username-based data separation for multi-user support
final userNamespaceProvider = Provider<String>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  return currentUser?.username ?? 'guest';
});

/// 🔐 AUTHENTICATION FORM STATE
/// ⭐ RIVERPOD LEVEL 1: StateProvider ⭐
/// Simple form state management for login/register screens
class AuthFormState {
  final bool isLoginMode;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final bool rememberMe;

  const AuthFormState({
    this.isLoginMode = true,
    this.obscurePassword = true,
    this.obscureConfirmPassword = true,
    this.rememberMe = false,
  });

  AuthFormState copyWith({
    bool? isLoginMode,
    bool? obscurePassword,
    bool? obscureConfirmPassword,
    bool? rememberMe,
  }) {
    return AuthFormState(
      isLoginMode: isLoginMode ?? this.isLoginMode,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      obscureConfirmPassword: obscureConfirmPassword ?? this.obscureConfirmPassword,
      rememberMe: rememberMe ?? this.rememberMe,
    );
  }
}

/// 🔐 AUTH FORM STATE PROVIDER
/// ⭐ RIVERPOD LEVEL 1: StateProvider ⭐
/// Form state management for authentication screens
final authFormStateProvider = StateProvider<AuthFormState>((ref) {
  return const AuthFormState();
});
