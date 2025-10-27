# 👥 USER INTERACTION SCENARIO - Kịch Bản Tương Tác 2 Người Dùng

## 📋 **TỔNG QUAN KỊCH BẢN**

Tài liệu này mô tả kịch bản tương tác chi tiết giữa 2 người dùng trong Todo App với đầy đủ các tính năng:
- **🔐 Authentication & User Management**
- **🤝 Shared Project Collaboration**
- **📝 Task Assignment & Management**
- **🔔 Real-time Notifications**
- **📅 Today/Upcoming Task Views**
- **⏰ Overdue Task Management**

---

## 👤 **NHÂN VẬT CHÍNH**

### **User A - Alice (Project Manager)**
- **Role**: Team Lead, Project Owner
- **Responsibilities**: Tạo projects, mời thành viên, assign tasks
- **Goals**: Quản lý team hiệu quả, theo dõi tiến độ

### **User B - Bob (Developer)**
- **Role**: Team Member, Task Executor
- **Responsibilities**: Thực hiện tasks được assign, cập nhật tiến độ
- **Goals**: Hoàn thành công việc đúng hạn, collaboration tốt

---

## 🎬 **KỊCH BẢN CHI TIẾT**

### **📖 Act 1: Authentication & Initial Setup**

#### **Scene 1.1: Alice Registration & Project Creation**
```
⏰ Time: Monday, 8:00 AM
📍 Location: Alice's Computer

[Alice mở Todo App lần đầu]

1. AuthScreen xuất hiện
2. Alice chọn "Register" tab
3. Điền thông tin:
   - Username: "alice_pm"
   - Display Name: "Alice Manager"
   - Email: "alice@company.com"
   - Password: "SecurePass123"

4. System validates và tạo tài khoản
   - AuthService.register() executed
   - Password hashed với SHA-256
   - User saved to Hive box('users')
   - Auto-login successful

5. Alice navigates to main app
   - AuthWrapper detects authentication
   - User-specific data boxes opened
   - TodoScreen loads with empty state

6. Alice tạo Project đầu tiên:
   - Click "My Projects" → "Add Project"
   - Tên project: "Website Redesign"
   - Project created với Alice là owner
   - ProjectModel saved với ownerId = alice.id

💭 Alice's thoughts: "Perfect! Tôi đã setup được workspace. Bây giờ cần tạo team."
```

#### **Scene 1.2: Bob Registration**
```
⏰ Time: Monday, 8:30 AM
📍 Location: Bob's Computer

[Bob được Alice thông báo về Todo App]

1. Bob mở app và register:
   - Username: "bob_dev"
   - Display Name: "Bob Developer"
   - Email: "bob@company.com"
   - Password: "DevPassword456"

2. System tạo tài khoản Bob
   - Separate user data boxes created
   - Complete data isolation from Alice
   - Bob has empty workspace initially

💭 Bob's thoughts: "App này trông clean và professional. Chờ Alice invite vào project."
```

### **📖 Act 2: Project Collaboration Setup**

#### **Scene 2.1: Alice Invites Bob to Project**
```
⏰ Time: Monday, 9:00 AM
📍 Location: Alice's Workspace

[Alice wants to add Bob to "Website Redesign" project]

1. Alice clicks on "Website Redesign" project
2. ProjectSectionWidget loads với shared project indicator
3. Alice clicks group icon (SharedProjectIndicator)
4. ProjectMembersDialog opens với:
   - Header: "Project Members - Website Redesign"
   - Current members: Alice (owner)
   - Invite section at top

5. Alice sử dụng InviteUserWidget:
   - Types "Bob Developer" trong search field
   - userDisplayNameProvider finds Bob
   - Dropdown shows Bob's profile
   - Alice selects Bob và clicks "Send Invitation"

6. System processes invitation:
   - SharedProjectNotifier.inviteUser() called
   - ProjectInvitation created với:
     * fromUserId: alice.id
     * toUserId: bob.id
     * projectId: websiteRedesign.id
     * status: pending
   - Invitation saved to invitationBox
   - InvitationNotifier updates state

7. Success message: "Đã gửi lời mời thành công!"

💭 Alice's thoughts: "Lời mời đã gửi. Bob sẽ thấy notification khi mở app."
```

