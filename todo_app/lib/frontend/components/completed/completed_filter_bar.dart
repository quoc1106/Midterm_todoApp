import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/todo_providers.dart';
import '../../../backend/models/project_model.dart';

/// Widget filter bar cho completed tasks
class CompletedFilterBar extends ConsumerStatefulWidget {
  const CompletedFilterBar({super.key});

  @override
  ConsumerState<CompletedFilterBar> createState() => _CompletedFilterBarState();
}

class _CompletedFilterBarState extends ConsumerState<CompletedFilterBar> {
  bool _showProjectDropdown = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Watch search provider và sync với text controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchController.addListener(() {
        ref.read(completedProjectSearchProvider.notifier).state = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filterType = ref.watch(completedFilterTypeProvider);
    final selectedProjectId = ref.watch(completedSelectedProjectIdProvider);
    final projects = ref.watch(searchableProjectsProvider);
    final searchQuery = ref.watch(completedProjectSearchProvider);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter buttons row
          Row(
            children: [
              _buildFilterButton(
                context,
                'ALL',
                CompletedFilterType.all,
                filterType == CompletedFilterType.all,
              ),
              const SizedBox(width: 8),
              _buildFilterButton(
                context,
                'Daily Tasks',
                CompletedFilterType.dailyTasks,
                filterType == CompletedFilterType.dailyTasks,
              ),
              const SizedBox(width: 8),
              _buildFilterButton(
                context,
                'Projects',
                CompletedFilterType.projects,
                filterType == CompletedFilterType.projects,
              ),
            ],
          ),

          // Project dropdown section (show when Projects filter is selected)
          if (filterType == CompletedFilterType.projects) ...[
            const SizedBox(height: 12),
            _buildProjectSection(context, projects, selectedProjectId, searchQuery), // ✅ FIXED: Pass searchQuery parameter
          ],
        ],
      ),
    );
  }

  Widget _buildFilterButton(
    BuildContext context,
    String label,
    CompletedFilterType type,
    bool isSelected,
  ) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        ref.read(completedFilterTypeProvider.notifier).state = type;

        // Reset project selection when switching away from projects filter
        if (type != CompletedFilterType.projects) {
          ref.read(completedSelectedProjectIdProvider.notifier).state = null;
          ref.read(completedProjectSearchProvider.notifier).state = '';
          _searchController.clear();
          setState(() {
            _showProjectDropdown = false;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildProjectSection(
    BuildContext context,
    List<dynamic> projects,
    String? selectedProjectId,
    String searchQuery, // ✅ FIXED: Receive searchQuery parameter
  ) {
    final selectedProject = selectedProjectId != null
        ? projects.cast<dynamic>().firstWhere(
            (p) => p.id == selectedProjectId,
            orElse: () => null,
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected project display or "Select project" button
        InkWell(
          onTap: () {
            setState(() {
              _showProjectDropdown = !_showProjectDropdown;
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).cardColor,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    selectedProject != null
                        ? selectedProject.name
                        : 'Select a project...',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: selectedProject != null
                          ? Theme.of(context).textTheme.bodyLarge?.color
                          : Theme.of(context).hintColor,
                      fontSize: 14,
                    ),
                  ),
                ),
                Icon(
                  _showProjectDropdown
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Theme.of(context).iconTheme.color,
                ),
              ],
            ),
          ),
        ),

        // Project dropdown with search
        if (_showProjectDropdown) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).cardColor,
            ),
            child: Column(
              children: [
                // Search box
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search projects...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),

                // Project list
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      // "All Projects" option
                      ListTile(
                        dense: true,
                        title: const Text(
                          'All Projects',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        leading: Icon(
                          Icons.folder_open,
                          size: 18,
                          color: Theme.of(context).primaryColor,
                        ),
                        selected: selectedProjectId == null,
                        onTap: () {
                          ref.read(completedSelectedProjectIdProvider.notifier).state = null;
                          setState(() {
                            _showProjectDropdown = false;
                          });
                        },
                      ),
                      const Divider(height: 1),

                      // Individual projects
                      ...projects.map((project) => ListTile(
                        dense: true,
                        title: Text(
                          project.name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(fontSize: 14),
                        ),
                        leading: Icon(
                          Icons.folder,
                          size: 18,
                          color: Theme.of(context).primaryColor.withOpacity(0.7),
                        ),
                        selected: selectedProjectId == project.id,
                        onTap: () {
                          ref.read(completedSelectedProjectIdProvider.notifier).state = project.id;
                          setState(() {
                            _showProjectDropdown = false;
                          });
                        },
                      )),

                      // Empty state when no projects found
                      if (projects.isEmpty && searchQuery.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'No projects found for "${searchQuery}"',
                            style: TextStyle(
                              color: Theme.of(context).hintColor,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
