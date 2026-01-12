import '../database/movie_database.dart';
import '../models/wishlist.dart';
import '../repositories/movie_repository.dart';

/// 위시리스트 데이터를 관리하는 Repository 클래스
/// 
/// DB와의 상호작용을 추상화하여 비즈니스 로직과 데이터 접근을 분리합니다.
class WishlistRepository {
  /// 위시리스트에 영화를 추가합니다.
  /// 
  /// [userId] 사용자 ID
  /// [movieId] 영화 ID
  static Future<void> addToWishlist({
    required int userId,
    required String movieId,
  }) async {
    await MovieDatabase.insertWishlist(
      userId: userId,
      movieId: movieId,
    );
  }

  /// 위시리스트에서 영화를 제거합니다.
  /// 
  /// [userId] 사용자 ID
  /// [movieId] 영화 ID
  static Future<void> removeFromWishlist({
    required int userId,
    required String movieId,
  }) async {
    await MovieDatabase.deleteWishlist(
      userId: userId,
      movieId: movieId,
    );
  }

  /// 사용자의 위시리스트를 조회합니다.
  /// 
  /// [userId] 사용자 ID
  /// Returns 위시리스트 아이템 목록
  static Future<List<WishlistItem>> getWishlist(int userId) async {
    final wishlistMaps = await MovieDatabase.getWishlistByUserId(userId);
    final wishlistItems = <WishlistItem>[];

    for (final wishlistMap in wishlistMaps) {
      // 영화 정보 조회
      final movieId = wishlistMap['movie_id'] as String;
      final movie = await MovieRepository.getMovieById(movieId);
      if (movie == null) continue;

      // savedAt 파싱
      final savedAtTimestamp = wishlistMap['saved_at'] as int;
      final savedAt = DateTime.fromMillisecondsSinceEpoch(savedAtTimestamp);

      wishlistItems.add(WishlistItem(
        movie: movie,
        savedAt: savedAt,
      ));
    }

    return wishlistItems;
  }

  /// 위시리스트에 포함되어 있는지 확인합니다.
  /// 
  /// [userId] 사용자 ID
  /// [movieId] 영화 ID
  /// Returns 포함되어 있으면 true
  static Future<bool> isInWishlist({
    required int userId,
    required String movieId,
  }) async {
    return await MovieDatabase.isInWishlist(
      userId: userId,
      movieId: movieId,
    );
  }

  /// 위시리스트를 토글합니다 (추가/제거).
  /// 
  /// [userId] 사용자 ID
  /// [movieId] 영화 ID
  /// Returns 추가되었으면 true, 제거되었으면 false
  static Future<bool> toggleWishlist({
    required int userId,
    required String movieId,
  }) async {
    final isIn = await isInWishlist(userId: userId, movieId: movieId);
    if (isIn) {
      await removeFromWishlist(userId: userId, movieId: movieId);
      return false;
    } else {
      await addToWishlist(userId: userId, movieId: movieId);
      return true;
    }
  }
}
