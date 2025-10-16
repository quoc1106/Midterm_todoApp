# Use Case Diagram - Todo App with Riverpod

## Actors
- **User (Người dùng)**: Người sử dụng ứng dụng quản lý công việc

## Use Cases

### 📱 **Theme Management (Cấp độ 1 - StateProvider)**
1. **Change Theme**
   - Switch to Light Theme
   - Switch to Dark Theme  
   - Switch to System Theme
   - View Current Theme Status

### 📝 **Task Management (Cấp độ 2 - StateNotifierProvider)**
2. **Manage Tasks**
   - Add New Task
   - Edit Task Description
   - Set Task Due Date
   - Mark Task as Completed/Uncompleted
   - Delete Task
   - View Task Details (Project/Section info)

### 📁 **Project Management**
3. **Manage Projects**
   - Add New Project
   - Rename Project
   - Delete Project
   - Select Project to View

### 🗂️ **Section Management**
4. **Manage Sections**
   - Add Section to Project
   - Edit Section Name
   - Delete Section
   - View Tasks in Section

### 🧭 **Navigation & Views (Cấp độ 4 - Computed Providers)**
5. **Navigate Between Views**
   - View Today Tasks
   - View Upcoming Tasks
   - View Completed Tasks
   - View Project Details
   - View Section Details

### 🔍 **Filtering & Grouping (Cấp độ 4)**
6. **Filter Tasks**
   - Filter by Date (Today/Upcoming)
   - Filter by Completion Status
   - Filter by Project
   - Filter by Section
   - View Today Tasks in Project

### 📊 **Statistics & Computed Data**
7. **View Statistics**
   - View Today Task Count
   - View Tasks by Date Groups
   - View Task Progress

## PlantUML Code
```plantuml
@startuml UseCase_TodoApp

!define RECTANGLE class

actor "User" as user

rectangle "Todo App with Riverpod" {
  
  package "Theme Management\n(Level 1 - StateProvider)" {
    usecase "Change Theme" as UC1
    usecase "View Theme Status" as UC1a
  }
  
  package "Task Management\n(Level 2 - StateNotifierProvider)" {
    usecase "Add Task" as UC2
    usecase "Edit Task" as UC3
    usecase "Delete Task" as UC4
    usecase "Toggle Task Status" as UC5
    usecase "Set Due Date" as UC6
  }
  
  package "Project Management" {
    usecase "Add Project" as UC7
    usecase "Edit Project" as UC8
    usecase "Delete Project" as UC9
    usecase "Select Project" as UC10
  }
  
  package "Section Management" {
    usecase "Add Section" as UC11
    usecase "Edit Section" as UC12
    usecase "Delete Section" as UC13
  }
  
  package "Navigation & Views\n(Level 4 - Computed Providers)" {
    usecase "View Today Tasks" as UC14
    usecase "View Upcoming Tasks" as UC15
    usecase "View Completed Tasks" as UC16
    usecase "View Project Details" as UC17
  }
  
  package "Filtering & Statistics" {
    usecase "Filter Tasks by Date" as UC18
    usecase "Filter Tasks by Status" as UC19
    usecase "View Task Statistics" as UC20
    usecase "Group Tasks by Date" as UC21
  }
}

' Relationships
user --> UC1
user --> UC1a
user --> UC2
user --> UC3
user --> UC4
user --> UC5
user --> UC6
user --> UC7
user --> UC8
user --> UC9
user --> UC10
user --> UC11
user --> UC12
user --> UC13
user --> UC14
user --> UC15
user --> UC16
user --> UC17
user --> UC18
user --> UC19
user --> UC20
user --> UC21

' Extensions and Includes
UC2 ..> UC7 : <<extend>>
UC2 ..> UC11 : <<extend>>
UC17 ..> UC10 : <<include>>
UC13 ..> UC10 : <<include>>
UC11 ..> UC10 : <<include>>

@enduml
```

## Mô tả chi tiết Use Cases

### **UC1: Change Theme (Level 1)**
- **Actor**: User
- **Description**: Người dùng thay đổi theme của ứng dụng
- **Riverpod**: StateProvider
- **Flow**: User clicks theme button → StateProvider updates → UI rebuilds

### **UC2-6: Task Management (Level 2)**
- **Actor**: User  
- **Description**: CRUD operations cho tasks
- **Riverpod**: StateNotifierProvider
- **Persistence**: Hive local storage

### **UC14-17: Navigation (Level 4)**
- **Actor**: User
- **Description**: Chuyển đổi giữa các view
- **Riverpod**: Computed Providers
- **Features**: Reactive filtering, automatic grouping

## Relationships
- **Include**: UC17 (View Project) bao gồm UC10 (Select Project)
- **Extend**: UC2 (Add Task) có thể mở rộng với UC7 (Add Project), UC11 (Add Section)