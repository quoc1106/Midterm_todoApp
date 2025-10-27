import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../backend/models/todo_model.dart';
import 'package:hive/hive.dart';
import 'performance_initialization_providers.dart';
import 'auth_providers.dart'; // for currentUserProvider
import 'project_providers.dart'; // for projectsProvider

// Provider lưu trạng thái ngày đầu tuần hiện tại để chuyển tuần (Riverpod)
final upcomingWeekStartProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  // ✅ CRITICAL FIXED: Tính toán đúng thứ 2 của tuần (Monday = 1)
  final today = DateTime(now.year, now.month, now.day); // Normalized to start of day
  final daysFromMonday = today.weekday - 1; // Monday = 0, Tuesday = 1, etc.
  final mondayOfThisWeek = today.subtract(Duration(days: daysFromMonday));

  print('🔍 WEEK DEBUG: Today is ${today} (weekday: ${today.weekday})');
  print('🔍 WEEK DEBUG: Days from Monday: $daysFromMonday');
  print('🔍 WEEK DEBUG: Monday of this week: $mondayOfThisWeek');

  return mondayOfThisWeek;
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

  // ⭐ NEW: Utility for overdue date validation
  static bool isOverdue(DateTime date) {
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
    // ✅ FIXED: Filter by assignee instead of owner for Today/Upcoming views
    // Business Logic: Users should see tasks assigned TO them, not created BY them
    final allTodos = box.values.toList();

    // Debug: Log all todos to understand the issue
    print('🔍 DEBUG: Filtering todos for user: $ownerId');
    print('🔍 DEBUG: Total todos in box: ${allTodos.length}');

    for (int i = 0; i < allTodos.length && i < 5; i++) {
      final todo = allTodos[i];
      print('🔍 DEBUG: Todo $i - ownerId: ${todo.ownerId}, assignedTo: ${todo.assignedToId}, desc: ${todo.description}');
    }

    List<Todo> filtered;

    if (ownerId == null) {
      // Guest user - only show unowned and unassigned todos
      filtered = allTodos.where((t) => t.ownerId == null && t.assignedToId == null).toList();
    } else {
      // ✅ FIXED: Show tasks assigned TO current user, not created BY current user
      // Business Rule: Today/Upcoming should show what user needs to work on
      filtered = allTodos.where((t) =>
        t.assignedToId == ownerId || // Tasks assigned to current user
        (t.assignedToId == null && t.ownerId == ownerId) // Unassigned tasks owned by user
      ).toList();
    }

    print('🔍 DEBUG: Filtered todos count: ${filtered.length}');
    print('🔍 DEBUG: Current user can see these todos (assigned to them):');
    for (int i = 0; i < filtered.length && i < 3; i++) {
      final todo = filtered[i];
      print('🔍 DEBUG: - ${todo.description} (assigned to: ${todo.assignedToId}, owner: ${todo.ownerId})');
    }

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

// ✅ NEW: Provider để quản lý trạng thái thu gọn/mở rộng của overdue section
final overdueCollapsedProvider = StateProvider<bool>((ref) => false);

// ✅ NEW: Provider để lấy danh sách overdue todos
final overdueTodosProvider = Provider<List<Todo>>((ref) {
  final todos = ref.watch(todoListProvider);
  return todos
      .where(
        (todo) =>
            !todo.completed &&
            todo.dueDate != null &&
            DateUtils.isOverdue(todo.dueDate!),
      )
      .toList();
});

// ✅ NEW: Provider để đếm số lượng overdue todos
final overdueTodoCountProvider = Provider<int>((ref) {
  final overdueTodos = ref.watch(overdueTodosProvider);
  return overdueTodos.length;
});

// ✅ NEW: Provider để lấy todos chỉ trong ngày hôm nay (không bao gồm overdue)
final todayOnlyTodosProvider = Provider<List<Todo>>((ref) {
  final todos = ref.watch(todoListProvider);
  return todos
      .where(
        (todo) =>
            !todo.completed &&
            todo.dueDate != null &&
            DateUtils.isToday(todo.dueDate!),
      )
      .toList();
});

// ✅ NEW: Provider cho Upcoming view - lấy TẤT CẢ overdue todos (không chỉ trong tuần)
final upcomingOverdueTodosProvider = Provider<List<Todo>>((ref) {
  final todos = ref.watch(todoListProvider);
  return todos
      .where(
        (todo) =>
            !todo.completed &&
            todo.dueDate != null &&
            DateUtils.isOverdue(todo.dueDate!),
      )
      .toList();
});

// ✅ NEW: Provider quản lý trạng thái thu gọn/mở rộng cho từng nhóm ngày trong Upcoming
final upcomingGroupCollapsedProvider = StateProvider.family<bool, String>((ref, dateKey) => false);

// ✅ NEW: Provider quản lý trạng thái thu gọn overdue section trong Upcoming
final upcomingOverdueCollapsedProvider = StateProvider<bool>((ref) => false);

// ✅ CRITICAL FIXED: Enhanced Provider cho Upcoming grouped todos - BÀO GỒM TASKS HÔM NAY
final enhancedUpcomingGroupedTodosProvider = Provider<List<GroupedTodos>>((ref) {
  final todos = ref.watch(todoListProvider);
  final selectedDate = ref.watch(upcomingSelectedDateProvider);

  // Nếu chọn "All" (year 9999), hiển thị tasks trong tuần hiện tại
  if (selectedDate.year == 9999) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // ✅ CRITICAL FIXED: Sử dụng upcomingWeekStartProvider để đồng bộ với date selector
    final weekStart = ref.watch(upcomingWeekStartProvider);
    final weekEnd = weekStart.add(const Duration(days: 6));

    print('🔍 ENHANCED DEBUG: Current date: $today');
    print('🔍 ENHANCED DEBUG: Week start: $weekStart');
    print('🔍 ENHANCED DEBUG: Week end: $weekEnd');
    print('🔍 ENHANCED DEBUG: Today weekday: ${today.weekday}');
    print('🔍 ENHANCED DEBUG: Is today >= weekStart? ${!today.isBefore(weekStart)}');
    print('🔍 ENHANCED DEBUG: Is today <= weekEnd? ${!today.isAfter(weekEnd)}');

    // ✅ DEBUG: Log all todos before filtering with detailed info
    print('🔍 ENHANCED DEBUG: All todos count: ${todos.length}');
    for (final todo in todos) {
      if (todo.dueDate != null) {
        final todoDueDate = DateTime(todo.dueDate!.year, todo.dueDate!.month, todo.dueDate!.day);
        print('🔍 ENHANCED DEBUG: Todo "${todo.description}"');
        print('   - Original date: ${todo.dueDate}');
        print('   - Normalized date: $todoDueDate');
        print('   - Completed: ${todo.completed}');
        print('   - Is >= weekStart? ${!todoDueDate.isBefore(weekStart)}');
        print('   - Is <= weekEnd? ${!todoDueDate.isAfter(weekEnd)}');
        print('   - Will be included? ${!todo.completed && !todoDueDate.isBefore(weekStart) && !todoDueDate.isAfter(weekEnd)}');
      }
    }

    // ✅ CRITICAL FIXED: Lấy tasks CHỈ trong tuần hiện tại - BÀO GỒM HÔM NAY
    final weekTodos = todos.where((todo) {
      if (todo.dueDate == null || todo.completed) return false;

      // ✅ FIXED: Normalize due date to start of day for comparison
      final todoDueDate = DateTime(todo.dueDate!.year, todo.dueDate!.month, todo.dueDate!.day);

      // ✅ CRITICAL FIXED: Chỉ check week boundaries, không exclude hôm nay
      final isInWeek = !todoDueDate.isBefore(weekStart) && !todoDueDate.isAfter(weekEnd);

      print('🔍 FILTER DEBUG: "${todo.description}" ($todoDueDate) -> included: $isInWeek');
      return isInWeek;
    }).toList();

    print('🔍 ENHANCED DEBUG: Week todos count after filtering: ${weekTodos.length}');
    for (final todo in weekTodos) {
      print('🔍 ENHANCED DEBUG: - ${todo.description} (${todo.dueDate})');
    }

    // Nhóm theo ngày
    final Map<String, List<Todo>> groupedByDate = {};
    for (final todo in weekTodos) {
      final todoDueDate = DateTime(todo.dueDate!.year, todo.dueDate!.month, todo.dueDate!.day);
      final dateKey = '${todoDueDate.year}-${todoDueDate.month}-${todoDueDate.day}';
      groupedByDate.putIfAbsent(dateKey, () => []).add(todo);
      print('🔍 GROUPING DEBUG: Added "${todo.description}" to group $dateKey');
    }

    // Chuyển đổi thành GroupedTodos và sắp xếp theo ngày
    final result = groupedByDate.entries.map((entry) {
      final parts = entry.key.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      return GroupedTodos(date, entry.value);
    }).toList();

    result.sort((a, b) => a.date.compareTo(b.date));

    print('🔍 ENHANCED DEBUG: Final grouped result count: ${result.length}');
    for (final group in result) {
      print('🔍 ENHANCED DEBUG: - ${group.date}: ${group.todos.length} todos');
      for (final todo in group.todos) {
        print('🔍 ENHANCED DEBUG:   * ${todo.description}');
      }
    }

    return result;
  }

  // ✅ FIXED: Logic cho khi chọn ngày cụ thể - sử dụng weekStart từ provider
  final weekStart = ref.watch(upcomingWeekStartProvider);
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

// ✅ NEW: Provider cho Project/Section views - hiển thị TẤT CẢ todos trong project
// Khác với todoListProvider, provider này không filter theo assignee
final projectTodosProvider = Provider<List<Todo>>((ref) {
  // ✅ FIX: Watch todoBoxProvider properly to ensure reactive updates
  final todoBox = ref.watch(todoBoxProvider);
  final currentUser = ref.watch(currentUserProvider);

  if (currentUser == null) {
    // Guest user - only show unowned and unassigned todos
    return todoBox.values.where((todo) =>
      todo.ownerId == null && todo.assignedToId == null
    ).toList();
  }

  // ✅ PROJECT/SECTION VIEW LOGIC: Show ALL tasks in accessible projects
  // Business Rule: In shared workspaces, users should see all tasks for collaboration
  final accessibleProjects = ref.watch(projectsProvider); // Already filtered by user access
  final accessibleProjectIds = accessibleProjects.map((p) => p.id).toSet();

  // ✅ FIX: Force refresh on todoBox changes by converting to list first
  final allTodos = todoBox.values.toList();

  return allTodos.where((todo) {
    // Show tasks in accessible projects (regardless of assignee)
    if (todo.projectId != null && accessibleProjectIds.contains(todo.projectId)) {
      return true;
    }

    // Also show personal tasks (owned by current user, no project)
    if (todo.projectId == null && todo.ownerId == currentUser.id) {
      return true;
    }

    return false;
  }).toList();
});

