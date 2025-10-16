/// 🔧 BACKEND - Todo Data Model với Business Logic
///
/// Đây là PURE BACKEND - chứa data structure và business methods
/// Không có UI logic hay Riverpod dependency
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

part 'todo_model.g.dart';

@HiveType(typeId: 0)
@immutable
class Todo {
  const Todo({
    required this.id,
    required this.description,
    this.completed = false,
    this.dueDate,
    this.projectId,
    this.sectionId,
  });

  @HiveField(0)
  final String id;
  @HiveField(1)
  final String description;
  @HiveField(2)
  final bool completed;
  @HiveField(3)
  final DateTime? dueDate;
  @HiveField(4)
  final String? projectId;
  @HiveField(5)
  final String? sectionId;

  /// ✅ BUSINESS LOGIC METHODS - Pure backend logic

  /// Check if todo is overdue
  bool get isOverdue {
    if (dueDate == null || completed) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  /// Check if todo is due today
  bool get isDueToday {
    if (dueDate == null) return false;
    final today = DateTime.now();
    return dueDate!.year == today.year &&
        dueDate!.month == today.month &&
        dueDate!.day == today.day;
  }

  /// Check if todo is due this week
  bool get isDueThisWeek {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return dueDate!.isAfter(startOfWeek) && dueDate!.isBefore(endOfWeek);
  }

  /// Get priority based on due date and completion
  String get priority {
    if (completed) return 'Completed';
    if (isOverdue) return 'Overdue';
    if (isDueToday) return 'Today';
    if (isDueThisWeek) return 'This Week';
    return 'Later';
  }

  /// Business rule: Can todo be moved to different project?
  bool canMoveToProject(String? newProjectId) {
    // Business rule: If todo has section, check compatibility
    if (sectionId != null && newProjectId != null) {
      // This would need project service to validate
      // For now, assume it's allowed
      return true;
    }
    return true;
  }

  /// Business rule: Can todo be completed?
  bool get canComplete {
    // Add any business rules here
    return !completed;
  }

  /// Search relevance score for search functionality
  double getSearchRelevance(String query) {
    if (query.isEmpty) return 0.0;

    final queryLower = query.toLowerCase();
    final descLower = description.toLowerCase();

    // Exact match gets highest score
    if (descLower == queryLower) return 1.0;

    // Contains query gets medium score
    if (descLower.contains(queryLower)) return 0.7;

    // Word match gets lower score
    final words = descLower.split(' ');
    final queryWords = queryLower.split(' ');

    double wordMatchScore = 0.0;
    for (String word in words) {
      for (String queryWord in queryWords) {
        if (word.contains(queryWord)) {
          wordMatchScore += 0.1;
        }
      }
    }

    return wordMatchScore.clamp(0.0, 1.0);
  }

  Todo copyWith({
    String? id,
    String? description,
    bool? completed,
    DateTime? dueDate,
    String? projectId,
    String? sectionId,
    bool projectIdSetToNull = false,
    bool sectionIdSetToNull = false,
  }) {
    return Todo(
      id: id ?? this.id,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      dueDate: dueDate ?? this.dueDate,
      projectId: projectIdSetToNull ? null : (projectId ?? this.projectId),
      sectionId: sectionIdSetToNull ? null : (sectionId ?? this.sectionId),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Todo && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Todo(id: $id, description: $description, completed: $completed)';
}
