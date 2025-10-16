# Riverpod Implementation - Level 1: Theme Management

## Mục tiêu
Chứng minh **"Ease of Use"** của Riverpod thông qua việc quản lý theme state đơn giản.

## Implementation Details

### 1. StateProvider cho Theme Management
```dart
// providers/theme_providers.dart
final themeProvider = StateProvider<AppTheme>((ref) => AppTheme.system);
```

**Tại sao StateProvider?**
- ✅ **Đơn giản nhất**: Chỉ cần 1 dòng code để tạo provider
- ✅ **Reactive**: UI tự động rebuild khi state thay đổi
- ✅ **Type-safe**: AppTheme enum đảm bảo type safety
- ✅ **No boilerplate**: Không cần StateNotifier class

### 2. Computed Providers
```dart
final themeModeProvider = Provider<ThemeMode>((ref) {
  final appTheme = ref.watch(themeProvider);
  // Convert AppTheme -> ThemeMode
});
```

**Ưu điểm:**
- ✅ **Separation of concerns**: Logic convert tách biệt khỏi UI
- ✅ **Reactive**: Tự động tính toán lại khi themeProvider thay đổi
- ✅ **Cacheable**: Kết quả được cache, không tính toán lại không cần thiết

### 3. UI Integration
```dart
class MyApp extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(themeMode: themeMode);
  }
}
```

**So sánh với setState:**

**❌ StatefulWidget + setState:**
```dart
class MyApp extends StatefulWidget {
  State createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  
  void _changeTheme(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }
  
  Widget build(BuildContext context) {
    return MaterialApp(themeMode: _themeMode);
  }
}
```

**✅ Riverpod StateProvider:**
```dart
class MyApp extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(themeMode: themeMode);
  }
}
```

## Chứng minh "Ease of Use"

### 1. Ít code hơn
- **setState**: 15+ dòng code, cần StatefulWidget
- **Riverpod**: 3 dòng code, ConsumerWidget

### 2. Tự động rebuild
- UI tự động cập nhật khi theme thay đổi
- Không cần gọi setState() manually

### 3. Global state
- Theme state có thể truy cập từ bất kỳ widget nào
- Không cần pass data qua constructor

### 4. Type safety
- AppTheme enum đảm bảo chỉ nhận giá trị hợp lệ
- Compile-time error nếu sai type

## Kết luận Cấp độ 1
✅ **Đã chứng minh**: Riverpod làm state management **cực kỳ đơn giản**
✅ **Ưu điểm**: Ít code, reactive, type-safe, global state
✅ **Use case**: Perfect cho primitive state (bool, enum, string, number)