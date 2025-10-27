/// 🎨 FRONTEND COMPONENTS - Navigation App Drawer
///
/// ⭐ RIVERPOD LEVEL 2-3 DEMONSTRATION ⭐
/// Sidebar Navigation with Multi-Provider State Management
///
/// EDUCATIONAL VALUE:
/// - LEVEL 2: StateNotifierProvider for sidebar selection
/// - LEVEL 3: Computed providers for dynamic counts
/// - Navigation state management with multiple providers
/// - Integration of theme, search, and project components
///
/// ARCHITECTURE PATTERNS:
/// 1. Provider coordination for navigation state
/// 2. Dynamic content based on provider state
/// 3. Integration with theme and search systems
/// 4. Clean separation of navigation logic

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Backend imports
import '../../../providers/todo_providers.dart';
import '../../../providers/search_providers.dart';
import '../../../providers/invitation_providers.dart'; // ✅ NEW: Import invitation providers

// Frontend component imports
import '../project/widgets/project_sidebar_widget.dart';
import '../theme/theme_toggle_widget.dart';
import '../auth/user_profile_dropdown.dart';
import '../notifications/notification_badge.dart'; // ✅ NEW: Import notification components
import '../notifications/notification_dialog.dart'; // ✅ UPDATED: Use notification dialog instead of panel
import 'search_dialog.dart';
import 'add_task_overlay.dart';

/// ⭐ LEVEL 2-3: Navigation Drawer with Provider Integration
///
/// DEMONSTRATES:
/// - Multi-provider state coordination for navigation
/// - Dynamic content rendering based on provider state
/// - Clean integration with search and theme systems
class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  @override
  Widget build(BuildContext context) {
    /// ⭐ PROVIDER COORDINATION: Multiple providers for navigation state
    final selectedItem = ref.watch(sidebarItemProvider);
    final todayCount = ref.watch(todayTodoCountProvider);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          /// ⭐ HEADER: App branding with close button for mobile
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF2C2C2C)),
            child: Row(
              children: [
                // ✅ Thu nhỏ vùng UserProfileDropdown để có chỗ cho notification
                Expanded(
                  flex: 3, // Giảm tỷ lệ để thu nhỏ vùng user profile
                  child: UserProfileDropdown(),
                ),
                const SizedBox(width: 8), // ✅ Add spacing between elements

                // ✅ NEW: Real Notification System với NotificationBadge
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: NotificationBadge(
                    onTap: () => _openNotificationDialog(context),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
                      onPressed: () => _openNotificationDialog(context),
                      tooltip: 'Thông báo',
                      iconSize: 20,
                    ),
                  ),
                ),

                const SizedBox(width: 4), // ✅ Reduce spacing before close button

                // Close button for all screen sizes with better design
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Đóng menu',
                    iconSize: 20,
                  ),
                ),
              ],
            ),
          ),

          /// ⭐ SEARCH BUTTON: Integration with search system
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Material(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _openSearchDialog(context, ref),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Tìm kiếm tasks & projects...',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          /// ⭐ ADD TASK BUTTON: Thêm mục Add Task ở đầu
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Material(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _openAddTaskOverlay(context, ref),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Add Task',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          /// ⭐ NAVIGATION ITEMS: Dynamic state-based rendering
          _buildDrawerItem(
            context,
            ref,
            icon: Icons.calendar_today_outlined,
            text: 'Today',
            item: SidebarItem.today,
            isSelected: selectedItem == SidebarItem.today,
            trailing: todayCount > 0 ? Text(todayCount.toString()) : null,
          ),
          _buildDrawerItem(
            context,
            ref,
            icon: Icons.calendar_month_outlined,
            text: 'Upcoming',
            item: SidebarItem.upcoming,
            isSelected: selectedItem == SidebarItem.upcoming,
          ),
          const Divider(),
          _buildDrawerItem(
            context,
            ref,
            icon: Icons.check_circle_outline,
            text: 'Completed',
            item: SidebarItem.completed,
            isSelected: selectedItem == SidebarItem.completed,
          ),
          const Divider(),

          /// ⭐ THEME SETTINGS: Integration with theme system
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            trailing: const ThemeToggleWidget(),
            onTap: () {}, // Display only
          ),

          const Divider(),

          /// ⭐ PROJECT SIDEBAR: Dynamic project management
          const ProjectSidebarWidget(),
        ],
      ),
    );
  }

  /// ⭐ DRAWER ITEM BUILDER: State-based styling
  Widget _buildDrawerItem(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String text,
    required SidebarItem item,
    required bool isSelected,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: isSelected ? theme.colorScheme.primary : null),
      title: Text(
        text,
        style: TextStyle(color: isSelected ? theme.colorScheme.primary : null),
      ),
      trailing: trailing,
      tileColor: isSelected
          ? theme.colorScheme.primary.withValues(alpha: 0.1)
          : null,
      onTap: () {
        /// ⭐ PROVIDER UPDATE: State management for navigation
        ref.read(sidebarItemProvider.notifier).state = item;
        Navigator.pop(context);
      },
    );
  }

  /// ⭐ SEARCH DIALOG: Integration with search system
  void _openSearchDialog(BuildContext context, WidgetRef ref) {
    // Set search dialog open state
    ref.read(searchDialogOpenProvider.notifier).state = true;

    // Close drawer first
    Navigator.pop(context);

    // Open search dialog
    showDialog(
      context: context,
      builder: (context) => const SearchDialog(),
    ).then((_) {
      // Reset state when dialog closes
      try {
        ref.read(searchDialogOpenProvider.notifier).state = false;
      } catch (e) {
        // Widget was disposed, ignore
      }
    });
  }

  /// ⭐ ADD TASK OVERLAY: Open full-screen add task overlay with slide animation
  void _openAddTaskOverlay(BuildContext context, WidgetRef ref) {
    // Close drawer first
    Navigator.pop(context);

    // Open add task overlay with slide animation
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AddTaskOverlay(),
        transitionDuration: Duration.zero, // We handle animation internally
        barrierDismissible: true,
        barrierColor: Colors.transparent,
        opaque: false,
      ),
    );
  }

  /// ⭐ NOTIFICATION DIALOG: Open notification dialog with animation like search
  void _openNotificationDialog(BuildContext context) {
    // Close drawer first
    Navigator.pop(context);

    // Open notification dialog with same animation as search
    showDialog(
      context: context,
      builder: (context) => const NotificationDialog(),
    );
  }
}
