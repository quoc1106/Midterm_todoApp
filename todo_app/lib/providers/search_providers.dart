import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'project_providers.dart';
import 'todo_providers.dart';

/// Search result item với type để phân biệt
class SearchResultItem {
  final String id;
  final String title;
  final String? subtitle;
  final SearchResultType type;
  final String? projectId;
  final DateTime? dueDate;
  final bool isCompleted;

  SearchResultItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.type,
    this.projectId,
    this.dueDate,
    this.isCompleted = false,
  });

  // Relevance score để sort kết quả
  double calculateRelevance(String query) {
    final lowerQuery = query.toLowerCase();
    final lowerTitle = title.toLowerCase();
    final lowerSubtitle = subtitle?.toLowerCase() ?? '';

    double score = 0.0;

    // Exact match có điểm cao nhất
    if (lowerTitle == lowerQuery) score += 100;

    // Start with query
    if (lowerTitle.startsWith(lowerQuery)) score += 50;

    // Contains query
    if (lowerTitle.contains(lowerQuery)) score += 25;

    // Subtitle contains query
    if (lowerSubtitle.contains(lowerQuery)) score += 10;

    // Project có priority cao hơn task một chút
    if (type == SearchResultType.project) score += 5;

    // Task hoàn thành có priority thấp hơn
    if (type == SearchResultType.task && isCompleted) score -= 5;

    return score;
  }
}

enum SearchResultType { project, task, section }

/// Level 3: Performance-aware search provider với debouncing
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Level 3: Enhanced search với performance monitoring
final searchResultsProvider = Provider.family<List<SearchResultItem>, String>((
  ref,
  query,
) {
  final startTime = DateTime.now();

  if (query.trim().isEmpty) return [];

  try {
    // Get data from enhanced providers
    final projects = ref.watch(projectsProvider);
    final todos = ref.watch(todoListProvider);

    final results = <SearchResultItem>[];
    final lowerQuery = query.toLowerCase();

    // Search projects
    for (final project in projects) {
      if (project.name.toLowerCase().contains(lowerQuery)) {
        results.add(
          SearchResultItem(
            id: project.id,
            title: project.name,
            subtitle:
                'Project • ${_getProjectTaskCount(ref, project.id)} tasks',
            type: SearchResultType.project,
          ),
        );
      }
    }

    // Search tasks
    for (final todo in todos) {
      if (todo.description.toLowerCase().contains(lowerQuery)) {
        String? projectName;
        if (todo.projectId != null) {
          final project = projects.firstWhereOrNull(
            (p) => p.id == todo.projectId,
          );
          projectName = project?.name;
        }

        results.add(
          SearchResultItem(
            id: todo.id,
            title: todo.description,
            subtitle: projectName != null
                ? 'Task in $projectName'
                : 'Everyday Task',
            type: SearchResultType.task,
            projectId: todo.projectId,
            dueDate: todo.dueDate,
            isCompleted: todo.completed,
          ),
        );
      }
    }

    // Sort by relevance
    results.sort(
      (a, b) =>
          b.calculateRelevance(query).compareTo(a.calculateRelevance(query)),
    );

    // Performance tracking
    final duration = DateTime.now().difference(startTime);
    if (duration.inMilliseconds > 100) {
      print(
        '⚠️ Search performance: ${duration.inMilliseconds}ms for ${results.length} results',
      );
    }

    return results.take(20).toList(); // Limit to 20 results
  } catch (e) {
    print('❌ Search error: $e');
    return [];
  }
});

/// Level 4: Advanced search với caching và analytics
final searchAnalyticsProvider =
    StateNotifierProvider<SearchAnalyticsNotifier, SearchAnalytics>((ref) {
      return SearchAnalyticsNotifier();
    });

class SearchAnalytics {
  final int totalSearches;
  final Map<String, int> popularQueries;
  final List<String> recentQueries;
  final Map<SearchResultType, int> resultTypeClicks;

  SearchAnalytics({
    this.totalSearches = 0,
    this.popularQueries = const {},
    this.recentQueries = const [],
    this.resultTypeClicks = const {},
  });

  SearchAnalytics copyWith({
    int? totalSearches,
    Map<String, int>? popularQueries,
    List<String>? recentQueries,
    Map<SearchResultType, int>? resultTypeClicks,
  }) {
    return SearchAnalytics(
      totalSearches: totalSearches ?? this.totalSearches,
      popularQueries: popularQueries ?? this.popularQueries,
      recentQueries: recentQueries ?? this.recentQueries,
      resultTypeClicks: resultTypeClicks ?? this.resultTypeClicks,
    );
  }
}

class SearchAnalyticsNotifier extends StateNotifier<SearchAnalytics> {
  SearchAnalyticsNotifier() : super(SearchAnalytics());

  void recordSearch(String query) {
    if (query.trim().isEmpty) return;

    final normalizedQuery = query.trim().toLowerCase();
    final popularQueries = Map<String, int>.from(state.popularQueries);
    popularQueries[normalizedQuery] =
        (popularQueries[normalizedQuery] ?? 0) + 1;

    final recentQueries = [
      normalizedQuery,
      ...state.recentQueries.where((q) => q != normalizedQuery),
    ].take(10).toList();

    state = state.copyWith(
      totalSearches: state.totalSearches + 1,
      popularQueries: popularQueries,
      recentQueries: recentQueries,
    );
  }

  void recordResultClick(SearchResultType type) {
    final clicks = Map<SearchResultType, int>.from(state.resultTypeClicks);
    clicks[type] = (clicks[type] ?? 0) + 1;

    state = state.copyWith(resultTypeClicks: clicks);
  }

  List<String> getSuggestions() {
    return state.recentQueries.take(5).toList();
  }
}

/// Debounced search để tránh spam
final debouncedSearchProvider = Provider<String>((ref) {
  final query = ref.watch(searchQueryProvider);
  // Implement debouncing logic here if needed
  return query;
});

/// Helper function
int _getProjectTaskCount(Ref ref, String projectId) {
  try {
    final todos = ref.read(todoListProvider);
    return todos
        .where((todo) => todo.projectId == projectId && !todo.completed)
        .length;
  } catch (e) {
    return 0;
  }
}

/// Search UI state provider
final searchDialogOpenProvider = StateProvider<bool>((ref) => false);

/// Recent searches cache
final recentSearchesProvider =
    StateNotifierProvider<RecentSearchesNotifier, List<String>>((ref) {
      return RecentSearchesNotifier();
    });

class RecentSearchesNotifier extends StateNotifier<List<String>> {
  RecentSearchesNotifier() : super([]);

  void addSearch(String query) {
    if (query.trim().isEmpty) return;

    final normalized = query.trim();
    final updated = [
      normalized,
      ...state.where((q) => q != normalized),
    ].take(5).toList();

    state = updated;
  }

  void clearAll() {
    state = [];
  }
}
