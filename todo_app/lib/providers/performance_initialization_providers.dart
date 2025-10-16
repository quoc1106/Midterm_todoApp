/// File: performance_initialization_providers.dart
/// Purpose: Level 3 FutureProvider Enhanced - Performance Monitoring Showcase
/// Demonstration: Advanced async patterns với performance tracking

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../backend/models/todo_model.dart';
import '../backend/models/project_model.dart';
import '../backend/models/section_model.dart';
import '../backend/core/hive_adapters.dart';

// ============================================================================
// ENHANCED DATA CLASSES
// ============================================================================

class PerformanceData {
  final Map<String, Duration> phaseTimes;
  final Duration totalTime;
  final DateTime startTime;
  final int memoryUsageKB;
  final Map<String, dynamic> metadata;

  const PerformanceData({
    required this.phaseTimes,
    required this.totalTime,
    required this.startTime,
    required this.memoryUsageKB,
    required this.metadata,
  });

  // Performance analysis
  String get slowestPhase {
    if (phaseTimes.isEmpty) return 'none';
    return phaseTimes.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  bool get isPerformant => totalTime.inMilliseconds < 3000; // Under 3 seconds

  List<String> get recommendations {
    final suggestions = <String>[];

    if (totalTime.inMilliseconds > 5000) {
      suggestions.add('Consider lazy loading non-critical data');
    }

    if ((phaseTimes['hive_init']?.inMilliseconds ?? 0) > 1000) {
      suggestions.add('Hive initialization is slow - check device storage');
    }

    if (memoryUsageKB > 50000) {
      suggestions.add('High memory usage detected - optimize data structures');
    }

    return suggestions;
  }
}

class EnhancedAppInitData {
  final Box<Todo> todoBox;
  final Box<ProjectModel> projectBox;
  final Box<SectionModel> sectionBox;
  final DateTime initializationTime;
  final PerformanceData performance;

