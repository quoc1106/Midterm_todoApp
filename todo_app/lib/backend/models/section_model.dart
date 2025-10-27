/// 🔧 BACKEND - Section Data Model với Business Logic
///
/// Đây là PURE BACKEND - chứa data structure và business methods
/// Không có UI logic hay Riverpod dependency
import 'package:hive/hive.dart';
part 'section_model.g.dart';

@HiveType(typeId: 2)
class SectionModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  final String projectId;
  @HiveField(3)
  final String ownerId; // 🔧 USER SEPARATION: Owner của section

  SectionModel({
    required this.id,
    required this.name,
    required this.projectId,
    required this.ownerId, // 🔧 Required owner ID
  });

  /// ✅ BUSINESS LOGIC METHODS - Pure backend logic

  /// Check if section name is valid
  bool get isValidName {
    return name.trim().isNotEmpty && name.trim().length >= 1;
  }

  /// Get display name with fallback
  String get displayName {
    return name.trim().isEmpty ? 'Untitled Section' : name.trim();
  }

  /// Business rule: Can section be renamed?
  bool canRename(String newName) {
    return newName.trim().isNotEmpty && newName.trim().length >= 1;
  }

  /// Business rule: Can section be moved to different project?
  bool canMoveToProject(String newProjectId) {
    return newProjectId.isNotEmpty && newProjectId != projectId;
  }

  /// Business rule: Can section be deleted?
  /// This would be enhanced with todo count checking in service layer
  bool get canDelete {
    // Basic rule: any section can be deleted
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

  /// Create copy with new values
  SectionModel copyWith({String? id, String? name, String? projectId}) {
    return SectionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      projectId: projectId ?? this.projectId,
      ownerId: ownerId, // ownerId không thay đổi
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SectionModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SectionModel(id: $id, name: $name, projectId: $projectId, ownerId: $ownerId)';
}
