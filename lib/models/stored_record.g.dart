// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stored_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StoredRecordAdapter extends TypeAdapter<StoredRecord> {
  @override
  final int typeId = 1;

  @override
  StoredRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StoredRecord(
      id: fields[0] as int,
      userId: fields[1] as int,
      rating: fields[2] as double,
      watchDate: fields[3] as DateTime,
      oneLiner: fields[4] as String?,
      detailedReview: fields[5] as String?,
      tags: (fields[6] as List).cast<String>(),
      photoPaths: (fields[7] as List).cast<String>(),
      movieId: fields[8] as String,
      movieTitle: fields[9] as String,
      moviePosterUrl: fields[10] as String,
      movieGenres: (fields[11] as List).cast<String>(),
      movieReleaseDate: fields[12] as String,
      movieRuntime: fields[13] as int,
      movieVoteAverage: fields[14] as double,
      movieIsRecent: fields[15] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, StoredRecord obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.rating)
      ..writeByte(3)
      ..write(obj.watchDate)
      ..writeByte(4)
      ..write(obj.oneLiner)
      ..writeByte(5)
      ..write(obj.detailedReview)
      ..writeByte(6)
      ..write(obj.tags)
      ..writeByte(7)
      ..write(obj.photoPaths)
      ..writeByte(8)
      ..write(obj.movieId)
      ..writeByte(9)
      ..write(obj.movieTitle)
      ..writeByte(10)
      ..write(obj.moviePosterUrl)
      ..writeByte(11)
      ..write(obj.movieGenres)
      ..writeByte(12)
      ..write(obj.movieReleaseDate)
      ..writeByte(13)
      ..write(obj.movieRuntime)
      ..writeByte(14)
      ..write(obj.movieVoteAverage)
      ..writeByte(15)
      ..write(obj.movieIsRecent);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoredRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
