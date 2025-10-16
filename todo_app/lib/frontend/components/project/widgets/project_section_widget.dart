import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/performance_initialization_providers.dart';
import '../../../../backend/utils/date_utils.dart' as app_date_utils;
import '../../../../backend/models/section_model.dart';
import '../../todo/todo_item.dart';
import '../../todo/add_task_widget.dart';

class ProjectSectionWidget extends ConsumerStatefulWidget {
  final String projectId;
  final String? projectName;

  const ProjectSectionWidget({
    super.key,
    required this.projectId,
    this.projectName,
  });

  @override
  ConsumerState<ProjectSectionWidget> createState() =>
      _ProjectSectionWidgetState();
}

class _ProjectSectionWidgetState extends ConsumerState<ProjectSectionWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String? _expandedSectionId;
  String? _addingTaskToSectionId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
    ); // Changed from 3 to 2
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// ⭐ RIVERPOD LEVEL 2: Multiple Provider Watching
    /// These ref.watch() calls make widget reactive to data changes:
    final projectBox = ref.watch(projectBoxProvider); // Project data
    final sectionBox = ref.watch(sectionBoxProvider); // Section data
    final todoBox = ref.watch(todoBoxProvider); // Todo data
    /// Widget rebuilds automatically when any box content changes

    final project = projectBox.get(widget.projectId);
    final sections = sectionBox.values
        .where((section) => section.projectId == widget.projectId)
        .toList();

    final allProjectTodos = todoBox.values
        .where((todo) => todo.projectId == widget.projectId)
        .toList();

    /// ⭐ RIVERPOD LEVEL 2: Derived State Calculation
    /// Filtered data that auto-updates when todoBox changes
    final todayTodos = allProjectTodos
        .where(
          (todo) =>
              !todo.completed && // Filter out completed tasks
              todo.dueDate != null &&
              app_date_utils.DateUtils.isToday(todo.dueDate!),
        )
        .toList();

    return Column(
      children: [
        // FIXED: Compact header with stats inline - no search bar
        _buildCompactHeader(context, project, sections, allProjectTodos),

        // Tab bar
        _buildTabBar(context, sections.length, todayTodos.length),

        // Content area
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSectionsTab(context, sections, todoBox),
              _buildTodayTab(context, todayTodos),
              // Removed _buildAllTasksTab
            ],
          ),
        ),
      ],
    );
  }

  /// ⭐ RIVERPOD LEVEL 2: Reactive Stats Header
  /// Uses multiple Riverpod providers for real-time data:
  /// - projectBoxProvider: Project info with auto-refresh
  /// - sectionBoxProvider: Section count with reactive updates
  /// - todoBoxProvider: Todo counts with live updates
  /// Widget rebuilds automatically when any underlying data changes
  Widget _buildCompactHeader(
    BuildContext context,
    project,
    List sections,
    List allTodos,
  ) {
    /// ⭐ RIVERPOD LEVEL 2: Reactive calculations
    /// These values auto-update when todoBox changes via ref.watch()
    final activeTodos = allTodos.where((todo) => !todo.completed).length;
    final completedTodos = allTodos.length - activeTodos;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project name row
          Row(
            children: [
              Icon(
                Icons.work_outline,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  project?.name ?? widget.projectName ?? 'Unknown Project',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Stats row below project name
          Row(
            children: [
              _buildStatChip(
                context,
                '${sections.length}',
                'Sections',
                Icons.folder_outlined,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                context,
                '$activeTodos',
                'Active',
                Icons.radio_button_unchecked,
                Colors.blue,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                context,
                '$completedTodos',
                'Done',
                Icons.check_circle_outline,
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ⭐ RIVERPOD LEVEL 2: Stats Chip với Real-time Data
  /// Dữ liệu được reactive từ Riverpod providers:
  /// - projectBoxProvider: Auto-refresh khi project thay đổi
  /// - sectionBoxProvider: Auto-refresh khi section thay đổi
  /// - todoBoxProvider: Auto-refresh khi todo thay đổi
  /// Widget này rebuild automatically khi underlying data changes
  Widget _buildStatChip(
    BuildContext context,
    String value,
    String label,
    IconData icon, [
    Color? color,
  ]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (color ?? Theme.of(context).colorScheme.onSurface).withValues(
            alpha: 0.2,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color ?? Theme.of(context).colorScheme.onSurface,
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: color ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: (color ?? Theme.of(context).colorScheme.onSurface)
                  .withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, int sectionCount, int todayCount) {
    return TabBar(
      controller: _tabController,
      tabs: [
        Tab(text: 'Sections ($sectionCount)'),
        Tab(text: 'Today ($todayCount)'),
        // Removed "All Tasks" tab
      ],
    );
  }

  Widget _buildSectionsTab(BuildContext context, List sections, todoBox) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sections.length + 1,
      itemBuilder: (context, index) {
        // Move Add button to top (index 0)
        if (index == 0) {
          return _buildAddSectionButton(context);
        }

        // Sections start from index 1
        final section = sections[index - 1];
        final sectionTodos = todoBox.values
            .where(
              (todo) =>
                  todo.sectionId == section.id &&
                  !todo.completed, // Filter out completed tasks
            )
            .toList();

        return _buildSectionCard(context, section, sectionTodos);
      },
    );
  }

  Widget _buildTodayTab(BuildContext context, List todayTodos) {
    if (todayTodos.isEmpty) {
      return Center(child: Text('No tasks for today'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: todayTodos.length,
      itemBuilder: (context, index) {
        return TodoItem(todo: todayTodos[index]);
      },
    );
  }

  // Removed _buildAllTasksTab method as "All Tasks" tab was removed

  Widget _buildAddSectionButton(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showAddSectionDialog(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.add_circle_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Add New Section',
                style: TextStyle(
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

  Widget _buildSectionCard(BuildContext context, section, List sectionTodos) {
    final activeTodos = sectionTodos.where((todo) => !todo.completed).length;
    final completedTodos = sectionTodos.length - activeTodos;
    final isExpanded = _expandedSectionId == section.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        key: ValueKey(section.id),
        initiallyExpanded: isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _expandedSectionId = expanded ? section.id : null;
          });
        },
        leading: Icon(
          Icons.folder,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                section.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            // Compact stats with colored icons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.radio_button_unchecked,
                  size: 16,
                  color: Colors.blue,
                ),
                const SizedBox(width: 2),
                Text(
                  '$activeTodos',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.check_circle, size: 16, color: Colors.green),
                const SizedBox(width: 2),
                Text(
                  '$completedTodos',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 20),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'rename',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, size: 16),
                  SizedBox(width: 8),
                  Text('Rename'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'rename':
                _showRenameSectionDialog(context, section);
                break;
              case 'delete':
                _showDeleteSectionDialog(context, section);
                break;
            }
          },
        ),
        children: [
          ...sectionTodos.map<Widget>((todo) => TodoItem(todo: todo)),

          // Add task for this section
          if (_addingTaskToSectionId == section.id)
            Padding(
              padding: const EdgeInsets.all(16),
              child: AddTaskWidget(
                presetProjectId: widget.projectId,
                presetSectionId: section.id,
                showCancel: true,
                onCancel: () {
                  setState(() {
                    _addingTaskToSectionId = null;
                  });
                },
                onTaskAdded: () {
                  setState(() {
                    _addingTaskToSectionId = null;
                  });
                },
              ),
            )
          else
            ListTile(
              leading: Icon(
                Icons.add,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'Add task to ${section.name}',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
              onTap: () {
                setState(() {
                  _addingTaskToSectionId = section.id;
                });
              },
            ),
        ],
      ),
    );
  }

  void _showAddSectionDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Section'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Section Name',
            hintText: 'Enter section name...',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                _addSection(name);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addSection(String name) {
    final sectionBox = ref.read(enhancedSectionBoxProvider);
    final newSection = SectionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      projectId: widget.projectId,
    );
    sectionBox.put(newSection.id, newSection);
    setState(() {});
  }

  void _showRenameSectionDialog(BuildContext context, SectionModel section) {
    final TextEditingController controller = TextEditingController(
      text: section.name,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Section'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Section Name',
            hintText: 'Enter new section name...',
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              _renameSection(section.id, value.trim());
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
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                _renameSection(section.id, newName);
                Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showDeleteSectionDialog(BuildContext context, SectionModel section) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Section'),
        content: Text(
          'Are you sure you want to delete "${section.name}"? This will also delete all tasks in this section.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteSection(section.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _renameSection(String sectionId, String newName) {
    final sectionBox = ref.read(enhancedSectionBoxProvider);
    final section = sectionBox.get(sectionId);
    if (section != null) {
      section.name = newName;
      sectionBox.put(sectionId, section);
      setState(() {});
    }
  }

  void _deleteSection(String sectionId) {
    final sectionBox = ref.read(enhancedSectionBoxProvider);
    final todoBox = ref.read(todoBoxProvider);

    // Delete all tasks in this section
    final tasksToDelete = todoBox.values
        .where((todo) => todo.sectionId == sectionId)
        .toList();

    for (final task in tasksToDelete) {
      // Find and delete by key
      final keys = todoBox.keys.toList();
      for (final key in keys) {
        final todoValue = todoBox.get(key);
        if (todoValue?.id == task.id) {
          todoBox.delete(key);
          break;
        }
      }
    }

    // Delete the section
    sectionBox.delete(sectionId);
    setState(() {});
  }
}
