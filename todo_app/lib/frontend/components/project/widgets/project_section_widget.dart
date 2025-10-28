import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/performance_initialization_providers.dart';
import '../../../../providers/auth_providers.dart'; // 🔧 USER SEPARATION: Import for currentUserProvider
import '../../../../providers/project_providers.dart'; // 🔧 USER SEPARATION: Import for projectsProvider
import '../../../../providers/section_providers.dart'; // 🔧 USER SEPARATION: Import for sectionsByProjectProvider
import '../../../../providers/todo_providers.dart' show projectTodosProvider, sectionListNotifierProvider, allSectionsProvider, todoListProvider; // ✅ FIXED: Import projectTodosProvider
import '../../../../providers/task_filtering_providers.dart'; // ✅ NEW: Import for filteredTasksByMemberProvider
import '../../../../backend/utils/date_utils.dart' as app_date_utils;
import '../../../../backend/models/project_model.dart'; // 🔧 MISSING IMPORT: Add ProjectModel import
import '../../../../backend/models/section_model.dart';
import '../../todo/todo_item.dart';
import '../../todo/add_task_widget.dart';
import '../../shared_project/shared_project_indicator.dart'; // ✅ NEW: Import SharedProjectIndicator
import 'project_section_today_filter.dart'; // ✅ NEW: Import the filter widget

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
    /// ⭐ RIVERPOD LEVEL 2: Multiple Provider Watching với USER SEPARATION
    /// 🔧 USER SEPARATION: Sử dụng providers đã có user filtering
    final projects = ref.watch(projectsProvider); // 🔧 USER FILTERED: Chỉ projects của current user
    final sections = ref.watch(sectionsByProjectProvider(widget.projectId)); // 🔧 USER FILTERED: Chỉ sections của current user trong project này

    // ✅ FIXED: Use projectTasksWithFilterProvider for shared workspace collaboration
    // This shows ALL tasks in project (for team collaboration) with optional member filtering
    final todos = ref.watch(projectTasksWithFilterProvider(widget.projectId)); // 🔧 SHARED WORKSPACE: Show all team tasks

    // 🔧 USER SEPARATION: Handle case khi project không tồn tại hoặc không thuộc về current user
    ProjectModel? project;
    try {
      project = projects.firstWhere(
        (p) => p.id == widget.projectId,
      );
    } catch (e) {
      // Project not found hoặc không thuộc về current user
      print('⚠️ Project ${widget.projectId} not found or not owned by current user');
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Project not found',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This project may not exist or you don\'t have permission to access it.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate back to Today view
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.home),
                label: const Text('Go to Today'),
              ),
            ],
          ),
        ),
      );
    }

    final allProjectTodos = todos
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
              _buildSectionsTab(context, sections, todos),
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
                  overflow: TextOverflow.ellipsis, // ✅ NEW: Cắt ngắn tên project dài
                  maxLines: 1, // ✅ NEW: Giới hạn chỉ 1 dòng
                ),
              ),
              // ✅ NEW: Shared Project Indicator - biểu tượng nhóm bên cạnh tên project
              if (project != null)
                SharedProjectIndicator(
                  projectId: project.id,
                  projectName: project.name,
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
    // ✅ NEW: Use filtered today tasks count instead of basic count
    final filteredTodayCount = ref.watch(projectSectionTodayTasksProvider(widget.projectId)).length;

    return TabBar(
      controller: _tabController,
      tabs: [
        Tab(text: 'Sections ($sectionCount)'),
        Tab(text: 'Today ($filteredTodayCount)'),
        // Removed "All Tasks" tab
      ],
    );
  }

  Widget _buildSectionsTab(BuildContext context, List sections, todos) {
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
        final sectionTodos = todos
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
    // ✅ NEW: Use filtered today tasks instead of basic today todos
    final filteredTodayTasks = ref.watch(projectSectionTodayTasksProvider(widget.projectId));

    return Column(
      children: [
        // ✅ NEW: Add filter widget at the top
        ProjectSectionTodayFilter(projectId: widget.projectId),

        // Content area
        Expanded(
          child: filteredTodayTasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.today_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tasks for today',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tasks scheduled for today will appear here',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredTodayTasks.length,
                  itemBuilder: (context, index) {
                    return TodoItem(todo: filteredTodayTasks[index]);
                  },
                ),
        ),
      ],
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
    // 🔧 USER SEPARATION: Sử dụng SectionListNotifier thay vì raw box
    final currentUser = ref.read(currentUserProvider);

    if (currentUser == null) {
      print('❌ Cannot add section: No current user');
      return;
    }

    try {
      // Sử dụng SectionListNotifier đã có user separation logic
      final sectionNotifier = ref.read(sectionListNotifierProvider(widget.projectId).notifier);
      sectionNotifier.addSection(name);
      print('🔍 Added section "$name" to project ${widget.projectId} for user: ${currentUser.id}');
    } catch (e) {
      print('❌ Error adding section: $e');
    }
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
    print('🔍 Deleting section: $sectionId');

    // ✅ RIVERPOD PATTERN: Use StateNotifier instead of direct box manipulation
    ref.read(sectionListNotifierProvider(widget.projectId).notifier)
        .deleteSection(sectionId);

    // ✅ ENHANCED: Force UI refresh by invalidating providers
    try {
      ref.invalidate(sectionsByProjectProvider(widget.projectId));
      ref.invalidate(todoListProvider);
      ref.invalidate(allSectionsProvider);
      print('🔄 Invalidated providers after deleting section');
    } catch (e) {
      print('⚠️ Error invalidating providers: $e');
    }

    // ✅ ENHANCED: Close any expanded sections
    setState(() {
      if (_expandedSectionId == sectionId) {
        _expandedSectionId = null;
      }
      if (_addingTaskToSectionId == sectionId) {
        _addingTaskToSectionId = null;
      }
    });

    print('🔄 Section deletion completed');
  }
}
