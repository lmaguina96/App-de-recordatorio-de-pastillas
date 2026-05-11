// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'medicine.dart';

class MedicineAdapter extends TypeAdapter<Medicine> {
  @override
  final int typeId = 0;

  @override
  Medicine read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Medicine(
      nombre: fields[0] as String,
      horas: (fields[1] as List).cast<String>(),
      vecesAlDia: fields[2] as int,
      diario: fields[5] as bool,
      dias: (fields[6] as List).cast<String>(),
      tomadas: (fields[3] as List?)?.cast<bool>(),
      pospuestas: (fields[4] as List?)?.cast<bool>(),
      notificationIds: (fields[7] as List?)?.cast<int>() ?? [],
      postponedUntil: (fields[8] as List?)?.cast<String>() ?? [],
    );
  }

  @override
  void write(BinaryWriter writer, Medicine obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.nombre)
      ..writeByte(1)
      ..write(obj.horas)
      ..writeByte(2)
      ..write(obj.vecesAlDia)
      ..writeByte(3)
      ..write(obj.tomadas)
      ..writeByte(4)
      ..write(obj.pospuestas)
      ..writeByte(5)
      ..write(obj.diario)
      ..writeByte(6)
      ..write(obj.dias)
      ..writeByte(7)
      ..write(obj.notificationIds)
      ..writeByte(8)
      ..write(obj.postponedUntil);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is MedicineAdapter &&
              runtimeType == other.runtimeType &&
              typeId == other.typeId;
}