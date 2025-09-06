// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'communication_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CommunicationHistoryEntryAdapter
    extends TypeAdapter<CommunicationHistoryEntry> {
  @override
  final int typeId = 2;

  @override
  CommunicationHistoryEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CommunicationHistoryEntry(
      id: fields[0] as String,
      profileId: fields[1] as String,
      symbolsUsed: (fields[2] as List).cast<String>(),
      spokenText: fields[3] as String?,
      timestamp: fields[4] as DateTime,
      category: fields[5] as String?,
      durationSeconds: fields[6] as int?,
      notes: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CommunicationHistoryEntry obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.profileId)
      ..writeByte(2)
      ..write(obj.symbolsUsed)
      ..writeByte(3)
      ..write(obj.spokenText)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.durationSeconds)
      ..writeByte(7)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommunicationHistoryEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
