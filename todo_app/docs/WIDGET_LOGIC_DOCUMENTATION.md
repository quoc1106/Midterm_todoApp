# Widget Architecture Documentation

## 📁 Widget Files Overview và Logic áp dụng

### **🎨 Theme Widgets (features/theme/widgets/)**

#### **1. theme_toggle_widget.dart**
**Mục đích**: UI components để user thay đổi theme
**Logic áp dụng**:
```dart
// Chứng minh Level 1 - StateProvider "Ease of Use"
class ThemeToggleWidget extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider); // Lắng nghe state
    // PopupMenu với 3 options: Light/Dark/System
    onSelected: (theme) => ref.read(themeProvider.notifier).state = theme; // Đơn giản update
  }
}

class SimpleThemeToggle extends ConsumerWidget {
  // Icon button toggle Light ↔ Dark
  onPressed: () => ref.read(themeProvider.notifier).state = newTheme;
}
```
**Ưu điểm Riverpod**: 
- ✅ Không cần setState()
- ✅ UI tự động rebuild khi theme thay đổi
- ✅ Global state accessible từ mọi nơi

#### **2. theme_info_widget.dart**
**Mục đích**: Hiển thị thông tin theme reactive
**Logic áp dụng**:
```dart
class ThemeInfoWidget extends ConsumerWidget {
  Widget build(context, ref) {
    final currentTheme = ref.watch(themeProvider); // Auto rebuild
    final brightness = Theme.of(context).brightness;
    // Hiển thị: Selected Theme, Current Brightness, System Theme
    // Text: "Reactive Update: This widget automatically rebuilds when theme changes! 🚀"
  }
}
```
**Chứng minh**: Widget tự động cập nhật khi theme thay đổi mà không cần manual intervention.

---

### **📝 Todo Widgets (features/todo/widgets/)**

#### **3. add_task_widget.dart**
**Mục đích**: Form thêm task mới với project/section selection
**Logic áp dụng**:
```dart
class AddTaskWidget extends ConsumerStatefulWidget {
  // Logic phức tạp:
  // 1. Kiểm tra current view để hiển thị form phù hợp
  // 2. Auto-hide trong Completed view
  // 3. Project/Section selection với ProjectSectionPickerRow
  // 4. Date picker integration
  // 5. Validation và save to StateNotifier
  
  Widget build(context, ref) {
    final selectedItem = ref.watch(sidebarItemProvider);
    
    // Logic: Ẩn trong Completed view
    if (selectedItem == SidebarItem.completed) return SizedBox.shrink();
    
    // Logic: Hiển thị project/section picker trong Today/Upcoming
    if (selectedItem == SidebarItem.today || selectedItem == SidebarItem.upcoming) {
      // Show ProjectSectionPickerRow
    }
    
    // Logic: Auto-fill project trong Project view
    if (selectedItem == SidebarItem.myProject) {
      // Pre-fill current project, show section picker
    }
  }
  
  void _addTodo() {
    // Level 2 - StateNotifierProvider
    ref.read(todoListProvider.notifier).add(newTodo);
  }
}
```
**Riverpod Benefits**:
- ✅ Multi-provider dependency (sidebar + projects + sections)
- ✅ Conditional UI based on provider state
- ✅ Clean separation: UI logic vs Business logic

#### **4. todo_item.dart**
**Mục đích**: Display individual task với edit/delete functionality
**Logic áp dụng**:
```dart
class TodoItem extends ConsumerWidget {
  Widget build(context, ref) {
    // Logic 1: Fetch related data
    String? projectName, sectionName;
    if (todo.projectId != null) {
      final box = ref.read(projectBoxProvider);
      final project = box.get(todo.projectId!);
      projectName = project?.name; // Hiển thị tên project
    }
    // Tương tự cho section
    
    // Logic 2: Subtitle composition
    // Format: "DD/MM/YYYY • Project: ProjectName / Section: SectionName"
    
    // Logic 3: Actions
    onChanged: (val) => ref.read(todoListProvider.notifier).toggle(todo.id); // Toggle completed
    onTap: () => showEditDialog(); // Edit dialog với date picker
    trailing: DeleteButton(); // Confirmation dialog
  }
}
```
**Key Features**:
- ✅ Related data fetching (project/section names)
- ✅ Complex subtitle formatting
- ✅ Modal dialogs integration
- ✅ StateNotifier method calls

