# Cấu Trúc Dự Án Todo App

## Tổng Quan
Đây là một ứng dụng Flutter Todo được xây dựng với kiến trúc Clean Architecture, sử dụng Riverpod cho state management và Hive cho local storage.

## Cấu Trúc Thư Mục Chính

```
todo_app/
├── lib/                                    # Mã nguồn chính của ứng dụng
│   ├── main.dart                          # Entry point của ứng dụng
│   ├── app_initialization_widget.dart     # Widget khởi tạo ứng dụng
│   ├── backend/                           # Logic nghiệp vụ và dữ liệu
│   ├── frontend/                          # Giao diện người dùng
│   └── providers/                         # State management với Riverpod
├── docs/                                  # Tài liệu dự án
├── test/                                  # Test cases
├── android/                               # Cấu hình Android
├── ios/                                   # Cấu hình iOS
├── windows/                               # Cấu hình Windows
├── web/                                   # Cấu hình Web
├── linux/                                 # Cấu hình Linux
├── macos/                                 # Cấu hình macOS
└── build/                                 # File build tự động tạo
```

## Chi Tiết Cấu Trúc Backend (`lib/backend/`)

### 📁 `core/`
```
core/
└── hive_adapters.dart                     # Adapters cho Hive database
```
**Mục đích**: Chứa các adapter cần thiết để serialize/deserialize objects với Hive.

### 📁 `models/`
```
models/
├── project_model.dart                     # Model cho Project
├── project_model.g.dart                   # Generated code cho Project
├── section_model.dart                     # Model cho Section
├── section_model.g.dart                   # Generated code cho Section
├── todo_model.dart                        # Model cho Todo item
└── todo_model.g.dart                      # Generated code cho Todo
```
**Mục đích**: Định nghĩa các data models chính của ứng dụng với Hive annotations.

### 📁 `services/`
```
services/
├── data_service.dart                      # Service quản lý dữ liệu
└── performance_service.dart               # Service theo dõi performance
```
**Mục đích**: Chứa các service classes xử lý logic nghiệp vụ và tương tác với database.

### 📁 `utils/`
```
utils/
└── date_utils.dart                        # Utilities cho xử lý ngày tháng
```
**Mục đích**: Các hàm tiện ích dùng chung trong ứng dụng.

## Chi Tiết Cấu Trúc Frontend (`lib/frontend/`)

### 📁 `screens/`
```
screens/
└── todo_screen.dart                       # Màn hình chính của ứng dụng
```
**Mục đích**: Chứa các màn hình chính của ứng dụng.

### 📁 `components/`
Được tổ chức theo feature modules:

#### 📁 `app/`
```
app/
├── index.dart                             # Export file cho app components
├── app_initialization_widget.dart         # Widget khởi tạo ứng dụng
└── performance_floating_indicator.dart    # Indicator hiển thị performance
```

#### 📁 `layout/`
```
layout/
├── index.dart                             # Export file cho layout components
├── app_error_screen.dart                  # Màn hình lỗi
├── app_loading_screen.dart                # Màn hình loading
└── migration_loading_screen.dart          # Màn hình loading migration
```

#### 📁 `navigation/`
```
navigation/
├── index.dart                             # Export file cho navigation components
├── app_drawer.dart                        # Drawer menu
├── date_selector_widget.dart              # Widget chọn ngày
├── search_dialog.dart                     # Dialog tìm kiếm
└── search_result_item_widget.dart         # Item kết quả tìm kiếm
```

#### 📁 `project/`
```
project/
├── index.dart                             # Export file cho project components
├── pickers/                               # Các picker widgets cho project
└── widgets/                               # Các widget liên quan đến project
```

#### 📁 `theme/`
```
theme/
├── index.dart                             # Export file cho theme components
├── theme_info_widget.dart                 # Widget hiển thị thông tin theme
└── theme_toggle_widget.dart               # Widget chuyển đổi theme
```

#### 📁 `todo/`
```
todo/
├── index.dart                             # Export file cho todo components
├── add_task_widget.dart                   # Widget thêm task mới
├── edit_todo_dialog.dart                  # Dialog chỉnh sửa todo
├── todo_group_widget.dart                 # Widget nhóm todos
└── todo_item.dart                         # Widget todo item
```

## State Management (`lib/providers/`)

```
providers/
├── database_providers.dart                # Providers cho database operations
├── data_migration_providers.dart          # Providers cho data migration
├── performance_initialization_providers.dart # Providers cho performance tracking
├── project_providers.dart                 # Providers cho project management
├── search_providers.dart                  # Providers cho search functionality
├── section_providers.dart                 # Providers cho section management
├── selection_validation_providers.dart    # Providers cho validation
├── theme_providers.dart                   # Providers cho theme management
└── todo_providers.dart                    # Providers cho todo operations
```

**Mục đích**: Quản lý state của toàn bộ ứng dụng sử dụng Riverpod pattern.

## Tài Liệu (`docs/`)

Thư mục này chứa các tài liệu kỹ thuật:
- `ACTIVITY_DIAGRAMS.md` - Biểu đồ hoạt động
- `ARCHITECTURE_ANALYSIS.md` - Phân tích kiến trúc
- `SYSTEM_ARCHITECTURE.md` - Kiến trúc hệ thống
- `USE_CASE_DIAGRAM.md` - Biểu đồ use case
- Và nhiều tài liệu khác về optimization, performance, theme management...

## Công Nghệ Sử Dụng

### Dependencies Chính:
- **Flutter**: Framework UI đa nền tảng
- **flutter_riverpod**: State management
- **hive & hive_flutter**: Local database NoSQL
- **uuid**: Tạo unique identifiers
- **shared_preferences**: Lưu trữ preferences
- **intl**: Internationalization

### Dev Dependencies:
- **build_runner**: Code generation
- **hive_generator**: Tự động tạo Hive adapters
- **flutter_test**: Unit testing

## Kiến Trúc

Dự án áp dụng **Clean Architecture** với các layer rõ ràng:

1. **Presentation Layer** (`frontend/`): UI components và screens
2. **Business Logic Layer** (`providers/`): State management và business rules
3. **Data Layer** (`backend/`): Models, services, và data access

## Quy Tắc Tổ Chức Code

1. **Separation of Concerns**: Mỗi module có trách nhiệm riêng biệt
2. **Feature-based Organization**: Components được tổ chức theo feature
3. **Index Files**: Mỗi folder có `index.dart` để export public APIs
4. **Generated Code**: Files `.g.dart` được tự động tạo bởi build_runner
5. **Consistent Naming**: Tuân theo Dart naming conventions

## Hướng Dẫn Phát Triển

1. **Thêm Model mới**: Tạo trong `backend/models/` với Hive annotations
2. **Thêm Screen mới**: Tạo trong `frontend/screens/`
3. **Thêm Component mới**: Tạo trong folder tương ứng trong `frontend/components/`
4. **Thêm Provider mới**: Tạo trong `providers/` theo naming convention
5. **Build Models**: Chạy `flutter packages pub run build_runner build` sau khi thay đổi models

## Notes

- Dự án hỗ trợ đa nền tảng: Android, iOS, Web, Windows, Linux, macOS
- Sử dụng Hive cho local storage vì performance tốt và dễ sử dụng
- Riverpod được chọn cho state management vì type-safe và testable
- Code được tổ chức để dễ maintain và scale
