import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../backend/models/todo_model.dart';
import 'package:hive/hive.dart';
import 'performance_initialization_providers.dart';
import 'auth_providers.dart'; // for currentUserProvider

// Provider lưu trạng thái ngày đầu tuần hiện tại để chuyển tuần (Riverpod)
final upcomingWeekStartProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  // Tìm thứ 2 gần nhất (hoặc hôm nay nếu là thứ 2)
  return now.subtract(Duration(days: now.weekday - 1));
});

// Provider lưu trạng thái ngày đang chọn ở Upcoming (Riverpod)
// Provider quản lý trạng thái hiển thị AddTaskWidget cho từng nhóm ngày (Upcoming/All)
final addTaskGroupDateProvider = StateProvider<DateTime?>((ref) => null);
final upcomingSelectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

// Provider nhóm các task upcoming theo ngày, tối đa 10 ngày liên tiếp
class GroupedTodos {
  final DateTime date;
  final List<Todo> todos;
  GroupedTodos(this.date, this.todos);
}

final upcomingGroupedTodosProvider = Provider<List<GroupedTodos>>((ref) {
  final todos = ref.watch(todoListProvider);
  final weekStart = ref.watch(upcomingWeekStartProvider);
  // Tạo danh sách 7 ngày liên tiếp từ ngày đầu tuần hiện tại
  final days = List.generate(7, (i) {
    final d = weekStart.add(Duration(days: i));
    return DateTime(d.year, d.month, d.day);
  });
  List<GroupedTodos> result = [];
  for (final day in days) {
    final group = todos
        .where(
          (todo) =>
              todo.dueDate != null &&
              todo.dueDate!.year == day.year &&
              todo.dueDate!.month == day.month &&
              todo.dueDate!.day == day.day &&
              !todo.completed,
        )
        .toList();
    if (group.isNotEmpty) {
      result.add(GroupedTodos(day, group));
    }
  }
  return result;
});

const _uuid = Uuid();

// Enum mới cho các mục trong Sidebar - Thêm addTask ở đầu
enum SidebarItem { addTask, today, upcoming, completed, myProject }

// Provider để quản lý trạng thái AddTask overlay
final addTaskOverlayProvider = StateProvider<bool>((ref) => false);

// Provider để quản lý hiệu ứng thành công khi add task
final taskAddedSuccessProvider = StateProvider<bool>((ref) => false);

// Provider lưu project đang chọn trong sidebar
final selectedProjectIdProvider = StateProvider<String?>((ref) => null);

// Lớp tiện ích để kiểm tra ngày
class DateUtils {
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static bool isUpcoming(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final startOfTomorrow = DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
    );
    return date.isAtSameMomentAs(startOfTomorrow) ||
        date.isAfter(startOfTomorrow);
  }

  // ⭐ RIVERPOD LEVEL 1: Utility for upcoming date validation
  static bool isPastDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(date.year, date.month, date.day);
    return checkDate.isBefore(today);
  }

  static bool isTodayOrFuture(DateTime date) {
    return isToday(date) || isUpcoming(date);
  }
}

class TodoListNotifier extends StateNotifier<List<Todo>> {
  final Box<Todo> _box;
  final String? _currentUserId;
  final Ref _ref; // ✅ NEW: Inject Ref to access other providers

  TodoListNotifier(this._box, {String? currentUserId, required Ref ref})
      : _currentUserId = currentUserId,
        _ref = ref,
        super(_filterByOwner(_box, currentUserId)) {
    // 🔧 TEMP: Disabled debug prints to reduce noise
    // print('🔍 TodoListNotifier initialized for user: $_currentUserId');
    // print('🔍 Total todos in box: ${_box.length}');
    // print('🔍 Filtered todos for this user: ${state.length}');
  }

  static List<Todo> _filterByOwner(Box<Todo> box, String? ownerId) {
    // Legacy todos without ownerId (null) will not be visible to authenticated users.
    final filtered = box.values
        .where((t) => t.ownerId == ownerId)
        .toList();
    // print('🔍 _filterByOwner: ownerId=$ownerId, found ${filtered.length} todos');
    return filtered;
  }

  void add(
    String description, {
    DateTime? dueDate,
    String? projectId,
    String? sectionId,
  }) {
    // print('🔍 Adding todo for user: $_currentUserId');
    final newTodo = Todo(
      id: _uuid.v4(),
      description: description,
      dueDate: dueDate ?? DateTime.now(),
      projectId: projectId,
      sectionId: sectionId,
      ownerId: _currentUserId,
    );
    _box.add(newTodo);
    state = _filterByOwner(_box, _currentUserId);
    // print('🔍 Todo added. New state count: ${state.length}');
  }

