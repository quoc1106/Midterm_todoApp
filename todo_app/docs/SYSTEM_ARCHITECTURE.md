# System Architecture Overview

## Component Diagram - Riverpod Architecture

```plantuml
@startuml Component_Architecture

!define RECTANGLE class

package "UI Layer" {
  component [TodoScreen] as screen
  component [AddTaskWidget] as addWidget
  component [ProjectSectionWidget] as projectWidget
  component [ThemeToggleWidget] as themeWidget
  component [AppDrawer] as drawer
}

package "State Management Layer (Riverpod)" {
  
  package "Level 1 - StateProvider" {
    component [themeProvider] as themeP
    component [sidebarItemProvider] as sidebarP
  }
  
  package "Level 2 - StateNotifierProvider" {
    component [todoListProvider] as todoP
    component [projectsProvider] as projectsP
    component [sectionsProvider] as sectionsP
  }
  
  package "Level 4 - Computed Providers" {
    component [filteredTodosProvider] as filteredP
    component [todayTodoCountProvider] as countP
    component [upcomingGroupedTodosProvider] as groupedP
  }
}

package "Data Layer" {
  component [Hive Database] as hive
  component [TodoBox] as todoBox
  component [ProjectBox] as projectBox
  component [SectionBox] as sectionBox
}

package "Models" {
  component [Todo] as todoModel
  component [ProjectModel] as projectModel
  component [SectionModel] as sectionModel
}

' UI to State connections
screen --> themeP : ref.watch()
screen --> filteredP : ref.watch()
screen --> sidebarP : ref.watch()

addWidget --> todoP : ref.read().add()
addWidget --> projectsP : ref.watch()

themeWidget --> themeP : ref.read().notifier.state =

projectWidget --> sectionsP : ref.watch()
projectWidget --> todoP : ref.watch()

drawer --> sidebarP : ref.read().notifier.state =
drawer --> countP : ref.watch()

' State to State dependencies
filteredP --> todoP : depends on
filteredP --> sidebarP : depends on
countP --> todoP : depends on
groupedP --> todoP : depends on

' State to Data connections
todoP --> todoBox : read/write
projectsP --> projectBox : read/write
sectionsP --> sectionBox : read/write

' Data connections
todoBox --> hive
projectBox --> hive
sectionBox --> hive

' Model connections
todoP --> todoModel : manages
projectsP --> projectModel : manages
sectionsP --> sectionModel : manages

@enduml
```

## Class Diagram - Core Models and Providers

```plantuml
@startuml Class_CoreModels

class Todo {
  +String id
  +String description
  +DateTime? dueDate
  +bool completed
  +String? projectId
  +String? sectionId
  +DateTime createdAt
  +toggleCompleted(): Todo
}

class ProjectModel {
  +String id
  +String name
  +DateTime createdAt
}

class SectionModel {
  +String id
  +String name
  +String projectId
  +DateTime createdAt
}

enum AppTheme {
  light
  dark
  system
}

enum SidebarItem {
  today
  upcoming
  completed
  myProject
}

class TodoListNotifier {
  +List<Todo> state
  +add(Todo todo): void
  +remove(Todo todo): void
  +toggle(String id): void
  +edit(String id, String description, DateTime? dueDate): void
}

class ProjectsNotifier {
  +List<ProjectModel> state
  +addProject(String name): void
  +updateProject(String id, String name): void
  +deleteProject(String id): void
}

class SectionListNotifier {
  +List<SectionModel> state
  +addSection(String name): void
  +updateSection(String id, String name): void
  +deleteSection(String id): void
}

' Relationships
Todo --> ProjectModel : belongs to
Todo --> SectionModel : belongs to
SectionModel --> ProjectModel : belongs to

TodoListNotifier --> Todo : manages
ProjectsNotifier --> ProjectModel : manages
SectionListNotifier --> SectionModel : manages

@enduml
```

## Sequence Diagram - Add Task Flow

```plantuml
@startuml Sequence_AddTask

actor User
participant AddTaskWidget
participant "ref (WidgetRef)" as ref
participant TodoListNotifier
participant "Hive TodoBox" as hive
participant "Consumer Widgets" as consumers

User -> AddTaskWidget: Enter task description
User -> AddTaskWidget: Select project/section
User -> AddTaskWidget: Click "Add Task"

AddTaskWidget -> ref: read(todoListProvider.notifier)
ref -> TodoListNotifier: add(newTodo)

TodoListNotifier -> hive: put(todo.id, todo)
hive --> TodoListNotifier: success

TodoListNotifier -> TodoListNotifier: state = [...state, newTodo]
TodoListNotifier -> ref: notify state change

ref -> consumers: rebuild all consumers
consumers -> User: UI updates with new task

@enduml
```

## Data Flow Diagram

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   User Input    │───▶│  Riverpod State  │───▶│   UI Widgets    │
│                 │    │   Management     │    │                 │
│ • Theme toggle  │    │                  │    │ • Auto rebuild  │
│ • Add task      │    │ Level 1: Simple  │    │ • Reactive UI   │
│ • Edit task     │    │ Level 2: Complex │    │ • Conditional   │
│ • Navigate      │    │ Level 4: Computed│    │   rendering     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │ Hive Local DB   │
                       │                 │
                       │ • Persistent    │
                       │ • Offline       │
                       │ • Type-safe     │
                       └─────────────────┘
```