#### **Scene 2.2: Bob Receives & Accepts Invitation**
```
⏰ Time: Monday, 9:15 AM
📍 Location: Bob's Computer

[Bob mở app và thấy notification]

1. App khởi động với AuthInitializationProvider
2. Bob's session restored automatically
3. NotificationBadge shows "1" (pending invitation)
4. Bob clicks notification icon trong app drawer

5. NotificationDialog opens với animation:
   - FadeTransition + SlideTransition (300ms)
   - InvitationItem displays:
     * Project: "Website Redesign"
     * From: "Alice Manager"
     * Time: "Vừa xong"
     * Actions: Accept/Decline buttons

6. Bob clicks "Accept":
   - InvitationNotifier.acceptInvitation() called
   - Invitation status updated to "accepted"
   - ProjectMember record created:
     * userId: bob.id
     * projectId: websiteRedesign.id
     * role: member (full permissions)
   - Project.sharedUserIds updated: [bob.id]
   - Project.isShared = true

7. UI updates immediately:
   - "Website Redesign" appears in Bob's project list
   - Success message: "Đã chấp nhận lời mời!"
   - Notification badge resets to 0

💭 Bob's thoughts: "Great! Tôi đã join được team. Bây giờ có thể collaborate với Alice."
```

### **📖 Act 3: Task Management & Assignment**

#### **Scene 3.1: Alice Creates Sections & Tasks**
```
⏰ Time: Monday, 10:00 AM
📍 Location: Alice's Project View

[Alice organizes project structure]

1. Alice navigates to "Website Redesign" project
2. ProjectSectionWidget loads với:
   - Project header với group icon (indicating shared project)
   - Empty sections list
   - Bob visible as team member (real-time update)

3. Alice tạo sections:
   - Section 1: "UI Design"
     * SectionListNotifier.addSection() called
     * Section saved với projectId + ownerId
   - Section 2: "Frontend Development"
   - Section 3: "Backend Integration"

4. Alice adds tasks với assignments:
   
   **In "UI Design" section:**
   - Task: "Create wireframes for homepage"
     * Alice assigns to herself
     * Due date: Wednesday
     * assignedToId: alice.id
     * assignedToDisplayName: "Alice Manager"
   
   **In "Frontend Development" section:**
   - Task: "Implement responsive navigation"
     * AddTaskWidget shows AssignUserDropdown
     * assignableUsersInProjectProvider loads [Alice, Bob]
     * Alice assigns to Bob
     * Due date: Friday
     * assignedToId: bob.id
     * assignedToDisplayName: "Bob Developer"
   
   - Task: "Create component library"
     * Alice assigns to Bob
     * Due date: Next Monday
     * assignedToId: bob.id

5. All tasks saved to todoBox với proper assignments

💭 Alice's thoughts: "Project structure ready. Bob có 2 tasks cần làm trong tuần này."
```

#### **Scene 3.2: Bob Views Assigned Tasks**
```
⏰ Time: Monday, 10:30 AM
📍 Location: Bob's Dashboard

[Bob checks his assigned work]

1. Bob navigates to "Today" view:
   - todoListProvider filters by assignedToId = bob.id
   - Shows: "Implement responsive navigation" (due Friday)
   - Task displays với AssignedUserChip showing Bob's avatar

2. Bob checks "Upcoming" view:
   - enhancedUpcomingGroupedTodosProvider groups tasks by date
   - Friday section shows 1 task assigned to Bob
   - Next Monday section shows 1 task assigned to Bob
   - Overdue section empty (no overdue tasks yet)

3. Bob visits "Website Redesign" project view:
   - projectTodosProvider shows ALL tasks trong project
   - Bob thấy:
     * Alice's task: "Create wireframes" (assigned to Alice)
     * Bob's tasks: 2 tasks assigned to himself
   - Full project visibility for collaboration

💭 Bob's thoughts: "Clear picture của work. Tôi có 2 tasks this week. Alice đang làm wireframes."
```

### **📖 Act 4: Task Execution & Progress Updates**

