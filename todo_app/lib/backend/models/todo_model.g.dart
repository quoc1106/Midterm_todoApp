// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TodoAdapter extends TypeAdapter<Todo> {
  @override
  final int typeId = 0;

  @override
  Todo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Todo(
      id: fields[0] as String,
      description: fields[1] as String,
      completed: fields[2] as bool,
      dueDate: fields[3] as DateTime?,
      projectId: fields[4] as String?,
      sectionId: fields[5] as String?,
      ownerId: fields[6] as String?,
      assignedToId: fields[7] as String?,
      assignedToDisplayName: fields[8] as String?,
      completedByUserId: fields[9] as String?, // ✅ ADDED: Missing field for completion tracking
    );
  }

  @override
  void write(BinaryWriter writer, Todo obj) {
    writer
      ..writeByte(10) // ✅ UPDATED: Changed from 9 to 10 fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.completed)
      ..writeByte(3)
      ..write(obj.dueDate)
      ..writeByte(4)
      ..write(obj.projectId)
      ..writeByte(5)
      ..write(obj.sectionId)
      ..writeByte(6)
      ..write(obj.ownerId)
      ..writeByte(7)
      ..write(obj.assignedToId)
      ..writeByte(8)
      ..write(obj.assignedToDisplayName)
      ..writeByte(9)
      ..write(obj.completedByUserId); // ✅ ADDED: Write the completion tracking field
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
