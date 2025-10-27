# 🔄 SYSTEM WORKFLOW COMPLETE - Luồng Hoạt Động Logic Chi Tiết

## 📋 **TỔNG QUAN HỆ THỐNG**

Tài liệu này mô tả chi tiết luồng hoạt động logic của:
- **🔐 Authentication System** (Đăng nhập/Đăng ký)
- **📁 Project Section Management** (Quản lý sections trong project)
- **🔔 Shared Project Notifications** (Thông báo chia sẻ project)
- **🎯 Member Filtering System** (Lọc task theo member)

---

## 🔐 **AUTHENTICATION SYSTEM WORKFLOW**

### **1. Luồng Đăng Ký (Registration Flow)**

#### **Frontend Layer**:
```
AuthScreen → Input Validation → UI Feedback → Submit Form
     ↓              ↓              ↓           ↓
[FormState]    [Validation]   [ErrorState]  [LoadingState]
     ↓              ↓              ↓           ↓
StateProvider → Provider → StateNotifier → FutureProvider
```

#### **Riverpod Pattern Implementation**:

**LEVEL 1 - StateProvider (Simple State)**:
```dart
final authFormStateProvider = StateProvider<AuthFormState>((ref) => AuthFormState());
// Manages: isLogin, username, password, email, displayName
```

**LEVEL 2 - StateNotifierProvider (Complex Logic)**:
```dart
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.read(authServiceProvider);
  return AuthNotifier(authService);
});
// Manages: currentUser, isLoading, errorMessage, isAuthenticated
```

**LEVEL 3 - FutureProvider (Async Operations)**:
```dart
final authInitializationProvider = FutureProvider<void>((ref) async {
  final authNotifier = ref.read(authProvider.notifier);
  await authNotifier.initialize();
});
// Handles: Session restoration, user data loading
```

#### **Detailed Registration Workflow**:

```
1. User opens app
   ↓
2. AuthWrapper checks session
   ↓ (no session)
3. Navigate to AuthScreen
   ↓
4. User clicks "Register" tab
   ↓
5. Form shows registration fields
   ↓
6. User fills: username, password, email, displayName
   ↓
7. Real-time validation (ref.watch(authFormStateProvider))
   ↓
8. User submits form
   ↓
9. AuthNotifier.register() called
   ↓
10. AuthService validates input
    ↓
11. Check username uniqueness
    ↓
12. Hash password with SHA-256
    ↓
13. Create User model
    ↓
14. Save to Hive box('users')
    ↓
15. Auto-login new user
    ↓
16. Initialize user-specific data boxes
    ↓
17. Navigate to main app
```

### **2. Luồng Đăng Nhập (Login Flow)**

#### **Login Workflow**:

```
1. User enters credentials
   ↓
2. AuthFormState updates (ref.read(authFormStateProvider.notifier).state)
   ↓
3. Form validation runs
   ↓
4. User submits
   ↓
5. AuthNotifier.login() called
   ↓
6. AuthService.login() validates
   ↓
7. Find user by username
   ↓
8. Verify password hash
   ↓
9. Update AuthState with currentUser
   ↓
10. Initialize UserDataManager
    ↓
11. Open user-specific Hive boxes
    ↓
12. Navigate to main app
```

#### **Session Management**:

```
App Startup:
1. AuthInitializationProvider starts
   ↓
2. Check for existing session
   ↓
3. If found: restore user session
   ↓
4. Open user-specific data boxes
   ↓
5. Navigate to main app

App Shutdown:
1. Save current session
   ↓
2. Close user data boxes
   ↓
3. Preserve authentication state
```

---

## 📁 **PROJECT SECTION MANAGEMENT WORKFLOW**

### **1. Project Section Architecture**

#### **Riverpod Provider Hierarchy**:

```
ProjectSectionWidget (UI)
        ↓
    ref.watch()
        ↓
┌─────────────────────────────────────────┐
│           PROVIDER LAYER                │
├─────────────────────────────────────────┤
│ projectsProvider (all user projects)    │
│ sectionsByProjectProvider.family        │
│ filteredTodoListProvider                │
│ selectedMemberFilterProvider            │
└─────────────────────────────────────────┘
        ↓
┌─────────────────────────────────────────┐
│         DATA LAYER                      │
├─────────────────────────────────────────┤
│ projectBox (Hive)                       │
│ sectionBox (Hive)                       │
│ todoBox (Hive)                          │
└─────────────────────────────────────────┘
```

### **2. Section Management Workflow**

#### **Add Section Flow**:

