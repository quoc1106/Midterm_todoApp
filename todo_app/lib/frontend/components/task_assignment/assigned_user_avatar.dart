/// 🎯 ASSIGNED USER AVATAR - Avatar hiển thị user được assign cho task
///
/// Component hiển thị avatar của user được assign hoặc "UN" nếu unassigned
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/shared_project_providers.dart';

class AssignedUserAvatar extends ConsumerWidget {
  final String? assignedToId;
  final String? assignedToDisplayName;
  final double size;

  const AssignedUserAvatar({
    Key? key,
    this.assignedToId,
    this.assignedToDisplayName,
    this.size = 32,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (assignedToId == null) {
      // Unassigned task - show black avatar with "UN"
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            'UN',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.35,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // ✅ FIX: Always get fresh display name from provider based on assignedToId
    String displayName = ref.watch(userDisplayNameProvider(assignedToId!));

    // Fallback to cached name if provider returns empty
    if (displayName.isEmpty && assignedToDisplayName != null) {
      displayName = assignedToDisplayName!;
    }

    if (displayName.isEmpty) {
      displayName = 'Unknown';
    }

    // ✅ FIX: Create initials from fresh display name
    String initials = _getInitials(displayName);

    // ✅ FIX: Generate color based on assignedToId for consistency
    Color avatarColor = _generateAvatarColor(assignedToId!);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: avatarColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';

    List<String> nameParts = name.trim().split(' ');
    if (nameParts.length == 1) {
      return nameParts[0].substring(0, 1).toUpperCase();
    } else {
      return (nameParts[0].substring(0, 1) + nameParts[1].substring(0, 1)).toUpperCase();
    }
  }

  Color _generateAvatarColor(String input) {
    // Generate consistent color based on input string
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
