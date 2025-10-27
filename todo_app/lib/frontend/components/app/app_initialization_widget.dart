/// 🚀 FRONTEND COMPONENTS - App Initialization Widget (AUTH INTEGRATED)
///
/// ⭐ AUTHENTICATION INTEGRATED VERSION ⭐
/// App-Level State Management với Authentication System
/// Integrates AuthWrapper cho user session management
///
/// RIVERPOD PATTERNS APPLIED:
/// - Level 3: FutureProvider for async initialization
/// - Level 2: StateNotifierProvider for authentication
/// - Level 1: Provider for theme management

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/performance_initialization_providers.dart';
import '../../../providers/theme_providers.dart';
import '../../screens/todo_screen.dart';
import '../layout/app_loading_screen.dart';
import '../layout/app_error_screen.dart';
import '../auth/auth_wrapper.dart';

/// ⭐ AUTH INTEGRATED: App Root Widget với Authentication
///
/// DEMONSTRATES:
/// - Authentication-aware initialization
/// - User session management
/// - Multi-user data separation
class AppInitializationWidget extends ConsumerWidget {
  const AppInitializationWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// ⭐ RIVERPOD LEVEL 3: FutureProvider coordination
    /// Authentication-aware provider watching

    AsyncValue<dynamic>? initializationAsync;
    ThemeMode themeMode = ThemeMode.system;
    ThemeData? lightTheme;
    ThemeData? darkTheme;

    try {
      // PROVIDER 1: Core initialization với auth support
      initializationAsync = ref.watch(performanceAwareInitProvider);
    } catch (e, stackTrace) {
      print('🔧 FIX: Core provider error: $e');
      initializationAsync = AsyncValue.error(e, stackTrace);
    }

    try {
      // PROVIDER 2-4: Theme providers
      themeMode = ref.watch(themeModeProvider) ?? ThemeMode.system;
      lightTheme = ref.watch(lightThemeProvider);
      darkTheme = ref.watch(darkThemeProvider);
    } catch (e) {
      print('🔧 FIX: Theme provider error: $e');
      themeMode = ThemeMode.system;
      lightTheme = ThemeData.light();
      darkTheme = ThemeData.dark();
    }

    /// ⭐ AUTH INTEGRATED: Error recovery với auth state preservation
    void handleInitializationRetry() {
      try {
        ref.invalidate(performanceAwareInitProvider);
        ref.invalidate(themeModeProvider);
        ref.invalidate(lightThemeProvider);
        ref.invalidate(darkThemeProvider);
        // Don't invalidate auth providers để preserve user session
      } catch (e) {
        print('🔧 FIX: Error during provider invalidation: $e');
      }
    }

    return MaterialApp(
      title: 'Todo App - Multi-User System',

      /// ⭐ Theme Integration
      theme: lightTheme ?? ThemeData.light(),
      darkTheme: darkTheme ?? ThemeData.dark(),
      themeMode: themeMode,

      debugShowCheckedModeBanner: false,

      /// ✅ FIXED: Add proper Navigator configuration to prevent history.isNotEmpty error
      navigatorKey: GlobalKey<NavigatorState>(),

      home: Stack(
        children: [
          /// ⭐ AUTH INTEGRATED: Authentication-aware initialization
          if (initializationAsync != null)
            initializationAsync.when(
              // LOADING: Show loading screen
              loading: () => const AppLoadingScreen(),

              // ERROR: Show error screen with retry
              error: (error, stackTrace) => AppErrorScreen(
                error: error,
                stackTrace: stackTrace,
                onRetry: handleInitializationRetry,
                onAdvancedRetry: () {
                  print('🔧 FIX: Advanced recovery attempted');
                  handleInitializationRetry();
                },
              ),

              // SUCCESS: Show app với authentication wrapper
              data: (initData) => const AuthWrapper(
                child: TodoScreen(),
              ),
            )
          else
            // Fallback: Direct auth wrapper nếu initialization fails
            const AuthWrapper(
              child: TodoScreen(),
            ),
        ],
      ),
    );
  }
}
