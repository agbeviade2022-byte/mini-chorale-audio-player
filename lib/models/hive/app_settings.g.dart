// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 1;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      theme: fields[0] as String,
      defaultPupitre: fields[1] as String?,
      volume: fields[2] as double,
      offlineMode: fields[3] as bool,
      autoDownloadFavorites: fields[4] as bool,
      audioQuality: fields[5] as String,
      notificationsEnabled: fields[6] as bool,
      language: fields[7] as String,
      lastUpdated: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.theme)
      ..writeByte(1)
      ..write(obj.defaultPupitre)
      ..writeByte(2)
      ..write(obj.volume)
      ..writeByte(3)
      ..write(obj.offlineMode)
      ..writeByte(4)
      ..write(obj.autoDownloadFavorites)
      ..writeByte(5)
      ..write(obj.audioQuality)
      ..writeByte(6)
      ..write(obj.notificationsEnabled)
      ..writeByte(7)
      ..write(obj.language)
      ..writeByte(8)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