```
1. User clicks "Add New Section"
   ↓
2. Dialog opens with text input
   ↓
3. User enters section name
   ↓
4. Submit → _addSection(name) called
   ↓
5. SectionListNotifier.addSection() via ref.read()
   ↓
6. Create new Section model with:
   - id: UUID
   - name: user input
   - projectId: current project
   - ownerId: current user
   ↓
7. Save to sectionBox.add()
   ↓
8. Update local state: _filterByOwnerAndProject()
   ↓
9. Invalidate related providers:
   - ref.invalidate(sectionsByProjectProvider(projectId))
   - ref.invalidate(allSectionsProvider)
   ↓
10. UI automatically rebuilds with new section
```

#### **Delete Section Flow**:

```
1. User clicks section menu → Delete
   ↓
2. Confirmation dialog appears
   ↓
3. User confirms deletion
   ↓
4. SectionListNotifier.deleteSection(sectionId)
   ↓
5. Find and remove section from box
   ↓
6. Find and delete all todos in section
   ↓
7. Update UI state
   ↓
8. Invalidate providers
   ↓
9. Close expanded sections if needed
   ↓
10. UI rebuilds without deleted section
```

### **3. Task Management Within Sections**

#### **Add Task to Section Flow**:

```
1. User clicks "Add task to [Section Name]"
   ↓
2. AddTaskWidget appears with preset:
   - projectId: current project
   - sectionId: target section
   ↓
3. User fills task details
   ↓
4. Submit → TodoListNotifier.add() called
   ↓
5. Create Todo with section assignment
   ↓
6. Save to todoBox
   ↓
7. Update todoListProvider state
   ↓
8. UI shows new task in section
```

---

## 🔔 **SHARED PROJECT NOTIFICATIONS WORKFLOW**

### **1. Notification System Architecture**

#### **Provider Structure**:

```
NotificationDialog (UI)
        ↓
InvitationNotifier (StateNotifierProvider)
        ↓
┌─────────────────────────────────────────┐
│        INVITATION PROVIDERS             │
├─────────────────────────────────────────┤
│ invitationNotifierProvider              │
│ pendingInvitationCountProvider          │
│ allUserInvitationsProvider              │
└─────────────────────────────────────────┘
        ↓
┌─────────────────────────────────────────┐
│         DATA MODELS                     │
├─────────────────────────────────────────┤
│ ProjectInvitation (Hive)                │
│ ProjectMember (Hive)                    │
│ Project (updated with sharedUserIds)    │
└─────────────────────────────────────────┘
```

### **2. Send Invitation Workflow**

#### **Complete Invitation Flow**:

```
1. Project Owner clicks SharedProjectIndicator
   ↓
2. ProjectMembersDialog opens
   ↓
3. Owner clicks "Invite New Members" section
   ↓
4. InviteUserWidget appears
   ↓
5. Owner types username/display name
   ↓
6. System searches users via userDisplayNameProvider
   ↓
7. Owner selects user from dropdown
   ↓
8. Owner clicks "Send Invitation"
   ↓
9. InviteUserWidget.sendInvitation() called
   ↓
10. SharedProjectNotifier.inviteUser() via ref.read()
    ↓
11. Validate: user exists, not already member
    ↓
12. Create ProjectInvitation record:
    - id: UUID
    - projectId: current project
    - projectName: cached name
    - fromUserId: current user
    - toUserId: target user
    - status: InvitationStatus.pending
    - sentAt: DateTime.now()
    ↓
13. Save to invitationBox.add()
    ↓
14. InvitationNotifier.state updates
    ↓
15. Target user's notification badge updates
    ↓
16. Success message shown to sender
```

### **3. Receive & Process Invitation Workflow**

#### **Notification Display Flow**:

```
1. Target user opens app
   ↓
2. NotificationBadge shows count via pendingInvitationCountProvider
   ↓
3. User clicks notification icon
   ↓
4. NotificationDialog opens with animation
   ↓
5. InvitationItem components render via allUserInvitationsProvider
   ↓
6. Each invitation shows:
   - Project name
   - Sender avatar & name
   - Time sent (formatted)
   - Accept/Decline buttons
```

#### **Accept Invitation Flow**:

```
1. User clicks "Accept" on InvitationItem
   ↓
2. InvitationNotifier.acceptInvitation(invitationId)
   ↓
3. Find invitation in box
   ↓
4. Validate invitation is still pending
   ↓
5. Update invitation.status = accepted
   ↓
6. Create ProjectMember record:
   - id: UUID
   - projectId: invitation.projectId
   - userId: current user
   - userDisplayName: current user display name
   - joinedAt: DateTime.now()
   ↓
7. Save to projectMemberBox.add()
   ↓
8. Update Project.sharedUserIds list
   ↓
9. Invalidate related providers:
   - projectListProvider
   - accessibleProjectsProvider
   - sharedProjectProvider(projectId)
   - projectMembersProvider(projectId)
   ↓
10. UI updates: project appears in user's project list
    ↓
11. Success message shown
    ↓
12. Dialog auto-closes or updates
```

