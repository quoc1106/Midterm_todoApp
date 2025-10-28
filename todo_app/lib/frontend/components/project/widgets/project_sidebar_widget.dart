/// 🎨 FRONTEND - Project Sidebar Widget (SIMPLE VERSION)
///
/// ⭐ SIMPLIFIED FOR IMMEDIATE USAGE ⭐
/// Basic project sidebar without complex error handling

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/todo_providers.dart';
import '../../../../providers/project_providers.dart';
import '../../../../backend/models/project_model.dart';

class ProjectSidebarWidget extends ConsumerStatefulWidget {
  const ProjectSidebarWidget({super.key});

  @override
  ConsumerState<ProjectSidebarWidget> createState() =>
      _ProjectSidebarWidgetState();
}

class _ProjectSidebarWidgetState extends ConsumerState<ProjectSidebarWidget> {
  bool _isExpanded = false;
  String? _hoveredProjectId;

  @override
  Widget build(BuildContext context) {
    try {
      // Watch projects provider
      final projects = ref.watch(projectsProvider);
      final selectedSidebar = ref.watch(sidebarItemProvider);
      final selectedProjectId = ref.watch(selectedProjectIdProvider);

      return ExpansionTile(
        initiallyExpanded: selectedSidebar == SidebarItem.myProject,
        onExpansionChanged: (expanded) {
          if (mounted) {
            setState(() => _isExpanded = expanded);
          }
        },
        leading: Icon(
          Icons.work_outline,
          color: _isExpanded || selectedSidebar == SidebarItem.myProject
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'My Projects',
                style: TextStyle(
                  fontWeight: selectedSidebar == SidebarItem.myProject
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: selectedSidebar == SidebarItem.myProject
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),

            // Add project button
            IconButton(
              icon: const Icon(Icons.add, size: 16),
              onPressed: () => _showAddProjectDialog(context),
              tooltip: 'Add Project',
            ),
          ],
        ),
        children: [
          // Show projects list
          if (projects.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No projects yet. Create your first project!',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            )
          else
            ...projects.map(
              (project) =>
                  _buildProjectItem(context, project, selectedProjectId),
            ),
        ],
      );
    } catch (e) {
      // Simple error fallback
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              'Error loading projects',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Please try again later',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildProjectItem(
    BuildContext context,
    ProjectModel project,
    String? selectedProjectId,
  ) {
    final isSelected = selectedProjectId == project.id;
    final isHovered = _hoveredProjectId == project.id;

    return MouseRegion(
      onEnter: (_) {
        if (mounted) {
          setState(() => _hoveredProjectId = project.id);
        }
      },
      onExit: (_) {
        if (mounted) {
          setState(() => _hoveredProjectId = null);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : isHovered
              ? Theme.of(context).colorScheme.surfaceVariant
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          dense: true,
          leading: Icon(
            Icons.folder,
            size: 16,
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          title: Text(
            project.name,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          trailing: isHovered
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 14),
                      onPressed: () => _showEditProjectDialog(context, project),
                      tooltip: 'Edit Project',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 14),
                      onPressed: () =>
                          _showDeleteProjectDialog(context, project),
                      tooltip: 'Delete Project',
                    ),
                  ],
                )
              : null,
          onTap: () => _selectProject(context, project.id),
        ),
      ),
    );
  }

  void _selectProject(BuildContext context, String projectId) {
    try {
      ref.read(sidebarItemProvider.notifier).state = SidebarItem.myProject;
      ref.read(selectedProjectIdProvider.notifier).state = projectId;

      // Close drawer if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error selecting project: $e');
    }
  }

  void _showAddProjectDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Project'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Project Name',
            hintText: 'Enter project name...',
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              _addProject(value.trim());
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final projectName = controller.text.trim();
              if (projectName.isNotEmpty) {
                _addProject(projectName);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditProjectDialog(BuildContext context, ProjectModel project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Project'),
        content: TextField(
          decoration: const InputDecoration(labelText: 'Project Name'),
          controller: TextEditingController(text: project.name),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              _updateProject(project.id, value.trim());
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _updateProject(project.id, '${project.name} (edited)');
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteProjectDialog(BuildContext context, ProjectModel project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text('Are you sure you want to delete "${project.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteProject(project.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _addProject(String name) {
    try {
      ref.read(projectsProvider.notifier).addProject(name);
    } catch (e) {
      print('Error adding project: $e');
    }
  }

  void _updateProject(String id, String name) {
    try {
      ref.read(projectsProvider.notifier).updateProject(id, name);
    } catch (e) {
      print('Error updating project: $e');
    }
  }

  void _deleteProject(String id) {
    try {
      ref.read(projectsProvider.notifier).deleteProject(id);
    } catch (e) {
      print('Error deleting project: $e');
    }
  }
}
