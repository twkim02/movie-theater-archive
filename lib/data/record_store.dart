import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/movie.dart';
import '../models/record.dart';
import '../models/stored_record.dart';

class RecordStore {
  static const String _boxName = 'recordsBox';
  static late Box<StoredRecord> _box;

  static final ValueNotifier<List<Record>> records = ValueNotifier<List<Record>>([]);
  static int _nextId = 1;

  /// ✅ 앱 시작 시 1번 호출: Hive 열고 records 로드
  static Future<void> init() async {
    _box = await Hive.openBox<StoredRecord>(_boxName);

    final stored = _box.values.toList();
    stored.sort((a, b) => b.watchDate.compareTo(a.watchDate)); // 최신 위로

    records.value = stored.map(_fromStored).toList();

    final maxId =
        stored.isEmpty ? 0 : stored.map((e) => e.id).reduce((a, b) => a > b ? a : b);
    _nextId = maxId + 1;
  }

  static int nextId() => _nextId++;

  /// ✅ 추가 (Hive + 메모리)
  static Future<void> add(Record record) async {
    await _box.put(record.id, _toStored(record));

    final current = List<Record>.from(records.value);
    current.insert(0, record);
    records.value = current;
  }

  /// ✅ 삭제 (Hive + 메모리)
  static Future<void> delete(int id) async {
    await _box.delete(id);

    final current = List<Record>.from(records.value);
    current.removeWhere((r) => r.id == id);
    records.value = current;
  }

  /// ✅ 수정 (Hive + 메모리)
  static Future<void> update(Record updated) async {
    await _box.put(updated.id, _toStored(updated));

    final current = List<Record>.from(records.value);
    final index = current.indexWhere((r) => r.id == updated.id);
    if (index != -1) {
      current[index] = updated;
      current.sort((a, b) => b.watchDate.compareTo(a.watchDate));
      records.value = current;
    }
  }

  // -------------------------
  // 변환 로직 (Record <-> StoredRecord)
  // -------------------------

  static StoredRecord _toStored(Record r) {
    return StoredRecord(
      id: r.id,
      userId: r.userId,
      rating: r.rating,
      watchDate: r.watchDate,
      oneLiner: r.oneLiner,
      detailedReview: r.detailedReview,
      tags: List<String>.from(r.tags),
      photoPaths: List<String>.from(r.photoPaths),

      movieId: r.movie.id,
      movieTitle: r.movie.title,
      moviePosterUrl: r.movie.posterUrl,
      movieGenres: List<String>.from(r.movie.genres),
      movieReleaseDate: r.movie.releaseDate,
      movieRuntime: r.movie.runtime,
      movieVoteAverage: r.movie.voteAverage,
      movieIsRecent: r.movie.isRecent,
    );
  }

  static Record _fromStored(StoredRecord s) {
    final movie = Movie(
      id: s.movieId,
      title: s.movieTitle,
      posterUrl: s.moviePosterUrl,
      genres: List<String>.from(s.movieGenres),
      releaseDate: s.movieReleaseDate,
      runtime: s.movieRuntime,
      voteAverage: s.movieVoteAverage,
      isRecent: s.movieIsRecent,
    );

    return Record(
      id: s.id,
      userId: s.userId,
      rating: s.rating,
      watchDate: s.watchDate,
      oneLiner: s.oneLiner,
      detailedReview: s.detailedReview,
      tags: List<String>.from(s.tags),
      photoPaths: List<String>.from(s.photoPaths),
      movie: movie,
    );
  }
}