  const EnhancedAppInitData({
    required this.todoBox,
    required this.projectBox,
    required this.sectionBox,
    required this.initializationTime,
    required this.performance,
  });
}

// ============================================================================
// LEVEL 3 FUTUREPROVIER - PERFORMANCE ENHANCED
// ============================================================================

/// Enhanced FutureProvider showcasing performance monitoring
final performanceAwareInitProvider = FutureProvider<EnhancedAppInitData>((
  ref,
) async {
  final overallStopwatch = Stopwatch()..start();
  final startTime = DateTime.now();
  final phaseTimes = <String, Duration>{};
  final metadata = <String, dynamic>{};

  try {
    // Phase 1: Hive Initialization with custom path to avoid OneDrive conflicts
    final hiveStopwatch = Stopwatch()..start();
    // Use AppData/Local instead of OneDrive Documents
    await Hive.initFlutter('todo_app_data');
    phaseTimes['hive_init'] = hiveStopwatch.elapsed;

    // Phase 2: Adapter Registration
    final adapterStopwatch = Stopwatch()..start();
    HiveAdapterManager.registerAllAdapters();
    phaseTimes['adapter_registration'] = adapterStopwatch.elapsed;

    // Phase 3: Box Opening (Concurrent)
    final boxStopwatch = Stopwatch()..start();
    final (todoBox, projectBox, sectionBox) =
        await HiveAdapterManager.openAllBoxes();
    phaseTimes['box_opening'] = boxStopwatch.elapsed;

    // Phase 4: Data Analysis
    final analysisStopwatch = Stopwatch()..start();
    metadata['todo_count'] = todoBox.length;
    metadata['project_count'] = projectBox.length;
    metadata['section_count'] = sectionBox.length;
    metadata['total_records'] =
        todoBox.length + projectBox.length + sectionBox.length;

    // Simulate data validation/migration if needed
    if (metadata['total_records'] > 1000) {
      await Future.delayed(
        const Duration(milliseconds: 100),
      ); // Simulate heavy processing
    }
    phaseTimes['data_analysis'] = analysisStopwatch.elapsed;

    // Phase 5: Memory Usage Calculation
    final memoryStopwatch = Stopwatch()..start();
    final memoryUsageKB = _estimateMemoryUsage(todoBox, projectBox, sectionBox);
    metadata['memory_usage_kb'] = memoryUsageKB;
    phaseTimes['memory_calculation'] = memoryStopwatch.elapsed;

    // Create performance report
    final performanceData = PerformanceData(
      phaseTimes: phaseTimes,
      totalTime: overallStopwatch.elapsed,
      startTime: startTime,
      memoryUsageKB: memoryUsageKB,
      metadata: metadata,
    );

    // Log performance metrics (for development)
    _logPerformanceMetrics(performanceData);

    return EnhancedAppInitData(
      todoBox: todoBox,
      projectBox: projectBox,
      sectionBox: sectionBox,
      initializationTime: DateTime.now(),
      performance: performanceData,
    );
  } catch (error) {
    // Enhanced error with performance context
    final errorContext = {
      'elapsed_time_ms': overallStopwatch.elapsed.inMilliseconds,
      'completed_phases': phaseTimes.keys.toList(),
      'phase_times': phaseTimes.map((k, v) => MapEntry(k, v.inMilliseconds)),
      'memory_at_error': _getCurrentMemoryEstimate(),
    };

    throw PerformanceAwareInitException(
      'Performance-aware initialization failed: $error',
      context: errorContext,
    );
  }
});

// ============================================================================
// PERFORMANCE ANALYSIS PROVIDERS
// ============================================================================

/// Provider for real-time performance metrics
final performanceMetricsProvider = Provider<PerformanceData>((ref) {
  final initData = ref.watch(performanceAwareInitProvider);
  return initData.when(
    loading: () => PerformanceData(
      phaseTimes: {'loading': Duration.zero},
      totalTime: Duration.zero,
      startTime: DateTime.now(),
      memoryUsageKB: 0,
      metadata: {'status': 'loading'},
    ),
    error: (error, stack) => PerformanceData(
      phaseTimes: {'error': Duration.zero},
      totalTime: Duration.zero,
      startTime: DateTime.now(),
      memoryUsageKB: 0,
      metadata: {'status': 'error', 'error': error.toString()},
    ),
    data: (data) => data.performance,
  );
});

/// Provider for performance recommendations
final performanceRecommendationsProvider = Provider<List<String>>((ref) {
  final metrics = ref.watch(performanceMetricsProvider);
  return metrics.recommendations;
});

/// Provider for performance status
final appPerformanceStatusProvider = Provider<AppPerformanceStatus>((ref) {
  final metrics = ref.watch(performanceMetricsProvider);

  if (metrics.totalTime.inMilliseconds < 1000) {
    return AppPerformanceStatus.excellent;
  } else if (metrics.totalTime.inMilliseconds < 3000) {
    return AppPerformanceStatus.good;
  } else if (metrics.totalTime.inMilliseconds < 5000) {
    return AppPerformanceStatus.average;
  } else {
    return AppPerformanceStatus.poor;
  }
});

enum AppPerformanceStatus {
  excellent,
  good,
  average,
  poor;

  String get description {
    switch (this) {
      case AppPerformanceStatus.excellent:
        return 'Tuyệt vời! App khởi động rất nhanh';
      case AppPerformanceStatus.good:
        return 'Tốt! Thời gian khởi động hợp lý';
      case AppPerformanceStatus.average:
        return 'Trung bình! Có thể tối ưu thêm';
      case AppPerformanceStatus.poor:
        return 'Chậm! Cần tối ưu hiệu suất';
    }
  }