#### **Decline Invitation Flow**:

```
1. User clicks "Decline" on InvitationItem
   ↓
2. InvitationNotifier.declineInvitation(invitationId)
   ↓
3. Update invitation.status = declined
   ↓
4. Save to invitationBox
   ↓
5. Remove from pending list
   ↓
6. UI updates to remove invitation
   ↓
7. Notification count decreases
```

---

## 🎯 **MEMBER FILTERING SYSTEM WORKFLOW**

### **1. Filter Architecture**

#### **Provider Chain**:

```
ProjectMembersDialog (UI) ←→ ProjectSectionWidget (UI)
        ↓                           ↓
selectedMemberFilterProvider (shared state)
        ↓
filteredTodoListProvider
        ↓
todoListProvider (base data)
```

### **2. Member Selection Workflow**

#### **Filter Selection Flow**:

```
1. User opens ProjectMembersDialog
   ↓
2. Dialog shows members via assignableUsersInProjectProvider
   ↓
3. Each member shows task count via userTaskCountInProjectProvider
   ↓
4. User clicks on a member
   ↓
5. Member selection logic:
   - If already selected: clear filter (set null)
   - If not selected: set filter to user.id
   ↓
6. ref.read(selectedMemberFilterProvider.notifier).state = userId
   ↓
7. Visual feedback: member background turns blue
   ↓
8. filteredTodoListProvider automatically updates
   ↓
9. ProjectSectionWidget rebuilds with filtered todos
   ↓
10. Only selected member's tasks visible in project view
```

#### **Unassigned Tasks Filter**:

```
1. User clicks "Unassigned Tasks" in Tasks section
   ↓
2. selectedMemberFilterProvider.state = 'unassigned'
   ↓
3. filteredTodoListProvider filters for todos with null assignedToId
   ↓
4. Project view shows only unassigned tasks
   ↓
5. Orange badge indicates unassigned filter active
```

#### **Clear Filter Workflow**:

```
1. User clicks selected member again OR clicks elsewhere
   ↓
2. selectedMemberFilterProvider.state = null
   ↓
3. filteredTodoListProvider returns all todos
   ↓
4. Visual feedback: all member backgrounds return to transparent
   ↓
5. Project view shows all tasks again
```

### **3. Cross-Component Reactivity**

#### **Provider Integration Pattern**:

```
Component A: ProjectMembersDialog
   ↓ (user interaction)
Provider: selectedMemberFilterProvider
   ↓ (state change)
Provider: filteredTodoListProvider
   ↓ (automatic recalculation)
Component B: ProjectSectionWidget
   ↓ (automatic rebuild)
UI: Updated task display
```

#### **Real-time Updates**:

```
State Change Event → Provider Invalidation → UI Rebuild
        ↓                     ↓                 ↓
User clicks member → selectedMemberFilter → ProjectSectionWidget
Assignment change → userTaskCountProvider → Member task counts
Task completion → filteredTodoListProvider → Task visibility
```

---

## 🎨 **UI COMPONENT INTERACTION PATTERNS**

### **1. Dialog Integration**

#### **ProjectMembersDialog Structure**:

```
┌─────────────────────────────────────────┐
│              HEADER                     │
│  Project name + Close button            │
├─────────────────────────────────────────┤
│         INVITE SECTION                  │
│  🆕 Moved to top for better UX         │
│  Search & invite new members            │
├─────────────────────────────────────────┤
│         MEMBERS SECTION                 │
│  List of current members                │
│  - Avatar with initials                 │
│  - Display name & username              │
│  - Task count badge                     │
│  - Click to filter (blue highlight)    │
├─────────────────────────────────────────┤
│         TASKS SECTION                   │
│  🆕 Separate section for clarity       │
│  - Unassigned tasks (orange badge)     │
│  - Click to filter unassigned only     │
└─────────────────────────────────────────┘
```

### **2. Notification Integration**

#### **NotificationDialog Animation**:

```
Trigger: User clicks notification badge
   ↓
Animation: FadeTransition + SlideTransition
   ↓ (300ms duration)
Content: InvitationItem list
   ↓
User Action: Accept/Decline
   ↓
State Update: InvitationNotifier
   ↓
UI Feedback: Success/Error message
   ↓
Auto-close: Dialog dismisses
```

---

## 🔧 **TECHNICAL IMPLEMENTATION PATTERNS**

### **1. Riverpod Provider Patterns Used**

