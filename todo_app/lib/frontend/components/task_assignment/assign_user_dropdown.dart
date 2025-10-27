/// 🎯 ASSIGN USER DROPDOWN - Dropdown chọn người dùng để assign task
///
/// Component cho phép chọn thành viên trong project để assign task
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../backend/models/user.dart';
import '../../../providers/shared_project_providers.dart';

class AssignUserDropdown extends ConsumerWidget {
  final String? projectId;
  final String? currentAssigneeId;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  const AssignUserDropdown({
    Key? key,
    required this.projectId,
    this.currentAssigneeId,
    required this.onChanged,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Nếu không có projectId thì không hiển thị
    if (projectId == null) {
      return const SizedBox.shrink();
    }

    final assignableUsers = ref.watch(assignableUsersInProjectProvider(projectId!));

    // Nếu không có users để assign thì không hiển thị
    if (assignableUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: DropdownButton<String?>(
        value: currentAssigneeId,
        isExpanded: true,
        hint: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Assign to...',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        underline: const SizedBox.shrink(), // Remove default underline
        dropdownColor: Theme.of(context).colorScheme.surface,
        items: [
          // Unassigned option
          DropdownMenuItem<String?>(
            value: null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.person_off_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Unassigned',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // User options
          ...assignableUsers.map((user) => DropdownMenuItem<String?>(
            value: user.id,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 8,
                    backgroundColor: _getAvatarColor(user.displayName ?? user.username),
                    child: Text(
                      _getInitials(user.displayName ?? user.username),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      user.displayName ?? user.username,
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
        onChanged: enabled ? onChanged : null,
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else {
      return name.substring(0, 1).toUpperCase();
    }
  }

  Color _getAvatarColor(String name) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    final hash = name.hashCode;
    return colors[hash % colors.length];
  }
}