  // ✅ NEW: Method for adding tasks with assignment support
  void addWithAssignment(
    String description, {
    DateTime? dueDate,
    String? projectId,
    String? sectionId,
    String? assignedToId,
    String? assignedToDisplayName,
  }) {
    // print('🔍 Adding todo with assignment for user: $_currentUserId');
    final newTodo = Todo(
      id: _uuid.v4(),
      description: description,
      dueDate: dueDate ?? DateTime.now(),
      projectId: projectId,
      sectionId: sectionId,
      ownerId: _currentUserId,
      assignedToId: assignedToId,
      assignedToDisplayName: assignedToDisplayName,
    );
    _box.add(newTodo);
    state = _filterByOwner(_box, _currentUserId);
    // print('🔍 Todo with assignment added. New state count: ${state.length}');
  }

  void toggle(String id) {
    final idx = _box.values.toList().indexWhere((todo) => todo.id == id);
    if (idx != -1) {
      final todo = _box.getAt(idx);
      if (todo != null) {
        _box.putAt(idx, todo.copyWith(completed: !todo.completed));
        state = _filterByOwner(_box, _currentUserId);
      }
    }
  }

  void edit({
    required String id,
    required String description,
    DateTime? dueDate,
    String? projectId,
    String? sectionId,
    String? assignedToId, // ✅ NEW: Assignment support
  }) {
    final idx = _box.values.toList().indexWhere((todo) => todo.id == id);
    if (idx != -1) {
      final todo = _box.getAt(idx);
      if (todo != null) {
        // ✅ FIX: Use correct provider name and safe access
        String? assignedToDisplayName;
        if (assignedToId != null) {
          try {
            // Get user box through correct provider name
            final userBox = _ref.read(enhancedUserBoxProvider);
            final assignedUser = userBox.values.cast<dynamic>().firstWhere(
              (user) => user.id == assignedToId,
              orElse: () => null,
            );
            assignedToDisplayName = assignedUser?.displayName;
          } catch (e) {
            print('⚠️ Error getting user display name: $e');
            // Fallback: use assignedToId as display name
            assignedToDisplayName = assignedToId;
          }
        }

        _box.putAt(
          idx,
          todo.copyWith(
            description: description,
            dueDate: dueDate,
            projectId: projectId,
            sectionId: sectionId,
            assignedToId: assignedToId, // ✅ Save assignment ID
            assignedToDisplayName: assignedToDisplayName, // ✅ Save fresh display name
            projectIdSetToNull: projectId == null,
            sectionIdSetToNull: sectionId == null,
            assignedToIdSetToNull: assignedToId == null, // ✅ Clear assignment when null
          ),
        );
        state = _filterByOwner(_box, _currentUserId);
      }
    }
  }

  // ✅ NEW: Delete method for compatibility with edit_todo_dialog
  void delete(String id) {
    final idx = _box.values.toList().indexWhere((todo) => todo.id == id);
    if (idx != -1) {
      _box.deleteAt(idx);
      state = _filterByOwner(_box, _currentUserId);
    }
  }

  void remove(Todo target) {
    final idx = _box.values.toList().indexWhere((todo) => todo.id == target.id);
    if (idx != -1) {
      _box.deleteAt(idx);
      state = _filterByOwner(_box, _currentUserId);
    }
  }

  // Method để force refresh state từ box (dùng khi có external changes)
  void refreshFromBox() {
    state = _filterByOwner(_box, _currentUserId);
    print('🔄 TodoListNotifier refreshed for user ($_currentUserId): ${state.length} todos');
  }
}

// --- PROVIDERS ---
// Các provider dưới đây sử dụng Riverpod để quản lý state cho todo list, sidebar, bộ lọc, tiêu đề app bar...
// Provider lưu trạng thái ngày chọn khi tạo task mới ở Upcoming
// Auto-sync với upcomingSelectedDateProvider để cùng ngày
// final newTodoDateProvider = StateProvider<DateTime>((ref) {
//   final upcomingSelectedDate = ref.watch(upcomingSelectedDateProvider);
//
//   // Nếu user chọn "All" (year 9999) thì dùng ngày hôm nay
//   if (upcomingSelectedDate.year == 9999) {
//     final now = DateTime.now();
//     return DateTime(now.year, now.month, now.day);
//   }
//
//   // Ngược lại sync với ngày được chọn ở date selector
//   return DateTime(
//     upcomingSelectedDate.year,
//     upcomingSelectedDate.month,
//     upcomingSelectedDate.day,
//   );
// });
//
// // ⭐ RIVERPOD LEVEL 2: Enhanced Provider với date validation logic
final newTodoDateProvider = StateProvider<DateTime>((ref) {
  final upcomingSelectedDate = ref.watch(upcomingSelectedDateProvider);

  // Nếu user chọn "All" (year 9999) thì dùng ngày hôm nay
  if (upcomingSelectedDate.year == 9999) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // ✅ FIX: Nếu chọn ngày quá khứ, default về today
  if (DateUtils.isPastDate(upcomingSelectedDate)) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // Ngược lại sync với ngày được chọn ở date selector
  return DateTime(
    upcomingSelectedDate.year,
    upcomingSelectedDate.month,
    upcomingSelectedDate.day,
  );
});

