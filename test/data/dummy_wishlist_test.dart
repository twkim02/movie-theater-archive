import 'package:flutter_test/flutter_test.dart';
import 'package:movie_diary_app/data/dummy_wishlist.dart';
import 'package:movie_diary_app/models/wishlist.dart';

void main() {
  group('DummyWishlist 테스트', () {
    test('더미 위시리스트 데이터가 올바르게 로드되는지 확인', () {
      // When: 더미 위시리스트 목록 가져오기
      final wishlist = DummyWishlist.getWishlist();

      // Then: 2개의 위시리스트 아이템이 있어야 함 (더미데이터 예시.txt 기준)
      expect(wishlist.length, 2);
    });

    test('각 위시리스트 아이템의 필수 필드가 모두 채워져 있는지 확인', () {
      // When: 더미 위시리스트 목록 가져오기
      final wishlist = DummyWishlist.getWishlist();

      // Then: 모든 위시리스트 아이템의 필수 필드 확인
      for (final item in wishlist) {
        expect(item.movie.id.isNotEmpty, true, reason: '${item.movie.title}의 movie.id가 비어있음');
        expect(item.movie.title.isNotEmpty, true, reason: '${item.movie.title}의 movie.title이 비어있음');
        expect(item.movie.posterUrl.isNotEmpty, true, reason: '${item.movie.title}의 movie.posterUrl이 비어있음');
        expect(item.movie.genres.isNotEmpty, true, reason: '${item.movie.title}의 movie.genres가 비어있음');
        expect(item.savedAt, isNotNull, reason: '${item.movie.title}의 savedAt이 null임');
      }
    });

    test('더미데이터에 포함된 특정 영화가 있는지 확인', () {
      // Given: 더미데이터 예시.txt에 있는 영화들
      final expectedMovieIds = ["696506", "133200"]; // 미키 17, 광해, 왕이 된 남자
      final expectedTitles = ["미키 17", "광해, 왕이 된 남자"];

      // When: 더미 위시리스트 목록 가져오기
      final wishlist = DummyWishlist.getWishlist();
      final actualMovieIds = wishlist.map((item) => item.movie.id).toList();
      final actualTitles = wishlist.map((item) => item.movie.title).toList();

      // Then: 예상된 모든 영화가 포함되어 있어야 함
      for (final expectedId in expectedMovieIds) {
        expect(actualMovieIds.contains(expectedId), true,
            reason: '영화 ID $expectedId가 더미데이터에 없음');
      }

      for (final expectedTitle in expectedTitles) {
        expect(actualTitles.contains(expectedTitle), true,
            reason: '영화 제목 "$expectedTitle"가 더미데이터에 없음');
      }
    });

    test('모든 위시리스트 아이템의 영화 ID가 고유한지 확인', () {
      // When: 더미 위시리스트 목록 가져오기
      final wishlist = DummyWishlist.getWishlist();
      final movieIds = wishlist.map((item) => item.movie.id).toList();

      // Then: 모든 영화 ID가 고유해야 함
      expect(movieIds.toSet().length, movieIds.length,
          reason: '중복된 영화 ID가 있습니다');
    });

    test('savedAt 날짜가 올바른 형식인지 확인', () {
      // When: 더미 위시리스트 목록 가져오기
      final wishlist = DummyWishlist.getWishlist();

      // Then: 모든 savedAt이 유효한 날짜여야 함
      for (final item in wishlist) {
        expect(item.savedAt.year, greaterThan(2000),
            reason: '${item.movie.title}의 savedAt이 유효하지 않음');
        expect(item.savedAt.year, lessThanOrEqualTo(2030),
            reason: '${item.movie.title}의 savedAt이 미래가 너무 멈');
      }
    });

    test('위시리스트 아이템이 실제 더미 영화 데이터와 연결되어 있는지 확인', () {
      // When: 더미 위시리스트 목록 가져오기
      final wishlist = DummyWishlist.getWishlist();

      // Then: 모든 위시리스트의 영화 정보가 완전해야 함
      for (final item in wishlist) {
        // 영화 정보가 기본값이 아닌 실제 데이터여야 함
        expect(item.movie.title, isNot(equals('알 수 없는 영화')),
            reason: '${item.movie.id}의 영화 정보가 올바르게 연결되지 않음');
        expect(item.movie.runtime, greaterThan(0),
            reason: '${item.movie.title}의 runtime이 0임');
      }
    });

    test('위시리스트 아이템이 시간 순서로 정렬 가능한지 확인', () {
      // When: 더미 위시리스트 목록 가져오기
      final wishlist = DummyWishlist.getWishlist();

      // Then: savedAt으로 정렬이 가능해야 함
      final sorted = List<WishlistItem>.from(wishlist);
      sorted.sort((a, b) => a.savedAt.compareTo(b.savedAt));

      expect(sorted.length, wishlist.length);
    });
  });
}
