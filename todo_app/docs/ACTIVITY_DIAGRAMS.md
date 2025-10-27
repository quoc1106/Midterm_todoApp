# 📊 ACTIVITY DIAGRAMS - Sơ Đồ Hoạt Động Hệ Thống

## 📋 **TỔNG QUAN**

Tài liệu này chứa các sơ đồ Activity Diagram mô tả luồng hoạt động của:
- **🔐 Authentication Flow** (Đăng nhập/Đăng ký)
- **🔔 Notification System** (Hệ thống thông báo)
- **📁 Project Management** (Quản lý dự án)
- **🎯 Member Filtering** (Lọc theo thành viên)

---

## 🔐 **AUTHENTICATION SYSTEM ACTIVITY DIAGRAM**

### **1. Registration Flow (Luồng Đăng Ký)**

```
[START] User Opens App
    ↓
[Decision] Has Active Session?
    ↓ NO
[Activity] Show AuthScreen
    ↓
[Activity] User Selects "Register" Tab
    ↓
[Activity] User Fills Registration Form
    - Username
    - Password  
    - Email
    - Display Name
    ↓
[Activity] Real-time Validation
    ↓
[Decision] Form Valid?
    ↓ NO → [Activity] Show Error Messages → [Loop Back]
    ↓ YES
[Activity] Submit Registration
    ↓
[Activity] AuthService.register()
    ↓
[Decision] Username Available?
    ↓ NO → [Activity] Show "Username taken" → [Loop Back]
    ↓ YES
[Activity] Hash Password (SHA-256)
    ↓
[Activity] Create User Model
    ↓
[Activity] Save to Hive Box('users')
    ↓
[Activity] Auto-login New User
    ↓
[Activity] Initialize User Data Boxes
    ↓
[Activity] Navigate to Main App
    ↓
[END] User Successfully Registered & Logged In
```

### **2. Login Flow (Luồng Đăng Nhập)**

```
[START] User at AuthScreen
    ↓
[Activity] User Selects "Login" Tab
    ↓
[Activity] User Enters Credentials
    - Username
    - Password
    ↓
[Activity] Form Validation
    ↓
[Decision] Credentials Valid Format?
    ↓ NO → [Activity] Show Validation Errors → [Loop Back]
    ↓ YES
[Activity] Submit Login
    ↓
[Activity] AuthService.login()
    ↓
[Activity] Find User by Username
    ↓
[Decision] User Exists?
    ↓ NO → [Activity] Show "User not found" → [Loop Back]
    ↓ YES
[Activity] Verify Password Hash
    ↓
[Decision] Password Correct?
    ↓ NO → [Activity] Show "Invalid password" → [Loop Back]
    ↓ YES
[Activity] Create User Session
    ↓
[Activity] Update AuthState
    ↓
[Activity] Initialize UserDataManager
    ↓
[Activity] Open User-specific Hive Boxes
    ↓
[Activity] Navigate to Main App
    ↓
[END] User Successfully Logged In
```

### **3. Session Management Flow**

```
[START] App Startup
    ↓
[Activity] AuthInitializationProvider Starts
    ↓
[Activity] Check for Existing Session
    ↓
[Decision] Session Found?
    ↓ NO → [Activity] Navigate to AuthScreen → [END]
    ↓ YES
[Activity] Restore User Session
    ↓
[Activity] Validate Session Data
    ↓
[Decision] Session Valid?
    ↓ NO → [Activity] Clear Invalid Session → [Navigate to AuthScreen]
    ↓ YES
[Activity] Initialize User Data
    ↓
[Activity] Open User-specific Boxes
    ↓
[Activity] Navigate to Main App
    ↓
[END] User Auto-logged In

// Logout Flow
[START] User Clicks Logout
    ↓
[Activity] AuthNotifier.logout()
    ↓
[Activity] Clear User Session
    ↓
[Activity] Close User Data Boxes
    ↓
[Activity] Clear AuthState
    ↓
[Activity] Navigate to AuthScreen
    ↓
[END] User Logged Out
```

---

## 🔔 **NOTIFICATION SYSTEM ACTIVITY DIAGRAM**

### **1. Send Invitation Flow**

