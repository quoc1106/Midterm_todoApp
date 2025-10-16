/// 🎨 FRONTEND - Project Section Picker Row Component
///
/// ⭐ RIVERPOD LEVEL 2-3 DEMONSTRATION ⭐
/// Đây là PURE FRONTEND - project/section selection UI với advanced Riverpod patterns
/// Combines multiple providers for complex selection logic
///
/// LEVEL 2: Multiple provider coordination và conditional rendering
/// LEVEL 3: Provider dependencies và async state management

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/performance_initialization_providers.dart';
import 'project_section_picker_dialog.dart';

class ProjectSectionPickerRow extends ConsumerWidget {
  final String? projectId;
  final String? projectName;
  final String? sectionId;
  final String? sectionName;
  final void Function(
    String? projectId,
    String? projectName,
    String? sectionId,
    String? sectionName,
  )
  onSelected;
  final bool enabled;
  final bool showEverydayOption;

  const ProjectSectionPickerRow({
    super.key,
    this.projectId,
    this.projectName,
    this.sectionId,
    this.sectionName,
    required this.onSelected,
    this.enabled = true,
    this.showEverydayOption = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// ⭐ RIVERPOD LEVEL 2: Multiple Provider Watching
    /// Watch for project and section data changes

    final projectBox = ref.watch(projectBoxProvider);
    final sectionBox = ref.watch(sectionBoxProvider);

    return IntrinsicWidth(
      child: GestureDetector(
        onTap: enabled ? () => _showPicker(context, ref) : null,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 350),
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          decoration: BoxDecoration(
            border: Border.all(
              color: enabled
                  ? Theme.of(context).colorScheme.outline
                  : Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(8),
            color: enabled
                ? Theme.of(context).colorScheme.surface
                : Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// ⭐ LEVEL 2: Smart Icon Based on Selection State
              Icon(
                _getSelectionIcon(),
                size: 18,
                color: _getSelectionColor(context),
              ),
              const SizedBox(width: 8),

              /// ⭐ LEVEL 2: Dynamic Text Based on State
              Flexible(
                child: Text(
                  _getDisplayText(projectBox, sectionBox),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: enabled
                        ? _getSelectionColor(context)
                        : Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),

              /// Dropdown indicator
              Icon(
                Icons.expand_more,
                size: 18,
                color: enabled
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ⭐ LEVEL 3: Async Dialog Integration
  Future<void> _showPicker(BuildContext context, WidgetRef ref) async {
    final result = await showProjectSectionPickerDialog(
      context,
      ref,
      currentProjectId: projectId,
      currentSectionId: sectionId,
      showEverydayOption: showEverydayOption,
    );

    if (result != null) {
      onSelected(
        result['projectId'],
        result['projectName'],
        result['sectionId'],
        result['sectionName'],
      );
    }
  }

  /// ⭐ FRONTEND HELPER METHODS ⭐
  /// Pure UI logic methods

  IconData _getSelectionIcon() {
    if (projectId == null) {
      return Icons.today_outlined; // Everyday task
    } else if (sectionId != null) {
      return Icons.folder_outlined; // Section
    } else {
      return Icons.work_outline; // Project only
    }
  }

  Color _getSelectionColor(BuildContext context) {
    if (projectId == null) {
      return Theme.of(context).colorScheme.primary;
    } else if (sectionId != null) {
      return Theme.of(context).colorScheme.secondary;
    } else {
      return Theme.of(context).colorScheme.tertiary;
    }
  }

  String _getDisplayText(projectBox, sectionBox) {
    if (projectId == null) {
      return showEverydayOption ? 'Everyday Task' : 'No Project';
    }

    /// ⭐ LEVEL 2: Provider Data Validation
    /// Validate that the referenced project still exists
    final project = projectBox.get(projectId!);
    final displayProjectName =
        project?.name ?? projectName ?? 'Unknown Project';

    if (sectionId == null) {
      return '# $displayProjectName';
    }

    /// Validate section exists and belongs to project
    final section = sectionBox.get(sectionId!);
    if (section == null || section.projectId != projectId) {
      return '# $displayProjectName / [Deleted Section]';
    }

    final displaySectionName = section.name;
    return '# $displayProjectName / $displaySectionName';
  }
}

/// ⭐ RIVERPOD LEVEL 3: Enhanced Project Section Picker
/// Advanced version with validation and state management
class EnhancedProjectSectionPicker extends ConsumerStatefulWidget {
  final String? initialProjectId;
  final String? initialSectionId;
  final void Function(String? projectId, String? sectionId) onChanged;
  final bool allowEverydayTasks;
  final String label;

  const EnhancedProjectSectionPicker({
    super.key,
    this.initialProjectId,
    this.initialSectionId,
    required this.onChanged,
    this.allowEverydayTasks = true,
    this.label = 'Select Project & Section',
  });

  @override
  ConsumerState<EnhancedProjectSectionPicker> createState() =>
      _EnhancedProjectSectionPickerState();
}

class _EnhancedProjectSectionPickerState
    extends ConsumerState<EnhancedProjectSectionPicker> {
  String? _selectedProjectId;
  String? _selectedSectionId;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _selectedProjectId = widget.initialProjectId;
    _selectedSectionId = widget.initialSectionId;
  }

  @override
  Widget build(BuildContext context) {
    /// ⭐ RIVERPOD LEVEL 3: Complex Provider Dependencies
    /// Watch multiple providers and handle state changes

    final projectBox = ref.watch(projectBoxProvider);
    final sectionBox = ref.watch(sectionBoxProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header with expand/collapse
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Row(
                children: [
                  Text(
                    widget.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),

            const SizedBox(height: 8),

            /// Current selection display
            _buildCurrentSelection(context, projectBox, sectionBox),

            /// ⭐ LEVEL 3: Expandable Selection Interface
            if (_isExpanded) ...[
              const SizedBox(height: 16),
              _buildProjectSelection(context, projectBox),
              if (_selectedProjectId != null) ...[
                const SizedBox(height: 12),
                _buildSectionSelection(context, sectionBox),
              ],
            ],
          ],
        ),
      ),
    );
  }

  /// ⭐ LEVEL 3: Current Selection Display
  Widget _buildCurrentSelection(BuildContext context, projectBox, sectionBox) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _getSelectionIcon(),
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getCurrentSelectionText(projectBox, sectionBox),
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _isExpanded = !_isExpanded),
            icon: const Icon(Icons.edit),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  /// ⭐ LEVEL 3: Project Selection Grid
  Widget _buildProjectSelection(BuildContext context, projectBox) {
    final projects = projectBox.values.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Project:', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),

        /// Everyday task option
        if (widget.allowEverydayTasks)
          _buildProjectOption(
            context,
            id: null,
            name: 'Everyday Task',
            icon: Icons.today,
            isSelected: _selectedProjectId == null,
          ),

        /// Project grid
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: projects.map((project) {
            return _buildProjectOption(
              context,
              id: project.id,
              name: project.name,
              icon: Icons.work_outline,
              isSelected: _selectedProjectId == project.id,
            );
          }).toList(),
        ),
      ],
    );
  }

  /// ⭐ LEVEL 3: Section Selection
  Widget _buildSectionSelection(BuildContext context, sectionBox) {
    final sections = sectionBox.values
        .where((section) => section.projectId == _selectedProjectId)
        .toList();

    if (sections.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'No sections in this project',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Section (Optional):',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),

        /// No section option
        _buildSectionOption(
          context,
          id: null,
          name: 'No Section',
          isSelected: _selectedSectionId == null,
        ),

        /// Section list
        ...sections.map((section) {
          return _buildSectionOption(
            context,
            id: section.id,
            name: section.name,
            isSelected: _selectedSectionId == section.id,
          );
        }),
      ],
    );
  }

