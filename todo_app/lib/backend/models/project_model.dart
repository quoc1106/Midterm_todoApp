/// 🔧 BACKEND - Project Data Model với Business Logic
///
/// Đây là PURE BACKEND - chứa data structure và business methods
/// Không có UI logic hay Riverpod dependency
import 'package:hive/hive.dart';
part 'project_model.g.dart';

@HiveType(typeId: 3)
class ProjectModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  String name;

  ProjectModel({required this.id, required this.name});

  /// ✅ BUSINESS LOGIC METHODS - Pure backend logic

  /// Check if project name is valid
  bool get isValidName {
    return name.trim().isNotEmpty && name.trim().length >= 2;
  }

  /// Get display name with fallback
  String get displayName {
    return name.trim().isEmpty ? 'Untitled Project' : name.trim();
  }

  /// Business rule: Can project be renamed?
  bool canRename(String newName) {
    return newName.trim().isNotEmpty && newName.trim().length >= 2;
  }

  /// Business rule: Can project be deleted?
  /// This would be enhanced with todo count checking in service layer
  bool get canDelete {
    // Basic rule: any project can be deleted
    // Enhanced rule would check if it has todos
    return true;
  }

  /// Search relevance score for search functionality
  double getSearchRelevance(String query) {
    if (query.isEmpty) return 0.0;

    final queryLower = query.toLowerCase();
    final nameLower = name.toLowerCase();

    // Exact match gets highest score
    if (nameLower == queryLower) return 1.0;

    // Contains query gets medium score
    if (nameLower.contains(queryLower)) return 0.7;

    // Word match gets lower score
    final words = nameLower.split(' ');
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

  /// Create copy with new name
  ProjectModel copyWith({String? id, String? name}) {
    return ProjectModel(id: id ?? this.id, name: name ?? this.name);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ProjectModel(id: $id, name: $name)';
}
