/// 🚀 FRONTEND COMPONENTS - App Initialization Widget (SIMPLE VERSION)
///
/// ⭐ SIMPLIFIED FOR IMMEDIATE USAGE ⭐
/// Simple App-Level State Management without Migration complexity
///
/// SIMPLIFIED APPROACH:
/// - Skip migration for first install
/// - Direct initialization without version checks
/// - Clean startup experience

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/performance_initialization_providers.dart';
import '../../../providers/theme_providers.dart';
import '../../screens/todo_screen.dart';
import '../layout/app_loading_screen.dart';
import '../layout/app_error_screen.dart';

/// ⭐ SIMPLIFIED: App Root Widget for Immediate Usage
///
/// DEMONSTRATES:
/// - Simple FutureProvider coordination
/// - Basic theme provider integration
/// - Direct app initialization without migration complexity
class AppInitializationWidget extends ConsumerWidget {
  const AppInitializationWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// ⭐ SIMPLIFIED: Basic Provider Watching
    /// Simple provider coordination without migration complexity

    AsyncValue<dynamic>? initializationAsync;
    ThemeMode themeMode = ThemeMode.system;
    ThemeData? lightTheme;
    ThemeData? darkTheme;

    try {
      // PROVIDER 1: Basic initialization
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

    /// ⭐ SIMPLIFIED: Basic Error Recovery
    void handleInitializationRetry() {
      try {
        ref.invalidate(performanceAwareInitProvider);
        ref.invalidate(themeModeProvider);
        ref.invalidate(lightThemeProvider);
        ref.invalidate(darkThemeProvider);
      } catch (e) {
        print('🔧 FIX: Error during provider invalidation: $e');
      }
    }

    return MaterialApp(
      title: 'Todo App - Simplified Launch',

      /// ⭐ Theme Integration
      theme: lightTheme ?? ThemeData.light(),
      darkTheme: darkTheme ?? ThemeData.dark(),
      themeMode: themeMode,

      debugShowCheckedModeBanner: false,

      home: Stack(
        children: [
          /// ⭐ SIMPLIFIED: Direct Initialization
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

              // SUCCESS: Show main app
              data: (initData) => const TodoScreen(),
            )
          else
            const AppLoadingScreen(),

          /// Performance indicator now moved to AppBar in TodoScreen
        ],
      ),
    );
  }
}