#### **5. todo_group_widget.dart**
**Mục đích**: Group tasks theo ngày với add task functionality
**Logic áp dụng**:
```dart
class TodoGroupWidget extends ConsumerWidget {
  Widget build(context, ref) {
    // Logic 1: Filter active todos
    final activeTodos = todos.where((todo) => !todo.completed).toList();
    
    // Logic 2: Date header
    Text('${groupDate.day}/${groupDate.month}/${groupDate.year}')
    
    // Logic 3: Task list
    ...activeTodos.map((todo) => TodoItem(todo: todo))
    
    // Logic 4: Conditional Add Task button
    Consumer(builder: (context, ref, _) {
      final isOpen = ref.watch(addTaskGroupDateProvider) == groupDate;
      
      if (!isOpen && !_isPast(groupDate)) {
        return TextButton("Add task"); // Show button
      }
      
      if (isOpen) {
        return AddTaskWidget(initialDate: groupDate); // Show form
      }
    })
  }
  
  bool _isPast(DateTime date) {
    // Utility: Check if date is in the past
  }
}
```
**Design Pattern**:
- ✅ Composition: TodoItem reuse
- ✅ Conditional rendering based on state
- ✅ Date utility functions
- ✅ State management cho expand/collapse

#### **6. project_section_widget.dart**
**Mục đích**: Display sections trong project với Today tasks tab
**Logic áp dụng**:
```dart
class ProjectSectionWidget extends ConsumerStatefulWidget {
  // Complex State Management:
  String? _openAddTaskSectionId; // Track which section showing add form
  
  Widget build(context, ref) {
    // Logic 1: Fetch data
    final sections = ref.watch(sectionListNotifierProvider(widget.projectId));
    
    // Logic 2: Today tasks computation
    final todayTasks = [
      for (final section in sections)
        ...ref.watch(tasksBySectionProvider(section.id))
           .where((task) => isToday(task.dueDate))
    ];
    
    // Logic 3: Tab switching
    StatefulBuilder(builder: (context, setState) => {
      // "Sections" tab vs "Today tasks" tab
      showTodayTasks ? showTodayView() : showSectionsView()
    })
    
    // Logic 4: Per-section add task management
    if (_openAddTaskSectionId == section.id) {
      AddTaskWidget(
        projectId: widget.projectId,
        sectionId: section.id,
        onCancel: () => _toggleAddTask(section.id, false)
      );
    }
  }
}
```
**Advanced Features**:
- ✅ Family providers (sectionListNotifierProvider(projectId))
- ✅ Complex data computation (today tasks across sections)
- ✅ Local state + Global state combination
- ✅ Conditional widget rendering

#### **7. project_sidebar_widget.dart**
**Mục đích**: Sidebar expansion với project CRUD
**Logic áp dụng**:
```dart
class ProjectSidebarWidget extends ConsumerWidget {
  Widget build(context, ref) {
    final projects = ref.watch(projectsProvider); // Level 2 - StateNotifierProvider
    
    return ExpansionTile(
      title: Row(
        children: [
          Text('My Projects'),
          IconButton(icon: Icons.add, onPressed: _addProject) // Add project
        ]
      ),
      children: [
        for (final project in projects)
          ListTile(
            title: Text(project.name),
            onTap: () {
              // Navigation logic
              ref.read(sidebarItemProvider.notifier).state = SidebarItem.myProject;
              ref.read(selectedProjectIdProvider.notifier).state = project.id;
              Navigator.pop(context); // Close drawer
            },
            trailing: Row([
              IconButton(Icons.edit, onPressed: _editProject),
              IconButton(Icons.delete, onPressed: _deleteProject)
            ])
          )
      ]
    );
  }
}
```
**State Management**:
- ✅ Multi-provider updates (sidebar + selected project)
- ✅ Navigation integration
- ✅ CRUD dialogs
- ✅ List rendering từ StateNotifier

#### **8. app_drawer.dart**
**Mục đích**: Main navigation drawer
**Logic áp dụng**:
```dart
class AppDrawer extends ConsumerWidget {
  Widget build(context, ref) {
    final selectedItem = ref.watch(sidebarItemProvider);
    final todayCount = ref.watch(todayTodoCountProvider); // Level 4 - Computed Provider
    
    return Drawer(
      children: [
        DrawerHeader(),
        _buildDrawerItem(Icons.today, 'Today', SidebarItem.today, 
                        trailing: todayCount > 0 ? Text(todayCount.toString()) : null),
        _buildDrawerItem(Icons.upcoming, 'Upcoming', SidebarItem.upcoming),
        _buildDrawerItem(Icons.completed, 'Completed', SidebarItem.completed),
        Divider(),
        ListTile(title: 'Theme', trailing: ThemeToggleWidget()), // Theme integration
        ProjectSidebarWidget() // Composition
      ]
    );
  }
  
  Widget _buildDrawerItem(...) {
    // Highlight selected item với theme colors
    // onTap: Update sidebarItemProvider + Navigator.pop()
  }
}
```
**Integration Points**:
- ✅ Multiple providers (sidebar, count, theme)
- ✅ Widget composition (ThemeToggleWidget, ProjectSidebarWidget)
- ✅ Navigation logic
- ✅ Dynamic trailing widgets (count badge)

