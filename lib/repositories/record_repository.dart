import 'package:sqflite/sqflite.dart';
import '../database/movie_database.dart';
import '../models/record.dart';
import '../models/movie.dart';
import '../repositories/movie_repository.dart';
import 'tag_repository.dart';

/// 관람 기록 데이터를 관리하는 Repository 클래스
/// 
/// DB와의 상호작용을 추상화하여 비즈니스 로직과 데이터 접근을 분리합니다.
class RecordRepository {
  /// 기록을 추가합니다.
  /// 
  /// [record] 추가할 기록
  /// Returns 생성된 record_id
  static Future<int> addRecord(Record record) async {
    final db = await MovieDatabase.database;
    
    // 트랜잭션 시작
    return await db.transaction((txn) async {
      // 1. 기록 추가
      final recordId = await txn.insert(
        MovieDatabase.tableRecords,
        {
          'user_id': record.userId,
          'movie_id': record.movie.id,
          'rating': record.rating,
          'watch_date': record.watchDate.toIso8601String().split('T')[0], // YYYY-MM-DD
          'one_liner': record.oneLiner,
          'detailed_review': record.detailedReview,
          'photo_path': record.photoUrl,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
      );

      // 2. 태그 연결
      if (record.tags.isNotEmpty) {
        for (final tagName in record.tags) {
          final tagId = await TagRepository.getOrCreateTag(tagName);
          await txn.insert(
            MovieDatabase.tableRecordTags,
            {
              'record_id': recordId,
              'tag_id': tagId,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }

      return recordId;
    });
  }

  /// ID로 기록을 조회합니다.
  /// 
  /// [recordId] 기록 ID
  /// Returns 기록 정보 (없으면 null)
  static Future<Record?> getRecordById(int recordId) async {
    final recordMap = await MovieDatabase.getRecordById(recordId);
    if (recordMap == null) return null;

    // 영화 정보 조회
    final movieId = recordMap['movie_id'] as String;
    final movie = await MovieRepository.getMovieById(movieId);
    if (movie == null) return null;

    // 태그 조회
    final tagMaps = await MovieDatabase.getTagsByRecordId(recordId);
    final tags = tagMaps.map((t) => t['name'] as String).toList();

    return _mapToRecord(recordMap, movie, tags);
  }

  /// 사용자의 모든 기록을 조회합니다.
  /// 
  /// [userId] 사용자 ID
  /// Returns 기록 목록
  static Future<List<Record>> getAllRecords(int userId) async {
    final recordMaps = await MovieDatabase.getAllRecordsByUserId(userId);
    return await _convertRecordMapsToRecords(recordMaps);
  }

  /// 영화별 기록을 조회합니다.
  /// 
  /// [movieId] 영화 ID
  /// Returns 기록 목록
  static Future<List<Record>> getRecordsByMovieId(String movieId) async {
    final recordMaps = await MovieDatabase.getRecordsByMovieId(movieId);
    return await _convertRecordMapsToRecords(recordMaps);
  }

  /// 기간별 기록을 조회합니다.
  /// 
  /// [userId] 사용자 ID
  /// [startDate] 시작일 (YYYY-MM-DD)
  /// [endDate] 종료일 (YYYY-MM-DD)
  /// Returns 기록 목록
  static Future<List<Record>> getRecordsByDateRange(
    int userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final startDateStr = startDate.toIso8601String().split('T')[0];
    final endDateStr = endDate.toIso8601String().split('T')[0];
    
    final recordMaps = await MovieDatabase.getRecordsByDateRange(
      userId,
      startDateStr,
      endDateStr,
    );
    return await _convertRecordMapsToRecords(recordMaps);
  }

  /// 기록을 검색합니다.
  /// 
  /// [userId] 사용자 ID
  /// [query] 검색어
  /// Returns 기록 목록
  static Future<List<Record>> searchRecords(int userId, String query) async {
    final recordMaps = await MovieDatabase.searchRecords(userId, query);
    return await _convertRecordMapsToRecords(recordMaps);
  }

  /// 기록을 업데이트합니다.
  /// 
  /// [record] 업데이트할 기록
  static Future<void> updateRecord(Record record) async {
    // 기록 정보 업데이트
    await MovieDatabase.updateRecord(
      recordId: record.id,
      rating: record.rating,
      watchDate: record.watchDate.toIso8601String().split('T')[0],
      oneLiner: record.oneLiner,
      detailedReview: record.detailedReview,
      photoPath: record.photoUrl,
    );

    // 태그 업데이트 (기존 태그 삭제 후 재생성)
    final db = await MovieDatabase.database;
    await db.transaction((txn) async {
      // 기존 태그 삭제
      await txn.delete(
        MovieDatabase.tableRecordTags,
        where: 'record_id = ?',
        whereArgs: [record.id],
      );

      // 새 태그 연결
      if (record.tags.isNotEmpty) {
        for (final tagName in record.tags) {
          final tagId = await TagRepository.getOrCreateTag(tagName);
          await txn.insert(
            MovieDatabase.tableRecordTags,
            {
              'record_id': record.id,
              'tag_id': tagId,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
    });
  }

  /// 기록을 삭제합니다.
  /// 
  /// [recordId] 삭제할 기록 ID
  static Future<void> deleteRecord(int recordId) async {
    await MovieDatabase.deleteRecord(recordId);
    // Foreign Key CASCADE로 record_tags도 자동 삭제됨
  }

  /// DB Map을 Record 객체로 변환합니다.
  static Record _mapToRecord(
    Map<String, dynamic> map,
    Movie movie,
    List<String> tags,
  ) {
    return Record(
      id: map['record_id'] as int,
      userId: map['user_id'] as int,
      rating: (map['rating'] as num).toDouble(),
      watchDate: DateTime.parse(map['watch_date'] as String),
      oneLiner: map['one_liner'] as String?,
      detailedReview: map['detailed_review'] as String?,
      tags: tags,
      photoUrl: map['photo_path'] as String?,
      movie: movie,
    );
  }

  /// Record Map 리스트를 Record 객체 리스트로 변환합니다.
  static Future<List<Record>> _convertRecordMapsToRecords(
    List<Map<String, dynamic>> recordMaps,
  ) async {
    final records = <Record>[];

    for (final recordMap in recordMaps) {
      // 영화 정보 조회
      final movieId = recordMap['movie_id'] as String;
      final movie = await MovieRepository.getMovieById(movieId);
      if (movie == null) continue;

      // 태그 조회
      final recordId = recordMap['record_id'] as int;
      final tagMaps = await MovieDatabase.getTagsByRecordId(recordId);
      final tags = tagMaps.map((t) => t['name'] as String).toList();

      records.add(_mapToRecord(recordMap, movie, tags));
    }

    return records;
  }
}
