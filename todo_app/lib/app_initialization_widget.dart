/// File: app_initialization_widget.dart
/// Purpose: Widget quản lý UI states cho app initialization (Loading/Error/Success).
/// - Chứng minh khả năng xử lý async states của FutureProvider.
/// - Loại bỏ nhu cầu FutureBuilder trong UI.
/// - Clean error handling và loading indicators.
/// Team: Đọc phần này để hiểu cách UI handle async states với Riverpod.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/performance_initialization_providers.dart';
import 'providers/theme_providers.dart';
import 'frontend/screens/todo_screen.dart';
import 'package:flutter/foundation.dart';

class AppInitializationWidget extends ConsumerWidget {
  const AppInitializationWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch Enhanced FutureProvider - Level 3 với Performance Monitoring
    final initializationAsync = ref.watch(performanceAwareInitProvider);

    // Watch theme providers for dynamic theming
    final themeMode = ref.watch(themeModeProvider);
    final lightTheme = ref.watch(lightThemeProvider);
    final darkTheme = ref.watch(darkThemeProvider);

    return MaterialApp(
      title: 'Todo App with Riverpod',
      // Dynamic theme from providers
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      home: Stack(
        children: [
          initializationAsync.when(
            // Loading state - App đang khởi tạo với performance tracking
            loading: () => const AppLoadingScreen(),

            // Error state - Có lỗi trong quá trình khởi tạo
            error: (error, stackTrace) => AppErrorScreen(
              error: error,
              onRetry: () {
                // Invalidate enhanced provider để retry initialization
                ref.invalidate(performanceAwareInitProvider);
              },
            ),

            // Success state - App đã khởi tạo thành công với performance data
            data: (initData) => const TodoScreen(),
          ),

          // Performance indicator now moved to AppBar in TodoScreen
        ],
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppLoadingScreen extends StatelessWidget {
  const AppLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 48,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 32),

            // App title
            const Text(
              'Todo App',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Powered by Riverpod',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 48),

            // Loading indicator
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            const Text(
              'Initializing app...',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            const Text(
              'Loading your data from local storage',
              style: TextStyle(fontSize: 14, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}

class AppErrorScreen extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const AppErrorScreen({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red.shade600,
                ),
              ),
              const SizedBox(height: 32),

              // Error title
              Text(
                'Initialization Failed',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade800,
                ),
              ),
              const SizedBox(height: 16),

              // Error message
              Text(
                'Failed to initialize the application.',
                style: TextStyle(fontSize: 16, color: Colors.red.shade700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Technical error details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Text(
                  error.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade800,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),

              // Retry button
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Initialization'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Help text
              Text(
                'If this problem persists, please restart the app.',
                style: TextStyle(fontSize: 14, color: Colors.red.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget để display initialization info (for debugging)
class InitializationInfoWidget extends ConsumerWidget {
  const InitializationInfoWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isInitialized = ref.watch(isAppInitializedProvider);
    final initTime = ref.watch(initializationTimeProvider);

    if (!isInitialized || initTime == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
          const SizedBox(width: 8),
          Text(
            'App initialized in ${initTime.inMilliseconds}ms',
            style: TextStyle(fontSize: 12, color: Colors.green.shade800),
          ),
        ],
      ),
    );
  }
}
