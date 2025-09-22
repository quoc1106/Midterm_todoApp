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

  Todo copyWith({
    String? id,
    String? description,
    bool? completed,
    DateTime? dueDate,
    String? projectId,
    String? sectionId,
  }) {
    return Todo(
      id: id ?? this.id,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      dueDate: dueDate ?? this.dueDate,
      projectId: projectId ?? this.projectId,
      sectionId: sectionId ?? this.sectionId,
    );
  }
}
