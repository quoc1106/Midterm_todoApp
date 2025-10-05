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

  SectionModel({required this.id, required this.name, required this.projectId});
}