```
[START] Project Owner wants to invite member
    ↓
[Activity] Click SharedProjectIndicator
    ↓
[Activity] ProjectMembersDialog Opens
    ↓
[Activity] Click "Invite New Members"
    ↓
[Activity] InviteUserWidget Appears
    ↓
[Activity] Type Username/Display Name
    ↓
[Activity] System Searches Users
    ↓
[Decision] User Found?
    ↓ NO → [Activity] Show "User not found" → [Loop Back]
    ↓ YES
[Activity] Select User from Dropdown
    ↓
[Activity] Click "Send Invitation"
    ↓
[Activity] Validate Invitation
    ↓
[Decision] User Already Member?
    ↓ YES → [Activity] Show "Already member" → [Loop Back]
    ↓ NO
[Activity] Create ProjectInvitation
    - Generate UUID
    - Set projectId, projectName
    - Set fromUserId, toUserId
    - Set status: pending
    - Set sentAt: current time
    ↓
[Activity] Save to invitationBox
    ↓
[Activity] Update InvitationNotifier State
    ↓
[Activity] Target User's Notification Badge Updates
    ↓
[Activity] Show Success Message
    ↓
[END] Invitation Sent Successfully
```

### **2. Receive & Process Invitation Flow**

```
[START] Target User Opens App
    ↓
[Activity] Load Pending Invitations
    ↓
[Activity] Update Notification Badge Count
    ↓
[Decision] Has Pending Invitations?
    ↓ NO → [Activity] Badge Shows 0 → [END]
    ↓ YES
[Activity] Badge Shows Count
    ↓
[Activity] User Clicks Notification Icon
    ↓
[Activity] NotificationDialog Opens with Animation
    ↓
[Activity] Display InvitationItem List
    ↓
[Decision] User Action?
    ↓ CLOSE → [Activity] Close Dialog → [END]
    ↓ ACCEPT
[Activity] InvitationNotifier.acceptInvitation()
    ↓
[Activity] Validate Invitation Still Pending
    ↓
[Decision] Invitation Valid?
    ↓ NO → [Activity] Show Error → [Loop Back to Dialog]
    ↓ YES
[Activity] Update invitation.status = accepted
    ↓
[Activity] Create ProjectMember Record
    ↓
[Activity] Add to Project.sharedUserIds
    ↓
[Activity] Invalidate Related Providers
    - projectListProvider
    - accessibleProjectsProvider
    - sharedProjectProvider(projectId)
    ↓
[Activity] Show Success Message
    ↓
[Activity] Project Appears in User's List
    ↓
[END] Invitation Accepted Successfully

    ↓ DECLINE
[Activity] InvitationNotifier.declineInvitation()
    ↓
[Activity] Update invitation.status = declined
    ↓
[Activity] Remove from Pending List
    ↓
[Activity] Update Notification Count
    ↓
[Activity] Show Decline Message
    ↓
[END] Invitation Declined
```

### **3. Notification Badge Update Flow**

```
[START] System Event Occurs
    ↓
[Decision] Event Type?
    ↓ NEW_INVITATION
[Activity] Increment Pending Count
    ↓
[Activity] Update pendingInvitationCountProvider
    ↓
[Activity] NotificationBadge Rebuilds
    ↓
[Activity] Show New Count with Animation
    ↓
[END] Badge Updated

    ↓ INVITATION_PROCESSED
[Activity] Decrement Pending Count
    ↓
[Activity] Update Provider
    ↓
[Activity] Badge Rebuilds
    ↓
[Decision] Count = 0?
    ↓ YES → [Activity] Hide Badge
    ↓ NO → [Activity] Show Updated Count
    ↓
[END] Badge Updated
```

---

## 📁 **PROJECT MANAGEMENT ACTIVITY DIAGRAM**

### **1. Section Management Flow**

