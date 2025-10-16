# Widget Organization Strategy

## 📁 Current Structure vs Recommended Organization

### **❌ Current Structure (có thể cải thiện):**
```
lib/features/todo/widgets/
├── add_task_widget.dart
├── app_drawer.dart  
├── date_selector_widget.dart
├── project_section_picker_dialog.dart
├── project_section_picker_row.dart
├── project_section_widget.dart
├── project_sidebar_widget.dart
├── todo_group_widget.dart
├── todo_item.dart
```

### **✅ Recommended Structure (theo logic chức năng):**

```
lib/features/todo/widgets/
├── core/                           # Core todo functionality
│   ├── todo_item.dart             # Individual task display
│   ├── todo_group_widget.dart     # Date-grouped tasks
│   └── add_task_widget.dart       # Add new task form
├── project/                        # Project management
│   ├── project_sidebar_widget.dart
│   ├── project_section_widget.dart
│   └── pickers/                   # Selection widgets
│       ├── project_section_picker_dialog.dart
│       └── project_section_picker_row.dart
├── navigation/                     # Navigation & layout
│   ├── app_drawer.dart
│   └── date_selector_widget.dart
└── shared/                        # Reusable components
    └── (future shared widgets)
```

## 🎯 Alternative Organization Options

### **Option 1: By Functionality (Recommended)**
```
lib/features/todo/widgets/
├── task/                          # Task-related widgets
│   ├── task_item.dart            # Renamed from todo_item.dart
│   ├── task_group.dart           # Renamed from todo_group_widget.dart  
│   ├── task_form.dart            # Renamed from add_task_widget.dart
│   └── task_list.dart            # Future: task list container
├── project/                       # Project & section management
│   ├── project_sidebar.dart      # Renamed
│   ├── project_detail.dart       # Renamed from project_section_widget.dart
│   └── selectors/                # Selection components
│       ├── project_picker_dialog.dart
│       └── project_picker_inline.dart
├── layout/                        # Layout & navigation
│   ├── main_drawer.dart          # Renamed from app_drawer.dart
│   ├── date_picker.dart          # Renamed from date_selector_widget.dart
│   └── bottom_navigation.dart    # Future
└── common/                        # Shared/reusable widgets
    ├── confirmation_dialog.dart   # Extract from widgets
    ├── custom_button.dart         # Future
    └── loading_indicator.dart     # Future
```

### **Option 2: By Component Type**
```
lib/features/todo/widgets/
├── forms/                         # Input forms
│   ├── add_task_form.dart
│   ├── edit_task_form.dart
│   └── project_form.dart
├── lists/                         # List displays
│   ├── task_list.dart
│   ├── project_list.dart
│   └── grouped_task_list.dart
├── cards/                         # Card components
│   ├── task_card.dart
│   ├── project_card.dart
│   └── section_card.dart
├── dialogs/                       # Modal dialogs
│   ├── project_picker_dialog.dart
│   ├── date_picker_dialog.dart
│   └── confirmation_dialog.dart
└── navigation/                    # Navigation components
    ├── main_drawer.dart
    └── tab_bar.dart
```

### **Option 3: By Screen/Page**
```
lib/features/todo/widgets/
├── home/                          # Home screen widgets
│   ├── today_view.dart
│   ├── upcoming_view.dart
│   └── task_summary.dart
├── project/                       # Project screen widgets
│   ├── project_header.dart
│   ├── section_list.dart
│   └── project_stats.dart
├── shared/                        # Shared across screens
│   ├── task_item.dart
│   ├── add_task_form.dart
│   └── date_selector.dart
└── layout/                        # Layout widgets
    ├── app_drawer.dart
    └── app_bar.dart
```

## 🔧 Implementation Plan

### **Phase 1: Create New Folder Structure**
```bash
mkdir lib/features/todo/widgets/core
mkdir lib/features/todo/widgets/project
mkdir lib/features/todo/widgets/project/pickers
mkdir lib/features/todo/widgets/navigation
mkdir lib/features/todo/widgets/shared
```

### **Phase 2: Move Files (với import updates)**
1. **Core Todo Widgets:**
   - `todo_item.dart` → `core/todo_item.dart`
   - `todo_group_widget.dart` → `core/todo_group_widget.dart`
   - `add_task_widget.dart` → `core/add_task_widget.dart`

2. **Project Widgets:**
   - `project_sidebar_widget.dart` → `project/project_sidebar_widget.dart`
   - `project_section_widget.dart` → `project/project_section_widget.dart`
   - `project_section_picker_dialog.dart` → `project/pickers/project_section_picker_dialog.dart`
   - `project_section_picker_row.dart` → `project/pickers/project_section_picker_row.dart`

3. **Navigation Widgets:**
   - `app_drawer.dart` → `navigation/app_drawer.dart`
   - `date_selector_widget.dart` → `navigation/date_selector_widget.dart`

### **Phase 3: Update Import Statements**
Tất cả imports cần update paths:
```dart
// Old
import '../widgets/todo_item.dart';

// New  
import '../widgets/core/todo_item.dart';
```

### **Phase 4: Create Index Files (Optional)**
```dart
// lib/features/todo/widgets/core/index.dart
export 'todo_item.dart';
export 'todo_group_widget.dart';
export 'add_task_widget.dart';

// lib/features/todo/widgets/project/index.dart
export 'project_sidebar_widget.dart';
export 'project_section_widget.dart';
export 'pickers/project_section_picker_dialog.dart';
export 'pickers/project_section_picker_row.dart';
```

## 🎨 Alternative: Atomic Design Organization

```
lib/features/todo/widgets/
├── atoms/                         # Smallest components
│   ├── task_checkbox.dart
│   ├── priority_badge.dart
│   └── date_chip.dart
├── molecules/                     # Simple combinations
│   ├── task_item.dart
│   ├── project_picker.dart
│   └── date_selector.dart
├── organisms/                     # Complex combinations
│   ├── task_list.dart
│   ├── project_sidebar.dart
│   └── add_task_form.dart
├── templates/                     # Page layouts
│   ├── todo_page_template.dart
│   └── project_page_template.dart
└── pages/                        # Complete pages
    ├── today_page.dart
    ├── upcoming_page.dart
    └── project_detail_page.dart
```

## 📝 Recommended Action

**Tôi recommend Option 1: By Functionality** vì:

✅ **Pros:**
- Dễ tìm kiếm theo chức năng
- Phù hợp với feature-based architecture hiện tại
- Clear separation of concerns
- Scalable khi thêm features mới

✅ **Specific Benefits:**
- `core/`: Tất cả logic task cơ bản
- `project/`: Tất cả logic project/section
- `navigation/`: Layout và navigation
- `shared/`: Reusable components

✅ **Easy Migration:**
- Có thể move từng folder một
- Import updates đơn giản
- Không break existing functionality

Bạn có muốn tôi implement việc reorganize này không?