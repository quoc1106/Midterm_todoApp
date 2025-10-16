# 🔍 Smart Search Feature Documentation

## 📋 Overview
Advanced search functionality with command palette-style UI, supporting intelligent search across tasks and projects with real-time results and keyboard shortcuts.

## 🎯 Features

### ✨ Core Functionality
- **Smart Search**: Tìm kiếm tasks và projects theo tên
- **Real-time Results**: Kết quả hiển thị ngay lập tức khi gõ
- **Intelligent Ranking**: Results được sắp xếp theo độ relevance
- **Type Differentiation**: Phân biệt rõ ràng tasks vs projects với icons và colors

### 🎨 UI/UX Design
- **Command Palette Style**: Thiết kế giống VS Code command palette
- **Beautiful Animations**: Smooth fade-in và slide transitions
- **Keyboard Navigation**: Arrow keys để navigate, Enter để select
- **Responsive Design**: Adapts to different screen sizes

### ⌨️ Keyboard Shortcuts
- **Ctrl+K (Windows/Linux)** hoặc **Cmd+K (Mac)**: Mở search dialog
- **↑/↓**: Navigate giữa results
- **Enter**: Select result
- **Esc**: Close dialog

## 🏗️ Architecture

### 📁 File Structure
```
lib/
├── providers/
│   └── search_providers.dart         # Level 3-4 Riverpod providers
├── features/todo/widgets/
│   ├── navigation/
│   │   └── app_drawer.dart           # Search button integration
│   └── search/
│       ├── search_dialog.dart        # Main search dialog
│       └── search_result_item_widget.dart # Individual result items
└── features/todo/screens/
    └── todo_screen.dart              # Keyboard shortcut integration
```

### 🔧 Riverpod Implementation

#### Level 3: Performance-Aware Search
```dart
// Enhanced search với performance monitoring
final searchResultsProvider = Provider.family<List<SearchResultItem>, String>((ref, query) {
  // Performance tracking
  final startTime = DateTime.now();
  
  // Search logic với relevance scoring
  // Auto-limit results to 20 items
  // Performance warning nếu > 100ms
});
```

#### Level 4: Advanced Analytics & Caching
```dart
// Search analytics với user behavior tracking
final searchAnalyticsProvider = StateNotifierProvider<SearchAnalyticsNotifier, SearchAnalytics>((ref) {
  return SearchAnalyticsNotifier();
});

// Recent searches với caching
final recentSearchesProvider = StateNotifierProvider<RecentSearchesNotifier, List<String>>((ref) {
  return RecentSearchesNotifier();
});
```

## 🎯 Search Algorithm

### 📊 Relevance Scoring
```dart
double calculateRelevance(String query) {
  double score = 0.0;
  
  // Exact match: +100 points
  if (lowerTitle == lowerQuery) score += 100;
  
  // Starts with query: +50 points
  if (lowerTitle.startsWith(lowerQuery)) score += 50;
  
  // Contains query: +25 points
  if (lowerTitle.contains(lowerQuery)) score += 25;
  
  // Subtitle match: +10 points
  if (lowerSubtitle.contains(lowerQuery)) score += 10;
  
  // Project priority: +5 points
  if (type == SearchResultType.project) score += 5;
  
  // Completed task penalty: -5 points
  if (type == SearchResultType.task && isCompleted) score -= 5;
  
  return score;
}
```

### 🏷️ Type Differentiation
- **Projects**: 📁 Blue folder icon + "PROJECT" badge
- **Active Tasks**: ⭕ Primary color circle + "TASK" badge  
- **Completed Tasks**: ✅ Green check + "DONE" badge
- **Sections**: 🏷️ Orange label icon + "SECTION" badge

## 🎮 User Experience

### 🚀 Search Flow
1. **Trigger**: Click search button hoặc Ctrl+K
2. **Input**: Type query với real-time results
3. **Navigate**: Keyboard arrows hoặc mouse hover
4. **Select**: Enter hoặc click để navigate

### 🧭 Smart Navigation
- **Project Selection**: Navigate to My Projects → Select project
- **Task Selection**: Navigate to appropriate view (Today/Upcoming/Projects)
- **Context Awareness**: Tasks without projects → Today/Upcoming view
- **Date Intelligence**: Future tasks → Upcoming, Today tasks → Today

### 📱 Visual Indicators
- **Due Date Colors**:
  - 🔴 Red: Overdue tasks
  - 🟠 Orange: Due today  
  - ⚪ Gray: Future dates
- **Status Icons**:
  - ✅ Completed tasks
  - 📅 Tasks with due dates
- **Selection State**: Highlighted row với arrow indicator

## 🔧 Integration Points

### 🎯 Provider Dependencies
```dart
// Search depends on:
- projectsProvider (for project data)
- todoListProvider (for task data)
- sidebarItemProvider (for navigation)
- selectedProjectIdProvider (for project selection)
```

### 🎨 Theme Integration
- Adapts to light/dark themes
- Uses Material 3 color schemes
- Consistent với app design language

## 📈 Performance Features

### ⚡ Optimizations
- **Result Limiting**: Max 20 results để tránh lag
- **Debouncing**: Prevents spam searches
- **Performance Monitoring**: Tracks search times
- **Memory Efficient**: Cleans up resources properly

### 📊 Analytics Tracking
- **Search Frequency**: Tracks popular queries
- **Result Clicks**: Monitors user preferences  
- **Recent Searches**: Quick access to previous searches
- **Performance Metrics**: Search response times

## 🎯 Usage Examples

### 💼 Business Scenarios
1. **Quick Task Lookup**: "meeting" → Find all meeting-related tasks
2. **Project Management**: "website" → Find website project + related tasks  
3. **Status Checking**: "urgent" → Find all urgent tasks across projects
4. **Daily Planning**: "today" → Quick access to today's tasks

### 🔍 Search Patterns
- **Exact Match**: "Project X" → Direct project access
- **Partial Match**: "meet" → "meeting", "meetup", etc.
- **Cross-Type**: "work" → Both "Work Project" và "work tasks"

## 🎊 Success Metrics
✅ **Fast Search**: <100ms response time  
✅ **Smart Ranking**: Most relevant results first  
✅ **Beautiful UI**: Command palette design  
✅ **Keyboard Friendly**: Full keyboard navigation  
✅ **Type Safety**: Clear task vs project distinction  
✅ **Context Aware**: Smart navigation to appropriate views  

## 🚀 Future Enhancements
- **Fuzzy Search**: Typo tolerance
- **Search Filters**: By date, status, project
- **Search History**: Persistent across sessions
- **Quick Actions**: Direct task completion from search
- **Search Suggestions**: Auto-complete functionality