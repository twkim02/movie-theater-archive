import '../models/record.dart';
import '../database/movie_database.dart';
import '../repositories/movie_repository.dart';

/// 관람 기록 데이터를 관리하는 Repository 클래스
/// 
/// DB와의 상호작용을 추상화하여 비즈니스 로직과 데이터 접근을 분리합니다.
class RecordRepository {
  /// 기록을 추가합니다.
  /// 
  /// [record] 추가할 기록
  /// Returns 생성된 기록 ID
  /// 
  /// 태그가 없으면 자동 생성되고, 영화가 DB에 없으면 추가됩니다.
  static Future<int> addRecord(Record record) async {
    // 영화가 DB에 있는지 확인하고 없으면 추가
    final existingMovie = await MovieRepository.getMovieById(record.movie.id);
    if (existingMovie == null) {
      await MovieRepository.addMovie(record.movie);
    }

    // 기록 추가
    return await MovieDatabase.insertRecord(record);
  }

  /// 모든 기록을 가져옵니다.
  /// 
  /// Returns 기록 목록 (관람일 기준 내림차순)
  static Future<List<Record>> getAllRecords() async {
    return await MovieDatabase.getAllRecords();
  }

  /// ID로 기록을 조회합니다.
  /// 
  /// [recordId] 기록 ID
  /// Returns 기록 정보 (없으면 null)
  static Future<Record?> getRecordById(int recordId) async {
    return await MovieDatabase.getRecordById(recordId);
  }

  /// 사용자별 기록을 조회합니다.
  /// 
  /// [userId] 사용자 ID
  /// Returns 기록 목록 (관람일 기준 내림차순)
  static Future<List<Record>> getRecordsByUserId(int userId) async {
    return await MovieDatabase.getRecordsByUserId(userId);
  }

  /// 영화별 기록을 조회합니다.
  /// 
  /// [movieId] 영화 ID
  /// Returns 기록 목록 (관람일 기준 내림차순)
  static Future<List<Record>> getRecordsByMovieId(String movieId) async {
    return await MovieDatabase.getRecordsByMovieId(movieId);
  }

  /// 기록을 업데이트합니다.
  /// 
  /// [record] 업데이트할 기록
  /// 
  /// 영화 정보도 함께 업데이트됩니다.
  static Future<void> updateRecord(Record record) async {
    // 영화 정보 업데이트
    final existingMovie = await MovieRepository.getMovieById(record.movie.id);
    if (existingMovie == null) {
      await MovieRepository.addMovie(record.movie);
    } else {
      await MovieRepository.updateMovie(record.movie);
    }

    // 기록 업데이트
    await MovieDatabase.updateRecord(record);
  }

  /// 기록을 삭제합니다.
  /// 
  /// [recordId] 기록 ID
  /// 태그 매핑은 CASCADE로 자동 삭제됩니다.
  static Future<void> deleteRecord(int recordId) async {
    await MovieDatabase.deleteRecord(recordId);
  }

  /// 기록을 검색합니다.
  /// 
  /// [query] 검색어 (영화 제목 또는 한줄평)
  /// Returns 검색 결과 기록 목록
  static Future<List<Record>> searchRecords(String query) async {
    if (query.trim().isEmpty) return [];
    return await MovieDatabase.searchRecords(query);
  }

  /// 기간으로 기록을 필터링합니다.
  /// 
  /// [startDate] 시작일 (null이면 제한 없음)
  /// [endDate] 종료일 (null이면 제한 없음)
  /// Returns 필터링된 기록 목록
  static Future<List<Record>> getRecordsByDateRange(
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    return await MovieDatabase.getRecordsByDateRange(startDate, endDate);
  }

  /// 태그로 기록을 조회합니다.
  /// 
  /// [tagName] 태그 이름
  /// Returns 해당 태그가 있는 기록 목록
  static Future<List<Record>> getRecordsByTag(String tagName) async {
    return await MovieDatabase.getRecordsByTag(tagName);
  }

  /// 기록 개수를 반환합니다.
  /// 
  /// Returns 전체 기록 개수
  static Future<int> getRecordCount() async {
    final records = await getAllRecords();
    return records.length;
  }

  /// 사용자의 기록 개수를 반환합니다.
  /// 
  /// [userId] 사용자 ID
  /// Returns 해당 사용자의 기록 개수
  static Future<int> getRecordCountByUserId(int userId) async {
    final records = await getRecordsByUserId(userId);
    return records.length;
  }

  /// 영화의 기록 개수를 반환합니다.
  /// 
  /// [movieId] 영화 ID
  /// Returns 해당 영화의 기록 개수
  static Future<int> getRecordCountByMovieId(String movieId) async {
    final records = await getRecordsByMovieId(movieId);
    return records.length;
  }

  /// 기록의 평균 별점을 계산합니다.
  /// 
  /// Returns 평균 별점 (기록이 없으면 0.0)
  static Future<double> getAverageRating() async {
    final records = await getAllRecords();
    if (records.isEmpty) return 0.0;

    final total = records.fold<double>(
      0.0,
      (sum, record) => sum + record.rating,
    );
    return total / records.length;
  }

  /// 사용자의 평균 별점을 계산합니다.
  /// 
  /// [userId] 사용자 ID
  /// Returns 평균 별점 (기록이 없으면 0.0)
  static Future<double> getAverageRatingByUserId(int userId) async {
    final records = await getRecordsByUserId(userId);
    if (records.isEmpty) return 0.0;

    final total = records.fold<double>(
      0.0,
      (sum, record) => sum + record.rating,
    );
    return total / records.length;
  }
}
