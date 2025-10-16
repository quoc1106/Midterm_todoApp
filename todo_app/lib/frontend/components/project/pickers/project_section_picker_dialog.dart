/// 🎨 FRONTEND - Project Section Picker Dialog
///
/// ⭐ RIVERPOD LEVEL 3-4 DEMONSTRATION ⭐
/// Đây là PURE FRONTEND - advanced selection dialog với complex provider patterns
/// Shows sophisticated provider combinations and async state management
///
/// LEVEL 3: Provider dependencies với validation và error handling
/// LEVEL 4: Complex provider combinations với async operations

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/performance_initialization_providers.dart';

/// Enhanced project section picker dialog function
Future<Map<String, String?>?> showProjectSectionPickerDialog(
  BuildContext context,
  WidgetRef ref, {
  String? currentProjectId,
  String? currentSectionId,
  bool showEverydayOption = true,
}) async {
  return showDialog<Map<String, String?>>(
    context: context,
    builder: (context) => ProjectSectionPickerDialog(
      currentProjectId: currentProjectId,
      currentSectionId: currentSectionId,
      showEverydayOption: showEverydayOption,
    ),
  );
}

class ProjectSectionPickerDialog extends ConsumerStatefulWidget {
  final String? currentProjectId;
  final String? currentSectionId;
  final bool showEverydayOption;

  const ProjectSectionPickerDialog({
    super.key,
    this.currentProjectId,
    this.currentSectionId,
    this.showEverydayOption = true,
  });

  @override
  ConsumerState<ProjectSectionPickerDialog> createState() =>
      _ProjectSectionPickerDialogState();
}

