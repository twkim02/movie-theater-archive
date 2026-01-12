import '../models/wishlist.dart';
import '../database/movie_database.dart';
import '../repositories/movie_repository.dart';

/// 위시리스트 데이터를 관리하는 Repository 클래스
/// 
/// DB와의 상호작용을 추상화하여 비즈니스 로직과 데이터 접근을 분리합니다.
class WishlistRepository {
  /// 위시리스트에 영화를 추가합니다.
  /// 
  /// [userId] 사용자 ID
  /// [movieId] 영화 ID
  /// 
  /// 영화가 DB에 없으면 추가되지 않습니다 (먼저 영화를 추가해야 함).
  /// 이미 위시리스트에 있으면 추가하지 않습니다.
  static Future<void> addToWishlist(int userId, String movieId) async {
    // 영화가 DB에 있는지 확인
    final movie = await MovieRepository.getMovieById(movieId);
    if (movie == null) {
      throw Exception('영화를 찾을 수 없습니다: $movieId');
    }

    // 위시리스트에 추가
    await MovieDatabase.insertWishlist(userId, movieId);
  }

  /// 위시리스트에서 영화를 제거합니다.
  /// 
  /// [userId] 사용자 ID
  /// [movieId] 영화 ID
  static Future<void> removeFromWishlist(int userId, String movieId) async {
    await MovieDatabase.deleteWishlist(userId, movieId);
  }

  /// 위시리스트에 영화가 있는지 확인합니다.
  /// 
  /// [userId] 사용자 ID
  /// [movieId] 영화 ID
  /// Returns 위시리스트에 있으면 true
  static Future<bool> isInWishlist(int userId, String movieId) async {
    return await MovieDatabase.isInWishlist(userId, movieId);
  }

  /// 사용자의 위시리스트를 조회합니다.
  /// 
  /// [userId] 사용자 ID
  /// Returns WishlistItem 목록 (saved_at 기준 내림차순, 최신순)
  static Future<List<WishlistItem>> getWishlist(int userId) async {
    return await MovieDatabase.getWishlist(userId);
  }

  /// 사용자의 위시리스트 개수를 반환합니다.
  /// 
  /// [userId] 사용자 ID
  /// Returns 위시리스트 개수
  static Future<int> getWishlistCount(int userId) async {
    return await MovieDatabase.getWishlistCount(userId);
  }

  /// 위시리스트의 모든 영화 ID를 반환합니다.
  /// 
  /// [userId] 사용자 ID
  /// Returns 영화 ID 리스트
  static Future<List<String>> getWishlistMovieIds(int userId) async {
    return await MovieDatabase.getWishlistMovieIds(userId);
  }

  /// 위시리스트를 토글합니다 (있으면 제거, 없으면 추가).
  /// 
  /// [userId] 사용자 ID
  /// [movieId] 영화 ID
  /// Returns 추가되었으면 true, 제거되었으면 false
  static Future<bool> toggleWishlist(int userId, String movieId) async {
    final isIn = await isInWishlist(userId, movieId);
    if (isIn) {
      await removeFromWishlist(userId, movieId);
      return false;
    } else {
      await addToWishlist(userId, movieId);
      return true;
    }
  }

  /// 위시리스트를 영화 제목 순으로 정렬하여 반환합니다.
  /// 
  /// [userId] 사용자 ID
  /// [ascending] true면 오름차순(가나다 순), false면 내림차순
  /// Returns 정렬된 WishlistItem 목록
  static Future<List<WishlistItem>> getWishlistSortedByTitle(
    int userId, {
    bool ascending = true,
  }) async {
    final wishlist = await getWishlist(userId);
    wishlist.sort((a, b) {
      final comparison = a.movie.title.compareTo(b.movie.title);
      return ascending ? comparison : -comparison;
    });
    return wishlist;
  }

  /// 위시리스트를 평점 순으로 정렬하여 반환합니다.
  /// 
  /// [userId] 사용자 ID
  /// [ascending] true면 오름차순(낮은 평점 순), false면 내림차순(높은 평점 순)
  /// Returns 정렬된 WishlistItem 목록
  static Future<List<WishlistItem>> getWishlistSortedByRating(
    int userId, {
    bool ascending = false,
  }) async {
    final wishlist = await getWishlist(userId);
    wishlist.sort((a, b) {
      final comparison = a.movie.voteAverage.compareTo(b.movie.voteAverage);
      return ascending ? comparison : -comparison;
    });
    return wishlist;
  }

  /// 위시리스트를 특정 장르로 필터링합니다.
  /// 
  /// [userId] 사용자 ID
  /// [genre] 장르 이름
  /// Returns 해당 장르의 WishlistItem 목록
  static Future<List<WishlistItem>> getWishlistByGenre(
    int userId,
    String genre,
  ) async {
    final wishlist = await getWishlist(userId);
    return wishlist
        .where((item) => item.movie.genres.contains(genre))
        .toList();
  }
}
