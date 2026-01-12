import '../models/movie.dart';
import '../database/movie_database.dart';

/// 영화 데이터를 관리하는 Repository 클래스
/// 
/// DB와의 상호작용을 추상화하여 비즈니스 로직과 데이터 접근을 분리합니다.
class MovieRepository {
  /// 모든 영화를 가져옵니다.
  /// 
  /// Returns 영화 목록 (최신 개봉일 순)
  static Future<List<Movie>> getAllMovies() async {
    return await MovieDatabase.getAllMovies();
  }

  /// 최근 상영 중인 영화를 가져옵니다.
  /// 
  /// Returns 최근 상영 중인 영화 목록
  static Future<List<Movie>> getRecentMovies() async {
    return await MovieDatabase.getRecentMovies();
  }

  /// 과거 영화(최근 상영 아님)를 가져옵니다.
  /// 
  /// Returns 과거 영화 목록
  static Future<List<Movie>> getNonRecentMovies() async {
    return await MovieDatabase.getNonRecentMovies();
  }

  /// ID로 영화를 조회합니다.
  /// 
  /// [movieId] 영화 ID
  /// Returns 영화 정보 (없으면 null)
  static Future<Movie?> getMovieById(String movieId) async {
    return await MovieDatabase.getMovieById(movieId);
  }

  /// 제목으로 영화를 검색합니다.
  /// 
  /// [query] 검색어
  /// Returns 검색 결과 영화 목록
  static Future<List<Movie>> searchMovies(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }
    return await MovieDatabase.searchMovies(query);
  }

  /// 영화를 추가합니다.
  /// 
  /// [movie] 추가할 영화
  /// 이미 존재하면 업데이트됩니다.
  static Future<void> addMovie(Movie movie) async {
    await MovieDatabase.insertMovie(movie);
  }

  /// 여러 영화를 일괄 추가합니다.
  /// 
  /// [movies] 추가할 영화 목록
  /// 트랜잭션을 사용하여 성능을 최적화합니다.
  static Future<void> addMovies(List<Movie> movies) async {
    if (movies.isEmpty) return;
    await MovieDatabase.insertMovies(movies);
  }

  /// 영화 정보를 업데이트합니다.
  /// 
  /// [movie] 업데이트할 영화
  static Future<void> updateMovie(Movie movie) async {
    await MovieDatabase.updateMovie(movie);
  }

  /// 영화를 삭제합니다.
  /// 
  /// [movieId] 삭제할 영화 ID
  static Future<void> deleteMovie(String movieId) async {
    await MovieDatabase.deleteMovie(movieId);
  }

  /// 모든 영화를 삭제합니다.
  /// 
  /// 주의: 이 메서드는 모든 데이터를 삭제합니다.
  static Future<void> deleteAllMovies() async {
    await MovieDatabase.deleteAllMovies();
  }

  /// 영화 개수를 반환합니다.
  /// 
  /// Returns 영화 개수
  static Future<int> getMovieCount() async {
    return await MovieDatabase.getMovieCount();
  }

  /// 최근 상영 영화의 플래그를 업데이트합니다.
  /// 
  /// [recentMovieIds] 최근 상영 중인 영화 ID 목록
  /// 이 목록에 포함된 영화는 is_recent = 1로, 나머지는 0으로 설정됩니다.
  static Future<void> updateRecentFlag(List<String> recentMovieIds) async {
    await MovieDatabase.updateRecentFlag(recentMovieIds);
  }

  /// DB에 영화가 있는지 확인합니다.
  /// 
  /// [movieId] 확인할 영화 ID
  /// Returns 영화가 존재하면 true
  static Future<bool> movieExists(String movieId) async {
    final movie = await MovieDatabase.getMovieById(movieId);
    return movie != null;
  }

  /// DB에 없는 영화만 필터링합니다.
  /// 
  /// [movies] 확인할 영화 목록
  /// Returns DB에 없는 영화 목록
  static Future<List<Movie>> filterNewMovies(List<Movie> movies) async {
    final newMovies = <Movie>[];
    for (final movie in movies) {
      final exists = await movieExists(movie.id);
      if (!exists) {
        newMovies.add(movie);
      }
    }
    return newMovies;
  }
}
