/// 🎯 NOTIFICATION BADGE - Badge hiển thị số lượng thông báo
///
/// Component hiển thị số thông báo chưa đọc trên icon notification
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/invitation_providers.dart';

class NotificationBadge extends ConsumerWidget {
  final Widget child;
  final VoidCallback? onTap;

  const NotificationBadge({
    Key? key,
    required this.child,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Safe access to pending invitation count with error handling
    final pendingCountAsync = ref.watch(pendingInvitationCountProvider);

    // Handle the case where provider might not be ready yet
    int pendingCount = 0;
    try {
      pendingCount = pendingCountAsync;
    } catch (e) {
      // If there's an error accessing the provider, default to 0
      print('⚠️ Error accessing pendingInvitationCountProvider: $e');
      pendingCount = 0;
    }

    return Stack(
      children: [
        GestureDetector(
          onTap: onTap,
          child: child,
        ),
        if (pendingCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Text(
                pendingCount > 99 ? '99+' : '$pendingCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