  /// ⭐ LEVEL 3: Project Option Builder
  Widget _buildProjectOption(
    BuildContext context, {
    required String? id,
    required String name,
    required IconData icon,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedProjectId = id;
          _selectedSectionId = null; // Reset section when project changes
        });
        widget.onChanged(_selectedProjectId, _selectedSectionId);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
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
    );
  }

  /// ⭐ LEVEL 3: Section Option Builder
  Widget _buildSectionOption(
    BuildContext context, {
    required String? id,
    required String name,
    required bool isSelected,
  }) {
    return ListTile(
      leading: Icon(
        id == null ? Icons.remove : Icons.folder_outlined,
        size: 20,
      ),
      title: Text(name),
      selected: isSelected,
      onTap: () {
        setState(() {
          _selectedSectionId = id;
        });
        widget.onChanged(_selectedProjectId, _selectedSectionId);
      },
    );
  }

  /// ⭐ FRONTEND HELPER METHODS ⭐

  IconData _getSelectionIcon() {
    if (_selectedProjectId == null) return Icons.today;
    if (_selectedSectionId != null) return Icons.folder_outlined;
    return Icons.work_outline;
  }

  String _getCurrentSelectionText(projectBox, sectionBox) {
    if (_selectedProjectId == null) {
      return widget.allowEverydayTasks
          ? 'Everyday Task'
          : 'No Project Selected';
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
