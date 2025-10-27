/// 🎯 PROJECT MEMBERS DIALOG - Enhanced with Task Counts and Filtering
///
/// Display project members with task assignment counts and filtering capabilities
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/shared_project_providers.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/todo_providers.dart';
import '../../../providers/project_providers.dart';
import 'invite_user_widget.dart';
import 'project_member_item.dart';

// ✅ REMOVED: selectedMemberFilterProvider - now imported from todo_providers.dart

// ✅ NEW: Provider to get task counts for each user in project
final userTaskCountProvider = Provider.family<int, String>((ref, userId) {
  final todos = ref.watch(todoListProvider);
  return todos.where((todo) => todo.assignedToId == userId).length;
});

// ✅ FIXED: Provider to get task counts for each user in SPECIFIC project only
final userTaskCountInProjectProvider =
    Provider.family<int, Map<String, String>>((ref, params) {
      final projectId = params['projectId']!;
      final userId = params['userId']!;

      final todos = ref.watch(todoListProvider);
      return todos
          .where(
            (todo) =>
                todo.projectId == projectId &&
                todo.assignedToId == userId &&
                !todo.completed,
          )
          .length;
    });

// ✅ NEW: Provider to get unassigned task count in project
final unassignedTaskCountProvider = Provider.family<int, String>((
  ref,
  projectId,
) {
  final todos = ref.watch(todoListProvider);
  return todos
      .where(
        (todo) =>
            todo.projectId == projectId &&
            todo.assignedToId == null &&
            !todo.completed,
      )
      .length;
});

class ProjectMembersDialog extends ConsumerWidget {
  final String projectId;
  final String projectName;

  const ProjectMembersDialog({
    Key? key,
    required this.projectId,
    required this.projectName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignableUsers = ref.watch(
      assignableUsersInProjectProvider(projectId),
    );
    final selectedFilter = ref.watch(selectedMemberFilterProvider);
    final unassignedCount = ref.watch(unassignedTaskCountProvider(projectId));

    return Dialog(
      backgroundColor: const Color(0xFF2D2D30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 450,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF3C3C3C),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.group, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Project Members',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          projectName,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // ✅ MOVED: Invite section moved to top, above members
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person_add,
                        color: Colors.white.withOpacity(0.7),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Invite New Members',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InviteUserWidget(
                    projectId: projectId,
                    projectName: projectName,
                  ),
                ],
              ),
            ),

            // Divider
            Divider(color: Colors.white.withOpacity(0.1), height: 1),

            // Members section header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.people,
                    color: Colors.white.withOpacity(0.7),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Members (${assignableUsers.length})',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Members list with task counts
            if (assignableUsers.isNotEmpty) ...[
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: assignableUsers.length,
                  itemBuilder: (context, index) {
                    final user = assignableUsers[index];
                    final taskCount = ref.watch(
                      userTaskCountInProjectProvider({
                        'userId': user.id,
                        'projectId': projectId,
                      }),
                    );
                    final isSelected = selectedFilter == user.id;

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 2,
                      ),
                      child: Material(
                        color: isSelected
                            ? Colors.blue.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: () {
                            ref
                                .read(selectedMemberFilterProvider.notifier)
                                .state = isSelected
                                ? null
                                : user.id;
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // User avatar
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: _generateAvatarColor(user.id),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      _getInitials(user.displayName),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // User info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.displayName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '@${user.username}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // ✅ NEW: Task count badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: taskCount > 0
                                        ? Colors.blue.withOpacity(0.2)
                                        : Colors.grey.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$taskCount tasks',
                                    style: TextStyle(
                                      color: taskCount > 0
                                          ? Colors.blue
                                          : Colors.grey,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No members yet',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
              ),
            ],

            // ✅ NEW: Tasks section header
            if (unassignedCount > 0) ...[
              Divider(color: Colors.white.withOpacity(0.1), height: 1),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.task_alt,
                      color: Colors.white.withOpacity(0.7),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tasks',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // ✅ MOVED: Unassigned tasks section - now under Tasks
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Material(
                  color: selectedFilter == 'unassigned'
                      ? Colors.blue.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () {
                      ref.read(selectedMemberFilterProvider.notifier).state =
                          selectedFilter == 'unassigned' ? null : 'unassigned';
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.grey[600],
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                'UN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Unassigned Tasks',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Tasks with no assignee',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$unassignedCount tasks',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  /// Helper methods for avatar generation
  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    List<String> nameParts = name.trim().split(' ');
    if (nameParts.length == 1) {
      return nameParts[0].substring(0, 1).toUpperCase();
    } else {
      return (nameParts[0].substring(0, 1) + nameParts[1].substring(0, 1))
          .toUpperCase();
    }
  }

  Color _generateAvatarColor(String input) {
    int hash = input.hashCode;
    List<Color> colors = [
      Colors.blue[600]!,
      Colors.green[600]!,
      Colors.orange[600]!,
      Colors.purple[600]!,
      Colors.teal[600]!,
      Colors.indigo[600]!,
      Colors.pink[600]!,
      Colors.cyan[600]!,
    ];
    return colors[hash.abs() % colors.length];
  }
}
