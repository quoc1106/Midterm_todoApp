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

// Frontend component imports
import '../project/widgets/project_sidebar_widget.dart';
import '../theme/theme_toggle_widget.dart';
import 'search_dialog.dart';

/// ⭐ LEVEL 2-3: Navigation Drawer with Provider Integration
///
/// DEMONSTRATES:
/// - Multi-provider state coordination for navigation
/// - Dynamic content rendering based on provider state
/// - Clean integration with search and theme systems
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                const Expanded(
                  child: Text(
                    'Todoist Demo',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
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
}