class _ProjectSectionPickerDialogState
    extends ConsumerState<ProjectSectionPickerDialog> {
  String? _selectedProjectId;
  String? _selectedSectionId;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedProjectId = widget.currentProjectId;
    _selectedSectionId = widget.currentSectionId;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// ⭐ RIVERPOD LEVEL 3: Multiple Box Providers
    /// Advanced provider coordination for data access

    final projectBox = ref.watch(projectBoxProvider);
    final sectionBox = ref.watch(sectionBoxProvider);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.folder_outlined),
          const SizedBox(width: 8),
          const Text('Select Project & Section'),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        height: 500,
        child: Column(
          children: [
            /// ⭐ LEVEL 3: Search Filter Integration
            _buildSearchField(context),
            const SizedBox(height: 16),

            /// ⭐ LEVEL 3: Selection Summary
            _buildSelectionSummary(context, projectBox, sectionBox),
            const SizedBox(height: 16),

            /// ⭐ LEVEL 3: Filterable Project List
            Expanded(child: _buildProjectList(context, projectBox, sectionBox)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => _confirmSelection(context, projectBox, sectionBox),
          child: const Text('Select'),
        ),
      ],
    );
  }

  /// ⭐ LEVEL 3: Search Field with Real-time Filtering
  Widget _buildSearchField(BuildContext context) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: 'Search projects...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                icon: const Icon(Icons.clear),
              )
            : null,
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) {
        setState(() => _searchQuery = value.toLowerCase());
      },
    );
  }

  /// ⭐ LEVEL 3: Selection Summary Display
  Widget _buildSelectionSummary(BuildContext context, projectBox, sectionBox) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _getSelectionIcon(),
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getSelectionText(projectBox, sectionBox),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ⭐ LEVEL 3: Filterable Project List
  Widget _buildProjectList(BuildContext context, projectBox, sectionBox) {
    final projects = projectBox.values.toList();
    final filteredProjects = _searchQuery.isEmpty
        ? projects
        : projects
              .where(
                (project) => project.name.toLowerCase().contains(_searchQuery),
              )
              .toList();

    return ListView(
      children: [
        /// ⭐ LEVEL 3: Everyday Task Option (if enabled)
        if (widget.showEverydayOption) _buildEverydayTaskOption(context),

        if (widget.showEverydayOption && filteredProjects.isNotEmpty)
          const Divider(),

        /// ⭐ LEVEL 3: Filtered Project List
        ...filteredProjects.map(
          (project) => _buildProjectTile(context, project, sectionBox),
        ),

        /// Empty state
        if (filteredProjects.isEmpty && _searchQuery.isNotEmpty)
          _buildEmptySearchState(context),
      ],
    );
  }

  /// ⭐ LEVEL 3: Everyday Task Option
  Widget _buildEverydayTaskOption(BuildContext context) {
    final isSelected = _selectedProjectId == null;

    return ListTile(
      leading: Icon(
        Icons.today,
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(
        'Everyday Task',
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: const Text('Not assigned to any project'),
      selected: isSelected,
      onTap: () {
        setState(() {
          _selectedProjectId = null;
          _selectedSectionId = null;
        });
      },
    );
  }

  /// ⭐ LEVEL 3: Project Tile with Sections
  Widget _buildProjectTile(BuildContext context, project, sectionBox) {
    final isSelected = _selectedProjectId == project.id;
    final sections = sectionBox.values
        .where((section) => section.projectId == project.id)
        .toList();

    return ExpansionTile(
      leading: Icon(
        Icons.work_outline,
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(
        project.name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text('${sections.length} sections'),
      initiallyExpanded: isSelected,
      onExpansionChanged: (expanded) {
        if (expanded) {
          setState(() {
            _selectedProjectId = project.id;
            if (sections.isEmpty) {
              _selectedSectionId = null;
            }
          });
        }
      },
      children: [
        /// No section option
        ListTile(
          leading: const Icon(Icons.remove),
          title: const Text('No Section'),
          subtitle: const Text('Project only'),
          selected: isSelected && _selectedSectionId == null,
          onTap: () {
            setState(() {
              _selectedProjectId = project.id;
              _selectedSectionId = null;
            });
          },
        ),

        /// Section options
        ...sections.map((section) {
          final isSectionSelected =
              isSelected && _selectedSectionId == section.id;

          return ListTile(
            leading: Icon(
              Icons.folder_outlined,
              color: isSectionSelected
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: Text(
              section.name,
              style: TextStyle(
                fontWeight: isSectionSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: isSectionSelected
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            selected: isSectionSelected,
            onTap: () {
              setState(() {
                _selectedProjectId = project.id;
                _selectedSectionId = section.id;
              });
            },
          );
        }),
      ],
    );
  }

  /// ⭐ LEVEL 3: Empty Search State
  Widget _buildEmptySearchState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No projects found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search query',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// ⭐ LEVEL 3: Confirm Selection
  void _confirmSelection(BuildContext context, projectBox, sectionBox) {
    String? projectName;
    String? sectionName;

    /// ⭐ LEVEL 3: Provider Data Validation
    if (_selectedProjectId != null) {
      final project = projectBox.get(_selectedProjectId!);
      projectName = project?.name;

      if (_selectedSectionId != null) {
        final section = sectionBox.get(_selectedSectionId!);
        sectionName = section?.name;
      }
    }

    Navigator.of(context).pop({
      'projectId': _selectedProjectId,
      'projectName': projectName,
      'sectionId': _selectedSectionId,
      'sectionName': sectionName,
    });
  }

  /// ⭐ FRONTEND HELPER METHODS ⭐

  IconData _getSelectionIcon() {
    if (_selectedProjectId == null) return Icons.today;
    if (_selectedSectionId != null) return Icons.folder_outlined;
    return Icons.work_outline;
  }

  String _getSelectionText(projectBox, sectionBox) {
    if (_selectedProjectId == null) {
      return 'Everyday Task';
    }

    final project = projectBox.get(_selectedProjectId!);
    final projectName = project?.name ?? 'Unknown Project';

    if (_selectedSectionId == null) {
      return '# $projectName';
    }

    final section = sectionBox.get(_selectedSectionId!);
    final sectionName = section?.name ?? 'Unknown Section';
    return '# $projectName / $sectionName';
  }
}

/// ⭐ RIVERPOD LEVEL 4: Quick Project Selector
/// Advanced component demonstrating provider composition patterns
class QuickProjectSelector extends ConsumerWidget {
  final String? currentProjectId;
  final void Function(String? projectId) onProjectSelected;
  final bool showCreateOption;

  const QuickProjectSelector({
    super.key,
    this.currentProjectId,
    required this.onProjectSelected,
    this.showCreateOption = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// ⭐ RIVERPOD LEVEL 4: Advanced Provider Composition
    /// Complex state management with computed values

    final projectBox = ref.watch(projectBoxProvider);
    final projects = projectBox.values.toList();

    return Container(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount:
            projects.length +
            (showCreateOption ? 2 : 1), // +1 for everyday, +1 for create
        itemBuilder: (context, index) {
          if (index == 0) {
            // Everyday task option
            return _buildQuickOption(
              context,
              id: null,
              name: 'Everyday',
              icon: Icons.today,
              isSelected: currentProjectId == null,
            );
          } else if (showCreateOption && index == projects.length + 1) {
            // Create new project option
            return _buildCreateOption(context);
          } else {
            // Project options
            final project = projects[index - 1];
            return _buildQuickOption(
              context,
              id: project.id,
              name: project.name,
              icon: Icons.work_outline,
              isSelected: currentProjectId == project.id,
            );
          }
        },
      ),
    );
  }

  Widget _buildQuickOption(
    BuildContext context, {
    required String? id,
    required String name,
    required IconData icon,
    required bool isSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => onProjectSelected(id),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surface,
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateOption(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          // Handle create new project
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Create new project feature coming soon!'),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'New Project',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