// ⭐ RIVERPOD LEVEL 2: Provider kiểm tra có nên hiển thị Add Task button không
final shouldShowAddTaskProvider = Provider<bool>((ref) {
  final selectedDate = ref.watch(upcomingSelectedDateProvider);

  // Không hiển thị Add Task cho ngày quá khứ
  if (DateUtils.isPastDate(selectedDate)) {
    return false;
  }

  // Hiển thị Add Task cho today và future dates
  return true;
});

// ⭐ RIVERPOD LEVEL 1: Provider tạo message phù hợp cho empty state
final emptyDateMessageProvider = Provider<String>((ref) {
  final selectedDate = ref.watch(upcomingSelectedDateProvider);

  if (DateUtils.isPastDate(selectedDate)) {
    return "No tasks were scheduled for this past date.";
  } else if (DateUtils.isToday(selectedDate)) {
    return "Great! No tasks for today.";
  } else {
    return "No tasks scheduled for this date yet.";
  }
});

// Provider quản lý danh sách công việc (StateNotifierProvider - Riverpod)
// Updated to use initialization provider instead of direct Hive.box() access
final todoListProvider = StateNotifierProvider<TodoListNotifier, List<Todo>>(
  (ref) {
    final box = ref.watch(
      todoBoxProvider,
    ); // Enhanced box through compatibility provider
    final currentUser = ref.watch(currentUserProvider);
    return TodoListNotifier(box, currentUserId: currentUser?.id, ref: ref);
  },
);

// Provider quản lý trạng thái bộ lọc sidebar (StateProvider - Riverpod)
// Ví dụ cho provider combination: provider này sẽ được các provider khác lắng nghe để lọc danh sách công việc
final sidebarItemProvider = StateProvider<SidebarItem>(
  (ref) => SidebarItem.today,
);

// Provider tính toán tiêu đề app bar dựa trên trạng thái sidebar (Provider - Riverpod)
final appBarTitleProvider = Provider<String>((ref) {
  final selectedItem = ref.watch(sidebarItemProvider);
  switch (selectedItem) {
    case SidebarItem.addTask:
      return 'Add Task';
    case SidebarItem.today:
      return 'Today';
    case SidebarItem.upcoming:
      return 'Upcoming';
    case SidebarItem.completed:
      return 'Completed';
    case SidebarItem.myProject:
      return 'My Projects';
  }
});

// Provider lọc danh sách công việc dựa trên mục Sidebar
// Provider combination: lọc danh sách công việc dựa trên trạng thái sidebar và danh sách gốc (Provider - Riverpod)
// Khi trạng thái bộ lọc hoặc danh sách công việc thay đổi, provider này sẽ tự động tính toán lại danh sách công việc cần hiển thị
final filteredTodosProvider = Provider<List<Todo>>((ref) {
  final selectedItem = ref.watch(sidebarItemProvider);
  final todos = ref.watch(todoListProvider);

  switch (selectedItem) {
    case SidebarItem.addTask:
      return []; // Không hiển thị tasks khi đang ở mode Add Task
    case SidebarItem.today:
      return todos
          .where(
            (todo) =>
                !todo.completed &&
                todo.dueDate != null &&
                DateUtils.isToday(todo.dueDate!),
          )
          .toList();
    case SidebarItem.upcoming:
      return todos
          .where(
            (todo) =>
                !todo.completed &&
                todo.dueDate != null &&
                DateUtils.isUpcoming(todo.dueDate!),
          )
          .toList();
    case SidebarItem.completed:
      return todos.where((todo) => todo.completed).toList();
    case SidebarItem.myProject:
      return [];
  }
});

// Provider đếm số lượng công việc cho mục Today (Provider - Riverpod)
final todayTodoCountProvider = Provider<int>((ref) {
  final todos = ref.watch(todoListProvider);
  return todos
      .where(
        (todo) =>
            !todo.completed &&
            todo.dueDate != null &&
            DateUtils.isToday(todo.dueDate!),
      )
      .length;
});

// Providers for project/section selection in AddTaskWidget
final newTodoProjectIdProvider = StateProvider<String?>((ref) => null);
final newTodoSectionIdProvider = StateProvider<String?>((ref) => null);

// ✅ NEW: Provider for filtered todos based on selected member
final filteredTodoListProvider = Provider<List<Todo>>((ref) {
  final allTodos = ref.watch(todoListProvider);
  final selectedFilter = ref.watch(selectedMemberFilterProvider);

  if (selectedFilter == null) {
    // No filter - show all todos
    return allTodos;
  } else if (selectedFilter == 'unassigned') {
    // Show only unassigned todos
    return allTodos.where((todo) => todo.assignedToId == null).toList();
  } else {
    // Show only todos assigned to specific user
    return allTodos.where((todo) => todo.assignedToId == selectedFilter).toList();
  }
});

// ✅ NEW: Provider to track selected member filter (moved from project_members_dialog.dart)
final selectedMemberFilterProvider = StateProvider<String?>((ref) => null);
