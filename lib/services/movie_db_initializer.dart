import '../data/dummy_movies.dart';
import '../repositories/movie_repository.dart';

/// 영화 DB 초기화 서비스
/// 
/// 더미 데이터를 DB에 저장하거나, DB가 비어있을 때 초기 데이터를 로드합니다.
class MovieDbInitializer {
  /// 더미 데이터를 DB에 저장합니다.
  /// 
  /// 이미 DB에 데이터가 있으면 스킵합니다.
  /// Returns 저장된 영화 개수
  static Future<int> initializeWithDummyData() async {
    // DB에 이미 데이터가 있는지 확인
    final count = await MovieRepository.getMovieCount();
    if (count > 0) {
      return count; // 이미 데이터가 있으면 스킵
    }

    // 더미 데이터 가져오기
    final dummyMovies = DummyMovies.getMovies();
    
    // DB에 저장
    await MovieRepository.addMovies(dummyMovies);
    
    return dummyMovies.length;
  }

  /// DB에 영화가 있는지 확인합니다.
  /// 
  /// Returns DB에 영화가 있으면 true
  static Future<bool> hasMovies() async {
    final count = await MovieRepository.getMovieCount();
    return count > 0;
  }

  /// DB를 초기화합니다 (모든 데이터 삭제 후 더미 데이터 추가).
  /// 
  /// 주의: 모든 데이터가 삭제됩니다.
  static Future<void> resetDatabase() async {
    await MovieRepository.deleteAllMovies();
    await initializeWithDummyData();
  }

  /// DB의 모든 데이터를 삭제합니다 (초기화만 수행).
  /// 
  /// 주의: 모든 데이터가 삭제됩니다. 더미 데이터는 추가하지 않습니다.
  static Future<void> clearDatabase() async {
    await MovieRepository.deleteAllMovies();
  }
}