  String get emoji {
    switch (this) {
      case AppPerformanceStatus.excellent:
        return '🚀';
      case AppPerformanceStatus.good:
        return '✅';
      case AppPerformanceStatus.average:
        return '⚠️';
      case AppPerformanceStatus.poor:
        return '🐌';
    }
  }
}

// ============================================================================
// BOX PROVIDERS (Enhanced)
// ============================================================================

final enhancedTodoBoxProvider = Provider<Box<Todo>>((ref) {
  final initData = ref.watch(performanceAwareInitProvider);
  return initData.when(
    loading: () => throw StateError('Performance-aware database not ready'),
    error: (error, stack) =>
        throw StateError('Database initialization failed: $error'),
    data: (data) => data.todoBox,
  );
});

final enhancedProjectBoxProvider = Provider<Box<ProjectModel>>((ref) {
  final initData = ref.watch(performanceAwareInitProvider);
  return initData.when(
    loading: () => throw StateError('Performance-aware database not ready'),
    error: (error, stack) =>
        throw StateError('Database initialization failed: $error'),
    data: (data) => data.projectBox,
  );
});

final enhancedSectionBoxProvider = Provider<Box<SectionModel>>((ref) {
  final initData = ref.watch(performanceAwareInitProvider);
  return initData.when(
    loading: () => throw StateError('Performance-aware database not ready'),
    error: (error, stack) =>
        throw StateError('Database initialization failed: $error'),
    data: (data) => data.sectionBox,
  );
});

// ============================================================================
// COMPATIBILITY PROVIDERS (for backward compatibility)
// ============================================================================

// These providers maintain compatibility with existing code
final todoBoxProvider = Provider<Box<Todo>>(
  (ref) => ref.watch(enhancedTodoBoxProvider),
);
final projectBoxProvider = Provider<Box<ProjectModel>>(
  (ref) => ref.watch(enhancedProjectBoxProvider),
);
final sectionBoxProvider = Provider<Box<SectionModel>>(
  (ref) => ref.watch(enhancedSectionBoxProvider),
);

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

int _estimateMemoryUsage(
  Box<Todo> todoBox,
  Box<ProjectModel> projectBox,
  Box<SectionModel> sectionBox,
) {
  // Rough estimation based on record counts
  const avgTodoSize = 200; // bytes per todo
  const avgProjectSize = 100; // bytes per project
  const avgSectionSize = 80; // bytes per section

  final totalBytes =
      (todoBox.length * avgTodoSize) +
      (projectBox.length * avgProjectSize) +
      (sectionBox.length * avgSectionSize);

  return totalBytes ~/ 1024; // Convert to KB
}

int _getCurrentMemoryEstimate() {
  // Simplified memory estimation
  return 1024; // 1MB placeholder
}

void _logPerformanceMetrics(PerformanceData performance) {
  print('🔍 Performance Metrics:');
  print('  Total time: ${performance.totalTime.inMilliseconds}ms');
  print('  Slowest phase: ${performance.slowestPhase}');
  print('  Memory usage: ${performance.memoryUsageKB}KB');
  print(
    '  Performance: ${performance.isPerformant ? "✅ Good" : "⚠️ Needs optimization"}',
  );

  if (performance.recommendations.isNotEmpty) {
    print('  Recommendations:');
    for (final rec in performance.recommendations) {
      print('    • $rec');
    }
  }
}

// ============================================================================
// ENHANCED EXCEPTION
// ============================================================================

class PerformanceAwareInitException implements Exception {
  final String message;
  final Map<String, dynamic> context;

  const PerformanceAwareInitException(this.message, {this.context = const {}});

  @override
  String toString() {
    return 'PerformanceAwareInitException: $message\nPerformance Context: $context';
  }
}

// ============================================================================
// BACKWARD COMPATIBILITY PROVIDERS
// ============================================================================

/// Compatibility provider for old appInitializationProvider
final appInitializationProvider = FutureProvider<void>((ref) async {
  await ref.watch(performanceAwareInitProvider.future);
  // Return void for backward compatibility
});

/// Compatibility provider for isAppInitializedProvider
final isAppInitializedProvider = Provider<bool>((ref) {
  final initAsync = ref.watch(performanceAwareInitProvider);
  return initAsync.hasValue;
});

/// Compatibility provider for initializationTimeProvider
final initializationTimeProvider = Provider<Duration?>((ref) {
  final initAsync = ref.watch(performanceAwareInitProvider);
  return initAsync.whenOrNull(data: (data) => data.performance.totalTime);
});