#### **Scene 4.1: Bob Completes First Task**
```
⏰ Time: Wednesday, 2:00 PM
📍 Location: Bob's Development Environment

[Bob finishes navigation implementation]

1. Bob opens "Website Redesign" project
2. Finds "Implement responsive navigation" trong "Frontend Development" section
3. Clicks checkbox to mark completed:
   - TodoListNotifier.toggle() called
   - todo.completed = true
   - Todo updated in todoBox
   - Real-time update across all views

4. Task immediately disappears from:
   - Bob's Today view (filtered out completed tasks)
   - Upcoming Friday section
   - Project view shows task as strikethrough

5. Alice sees update real-time trong project view:
   - Task shows completed status
   - Progress visible for project tracking

💭 Bob's thoughts: "One down, one to go. Navigation looks great!"
```

#### **Scene 4.2: Overdue Task Scenario**
```
⏰ Time: Tuesday Next Week, 9:00 AM
📍 Location: Bob's Computer

[Bob missed Monday deadline cho "Create component library"]

1. Bob opens Today view:
   - enhancedUpcomingGroupedTodosProvider detects overdue task
   - Overdue section appears với:
     * Red container với warning icon
     * "Overdue (1)" header
     * Expandable/collapsible functionality
     * Task: "Create component library" (due yesterday)

2. overdueCollapsedProvider manages expand/collapse state:
   - Bob clicks header to expand
   - Task details show với overdue indicator
   - Red color scheme emphasizes urgency

3. Bob checks Upcoming view:
   - Same overdue task appears trong red section
   - upcomingOverdueCollapsedProvider manages separate state
   - Consistent styling across views

4. Alice also sees overdue task trong project view:
   - Project collaboration shows all task states
   - Alice có visibility into team progress

💭 Bob's thoughts: "Oops! Missed the deadline. Need to prioritize this task today."
```

### **📖 Act 5: Advanced Collaboration Features**

#### **Scene 5.1: Task Reassignment**
```
⏰ Time: Tuesday, 10:00 AM
📍 Location: Alice's Management Dashboard

[Alice helps Bob với overdue task]

1. Alice opens "Website Redesign" project
2. Sees Bob's overdue task trong project view
3. Alice decides to help:
   - Clicks edit on "Create component library"
   - EditTodoDialog opens với AssignUserDropdown
   - Changes assignment from Bob to Alice
   - Updates due date to Thursday

4. System updates task:
   - assignedToId changed from bob.id to alice.id
   - assignedToDisplayName updated to "Alice Manager"
   - Real-time propagation across providers

5. Bob sees immediate update:
   - Task disappears from his Today/Overdue views
   - No longer assigned to him
   - Can still see task trong project view for awareness

6. Alice's views update:
   - Task appears trong her Today view
   - Due Thursday, not overdue anymore
   - AssignedUserChip shows Alice's avatar

💭 Alice's thoughts: "Team support! Bob có thể focus on other tasks."
```

#### **Scene 5.2: Member Filtering & Project Management**
```
⏰ Time: Tuesday, 11:00 AM
📍 Location: Alice's Project Review

[Alice analyzes team workload]

1. Alice opens ProjectMembersDialog for "Website Redesign":
   - Members section shows:
     * Alice Manager (@alice_pm) - 2 tasks
     * Bob Developer (@bob_dev) - 0 tasks
   - Task counts từ userTaskCountInProjectProvider

2. Alice clicks on Bob's member item:
   - selectedMemberFilterProvider.state = bob.id
   - filteredTodoListProvider filters project tasks
   - Blue highlight on Bob's profile
   - Project view shows only Bob's tasks (none currently)

3. Alice clicks "Unassigned Tasks" section:
   - selectedMemberFilterProvider.state = 'unassigned'
   - Orange badge shows unassigned task count
   - Project view filters to unassigned tasks only

4. Alice clicks Alice's member item:
   - Filter shows only Alice's tasks
   - Helps focus on specific member workload

5. Alice clears filter (clicks Alice again):
   - selectedMemberFilterProvider.state = null
   - Project view shows all tasks again
   - Full project visibility restored

💭 Alice's thoughts: "Good workload distribution. Bob có thể take on more tasks."
```

### **📖 Act 6: Advanced Scenarios & Edge Cases**

