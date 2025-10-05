import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/todo_model.dart';
import 'package:hive/hive.dart';

// Thêm search 
final searchQueryProvider = StateProvider<String>((ref) => '');


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

// Enum mới cho các mục trong Sidebar
enum SidebarItem { today, upcoming, completed, myProject }

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
}

class TodoListNotifier extends StateNotifier<List<Todo>> {
  final Box<Todo> _box;
  TodoListNotifier(this._box) : super(_box.values.toList());


  // Thêm hàm để toggle pin
  void togglePin(String id) {
    final idx = state.indexWhere((todo) => todo.id == id);
    if (idx != -1) {
      final todo = state[idx];
      final toggled = todo.copyWith(isPinned: !todo.isPinned);
      _box.putAt(idx, toggled);  // đồng bộ lên Hive
      state = _box.values.toList();
    }
  }
  void add(
    String description, {
    DateTime? dueDate,
    String? projectId,
    String? sectionId,
  }) {
    final newTodo = Todo(
      id: _uuid.v4(),
      description: description,
      dueDate: dueDate ?? DateTime.now(),
      projectId: projectId,
      sectionId: sectionId,
    );
    _box.add(newTodo);
    state = _box.values.toList();
  }

  void toggle(String id) {
    final idx = _box.values.toList().indexWhere((todo) => todo.id == id);
    if (idx != -1) {
      final todo = _box.getAt(idx);
      if (todo != null) {
        _box.putAt(idx, todo.copyWith(completed: !todo.completed));
        state = _box.values.toList();
      }
    }
  }

  void edit({
    required String id,
    required String description,
    DateTime? dueDate,
  }) {
    final idx = _box.values.toList().indexWhere((todo) => todo.id == id);
    if (idx != -1) {
      final todo = _box.getAt(idx);
      if (todo != null) {
        _box.putAt(
          idx,
          todo.copyWith(description: description, dueDate: dueDate),
        );
        state = _box.values.toList();
      }
    }
  }

  void remove(Todo target) {
    final idx = _box.values.toList().indexWhere((todo) => todo.id == target.id);
    if (idx != -1) {
      _box.deleteAt(idx);
      state = _box.values.toList();
    }
  }
}

// --- PROVIDERS ---
// Các provider dưới đây sử dụng Riverpod để quản lý state cho todo list, sidebar, bộ lọc, tiêu đề app bar...
// Provider lưu trạng thái ngày chọn khi tạo task mới ở Upcoming
final newTodoDateProvider = StateProvider<DateTime>((ref) {
  // Luôn khởi tạo là hôm nay, không lấy từ provider khác
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

// Provider quản lý danh sách công việc (StateNotifierProvider - Riverpod)
final todoListProvider = StateNotifierProvider<TodoListNotifier, List<Todo>>((
  ref,
) {
  final box = Hive.box<Todo>('todos');
  return TodoListNotifier(box);
});

// Provider quản lý trạng thái bộ lọc sidebar (StateProvider - Riverpod)
// Ví dụ cho provider combination: provider này sẽ được các provider khác lắng nghe để lọc danh sách công việc
final sidebarItemProvider = StateProvider<SidebarItem>(
  (ref) => SidebarItem.today,
);

// Provider tính toán tiêu đề app bar dựa trên trạng thái sidebar (Provider - Riverpod)
final appBarTitleProvider = Provider<String>((ref) {
  final selectedItem = ref.watch(sidebarItemProvider);
  switch (selectedItem) {
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
final filteredTodosProvider = Provider<List<Todo>>((ref) {// Fix 04/10
  final selectedItem = ref.watch(sidebarItemProvider);
  final todos = ref.watch(todoListProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  // Lọc các todo theo sidebar và query
  List<Todo> filtered;
  switch (selectedItem) {
    case SidebarItem.today:
      filtered = todos.where((todo) =>
        !todo.completed &&
        todo.dueDate != null &&
        DateUtils.isToday(todo.dueDate!) &&
        todo.description.toLowerCase().contains(query)
      ).toList();
      break;

    case SidebarItem.upcoming:
      filtered = todos.where((todo) =>
        !todo.completed &&
        todo.dueDate != null &&
        DateUtils.isUpcoming(todo.dueDate!) &&
        todo.description.toLowerCase().contains(query)
      ).toList();
      break;

    case SidebarItem.completed:
      filtered = todos.where((todo) =>
        todo.completed &&
        todo.description.toLowerCase().contains(query)
      ).toList();
      break;

    case SidebarItem.myProject:
      filtered = todos.where((todo) =>
        todo.description.toLowerCase().contains(query)
      ).toList();
      break;
  }

  // Sắp xếp để các task được đánh dấu là isPinned sẽ lên đầu danh sách
  filtered.sort((a, b) {
    if (a.isPinned && !b.isPinned) return -1;
    if (!a.isPinned && b.isPinned) return 1;
    return 0;
  });

  return filtered;
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