#### **LEVEL 1 - StateProvider (Simple State)**:
```dart
// Authentication form state
final authFormStateProvider = StateProvider<AuthFormState>((ref) => AuthFormState());

// Member filter selection
final selectedMemberFilterProvider = StateProvider<String?>((ref) => null);

// UI visibility states
final notificationPanelOpenProvider = StateProvider<bool>((ref) => false);
```

#### **LEVEL 2 - StateNotifierProvider (Complex Logic)**:
```dart
// Authentication management
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier(...));

// Invitation system
final invitationNotifierProvider = StateNotifierProvider<InvitationNotifier, List<ProjectInvitation>>((ref) => InvitationNotifier(...));

// Shared project management
final sharedProjectProvider = StateNotifierProvider.family<SharedProjectNotifier, List<ProjectMember>, String>((ref, projectId) => SharedProjectNotifier(...));
```

#### **LEVEL 3 - FutureProvider (Async Operations)**:
```dart
// Authentication initialization
final authInitializationProvider = FutureProvider<void>((ref) async => await authNotifier.initialize());

// User data loading
final userDataInitializationProvider = FutureProvider<void>((ref) async => await userDataManager.initialize());
```

#### **LEVEL 4 - Provider.family (Parameterized Data)**:
```dart
// Project members by project ID
final projectMembersProvider = Provider.family<List<ProjectMember>, String>((ref, projectId) => ...);

// User task count in specific project
final userTaskCountInProjectProvider = Provider.family<int, Map<String, String>>((ref, params) => ...);

// Assignable users in project
final assignableUsersInProjectProvider = Provider.family<List<User>, String>((ref, projectId) => ...);
```

### **2. State Invalidation Patterns**

#### **Cross-Provider Invalidation**:
```dart
// After accepting invitation
_ref.invalidate(projectListProvider);
_ref.invalidate(accessibleProjectsProvider);
_ref.invalidate(sharedProjectProvider(projectId));
_ref.invalidate(projectMembersProvider(projectId));

// After adding section
_ref.invalidate(sectionsByProjectProvider(projectId));
_ref.invalidate(allSectionsProvider);

// After member filtering
// Automatic via ref.watch() - no manual invalidation needed
```

### **3. Error Handling Patterns**

#### **Graceful Degradation**:
```dart
// Safe provider access
try {
  final data = ref.watch(dataProvider);
  return DataWidget(data);
} catch (e) {
  return ErrorWidget('Data unavailable');
}

// Fallback values
final userName = user?.displayName ?? 'Unknown User';
final taskCount = tasks?.length ?? 0;
```

---

## 📊 **PERFORMANCE OPTIMIZATION PATTERNS**

### **1. Provider Scoping**

#### **Family Providers for Efficiency**:
```dart
// Instead of loading all project data
final projectMembersProvider = Provider.family<List<ProjectMember>, String>((ref, projectId) {
  // Only load members for specific project
  return members.where((m) => m.projectId == projectId).toList();
});
```

### **2. Selective Rebuilds**

#### **Component-specific Providers**:
```dart
// Task count updates only affect count displays
final userTaskCountProvider = Provider.family<int, String>((ref, userId) => ...);

// Member selection only affects filtering
final selectedMemberFilterProvider = StateProvider<String?>((ref) => null);

// UI components watch only what they need
```

### **3. Lazy Loading**

#### **On-demand Data Loading**:
```dart
// User data loaded only when authenticated
final userSpecificDataProvider = Provider<UserData?>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return null;
  return loadUserData(currentUser.id);
});
```

---

## 🎯 **SUMMARY OF SYSTEM CAPABILITIES**

### **Authentication System**:
- ✅ **Multi-user registration/login** with secure password hashing
- ✅ **Session persistence** across app restarts
- ✅ **User data separation** with isolated Hive boxes
- ✅ **Real-time form validation** with Riverpod state management

### **Project Section Management**:
- ✅ **Dynamic section creation/deletion** with immediate UI updates
- ✅ **Task organization** within sections
- ✅ **User-scoped data** (only see your own sections)
- ✅ **Reactive UI updates** via provider invalidation

### **Shared Project Notifications**:
- ✅ **Real-time invitation system** with notification badges
- ✅ **Beautiful notification dialog** with smooth animations
- ✅ **Project member management** with role-based access
- ✅ **Cross-user collaboration** capabilities

### **Member Filtering System**:
- ✅ **Interactive member selection** with visual feedback
- ✅ **Real-time task filtering** across project views
- ✅ **Unassigned task management** with separate filtering
- ✅ **Cross-component reactivity** via shared providers

**🚀 The system demonstrates advanced Riverpod patterns with professional-grade architecture and user experience!**