#### **Scene 6.1: Multiple Project Collaboration**
```
⏰ Time: Wednesday, 9:00 AM
📍 Location: Both Users

[Alice creates second project, different collaboration pattern]

1. Alice creates "Mobile App" project:
   - New project với Alice as owner
   - Invites Bob immediately
   - Bob accepts invitation

2. Cross-project task management:
   - Bob giờ có tasks từ 2 projects
   - Today view shows combined assigned tasks
   - Upcoming view groups by date, không by project
   - Each project view shows project-specific tasks

3. Project switching workflow:
   - Bob navigates between projects via sidebar
   - Each project maintains separate task context
   - Shared project indicators show collaboration status

💭 Both users: "Multiple project collaboration seamlessly supported."
```

#### **Scene 6.2: Invitation Management Edge Cases**
```
⏰ Time: Wednesday, 10:00 AM
📍 Location: Alice's Admin Tasks

[Alice tests invitation system limits]

1. Alice invites non-existent user:
   - Types "John Unknown" trong InviteUserWidget
   - userDisplayNameProvider returns empty
   - Error message: "Không tìm thấy người dùng"
   - Graceful error handling

2. Alice tries to invite Bob again:
   - System validates existing membership
   - Error message: "Người dùng đã là thành viên"
   - Prevents duplicate invitations

3. Bob declines future invitation:
   - Alice invites Bob to different project
   - Bob clicks "Decline" trong NotificationDialog
   - Invitation status = declined
   - Bob doesn't gain project access
   - Notification removed from Bob's list

💭 Alice's thoughts: "Robust system với good error handling."
```

### **📖 Act 7: Long-term Usage Patterns**

#### **Scene 7.1: Weekly Review Workflow**
```
⏰ Time: Friday, 5:00 PM
📍 Location: End-of-week Review

[Both users review week progress]

**Alice's Review Process:**
1. Opens "Today" view:
   - completedTodosProvider shows finished tasks
   - Overdue section shows any missed deadlines
   - Clear overview of personal productivity

2. Checks each project separately:
   - "Website Redesign": 80% tasks completed
   - "Mobile App": 60% tasks completed
   - Team progress visible through shared views

3. Plans next week assignments:
   - Creates new tasks with future due dates
   - Assigns to appropriate team members
   - Sets priorities based on project needs

**Bob's Review Process:**
1. Reviews completed work:
   - Personal achievement tracking
   - Task completion timestamps
   - Project contribution overview

2. Checks upcoming commitments:
   - Next week's assigned tasks
   - Due date planning
   - Workload assessment

💭 Both users: "Clear visibility into productivity and team collaboration."
```

#### **Scene 7.2: Data Persistence & Session Management**
```
⏰ Time: Monday Next Week, 8:00 AM
📍 Location: App Restart Scenario

[Both users return after weekend]

1. Alice opens app:
   - AuthInitializationProvider restores session
   - User-specific data boxes reopen
   - All projects và tasks persist correctly
   - Collaboration state maintained

2. Bob opens app:
   - Same seamless session restoration
   - Shared project access preserved
   - Task assignments intact
   - Notification state consistent

3. Cross-user data integrity:
   - Alice's changes visible to Bob
   - Bob's updates reflected for Alice
   - Real-time collaboration continues
   - No data loss or corruption

💭 Both users: "Reliable persistence enables consistent workflow."
```

---

## 🎯 **SYSTEM CAPABILITIES DEMONSTRATED**

### **✅ Authentication & User Management**
- [x] Secure registration với password hashing
- [x] Session persistence across app restarts
- [x] Multi-user data isolation
- [x] Automatic login/logout workflows

### **✅ Shared Project Collaboration**
- [x] Project creation and ownership
- [x] User invitation by display name
- [x] Real-time invitation notifications
- [x] Accept/decline invitation workflows
- [x] Shared project indicators và team management

### **✅ Task Assignment & Management**
- [x] Task creation with assignments
- [x] AssignUserDropdown functionality
- [x] Real-time task updates across users
- [x] Task completion tracking
- [x] Due date management with overdue detection

### **✅ Advanced UI/UX Features**
- [x] Member filtering trong project views
- [x] Overdue task highlighting và grouping
- [x] Expandable/collapsible sections
- [x] Cross-view consistency (Today/Upcoming/Project)
- [x] Real-time badge updates

### **✅ Riverpod State Management Excellence**
- [x] Level 1: StateProvider cho simple UI state
- [x] Level 2: StateNotifierProvider cho complex logic
- [x] Level 3: FutureProvider cho async operations
- [x] Level 4: Provider.family cho parameterized data
- [x] Cross-provider dependencies và reactive updates

