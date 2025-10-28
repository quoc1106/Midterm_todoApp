import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/task_filtering_providers.dart';
import '../../../../providers/shared_project_providers.dart';
import '../../../../providers/auth_providers.dart';
import '../../../../backend/models/user.dart';

/// 🎯 PROJECT SECTION TODAY FILTER WIDGET
///
/// ⭐ RIVERPOD LEVEL 2-4 DEMONSTRATION ⭐
/// Widget để filter tasks trong Today view của project section
/// Cho phép chọn member hoặc xem unassigned tasks

class ProjectSectionTodayFilter extends ConsumerWidget {
  final String projectId;

  const ProjectSectionTodayFilter({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(projectSectionTodayFilterProvider);
    final projectMembers = ref.watch(projectMembersProvider(projectId));
    final currentUser = ref.watch(currentUserProvider);
    final unassignedCount = ref.watch(projectSectionTodayUnassignedCountProvider(projectId));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_list,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Filter Today Tasks',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // ✅ REMOVED: Clear Filter button - users can click filters to toggle
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              // All tasks chip
              _buildFilterChip(
                context,
                ref,
                label: 'All Tasks',
                isSelected: selectedFilter == null,
                onTap: () {
                  // ✅ NEW: Toggle functionality - clicking "All Tasks" when selected does nothing
                  // Clicking "All Tasks" when another filter is active clears the filter
                  if (selectedFilter != null) {
                    ref.read(projectSectionTodayFilterProvider.notifier).state = null;
                  }
                },
              ),

              // Unassigned tasks chip
              _buildFilterChip(
                context,
                ref,
                label: 'Unassigned ($unassignedCount)',
                isSelected: selectedFilter == 'unassigned',
                onTap: unassignedCount > 0 ? () {
                  // ✅ NEW: Toggle functionality for unassigned filter
                  final currentFilter = ref.read(projectSectionTodayFilterProvider);
                  if (currentFilter == 'unassigned') {
                    // If already selected, clear filter
                    ref.read(projectSectionTodayFilterProvider.notifier).state = null;
                  } else {
                    // If not selected, apply unassigned filter
                    ref.read(projectSectionTodayFilterProvider.notifier).state = 'unassigned';
                  }
                } : null,
                icon: Icons.person_off,
              ),

              // ✅ NEW: Members filter button - opens dialog instead of individual chips
              _buildMembersFilterButton(context, ref, projectMembers, selectedFilter),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required bool isSelected,
    required VoidCallback? onTap,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final isEnabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : isEnabled
                  ? theme.colorScheme.surfaceVariant
                  : theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : isEnabled
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : isEnabled
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Members filter button that opens a selection dialog
  Widget _buildMembersFilterButton(
    BuildContext context,
    WidgetRef ref,
    List projectMembers,
    String? selectedFilter,
  ) {
    // Count selected member's tasks if a member filter is active
    int selectedMemberCount = 0;
    String? selectedMemberName;

    if (selectedFilter != null && selectedFilter != 'unassigned') {
      // ✅ FIXED: Proper type handling for firstWhere orElse parameter
      dynamic member;
      try {
        member = projectMembers.firstWhere(
          (m) => m.userId == selectedFilter,
        );
      } catch (e) {
        member = null; // Member not found
      }

      if (member != null) {
        selectedMemberCount = ref.watch(projectSectionTodayMemberCountProvider({
          'projectId': projectId,
          'memberId': selectedFilter,
        }));
        selectedMemberName = member.userDisplayName;
      }
    }

    final isSelected = selectedFilter != null && selectedFilter != 'unassigned';

    return _buildFilterChip(
      context,
      ref,
      label: isSelected
          ? '$selectedMemberName ($selectedMemberCount)'
          : 'Members',
      isSelected: isSelected,
      onTap: () {
        if (isSelected) {
          // ✅ NEW: Toggle - if member filter is active, clear it
          ref.read(projectSectionTodayFilterProvider.notifier).state = null;
        } else {
          // ✅ NEW: Open member selection dialog
          _showMemberSelectionDialog(context, ref, projectMembers);
        }
      },
      icon: isSelected ? Icons.person : Icons.people,
    );
  }

  // ✅ NEW: Show member selection dialog
  void _showMemberSelectionDialog(
    BuildContext context,
    WidgetRef ref,
    List projectMembers,
  ) {
    final currentUser = ref.read(currentUserProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.people, size: 20),
            const SizedBox(width: 8),
            Text('Select Member'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: projectMembers.length,
            itemBuilder: (context, index) {
              final member = projectMembers[index];
              final taskCount = ref.watch(projectSectionTodayMemberCountProvider({
                'projectId': projectId,
                'memberId': member.userId,
              }));

              final isCurrentUser = member.userId == currentUser?.id;
              final hasTasksToday = taskCount > 0;

              return ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: isCurrentUser
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Theme.of(context).colorScheme.surfaceVariant,
                  child: Icon(
                    isCurrentUser ? Icons.person : Icons.person_outline,
                    size: 16,
                    color: isCurrentUser
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        member.userDisplayName,
                        style: TextStyle(
                          fontWeight: isCurrentUser ? FontWeight.w600 : FontWeight.normal,
                          color: hasTasksToday
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: hasTasksToday
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$taskCount',
                        style: TextStyle(
                          color: hasTasksToday
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: isCurrentUser
                    ? Text(
                        'You',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 12,
                        ),
                      )
                    : null,
                enabled: hasTasksToday,
                onTap: hasTasksToday ? () {
                  ref.read(projectSectionTodayFilterProvider.notifier).state = member.userId;
                  Navigator.of(context).pop();
                } : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
