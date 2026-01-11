import '../models/wishlist.dart';
import '../models/movie.dart';
import 'dummy_movies.dart';

/// 더미 위시리스트 데이터를 제공하는 클래스
/// 더미데이터 예시.txt 파일의 위시리스트 정보를 기반으로 합니다.
class DummyWishlist {
  /// 더미 영화 데이터에서 영화를 찾아 Movie 객체를 반환합니다.
  /// 찾지 못하면 기본값으로 Movie 객체를 생성합니다.
  static Movie _findMovieById(String movieId) {
    final allMovies = DummyMovies.getMovies();
    final movie = allMovies.firstWhere(
      (m) => m.id == movieId,
      orElse: () => Movie(
        id: movieId,
        title: '알 수 없는 영화',
        posterUrl: '',
        genres: [],
        releaseDate: DateTime.now(),
        runtime: 0,
        voteAverage: 0.0,
        isRecent: false,
    );
    return movie;
  }

  /// 더미 위시리스트 목록을 반환합니다.
  /// 더미데이터 예시.txt 파일의 2개 위시리스트 아이템을 기반으로 합니다.
  static List<WishlistItem> getWishlist() {
    return [
      WishlistItem.fromJson(
        {
          "id": "696506",
          "title": "미키 17",
          "posterUrl": "https://image.tmdb.org/t/p/w500/mH7QnJDxQibVZw0M66IBZbsw2O6.jpg",
          "genres": ["SF", "코미디", "모험"],
          "rating": 3.4,
          "savedAt": "2026-01-05T10:00:00Z",
        },
        movie: _findMovieById("696506"), // 미키 17
      ),
      WishlistItem.fromJson(
        {
          "id": "133200",
          "title": "광해, 왕이 된 남자",
          "posterUrl": "https://image.tmdb.org/t/p/w500/6Pg5AwsJUqeGanGOWcaljQXGe5g.jpg",
          "genres": ["드라마", "역사"],
          "rating": 3.7,
          "savedAt": "2026-01-05T10:01:00Z",
        },
        movie: _findMovieById("133200"), // 광해, 왕이 된 남자
      ),
    ];
  }
}
