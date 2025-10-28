import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 🔄 TASK UPDATE NOTIFICATION SYSTEM
///
/// ⭐ RIVERPOD LEVEL 1-2 DEMONSTRATION ⭐
/// Simple notification system để trigger updates cho task filtering providers
/// Tránh circular dependency bằng cách sử dụng event-based invalidation

/// ✅ LEVEL 1: StateProvider - Task update notification trigger
final taskUpdateNotificationProvider = StateProvider<int>((ref) => 0);

/// ✅ LEVEL 1: Helper function để trigger task update notifications
void notifyTaskUpdate(WidgetRef ref) {
  final currentValue = ref.read(taskUpdateNotificationProvider);
  ref.read(taskUpdateNotificationProvider.notifier).state = currentValue + 1;
}

/// ✅ LEVEL 1: Helper function để trigger task update từ bất kỳ context nào
class TaskUpdateNotifier {
  static void notify(WidgetRef ref) {
    notifyTaskUpdate(ref);
  }
}
