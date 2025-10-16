import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/search_providers.dart';
import '../../../providers/todo_providers.dart';
import '../todo/edit_todo_dialog.dart';
import 'search_result_item_widget.dart';

/// Command Palette style search dialog với thiết kế đẹp mắt
class SearchDialog extends ConsumerStatefulWidget {
  const SearchDialog({super.key});

  @override
  ConsumerState<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends ConsumerState<SearchDialog>
    with TickerProviderStateMixin {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();

    // Animation setup
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutQuart,
          ),
        );

    // Auto focus và start animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final results = ref.read(searchResultsProvider(_controller.text));

      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _selectedIndex =
              (_selectedIndex + 1) % (results.isNotEmpty ? results.length : 1);
        });
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _selectedIndex =
              (_selectedIndex - 1) % (results.isNotEmpty ? results.length : 1);
          if (_selectedIndex < 0) _selectedIndex = results.length - 1;
        });
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (results.isNotEmpty && _selectedIndex < results.length) {
          _selectResult(results[_selectedIndex]);
        }
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.of(context).pop();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  /// ⭐ RIVERPOD LEVEL 3: Enhanced Search Result Selection với Analytics
  void _selectResult(SearchResultItem item) {
    // Record analytics with Riverpod state management
    ref.read(searchAnalyticsProvider.notifier).recordResultClick(item.type);
    ref.read(recentSearchesProvider.notifier).addSearch(_controller.text);

    Navigator.of(context).pop();

    // Enhanced navigation logic with task editing
    if (item.type == SearchResultType.task) {
      // For tasks: show edit dialog instead of navigation (except completed)
      if (item.isCompleted) {
        // Completed tasks - navigate to Completed view
        ref.read(sidebarItemProvider.notifier).state = SidebarItem.completed;
      } else {
        // Non-completed tasks - show edit dialog
        _showTaskEditDialog(item);
      }
    } else if (item.type == SearchResultType.project) {
      // Switch to My Projects view and select project
      ref.read(sidebarItemProvider.notifier).state = SidebarItem.myProject;
      ref.read(selectedProjectIdProvider.notifier).state = item.id;
    } else if (item.type == SearchResultType.section) {
      // Navigate to project view for section
      ref.read(sidebarItemProvider.notifier).state = SidebarItem.myProject;
      ref.read(selectedProjectIdProvider.notifier).state = item.projectId;
    }
  }

  /// ⭐ RIVERPOD LEVEL 2: Task Edit Dialog với Provider Integration
  void _showTaskEditDialog(SearchResultItem item) {
    final todos = ref.read(todoListProvider);
    final todo = todos.firstWhere(
      (t) => t.id == item.id,
      orElse: () => throw StateError('Todo not found'),
    );

    showDialog(
      context: context,
      builder: (context) => EditTodoDialog(todo: todo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text;
    final results = ref.watch(searchResultsProvider(query));
    final recentSearches = ref.watch(recentSearchesProvider);
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.6,
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search Input Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: Focus(
                    onKeyEvent: (node, event) => _handleKeyEvent(event),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm tasks, projects, sections...',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                        suffixIcon: _controller.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                onPressed: () {
                                  _controller.clear();
                                  setState(() {
                                    _selectedIndex = 0;
                                  });
                                },
                                tooltip: 'Xóa tìm kiếm',
                              )
                            : null,
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.colorScheme.onSurface,
                      ),
                      onChanged: (value) {
                        ref.read(searchQueryProvider.notifier).state = value;
                        setState(() {
                          _selectedIndex = 0;
                        });

                        if (value.isNotEmpty) {
                          ref
                              .read(searchAnalyticsProvider.notifier)
                              .recordSearch(value);
                        }
                      },
                    ),
                  ),
                ),

                // Results Section
                Flexible(
                  child: query.isEmpty
                      ? _buildEmptyState(context, theme, recentSearches)
                      : _buildResults(context, theme, results),
                ),

                // Footer với shortcuts
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Always show cancel button with better design
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.3),
                              ),
                              color: Colors.red.withOpacity(0.1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Hủy',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${results.length} kết quả',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ThemeData theme,
    List<String> recentSearches,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recentSearches.isNotEmpty) ...[
            Text(
              'Recent Searches',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            ...recentSearches.map(
              (search) => _buildRecentSearchItem(context, theme, search),
            ),
            const SizedBox(height: 20),
          ],
          Text(
            'Mẹo tìm kiếm',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildTip(theme, Icons.task_outlined, 'Tìm kiếm theo tên task'),
          _buildTip(theme, Icons.folder_outlined, 'Tìm kiếm theo tên project'),
          _buildTip(theme, Icons.label_outlined, 'Tìm kiếm theo tên section'),
        ],
      ),
    );
  }

  Widget _buildResults(
    BuildContext context,
    ThemeData theme,
    List<SearchResultItem> results,
  ) {
    if (results.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords or check spelling',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.7,
                ),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        final isSelected = index == _selectedIndex;

        return SearchResultItemWidget(
          item: item,
          isSelected: isSelected,
          onTap: () => _selectResult(item),
        );
      },
    );
  }

  Widget _buildRecentSearchItem(
    BuildContext context,
    ThemeData theme,
    String search,
  ) {
    return InkWell(
      onTap: () {
        _controller.text = search;
        ref.read(searchQueryProvider.notifier).state = search;
        setState(() {
          _selectedIndex = 0;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Row(
          children: [
            Icon(
              Icons.history_rounded,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                search,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(ThemeData theme, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