### **✅ Error Handling & Edge Cases**
- [x] Graceful invitation error handling
- [x] Duplicate member prevention
- [x] Non-existent user validation
- [x] Navigation error prevention
- [x] Data consistency maintenance

---

## 📊 **PERFORMANCE & TECHNICAL METRICS**

### **🚀 App Performance (From Terminal Output)**
```
✅ Registered TodoAdapter (typeId: 0)
✅ Registered SectionModelAdapter (typeId: 2)
✅ Registered ProjectModelAdapter (typeId: 3)
✅ Registered UserAdapter (typeId: 10)
✅ Registered ProjectMemberAdapter (typeId: 11)
✅ Registered ProjectInvitationAdapter (typeId: 12)
✅ Registered InvitationStatusAdapter (typeId: 13)

🔍 Performance Metrics:
  Total time: 918ms
  Slowest phase: hive_init
  Memory usage: 2KB
  Performance: ✅ Good
```

### **🔍 Real-time Debug Tracking**
```
🔍 DEBUG: Filtering todos for user: [user_id]
🔍 DEBUG: Total todos in box: [count]
🔍 DEBUG: Current user can see these todos (assigned to them):
🔍 WEEK DEBUG: Today is [date] (weekday: [day])
🔍 WEEK DEBUG: Days from Monday: [offset]
🔍 WEEK DEBUG: Monday of this week: [week_start]
```

### **💾 Data Architecture Efficiency**
- **7 Hive Adapters** registered successfully
- **6 Database Boxes** opened concurrently
- **Real-time provider updates** với minimal latency
- **Cross-user data separation** maintained
- **Memory usage**: 2KB (highly efficient)

---

## 🏆 **SUCCESS CRITERIA ACHIEVED**

### **👥 User Experience Success**
- ✅ **Intuitive workflow**: Both users completed all tasks naturally
- ✅ **Real-time collaboration**: Changes reflected immediately
- ✅ **Clear visual feedback**: Status updates, notifications, badges
- ✅ **Error prevention**: Graceful handling of edge cases

### **🛠️ Technical Excellence**
- ✅ **Riverpod mastery**: All 4 levels implemented perfectly
- ✅ **Data consistency**: No corruption across multi-user scenarios
- ✅ **Performance optimization**: Sub-second load times
- ✅ **Scalable architecture**: Supports multiple projects/users

### **🎨 UI/UX Excellence**
- ✅ **Consistent styling**: Unified design across all views
- ✅ **Responsive interactions**: Smooth animations và transitions
- ✅ **Information hierarchy**: Clear task organization
- ✅ **Accessibility**: Intuitive navigation và discovery

---

## 🎓 **LEARNING OUTCOMES**

### **For Developers**
1. **Advanced Riverpod patterns** trong real-world scenarios
2. **Multi-user state management** với data isolation
3. **Real-time collaboration** implementation strategies
4. **Error handling** best practices trong Flutter apps

### **For Users**
1. **Effective team collaboration** workflows
2. **Task management** strategies với deadlines
3. **Project organization** methods
4. **Cross-platform productivity** techniques

### **For Product Teams**
1. **Feature integration** across complex user journeys
2. **Performance optimization** strategies
3. **User feedback incorporation** mechanisms
4. **Scalable collaboration** platform design

---

## 🔮 **FUTURE ENHANCEMENT OPPORTUNITIES**

### **Based on User Interactions**
1. **Advanced Permissions**: Role-based access control
2. **Activity Feed**: Real-time project activity tracking
3. **Due Date Notifications**: Proactive deadline reminders
4. **Bulk Operations**: Multi-task management tools
5. **Project Templates**: Standardized project structures
6. **Time Tracking**: Task duration monitoring
7. **File Attachments**: Document collaboration
8. **Comment System**: Task-specific communication

### **Technical Improvements**
1. **Offline Sync**: Conflict resolution strategies
2. **Push Notifications**: Mobile alert system
3. **API Integration**: External service connections
4. **Advanced Analytics**: Usage pattern tracking
5. **Performance Monitoring**: Real-time metrics dashboard

---

*Kịch bản này demonstrates comprehensive user interaction patterns trong Todo App, showcasing tất cả major features và technical capabilities thông qua realistic workflow scenarios.*