// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'symbol.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SymbolAdapter extends TypeAdapter<Symbol> {
  @override
  final int typeId = 0;

  @override
  Symbol read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Symbol(
      label: fields[0] as String,
      imagePath: fields[1] as String,
      category: fields[2] as String,
      dateCreated: fields[3] as DateTime?,
      isDefault: fields[4] as bool,
      description: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Symbol obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.label)
      ..writeByte(1)
      ..write(obj.imagePath)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.dateCreated)
      ..writeByte(4)
      ..write(obj.isDefault)
      ..writeByte(5)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SymbolAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CategoryAdapter extends TypeAdapter<Category> {
  @override
  final int typeId = 1;

  @override
  Category read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Category(
      name: fields[0] as String,
      iconPath: fields[1] as String,
      colorCode: fields[2] as int,
      dateCreated: fields[3] as DateTime?,
      isDefault: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Category obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.iconPath)
      ..writeByte(2)
      ..write(obj.colorCode)
      ..writeByte(3)
      ..write(obj.dateCreated)
      ..writeByte(4)
      ..write(obj.isDefault);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}