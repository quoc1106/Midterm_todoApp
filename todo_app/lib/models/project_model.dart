import 'package:hive/hive.dart';
part 'project_model.g.dart';

@HiveType(typeId: 3)
class ProjectModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  String name;

  ProjectModel({required this.id, required this.name});
}
