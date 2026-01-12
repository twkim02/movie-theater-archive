import '../models/movie.dart';
import 'tmdb_client.dart';

/// TMDb API 응답을 앱의 Movie 모델로 변환하는 매퍼 클래스
class TmdbMapper {
  /// 장르 ID를 장르 이름으로 변환하는 맵
  /// 이 맵은 TmdbClient.getGenres()로 미리 로드해야 합니다.
  static Map<int, String>? _genreMap;

  /// 장르 맵을 설정합니다.
  /// 
  /// [genreMap] TMDb API에서 가져온 장르 ID → 이름 매핑
  static void setGenreMap(Map<int, String> genreMap) {
    _genreMap = genreMap;
  }

  /// 장르 맵을 가져옵니다.
  static Map<int, String>? get genreMap => _genreMap;

  /// 장르 ID 배열을 장르 이름 배열로 변환합니다.
  /// 
  /// [genreIds] TMDb 장르 ID 배열
  /// Returns 장르 이름 배열
  static List<String> convertGenreIdsToNames(List<int> genreIds) {
    if (_genreMap == null || genreIds.isEmpty) {
      return [];
    }

    return genreIds
        .map((id) => _genreMap![id])
        .where((name) => name != null)
        .cast<String>()
        .toList();
  }

  /// TMDb 영화 정보를 앱의 Movie 모델로 변환합니다.
  /// 
  /// [tmdbMovie] TMDb API 응답의 영화 정보
  /// [isRecent] 최근 상영 여부 (기본값: false)
  /// Returns 앱의 Movie 모델
  static Movie toMovie(TmdbMovie tmdbMovie, {bool isRecent = false}) {
    // 장르 ID를 장르 이름으로 변환
    final genres = convertGenreIdsToNames(tmdbMovie.genreIds);

    // 포스터 URL 생성
    final posterUrl = TmdbClient.buildImageUrl(tmdbMovie.posterPath);

    return Movie(
      id: tmdbMovie.id.toString(),
      title: tmdbMovie.title,
      posterUrl: posterUrl,
      genres: genres,
      releaseDate: tmdbMovie.releaseDate ?? '',
      runtime: tmdbMovie.runtime ?? 0,
      voteAverage: tmdbMovie.voteAverage ?? 0.0,
      isRecent: isRecent,
    );
  }

  /// TMDb 영화 상세 정보를 앱의 Movie 모델로 변환합니다.
  /// 
  /// [tmdbMovieDetail] TMDb API 응답의 영화 상세 정보
  /// [isRecent] 최근 상영 여부 (기본값: false)
  /// Returns 앱의 Movie 모델
  static Movie toMovieFromDetail(
    TmdbMovieDetail tmdbMovieDetail, {
    bool isRecent = false,
  }) {
    // 장르 정보가 있으면 사용, 없으면 genreIds 사용
    List<String> genres;
    if (tmdbMovieDetail.genres.isNotEmpty) {
      genres = tmdbMovieDetail.genres.map((g) => g.name).toList();
    } else {
      genres = convertGenreIdsToNames(tmdbMovieDetail.genreIds);
    }

    // 포스터 URL 생성
    final posterUrl = TmdbClient.buildImageUrl(tmdbMovieDetail.posterPath);

    return Movie(
      id: tmdbMovieDetail.id.toString(),
      title: tmdbMovieDetail.title,
      posterUrl: posterUrl,
      genres: genres,
      releaseDate: tmdbMovieDetail.releaseDate ?? '',
      runtime: tmdbMovieDetail.runtime ?? 0,
      voteAverage: tmdbMovieDetail.voteAverage ?? 0.0,
      isRecent: isRecent,
    );
  }

  /// TMDb 영화 목록을 앱의 Movie 모델 리스트로 변환합니다.
  /// 
  /// [tmdbMovies] TMDb API 응답의 영화 목록
  /// [isRecent] 최근 상영 여부 (기본값: false)
  /// Returns 앱의 Movie 모델 리스트
  static List<Movie> toMovieList(
    List<TmdbMovie> tmdbMovies, {
    bool isRecent = false,
  }) {
    return tmdbMovies.map((movie) => toMovie(movie, isRecent: isRecent)).toList();
  }
}