```
[START] User in Project View
    ↓
[Activity] ProjectSectionWidget Loads
    ↓
[Activity] Load Sections via sectionsByProjectProvider
    ↓
[Decision] User Action?
    ↓ ADD_SECTION
[Activity] Click "Add New Section"
    ↓
[Activity] Show Section Name Dialog
    ↓
[Activity] User Enters Section Name
    ↓
[Decision] Name Valid?
    ↓ NO → [Activity] Show Validation Error → [Loop Back]
    ↓ YES
[Activity] SectionListNotifier.addSection()
    ↓
[Activity] Create Section Model
    - Generate UUID
    - Set name, projectId, ownerId
    ↓
[Activity] Save to sectionBox
    ↓
[Activity] Update Local State
    ↓
[Activity] Invalidate Related Providers
    ↓
[Activity] UI Rebuilds with New Section
    ↓
[END] Section Added Successfully

    ↓ DELETE_SECTION
[Activity] Click Section Menu → Delete
    ↓
[Activity] Show Confirmation Dialog
    ↓
[Decision] User Confirms?
    ↓ NO → [Activity] Cancel → [END]
    ↓ YES
[Activity] SectionListNotifier.deleteSection()
    ↓
[Activity] Remove Section from Box
    ↓
[Activity] Delete All Tasks in Section
    ↓
[Activity] Update UI State
    ↓
[Activity] Invalidate Providers
    ↓
[Activity] UI Rebuilds without Section
    ↓
[END] Section Deleted Successfully
```

### **2. Task Assignment Flow**

```
[START] User Creating/Editing Task
    ↓
[Decision] In Shared Project?
    ↓ NO → [Activity] Normal Task Creation → [END]
    ↓ YES
[Activity] Show Assignment Section
    ↓
[Activity] Load assignableUsersInProjectProvider
    ↓
[Activity] Display Assignment Dropdown
    ↓
[Decision] User Selects Assignee?
    ↓ NO → [Activity] Create Unassigned Task
    ↓ YES
[Activity] Select User from Dropdown
    ↓
[Activity] Update Task with Assignment
    - Set assignedToId
    - Set assignedToDisplayName
    ↓
[Activity] Save Task
    ↓
[Activity] Update Task Counts
    ↓
[Activity] UI Shows Assigned User Chip
    ↓
[END] Task Assigned Successfully
```

---

## 🎯 **MEMBER FILTERING ACTIVITY DIAGRAM**

### **1. Member Filter Selection Flow**

```
[START] User Opens ProjectMembersDialog
    ↓
[Activity] Load Project Members
    ↓
[Activity] Calculate Task Counts per Member
    ↓
[Activity] Display Members with Counts
    ↓
[Activity] Show Unassigned Tasks Count
    ↓
[Decision] User Clicks Member?
    ↓ MEMBER_CLICK
[Decision] Member Already Selected?
    ↓ YES → [Activity] Clear Filter (set null)
        ↓
        [Activity] Remove Blue Background
        ↓
        [Activity] Show All Tasks in Project
        ↓
        [END] Filter Cleared
    ↓ NO
[Activity] Set selectedMemberFilterProvider = userId
    ↓
[Activity] Add Blue Background to Member
    ↓
[Activity] filteredTodoListProvider Updates
    ↓
[Activity] ProjectSectionWidget Rebuilds
    ↓
[Activity] Show Only Selected Member's Tasks
    ↓
[END] Member Filter Applied

    ↓ UNASSIGNED_CLICK
[Decision] Unassigned Already Selected?
    ↓ YES → [Activity] Clear Filter → [Show All Tasks]
    ↓ NO
[Activity] Set selectedMemberFilterProvider = 'unassigned'
    ↓
[Activity] Filter Tasks with null assignedToId
    ↓
[Activity] Show Only Unassigned Tasks
    ↓
[Activity] Orange Badge Highlights
    ↓
[END] Unassigned Filter Applied
```

### **2. Cross-Component Filter Sync Flow**

```
[START] Filter State Changes in Dialog
    ↓
[Activity] selectedMemberFilterProvider Updates
    ↓
[Activity] filteredTodoListProvider Recalculates
    ↓
[Decision] Filter Value?
    ↓ NULL → [Activity] Return All Todos
    ↓ 'unassigned' → [Activity] Filter null assignedToId
    ↓ userId → [Activity] Filter by assignedToId = userId
    ↓
[Activity] ProjectSectionWidget Watches Provider
    ↓
[Activity] Component Rebuilds with Filtered Data
    ↓
[Activity] Update Section Task Counts
    ↓
[Activity] Update Today Tab Counts
    ↓
[Activity] Visual Feedback in Both Components
    ↓
[END] Filter Synchronized Across UI
```

### **3. Task Count Update Flow**

