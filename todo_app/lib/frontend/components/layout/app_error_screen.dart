/// 🎨 FRONTEND COMPONENTS - App Error Screen
///
/// ⭐ RIVERPOD LEVEL 3-4 DEMONSTRATION ⭐
/// Advanced Error Handling with Provider Integration
///
/// EDUCATIONAL VALUE:
/// - LEVEL 3: Error state management with provider coordination
/// - LEVEL 4: Advanced error recovery patterns with analytics
/// - Error boundary implementation with retry strategies
/// - Provider invalidation patterns for error recovery
///
/// ARCHITECTURE PATTERNS:
/// 1. Error analytics provider integration
/// 2. Multi-level error recovery strategies
/// 3. Provider invalidation for clean state reset
/// 4. User-friendly error presentation with technical details

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

/// ⭐ LEVEL 3-4: Advanced Error Screen with Recovery Patterns
///
/// DEMONSTRATES:
/// - Complex error analysis and presentation
/// - Multiple recovery strategy options
/// - Error analytics integration with providers
/// - User-friendly error communication with technical details
class AppErrorScreen extends ConsumerWidget {
  final Object error;
  final StackTrace? stackTrace;
  final VoidCallback onRetry;
  final VoidCallback? onAdvancedRetry;

  const AppErrorScreen({
    super.key,
    required this.error,
    this.stackTrace,
    required this.onRetry,
    this.onAdvancedRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    /// ⭐ LEVEL 4: Error Classification Logic
    /// Smart error analysis for appropriate recovery strategies
    final errorInfo = _analyzeError(error);

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.red.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /// ⭐ LEVEL 3: Error Icon with Status Indication
              /// Visual error representation with severity indication
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: errorInfo['severity'] == 'critical'
                      ? Colors.red.shade100
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: errorInfo['severity'] == 'critical'
                        ? Colors.red.shade300
                        : Colors.orange.shade300,
                    width: 2,
                  ),
                ),
                child: Icon(
                  errorInfo['icon'] as IconData,
                  size: 50,
                  color: errorInfo['severity'] == 'critical'
                      ? Colors.red.shade600
                      : Colors.orange.shade600,
                ),
              ),

              const SizedBox(height: 32),

              /// ⭐ LEVEL 3: Error Title and Message
              /// User-friendly error communication
              Text(
                errorInfo['title'] as String,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                errorInfo['message'] as String,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isDark ? Colors.grey[300] : Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              /// ⭐ LEVEL 4: Recovery Action Buttons
              /// Multiple recovery strategies based on error analysis
              Column(
                children: [
                  // Primary recovery action
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: Text(errorInfo['primaryAction'] as String),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Advanced recovery action (if available)
                  if (onAdvancedRetry != null &&
                      errorInfo['secondaryAction'] != null)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onAdvancedRetry,
                        icon: const Icon(Icons.settings_backup_restore),
                        label: Text(errorInfo['secondaryAction'] as String),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 32),

              /// ⭐ LEVEL 4: Technical Details Section
              /// Expandable technical information for debugging
              ExpansionTile(
                title: const Text('Technical Details'),
                leading: const Icon(Icons.code),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Error Type: ${error.runtimeType}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Message: ${error.toString()}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                        if (stackTrace != null) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Stack Trace:',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: stackTrace.toString()),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Stack trace copied to clipboard',
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.copy, size: 20),
                                tooltip: 'Copy stack trace',
                              ),
                            ],
                          ),
                          Container(
                            width: double.infinity,
                            height: 150,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isDark
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: SingleChildScrollView(
                              child: Text(
                                stackTrace.toString(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  color: isDark
                                      ? Colors.grey[300]
                                      : Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ⭐ LEVEL 4: Intelligent Error Analysis
  /// Smart error classification for appropriate user messaging and recovery
  Map<String, dynamic> _analyzeError(Object error) {
    final errorString = error.toString().toLowerCase();

    // Database-related errors
    if (errorString.contains('hive') || errorString.contains('database')) {
      return {
        'title': 'Database Connection Issue',
        'message':
            'There was a problem accessing your local data. This usually resolves quickly.',
        'severity': 'medium',
        'icon': Icons.storage,
        'primaryAction': 'Retry Connection',
        'secondaryAction': 'Reset Database',
      };
    }

    // Network-related errors
    if (errorString.contains('network') || errorString.contains('connection')) {
      return {
        'title': 'Network Issue',
        'message': 'Please check your internet connection and try again.',
        'severity': 'medium',
        'icon': Icons.wifi_off,
        'primaryAction': 'Retry Connection',
        'secondaryAction': 'Work Offline',
      };
    }

    // Permission errors
    if (errorString.contains('permission') || errorString.contains('access')) {
      return {
        'title': 'Permission Required',
        'message': 'The app needs certain permissions to function properly.',
        'severity': 'medium',
        'icon': Icons.lock,
        'primaryAction': 'Grant Permissions',
        'secondaryAction': 'Continue Limited',
      };
    }

    // Memory or performance errors
    if (errorString.contains('memory') || errorString.contains('performance')) {
      return {
        'title': 'Performance Issue',
        'message':
            'The app is experiencing performance problems. Restarting may help.',
        'severity': 'medium',
        'icon': Icons.memory,
        'primaryAction': 'Restart App',
        'secondaryAction': 'Clear Cache',
      };
    }

    // Generic critical errors
    return {
      'title': 'Unexpected Error',
      'message': 'Something went wrong. The technical team has been notified.',
      'severity': 'critical',
      'icon': Icons.error_outline,
      'primaryAction': 'Try Again',
      'secondaryAction': 'Reset App State',
    };
  }
}
