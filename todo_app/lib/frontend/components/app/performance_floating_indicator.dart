/// 🎨 FRONTEND COMPONENTS - Performance Floating Indicator
///
/// ⭐ RIVERPOD LEVEL 3-4 DEMONSTRATION ⭐
/// Real-time Performance Monitoring with Provider Integration
///
/// EDUCATIONAL VALUE:
/// - LEVEL 3: Real-time provider watching for performance metrics
/// - LEVEL 4: Complex performance analytics with multiple providers
/// - Development-mode debugging tools with provider integration
/// - Performance data visualization with state management
///
/// ARCHITECTURE PATTERNS:
/// 1. Performance metrics provider watching
/// 2. Real-time data visualization with providers
/// 3. Development tools integration
/// 4. Animated performance indicators

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/performance_initialization_providers.dart';

/// ⭐ LEVEL 3-4: Real-time Performance Monitor
///
/// DEMONSTRATES:
/// - Performance metrics provider integration
/// - Real-time data visualization with providers
/// - Development debugging tools with state management
/// - Complex performance analytics display
class PerformanceFloatingIndicator extends ConsumerStatefulWidget {
  final bool isCompact; // New parameter for AppBar usage

  const PerformanceFloatingIndicator({super.key, this.isCompact = false});

  @override
  ConsumerState<PerformanceFloatingIndicator> createState() =>
      _PerformanceFloatingIndicatorState();
}

class _PerformanceFloatingIndicatorState
    extends ConsumerState<PerformanceFloatingIndicator> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    /// ⭐ LEVEL 3: Performance Metrics Provider Watching WITH REAL FUNCTIONALITY
    /// Real-time monitoring of app performance through providers
    final performanceAsync = ref.watch(performanceAwareInitProvider);

    // Compact version for AppBar
    if (widget.isCompact) {
      return performanceAsync.when(
        loading: () => const Icon(Icons.hourglass_empty, size: 20),
        error: (error, stack) =>
            const Icon(Icons.error, color: Colors.red, size: 20),
        data: (initData) => _buildCompactIndicator(context, initData),
      );
    }

    // Full floating version
    return Positioned(
      top: 50,
      right: 60, // Moved more to the left (was 16)
      child: performanceAsync.when(
        loading: () => _buildLoadingIndicator(context),
        error: (error, stack) => _buildErrorIndicator(context, error),
        data: (initData) => Container(
          width: _isExpanded ? 200 : 40, // Reduced further to prevent overflow
          height: _isExpanded ? 180 : 40, // Reduced further to prevent overflow
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
            borderRadius: BorderRadius.circular(_isExpanded ? 12 : 20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(_isExpanded ? 12 : 20),
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: _isExpanded
                  ? _buildDialogExpandedView(initData.performance)
                  : _buildCollapsedView(initData.performance),
            ),
          ),
        ),
      ),
    );
  }

  /// ⭐ NEW: Loading Indicator
  Widget _buildLoadingIndicator(BuildContext context) {
    return Container(
      width: 40, // Reduced to match collapsed size
      height: 40, // Reduced to match collapsed size
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.primary),
      ),
      child: Center(
        child: SizedBox(
          width: 18, // Reduced from 20
          height: 18, // Reduced from 20
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  /// ⭐ NEW: Error Indicator
  Widget _buildErrorIndicator(BuildContext context, Object error) {
    return Container(
      width: 40, // Reduced to match collapsed size
      height: 40, // Reduced to match collapsed size
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.error),
      ),
      child: Icon(
        Icons.error,
        color: Theme.of(context).colorScheme.error,
        size: 18, // Reduced icon size
      ),
    );
  }

  /// ⭐ LEVEL 4: Collapsed Performance Indicator
  /// Minimized view with essential performance status (no animation)
  Widget _buildCollapsedView(PerformanceData performanceData) {
    /// ⭐ LEVEL 3: Performance Status Calculation
    /// Smart performance status analysis from provider data
    final isPerformant = performanceData.isPerformant;
    final statusColor = isPerformant ? Colors.green : Colors.orange;

    return InkWell(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded; // Toggle instead of always expanding
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40, // Reduced to match other components
        height: 40, // Reduced to match other components
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: statusColor, width: 2),
        ),
        child: Icon(
          isPerformant ? Icons.speed : Icons.warning,
          color: statusColor,
          size: 16, // Reduced from 18
        ),
      ),
    );
  }

  /// ⭐ COMPACT: Performance Indicator for AppBar
  /// Minimized version for header integration
  Widget _buildCompactIndicator(BuildContext context, dynamic initData) {
    final performanceData = initData.performance;
    final isPerformant = performanceData.isPerformant;
    // Use more visible and vibrant colors for both light and dark theme
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = isPerformant
        ? (isDark
              ? const Color(0xFF4CAF50) // Brighter green for dark theme
              : const Color(0xFF1B5E20)) // Darker green for light theme
        : (isDark
              ? const Color(0xFFFF9800) // Brighter orange for dark theme
              : const Color(0xFFBF360C)); // Darker orange for light theme

    return InkWell(
      onTap: () {
        // Show performance dialog when tapped
        _showPerformanceDialog(context, performanceData);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: statusColor.withOpacity(
            0.25,
          ), // Increased opacity for better visibility
          border: Border.all(color: statusColor, width: 2), // Thicker border
        ),
        child: Icon(
          Icons.speed_outlined, // Better performance icon
          color: statusColor,
          size: 16,
        ),
      ),
    );
  }

  /// Show performance dialog
  void _showPerformanceDialog(
    BuildContext context,
    PerformanceData performanceData,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.analytics_outlined, color: Colors.blue),
            SizedBox(width: 8),
            Text('Performance Analytics'),
          ],
        ),
        content: SizedBox(
          width: 300,
          height: 200,
          child: _buildDialogExpandedView(performanceData),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  /// ⭐ LEVEL 4: Dialog version without close button
  Widget _buildDialogExpandedView(PerformanceData performanceData) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Header without close button
          Row(
            children: [
              Icon(
                Icons.speed,
                color: Theme.of(context).colorScheme.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Performance',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// ⭐ LEVEL 4: Performance Metrics Display
          /// Complex performance data visualization
          Expanded(
            child: Column(
              children: [
                // Total initialization time
                _buildMetricRow(
                  'Init Time',
                  '${performanceData.totalTime.inMilliseconds}ms',
                  performanceData.isPerformant ? Colors.green : Colors.orange,
                ),

                const SizedBox(height: 8),

                // Memory usage
                _buildMetricRow(
                  'Memory',
                  '${(performanceData.memoryUsageKB / 1024).toStringAsFixed(1)}MB',
                  performanceData.memoryUsageKB < 50000
                      ? Colors.green
                      : Colors.orange,
                ),

                const SizedBox(height: 8),

                // Slowest phase
                _buildMetricRow(
                  'Slowest',
                  performanceData.slowestPhase,
                  Colors.blue,
                ),

                const SizedBox(height: 12),

                // Performance recommendations
                if (performanceData.recommendations.isNotEmpty) ...[
                  const Text(
                    'Suggestions:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: performanceData.recommendations
                            .take(2) // Show only top 2 recommendations
                            .map(
                              (recommendation) => Container(
                                width: double.infinity,
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.orange.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  recommendation,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ⭐ LEVEL 3: Metric Display Component
  /// Reusable metric display with status indication
  Widget _buildMetricRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 6, // Reduced from 8
          height: 6, // Reduced from 8
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6), // Reduced from 8
        Expanded(
          child: Text(
            '$label:',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 10, // Reduced from 11
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 10, // Reduced from 11
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
