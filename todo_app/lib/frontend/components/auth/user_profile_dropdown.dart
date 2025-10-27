/// 🔐 USER PROFILE DROPDOWN - Sidebar User Management
///
/// ⭐ RIVERPOD LEVEL 1-2 UI INTEGRATION ⭐
/// User profile dropdown trong sidebar với logout functionality
/// Integrates với AuthProvider cho user session management
/// Overlay dropdown design tránh overflow

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_providers.dart';

class UserProfileDropdown extends ConsumerStatefulWidget {
  const UserProfileDropdown({super.key});

  @override
  ConsumerState<UserProfileDropdown> createState() => _UserProfileDropdownState();
}

class _UserProfileDropdownState extends ConsumerState<UserProfileDropdown>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5, // 180 degrees rotation
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    // 🔧 FIX: Remove overlay without setState to avoid calling setState on disposed widget
    _overlayEntry?.remove();
    _overlayEntry = null;
    _animationController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isExpanded) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    if (mounted) {
      setState(() {
        _isExpanded = true;
      });
    }
    _animationController.forward();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {
        _isExpanded = false;
      });
    }
    _animationController.reverse();
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Positioned(
        width: 300,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60), // Position below the header
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _animationController.value,
                  alignment: Alignment.topCenter,
                  child: Opacity(
                    opacity: _animationController.value,
                    child: child,
                  ),
                );
              },
              child: _buildDropdownContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownContent() {
    final currentUser = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    if (currentUser == null) return const SizedBox.shrink();

    final displayText = currentUser.displayName.isNotEmpty
        ? currentUser.displayName
        : currentUser.username;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface, // ✅ Use theme surface color instead of white
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)), // ✅ Use theme outline
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1), // ✅ Use theme shadow color
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // User info header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest, // ✅ Use theme surface variant
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    displayText.isNotEmpty ? displayText[0].toUpperCase() : 'U',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayText,
                        style: TextStyle( // ✅ Use theme text color
                          color: theme.colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '@${currentUser.username}',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant, // ✅ Use theme secondary text color
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Account info section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Email', currentUser.email),
                const SizedBox(height: 8),
                _buildInfoRow('Member since', _formatDate(currentUser.createdAt)),
              ],
            ),
          ),

          Divider(height: 1, color: theme.colorScheme.outline.withOpacity(0.2)), // ✅ Use theme divider color

          // Action buttons
          Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.search,
                  label: 'Tìm kiếm tasks & projects...',
                  onTap: () {
                    _removeOverlay();
                    // Add search functionality here
                  },
                ),
                _buildMenuItem(
                  icon: Icons.logout,
                  label: 'Logout',
                  iconColor: theme.colorScheme.error,
                  textColor: theme.colorScheme.error,
                  onTap: _handleLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final theme = Theme.of(context); // ✅ Add theme reference
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant, // ✅ Use theme color instead of Colors.grey.shade600
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle( // ✅ Use theme color instead of Colors.black87
              color: theme.colorScheme.onSurface,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    final theme = Theme.of(context); // ✅ Add theme reference
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: iconColor ?? theme.colorScheme.onSurfaceVariant, // ✅ Use theme color instead of Colors.grey.shade700
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor ?? theme.colorScheme.onSurface, // ✅ Use theme color instead of Colors.black87
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogout() async {
    _removeOverlay();

    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    if (currentUser == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: const Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey,
              child: Text('G', style: TextStyle(color: Colors.white, fontSize: 14)),
            ),
            SizedBox(width: 8),
            Text(
              'Guest User',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    final displayText = currentUser.displayName.isNotEmpty
        ? currentUser.displayName
        : currentUser.username;

    final avatarText = displayText.isNotEmpty
        ? displayText[0].toUpperCase()
        : 'U';

    return CompositedTransformTarget(
      link: _layerLink,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleDropdown,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    avatarText,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    displayText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AnimatedBuilder(
                  animation: _rotationAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationAnimation.value * 3.14159,
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white.withOpacity(0.8),
                        size: 20,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
