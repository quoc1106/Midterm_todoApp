// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_member.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProjectMemberAdapter extends TypeAdapter<ProjectMember> {
  @override
  final int typeId = 11;

  @override
  ProjectMember read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectMember(
      id: fields[0] as String,
      projectId: fields[1] as String,
      userId: fields[2] as String,
      userDisplayName: fields[3] as String,
      joinedAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ProjectMember obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.userDisplayName)
      ..writeByte(4)
      ..write(obj.joinedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectMemberAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
