/// 🔄 FRONTEND COMPONENTS - Migration Loading Screen
///
/// ⭐ RIVERPOD LEVEL 4 DEMONSTRATION - REAL MIGRATION UI ⭐
/// Real-time Migration Progress Display with Provider Integration
///
/// EDUCATIONAL VALUE:
/// - LEVEL 4: Real-time migration progress monitoring with providers
/// - Complex UI state management during migration operations
/// - User-friendly migration progress visualization
/// - Error handling and recovery UI for migration failures
///
/// REAL FUNCTIONALITY:
/// 1. Real-time migration progress display
/// 2. Step-by-step operation tracking
/// 3. Error recovery and retry mechanisms
/// 4. Performance monitoring during migration
/// 5. User feedback and status updates

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/data_migration_providers.dart';

/// ⭐ LEVEL 4: Migration Loading Screen with Real Progress Tracking
///
/// DEMONSTRATES:
/// - Real-time migration progress monitoring
/// - Complex UI state management with providers
/// - User-friendly migration operation display
/// - Error recovery UI patterns
class MigrationLoadingScreen extends ConsumerWidget {
  final String title;
  final String subtitle;

  const MigrationLoadingScreen({
    super.key,
    this.title = 'Upgrading App',
    this.subtitle = 'Migrating your data to the latest version...',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// ⭐ LEVEL 4: Migration Progress Provider Watching
    /// Real-time monitoring of migration operations
    final migrationProgress = ref.watch(migrationProgressProvider);
    final versionInfo = ref.watch(appVersionProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /// App Icon and Title
              Icon(
                Icons.upgrade,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),

              const SizedBox(height: 24),

              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              /// ⭐ LEVEL 4: Real Migration Progress Display
              if (migrationProgress != null) ...[
                _buildProgressCard(context, migrationProgress),
                const SizedBox(height: 24),
              ],

              /// ⭐ LEVEL 4: Version Information Display
              versionInfo.when(
                loading: () => const CircularProgressIndicator(),
                error: (error, _) => _buildErrorCard(context, error.toString()),
                data: (version) => _buildVersionCard(context, version),
              ),

              const SizedBox(height: 48),

              /// Migration Status
              if (migrationProgress?.isComplete == true)
                _buildCompletionCard(context)
              else
                _buildProgressIndicator(context, migrationProgress),
            ],
          ),
        ),
      ),
    );
  }

  /// ⭐ LEVEL 4: Progress Card Display
  Widget _buildProgressCard(BuildContext context, MigrationProgress progress) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.construction,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Migration Progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress bar
            LinearProgressIndicator(
              value: progress.percentage / 100,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(height: 12),

            // Progress text
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  progress.progressText,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${progress.percentage.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Current operation
            Text(
              progress.currentOperation,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ⭐ LEVEL 4: Version Information Card
  Widget _buildVersionCard(BuildContext context, AppVersionInfo version) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Version ${version.currentVersion} → ${version.targetVersion}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (version.needsMigration)
                    Text(
                      'Data migration required',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
            if (version.isUpToDate)
              Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
      ),
    );
  }

  /// ⭐ LEVEL 4: Error Display Card
  Widget _buildErrorCard(BuildContext context, String error) {
    return Card(
      elevation: 2,
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Migration Error: $error',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ⭐ LEVEL 4: Progress Indicator
  Widget _buildProgressIndicator(
    BuildContext context,
    MigrationProgress? progress,
  ) {
    if (progress == null) {
      return const CircularProgressIndicator();
    }

    return Column(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            children: [
              // Background circle
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: progress.percentage / 100,
                  strokeWidth: 6,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              // Percentage text
              Center(
                child: Text(
                  '${progress.percentage.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'Please wait while we upgrade your app...',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// ⭐ LEVEL 4: Completion Card
  Widget _buildCompletionCard(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.green.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 48),

            const SizedBox(height: 12),

            Text(
              'Migration Complete!',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Your app has been successfully upgraded.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
