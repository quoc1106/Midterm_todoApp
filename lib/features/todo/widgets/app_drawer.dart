import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/todo_providers.dart';
import 'project_sidebar_widget.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedItem = ref.watch(sidebarItemProvider);
    final todayCount = ref.watch(todayTodoCountProvider);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF2C2C2C)),
            child: Text(
              'Todoist Demo',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
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
          const ProjectSidebarWidget(),
        ],
      ),
    );
  }

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
          ? theme.colorScheme.primary.withAlpha(25)
          : null, // 0.1 opacity ≈ 25 alpha
      onTap: () {
        ref.read(sidebarItemProvider.notifier).state = item;
        Navigator.pop(context);
      },
    );
  }
}