```
[START] Task Assignment Changes
    ↓ (any of these events)
[Activity] Task Created with Assignment
[Activity] Task Assignment Modified
[Activity] Task Completed/Uncompleted
[Activity] Task Deleted
    ↓
[Activity] todoListProvider State Updates
    ↓
[Activity] userTaskCountInProjectProvider Recalculates
    ↓
[Activity] unassignedTaskCountProvider Updates
    ↓
[Activity] ProjectMembersDialog Task Badges Update
    ↓
[Activity] Filter Results Update (if filter active)
    ↓
[Activity] All UI Components Reflect New Counts
    ↓
[END] Counts Synchronized System-wide
```

---

## 🔄 **PROVIDER INTERACTION ACTIVITY DIAGRAM**

### **1. Provider Invalidation Chain**

```
[START] User Action Triggers State Change
    ↓
[Activity] StateNotifier Method Called
    ↓
[Activity] Update Local State
    ↓
[Activity] Modify Hive Box Data
    ↓
[Activity] Call ref.invalidate() for Related Providers
    ↓
[Decision] Provider Type?
    ↓ SIMPLE_PROVIDER
[Activity] Provider Recalculates Immediately
    ↓ FAMILY_PROVIDER
[Activity] Specific Parameter Instance Invalidated
    ↓ DEPENDENT_PROVIDERS
[Activity] Chain Invalidation to Watching Providers
    ↓
[Activity] UI Components Rebuild
    ↓
[Activity] New Data Rendered
    ↓
[END] State Synchronized Across App
```

### **2. Error Handling Flow**

```
[START] Provider Operation Attempted
    ↓
[Activity] Try Provider Access/Modification
    ↓
[Decision] Operation Successful?
    ↓ YES → [Activity] Continue Normal Flow → [END]
    ↓ NO
[Activity] Catch Exception
    ↓
[Decision] Error Type?
    ↓ NETWORK_ERROR
[Activity] Show Retry Option
    ↓ DATA_ERROR  
[Activity] Show Default/Cached Data
    ↓ PERMISSION_ERROR
[Activity] Redirect to Auth
    ↓ UNKNOWN_ERROR
[Activity] Log Error + Show Generic Message
    ↓
[Activity] Attempt Graceful Recovery
    ↓
[Decision] Recovery Successful?
    ↓ YES → [Activity] Continue with Fallback → [END]
    ↓ NO → [Activity] Show Error State → [END]
```

---

## 📊 **SYSTEM INTEGRATION ACTIVITY DIAGRAM**

### **1. Complete User Journey**

```
[START] New User
    ↓
[Activity] Registration Flow
    ↓
[Activity] Auto-login
    ↓
[Activity] Initialize User Data
    ↓
[Activity] Navigate to Main App
    ↓
[Activity] Create First Project
    ↓
[Activity] Add Sections to Project
    ↓
[Activity] Create Tasks in Sections
    ↓
[Activity] Invite Other Users
    ↓
[Activity] Manage Shared Project
    ↓
[Activity] Use Member Filtering
    ↓
[Activity] Process Notifications
    ↓
[END] Full System Usage

// Returning User
[START] App Launch
    ↓
[Activity] Session Check
    ↓
[Activity] Auto-login
    ↓
[Activity] Load User Data
    ↓
[Activity] Check Notifications
    ↓
[Activity] Continue Project Work
    ↓
[END] Seamless Experience
```

---

## 🎯 **DIAGRAM SUMMARY**

### **Key Activity Patterns**:

1. **🔐 Authentication**: Registration → Validation → Session → Data Init
2. **🔔 Notifications**: Invite → Send → Receive → Process → Update UI
3. **📁 Projects**: Create → Manage → Share → Collaborate → Filter
4. **🎯 Filtering**: Select → Filter → Update → Sync → Display

### **Riverpod Integration Points**:

- **StateProvider**: Simple UI state (form data, selections)
- **StateNotifierProvider**: Complex business logic (auth, invitations)
- **FutureProvider**: Async operations (initialization, data loading)
- **Provider.family**: Parameterized data (project-specific, user-specific)

### **Error Handling Strategies**:

- **Graceful Degradation**: Show fallback data when errors occur
- **User Feedback**: Clear error messages with recovery options
- **State Recovery**: Automatic retry and state restoration
- **Defensive Programming**: Null checks and type safety

**🚀 These diagrams provide a complete blueprint for understanding system behavior and implementing similar patterns!**
