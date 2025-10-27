// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_invitation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProjectInvitationAdapter extends TypeAdapter<ProjectInvitation> {
  @override
  final int typeId = 12;

  @override
  ProjectInvitation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectInvitation(
      id: fields[0] as String,
      projectId: fields[1] as String,
      projectName: fields[2] as String,
      fromUserId: fields[3] as String,
      fromUserDisplayName: fields[4] as String,
      toUserId: fields[5] as String,
      toUserDisplayName: fields[6] as String,
      status: fields[7] as InvitationStatus,
      createdAt: fields[8] as DateTime,
      respondedAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ProjectInvitation obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.projectName)
      ..writeByte(3)
      ..write(obj.fromUserId)
      ..writeByte(4)
      ..write(obj.fromUserDisplayName)
      ..writeByte(5)
      ..write(obj.toUserId)
      ..writeByte(6)
      ..write(obj.toUserDisplayName)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.respondedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectInvitationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InvitationStatusAdapter extends TypeAdapter<InvitationStatus> {
  @override
  final int typeId = 13;

  @override
  InvitationStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return InvitationStatus.pending;
      case 1:
        return InvitationStatus.accepted;
      case 2:
        return InvitationStatus.declined;
      default:
        return InvitationStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, InvitationStatus obj) {
    switch (obj) {
      case InvitationStatus.pending:
        writer.writeByte(0);
        break;
      case InvitationStatus.accepted:
        writer.writeByte(1);
        break;
      case InvitationStatus.declined:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvitationStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