#### **9. date_selector_widget.dart**
**Mục đích**: Week date picker cho Upcoming view
**Logic áp dụng**:
```dart
class DateSelectorWidget extends ConsumerWidget {
  Widget build(context, ref) {
    final weekStart = ref.watch(upcomingWeekStartProvider);
    final selectedDate = ref.watch(upcomingSelectedDateProvider);
    
    // Logic 1: Generate week days
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final daysWithAll = [DateTime(9999, 1, 1), ...days]; // "All" option
    
    // Logic 2: Horizontal scrollable list
    ListView.separated(
      scrollDirection: Axis.horizontal,
      itemBuilder: (context, i) {
        final day = daysWithAll[i];
        final isSelected = isSameDay(day, selectedDate);
        
        return GestureDetector(
          onTap: () => ref.read(upcomingSelectedDateProvider.notifier).state = day,
          child: Container(
            decoration: isSelected ? selectedStyle : normalStyle,
            child: Column([
              Text(weekdayStr), // Mon, Tue, Wed...
              if (!isAll) Text('${day.day}') // Day number
            ])
          )
        );
      }
    )
    
    // Logic 3: Navigation buttons
    IconButton(Icons.chevron_left, onPressed: () => moveWeek(-7)),
    TextButton('Today', onPressed: () => goToToday()),
    IconButton(Icons.chevron_right, onPressed: () => moveWeek(7)),
    IconButton(Icons.calendar, onPressed: () => showDatePicker())
  }
}
```
**Sophisticated Features**:
- ✅ Date manipulation logic
- ✅ Horizontal scrolling
- ✅ Multiple provider updates
- ✅ Modal integration (DatePicker)

#### **10. project_section_picker_dialog.dart**
**Mục đích**: Reusable dialog cho project/section selection
**Logic áp dụng**:
```dart
class ProjectSectionPickerDialog extends ConsumerStatefulWidget {
  // Reusable component cho project/section selection
  // Local state: selectedProjectId, selectedSectionId
  // Global state: projects, sections per project
  
  Widget build(context, ref) {
    final projects = ref.watch(projectsProvider);
    
    // Step 1: Project selection
    DropdownButton<String>(
      items: projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
      onChanged: (projectId) => setState(() => selectedProjectId = projectId)
    )
    
    // Step 2: Section selection (conditional)
    if (selectedProjectId != null) {
      final sections = ref.watch(sectionListNotifierProvider(selectedProjectId!));
      DropdownButton<String>(
        items: sections.map((s) => DropdownMenuItem(...)),
        onChanged: (sectionId) => setState(() => selectedSectionId = sectionId)
      )
    }
  }
}
```
**Reusability Pattern**:
- ✅ Generic dialog component
- ✅ Callback-based result return
- ✅ Mixed local + global state
- ✅ Conditional UI rendering

#### **11. project_section_picker_row.dart**
**Mục đích**: Inline widget cho project/section selection
**Logic tương tự ProjectSectionPickerDialog nhưng inline format**

---

## 🧠 **Logic Architecture Summary**

### **Widget Hierarchy & Composition**:
```
TodoScreen
├── AppDrawer
│   ├── ThemeToggleWidget
│   └── ProjectSidebarWidget
├── AddTaskWidget
│   └── ProjectSectionPickerRow
├── DateSelectorWidget (conditional)
└── Content Area
    ├── TodoGroupWidget
    │   └── TodoItem (multiple)
    ├── ProjectSectionWidget
    │   └── AddTaskWidget (per section)
    └── Simple ListView (Today/Completed)
```

### **Riverpod Integration Patterns**:
1. **ref.watch()**: Lắng nghe state changes → auto rebuild
2. **ref.read()**: One-time access hoặc update state
3. **Consumer**: Nested reactive widgets
4. **Family Providers**: Parameterized providers (sections per project)
5. **Computed Providers**: Automatic dependency resolution

### **State Flow Patterns**:
1. **User Input** → **Provider Update** → **UI Rebuild**
2. **Conditional Rendering** based on provider state
3. **Cross-widget Communication** through shared providers
4. **Hierarchical Data** (Project → Section → Task) with proper provider structure

**Kết luận**: Mỗi widget có vai trò rõ ràng trong architecture, từ đơn giản (theme toggle) đến phức tạp (project hierarchy), tất cả đều leverage Riverpod để achieve reactive, maintainable UI.