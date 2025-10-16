import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../providers/search_providers.dart';

/// Widget hiển thị từng search result với thiết kế đẹp mắt
class SearchResultItemWidget extends StatelessWidget {
  final SearchResultItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const SearchResultItemWidget({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? theme.colorScheme.primary.withValues(alpha: 0.1)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // Type icon với màu sắc phân biệt
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _getTypeColor(theme).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTypeIcon(),
                  color: _getTypeColor(theme),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title với highlight
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [TextSpan(text: item.title)],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (item.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle!,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Status indicators
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getTypeColor(theme).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _getTypeName(),
                      style: TextStyle(
                        color: _getTypeColor(theme),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // Additional info
                  if (item.dueDate != null || item.isCompleted) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.isCompleted)
                          Icon(
                            Icons.check_circle_outline,
                            size: 12,
                            color: Colors.green,
                          ),
                        if (item.dueDate != null) ...[
                          if (item.isCompleted) const SizedBox(width: 4),
                          Icon(
                            Icons.schedule_outlined,
                            size: 12,
                            color: _getDueDateColor(theme),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            _formatDueDate(),
                            style: TextStyle(
                              color: _getDueDateColor(theme),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),

              // Selected indicator
              if (isSelected) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.keyboard_arrow_right_rounded,
                  color: theme.colorScheme.primary,
                  size: 16,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon() {
    switch (item.type) {
      case SearchResultType.project:
        return Icons.folder_outlined;
      case SearchResultType.task:
        return item.isCompleted
            ? Icons.check_circle_outline
            : Icons.radio_button_unchecked;
      case SearchResultType.section:
        return Icons.label_outline;
    }
  }

  Color _getTypeColor(ThemeData theme) {
    switch (item.type) {
      case SearchResultType.project:
        return Colors.blue;
      case SearchResultType.task:
        return item.isCompleted ? Colors.green : theme.colorScheme.primary;
      case SearchResultType.section:
        return Colors.orange;
    }
  }

  String _getTypeName() {
    switch (item.type) {
      case SearchResultType.project:
        return 'PROJECT';
      case SearchResultType.task:
        return item.isCompleted ? 'DONE' : 'TASK';
      case SearchResultType.section:
        return 'SECTION';
    }
  }

  Color _getDueDateColor(ThemeData theme) {
    if (item.dueDate == null) return theme.colorScheme.onSurfaceVariant;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(
      item.dueDate!.year,
      item.dueDate!.month,
      item.dueDate!.day,
    );

    if (dueDate.isBefore(today)) {
      return Colors.red; // Overdue
    } else if (dueDate.isAtSameMomentAs(today)) {
      return Colors.orange; // Today
    } else {
      return theme.colorScheme.onSurfaceVariant; // Future
    }
  }

  String _formatDueDate() {
    if (item.dueDate == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dueDate = DateTime(
      item.dueDate!.year,
      item.dueDate!.month,
      item.dueDate!.day,
    );

    if (dueDate.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (dueDate.isAtSameMomentAs(tomorrow)) {
      return 'Tomorrow';
    } else if (dueDate.isBefore(today)) {
      final diff = today.difference(dueDate).inDays;
      return '${diff}d overdue';
    } else {
      return DateFormat('MMM d').format(item.dueDate!);
    }
  }
}
