/// 🎯 SHARED PROJECT INDICATOR - Biểu tượng nhóm bên cạnh tên project
///
/// Component hiển thị icon nhóm và cho phép mở dialog quản lý members
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/project_providers.dart';
import '../../../providers/shared_project_providers.dart';
import 'project_members_dialog.dart';

class SharedProjectIndicator extends ConsumerWidget {
  final String projectId;
  final String projectName;

  const SharedProjectIndicator({
    Key? key,
    required this.projectId,
    required this.projectName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isShared = ref.watch(isSharedProjectProvider(projectId));
    final canInvite = ref.watch(canCurrentUserInviteProvider(projectId));

    // Nếu không phải shared project thì không hiển thị gì
    if (!isShared && !canInvite) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(left: 8.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: canInvite ? () => _showMembersDialog(context, ref) : null,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Icon(
              isShared ? Icons.group : Icons.group_add,
              size: 18,
              color: canInvite
                  ? Colors.white.withOpacity(0.9)
                  : Colors.white.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }

  void _showMembersDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => ProjectMembersDialog(
        projectId: projectId,
        projectName: projectName,
      ),
    );
  }
}
