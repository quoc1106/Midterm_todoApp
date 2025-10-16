/// File: performance_debug_widget.dart
/// Purpose: Debug widget để hiển thị performance metrics của Level 3 FutureProvider
/// Showcase: Real-time performance monitoring và recommendations

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/performance_initialization_providers.dart';

class PerformanceDebugWidget extends ConsumerWidget {
  const PerformanceDebugWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final performanceAsync = ref.watch(performanceAwareInitProvider);

    return performanceAsync.when(
      loading: () => const PerformanceLoadingWidget(),
      error: (error, stack) => PerformanceErrorWidget(error: error),
      data: (data) => PerformanceDataWidget(data: data),
    );
  }
}

class PerformanceLoadingWidget extends StatelessWidget {
  const PerformanceLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text(
            '⚡ Performance monitoring initializing...',
            style: TextStyle(fontSize: 12, color: Colors.blue),
          ),
        ],
      ),
    );
  }
}

class PerformanceErrorWidget extends StatelessWidget {
  final Object error;

  const PerformanceErrorWidget({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 16, color: Colors.red.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '❌ Performance monitoring failed: ${error.toString()}',
              style: TextStyle(fontSize: 12, color: Colors.red.shade800),
            ),
          ),
        ],
      ),
    );
  }
}

class PerformanceDataWidget extends ConsumerWidget {
  final EnhancedAppInitData data;

  const PerformanceDataWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final performanceStatus = ref.watch(appPerformanceStatusProvider);
    final recommendations = ref.watch(performanceRecommendationsProvider);

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getStatusColor(performanceStatus).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getStatusColor(performanceStatus).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header với performance status
          Row(
            children: [
              Text(
                performanceStatus.emoji,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '⚡ ${performanceStatus.description}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(performanceStatus),
                  ),
                ),
              ),
              Text(
                '${data.performance.totalTime.inMilliseconds}ms',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(performanceStatus),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Performance breakdown
          ...data.performance.phaseTimes.entries.map((entry) {
            final percentage =
                (entry.value.inMilliseconds /
                        data.performance.totalTime.inMilliseconds *
                        100)
                    .round();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      _formatPhaseName(entry.key),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(
                        _getPhaseColor(entry.key),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${entry.value.inMilliseconds}ms ($percentage%)',
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),

          // Data summary
          Text(
            '📊 Data: ${data.performance.metadata['total_records']} records, '
            '${data.performance.memoryUsageKB}KB memory',
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),

          // Recommendations (if any)
          if (recommendations.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              '💡 Recommendations:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            ...recommendations.map(
              (rec) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Text(
                  '• $rec',
                  style: const TextStyle(fontSize: 10, color: Colors.orange),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(AppPerformanceStatus status) {
    switch (status) {
      case AppPerformanceStatus.excellent:
        return Colors.green;
      case AppPerformanceStatus.good:
        return Colors.blue;
      case AppPerformanceStatus.average:
        return Colors.orange;
      case AppPerformanceStatus.poor:
        return Colors.red;
    }
  }

  Color _getPhaseColor(String phase) {
    switch (phase) {
      case 'hive_init':
        return Colors.purple;
      case 'adapter_registration':
        return Colors.indigo;
      case 'box_opening':
        return Colors.blue;
      case 'data_analysis':
        return Colors.green;
      case 'memory_calculation':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatPhaseName(String phase) {
    switch (phase) {
      case 'hive_init':
        return 'Hive Init';
      case 'adapter_registration':
        return 'Adapters';
      case 'box_opening':
        return 'Box Open';
      case 'data_analysis':
        return 'Analysis';
      case 'memory_calculation':
        return 'Memory';
      default:
        return phase;
    }
  }
}

// Floating performance indicator
class PerformanceFloatingIndicator extends ConsumerWidget {
  const PerformanceFloatingIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final performanceAsync = ref.watch(performanceAwareInitProvider);

    return performanceAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (data) {
        final status = ref.watch(appPerformanceStatusProvider);

        return Positioned(
          top: 40,
          right: 16,
          child: GestureDetector(
            onTap: () {
              _showPerformanceDetails(context, data, status);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(status.emoji, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    '${data.performance.totalTime.inMilliseconds}ms',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(AppPerformanceStatus status) {
    switch (status) {
      case AppPerformanceStatus.excellent:
        return Colors.green;
      case AppPerformanceStatus.good:
        return Colors.blue;
      case AppPerformanceStatus.average:
        return Colors.orange;
      case AppPerformanceStatus.poor:
        return Colors.red;
    }
  }

  void _showPerformanceDetails(
    BuildContext context,
    EnhancedAppInitData data,
    AppPerformanceStatus status,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(status.emoji),
            const SizedBox(width: 8),
            const Text('Performance Details'),
          ],
        ),
        content: SizedBox(width: 300, child: PerformanceDataWidget(data: data)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
