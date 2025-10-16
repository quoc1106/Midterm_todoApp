# Activity Diagram - Todo App Key Flows

## 1. Activity Diagram: Change Theme (Level 1 - StateProvider)

```plantuml
@startuml Activity_ChangeTheme

start
:User opens app;
:UI displays current theme;
note right: ref.watch(themeProvider)

if (User wants to change theme?) then (yes)
  :User clicks theme toggle button;
  :Show theme options (Light/Dark/System);
  :User selects new theme;
  :Update StateProvider;
  note right: ref.read(themeProvider.notifier).state = newTheme
  :StateProvider notifies consumers;
  :All widgets using theme rebuild automatically;
  note right: Reactive UI update
  :Theme changed successfully;
else (no)
  :Continue using current theme;
endif

stop

@enduml
```

## 2. Activity Diagram: Add Task with Project/Section (Level 2 & 4)

```plantuml
@startuml Activity_AddTask

start
:User opens Add Task widget;
:System checks current view;
note right: ref.watch(sidebarItemProvider)

if (View is Today/Upcoming?) then (yes)
  :Show project/section picker;
  :Load projects from Hive;
  note right: ref.watch(projectsProvider)
  
  if (User selects project?) then (yes)
    :Load sections for project;
    note right: ref.watch(sectionListNotifierProvider)
    :User selects section (optional);
  else (no)
    :Skip project/section selection;
  endif
  
else (View is Project?)
  :Auto-fill current project;
  :Show section picker for current project;
endif

:User enters task description;
:User sets due date (optional);
:User clicks Add button;

:Validate input;
if (Input valid?) then (yes)
  :Create Todo object;
  :Save to Hive database;
  note right: StateNotifier.add()
  :Update StateNotifier state;
  note right: state = [...state, newTodo]
  :UI rebuilds with new task;
  note right: Consumer widgets rebuild
  :Show success feedback;
else (no)
  :Show error message;
  :Return to form;
endif

stop

@enduml
```

## 3. Activity Diagram: Filter Tasks (Level 4 - Computed Providers)

```plantuml
@startuml Activity_FilterTasks

start
:User navigates to different view;
:Update sidebar selection;
note right: ref.read(sidebarItemProvider.notifier).state = newView

:System triggers computed providers;
note right: Automatic dependency chain

fork
  :filteredTodosProvider recomputes;
  note right: Watches todoListProvider + sidebarItemProvider
fork again
  :upcomingGroupedTodosProvider recomputes;
  note right: Groups tasks by date
fork again
  :todayTodoCountProvider recomputes;
  note right: Counts today's tasks
end fork

:All dependent widgets rebuild;
note right: Only affected widgets rebuild

if (View is Upcoming?) then (yes)
  :Show DateSelectorWidget;
  if (User selects specific date?) then (yes)
    :Update upcomingSelectedDateProvider;
    :Filter tasks for selected date;
  else (no)
    :Show all upcoming tasks grouped by date;
  endif
  
else if (View is Today?) then (yes)
  :Show only today's tasks;
  :Hide completed tasks;
  
else if (View is Completed?) then (yes)
  :Show only completed tasks;
  :Hide Add Task widget;
  
else (View is Project)
  :Show ProjectSectionWidget;
  :Load sections for selected project;
  if (User switches to Today tab in project?) then (yes)
    :Filter tasks for today in this project;
  else (no)
    :Show all sections with tasks;
  endif
endif

:Display filtered results;
stop

@enduml
```

## 4. Activity Diagram: App Initialization (Level 3 - FutureProvider concept)

```plantuml
@startuml Activity_AppInit

start
:App starts;
:Initialize Flutter binding;
:Initialize date formatting;

:Initialize Hive;
note right: await Hive.initFlutter()

:Register adapters;
note right: TodoAdapter, ProjectAdapter, SectionAdapter

fork
  :Open todos box;
  note right: await Hive.openBox<Todo>('todos')
fork again
  :Open projects box;
  note right: await Hive.openBox<ProjectModel>('projects')
fork again
  :Open sections box;
  note right: await Hive.openBox<SectionModel>('sections')
end fork

:Load data into providers;
note right: StateNotifiers read from boxes

:Start ProviderScope;
:Initialize MyApp with theme providers;
:Start TodoScreen;

:UI renders with loaded data;
stop

@enduml
```

## 5. Activity Diagram: Project-Section-Task Hierarchy

```plantuml
@startuml Activity_ProjectHierarchy

start
:User selects "My Projects" from sidebar;
:Expand project list;
:Show all projects with actions;

:User clicks on project;
:Navigate to ProjectSectionWidget;
:Set selectedProjectIdProvider;

:Load sections for project;
note right: sectionListNotifierProvider(projectId)

fork
  :Show "Sections" tab;
  :Display sections with tasks;
  note right: tasksBySectionProvider(sectionId)
fork again
  :Show "Today tasks" tab;
  :Filter today's tasks in this project;
  note right: Computed from all sections
end fork

if (User wants to add section?) then (yes)
  :Show add section dialog;
  :User enters section name;
  :Add section to project;
  note right: StateNotifier.addSection()
  :Refresh sections list;
endif

if (User wants to add task to section?) then (yes)
  :Show AddTaskWidget;
  :Pre-fill project and section;
  :User enters task details;
  :Save task with project/section IDs;
  note right: Task linked to hierarchy
  :Update task list for section;
endif

stop

@enduml
```

## Key Insights from Activity Diagrams

### **Riverpod Patterns Demonstrated:**

1. **Level 1 (StateProvider)**: Simple theme toggle với automatic UI rebuild
2. **Level 2 (StateNotifierProvider)**: Complex task management với business logic
3. **Level 4 (Computed Providers)**: Reactive filtering và dependency chains

### **Data Flow:**
- **Unidirectional**: User action → Provider update → UI rebuild
- **Reactive**: Dependent providers tự động recompute
- **Persistent**: Hive integration trong StateNotifier methods

### **UI Patterns:**
- **Consumer widgets**: Automatic rebuild khi provider changes
- **Conditional rendering**: Based on provider state
- **Form handling**: Validation và error states