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
  @HiveField(2)
  final String ownerId; // 🔧 USER SEPARATION: Owner của project
  @HiveField(3)
  final List<String> sharedUserIds; // ✅ NEW: Danh sách user được share
  @HiveField(4)
  final DateTime createdAt;
  @HiveField(5)
  final DateTime? lastModified;

  ProjectModel({
    required this.id,
    required this.name,
    required this.ownerId, // 🔧 Required owner ID
    this.sharedUserIds = const [], // ✅ NEW: Default empty
    required this.createdAt,
    this.lastModified,
  });

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

  /// ✅ NEW: Shared project business logic
  bool get isSharedProject => sharedUserIds.isNotEmpty;

  bool canUserAccess(String userId) => ownerId == userId || sharedUserIds.contains(userId);

  List<String> get allMembers => [ownerId, ...sharedUserIds];

  bool isMember(String userId) => allMembers.contains(userId);

  bool canUserInvite(String userId) => canUserAccess(userId); // All members can invite

  bool canUserManage(String userId) => canUserAccess(userId); // All members can manage

  /// Create copy with new values - UPDATED to include shared fields
  ProjectModel copyWith({
    String? id,
    String? name,
    List<String>? sharedUserIds,
    DateTime? lastModified,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId,
      sharedUserIds: sharedUserIds ?? this.sharedUserIds,
      createdAt: createdAt,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  /// Check if project belongs to specific user - UPDATED to include shared access
  bool belongsToUser(String userId) {
    return canUserAccess(userId);
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
  String toString() => 'ProjectModel(id: $id, name: $name, ownerId: $ownerId)';
}
