import 'package:flutter_test/flutter_test.dart';
import 'package:movie_diary_app/state/app_state.dart';
import 'package:movie_diary_app/models/movie.dart';

void main() {
  group('AppState 위시리스트(Wishlist) 기능 테스트', () {
    late AppState appState;

    setUp(() {
      // 각 테스트 전에 새로운 AppState 인스턴스 생성
      appState = AppState();
    });

    test('초기 상태에서 위시리스트 리스트가 비어있지 않아야 함', () {
      // Then: 더미 데이터가 로드되어 있어야 함
      expect(appState.wishlist.isEmpty, false);
      expect(appState.wishlist.length, greaterThanOrEqualTo(2)); // 더미데이터에 최소 2개
    });

    test('더미 위시리스트가 올바르게 로드되는지 확인', () {
      // When: 더미 위시리스트 조회
      final dummyWishlist = appState.dummyWishlist;

      // Then: 2개의 더미 위시리스트 아이템이 있어야 함
      expect(dummyWishlist.length, 2);
    });

    test('위시리스트에 영화 추가', () {
      // Given: 영화 객체
      final movie = Movie(
        id: "999999",
        title: "테스트 영화",
        posterUrl: "https://test.jpg",
        genres: ["액션"],
        releaseDate: DateTime.now().toIso8601String().split('T')[0],
        runtime: 120,
        voteAverage: 4.0,
        isRecent: false,
      );

      // When: 위시리스트에 추가
      final beforeCount = appState.wishlistCount;
      appState.addToWishlist(movie);

      // Then: 위시리스트 개수가 증가해야 함
      expect(appState.wishlistCount, beforeCount + 1);
      expect(appState.isInWishlist(movie.id), true);
    });

    test('이미 위시리스트에 있는 영화를 추가하면 중복되지 않음', () {
      // Given: 더미 위시리스트에 있는 영화 ID
      final existingMovie = appState.wishlist.first.movie;

      // When: 같은 영화를 다시 추가 시도
      final beforeCount = appState.wishlistCount;
      appState.addToWishlist(existingMovie);

      // Then: 개수가 증가하지 않아야 함
      expect(appState.wishlistCount, beforeCount);
    });

    test('위시리스트에서 영화 제거', () {
      // Given: 위시리스트에 추가된 영화
      final movie = Movie(
        id: "888888",
        title: "제거 테스트 영화",
        posterUrl: "https://test.jpg",
        genres: ["드라마"],
        releaseDate: DateTime.now().toIso8601String().split('T')[0],
        runtime: 100,
        voteAverage: 3.5,
        isRecent: false,
      );
      appState.addToWishlist(movie);
      expect(appState.isInWishlist(movie.id), true);

      // When: 위시리스트에서 제거
      final beforeCount = appState.wishlistCount;
      appState.removeFromWishlist(movie.id);

      // Then: 제거되어야 함
      expect(appState.wishlistCount, beforeCount - 1);
      expect(appState.isInWishlist(movie.id), false);
    });

    test('더미데이터는 제거되지 않음', () {
      // Given: 더미 위시리스트에 있는 영화 ID
      final dummyItem = appState.dummyWishlist.first;
      final dummyMovieId = dummyItem.movie.id;

      // When: 더미 영화를 제거 시도
      final beforeCount = appState.wishlistCount;
      appState.removeFromWishlist(dummyMovieId);

      // Then: 더미데이터는 제거되지 않아야 함 (개수가 그대로여야 함)
      expect(appState.wishlistCount, beforeCount);
      expect(appState.isInWishlist(dummyMovieId), true);
    });

    test('특정 영화 ID로 위시리스트 아이템 찾기', () {
      // Given: 더미데이터에 있는 영화 ID
      final existingItem = appState.wishlist.first;
      final movieId = existingItem.movie.id;

      // When: 위시리스트 아이템 찾기
      final foundItem = appState.getWishlistItemByMovieId(movieId);

      // Then: 올바른 아이템이 반환되어야 함
      expect(foundItem, isNotNull);
      expect(foundItem!.movie.id, movieId);
      expect(foundItem.movie.title, existingItem.movie.title);
    });

    test('존재하지 않는 영화 ID로 찾기 시 null 반환', () {
      // Given: 존재하지 않는 영화 ID
      const movieId = "999999";

      // When: 위시리스트 아이템 찾기
      final foundItem = appState.getWishlistItemByMovieId(movieId);

      // Then: null이 반환되어야 함
      expect(foundItem, isNull);
    });

    test('위시리스트 영화 목록만 반환', () {
      // When: 위시리스트 영화 목록 조회
      final wishlistMovies = appState.wishlistMovies;

      // Then: Movie 객체 리스트가 반환되어야 함
      expect(wishlistMovies, isA<List<Movie>>());
      expect(wishlistMovies.length, appState.wishlistCount);
      
      // 모든 항목이 Movie 객체인지 확인
      for (final movie in wishlistMovies) {
        expect(movie, isA<Movie>());
        expect(movie.id.isNotEmpty, true);
        expect(movie.title.isNotEmpty, true);
      }
    });

    test('날짜 순 정렬 (최신순)', () {
      // When: 최신순으로 정렬
      final sorted = appState.getSortedWishlistByDate(ascending: false);

      // Then: savedAt 기준 내림차순으로 정렬되어야 함
      if (sorted.length > 1) {
        for (int i = 0; i < sorted.length - 1; i++) {
          expect(sorted[i].savedAt.isAfter(sorted[i + 1].savedAt) ||
                 sorted[i].savedAt.isAtSameMomentAs(sorted[i + 1].savedAt),
                 true,
                 reason: '최신순 정렬이 올바르지 않음');
        }
      }
    });

    test('날짜 순 정렬 (오래된 순)', () {
      // When: 오래된 순으로 정렬
      final sorted = appState.getSortedWishlistByDate(ascending: true);

      // Then: savedAt 기준 오름차순으로 정렬되어야 함
      if (sorted.length > 1) {
        for (int i = 0; i < sorted.length - 1; i++) {
          expect(sorted[i].savedAt.isBefore(sorted[i + 1].savedAt) ||
                 sorted[i].savedAt.isAtSameMomentAs(sorted[i + 1].savedAt),
                 true,
                 reason: '오래된 순 정렬이 올바르지 않음');
        }
      }
    });

    test('제목 순 정렬 (가나다 순)', () {
      // When: 제목 순으로 정렬 (오름차순)
      final sorted = appState.getSortedWishlistByTitle(ascending: true);

      // Then: 제목 기준 오름차순으로 정렬되어야 함
      if (sorted.length > 1) {
        for (int i = 0; i < sorted.length - 1; i++) {
          expect(sorted[i].movie.title.compareTo(sorted[i + 1].movie.title) <= 0,
                 true,
                 reason: '제목순 정렬이 올바르지 않음');
        }
      }
    });

    test('제목 순 정렬 (역순)', () {
      // When: 제목 역순으로 정렬 (내림차순)
      final sorted = appState.getSortedWishlistByTitle(ascending: false);

      // Then: 제목 기준 내림차순으로 정렬되어야 함
      if (sorted.length > 1) {
        for (int i = 0; i < sorted.length - 1; i++) {
          expect(sorted[i].movie.title.compareTo(sorted[i + 1].movie.title) >= 0,
                 true,
                 reason: '제목 역순 정렬이 올바르지 않음');
        }
      }
    });

    test('평점 순 정렬 (높은 평점 순)', () {
      // When: 높은 평점 순으로 정렬
      final sorted = appState.getSortedWishlistByRating(ascending: false);

      // Then: 평점 기준 내림차순으로 정렬되어야 함
      if (sorted.length > 1) {
        for (int i = 0; i < sorted.length - 1; i++) {
          expect(sorted[i].movie.voteAverage >= sorted[i + 1].movie.voteAverage,
                 true,
                 reason: '높은 평점 순 정렬이 올바르지 않음');
        }
      }
    });

    test('평점 순 정렬 (낮은 평점 순)', () {
      // When: 낮은 평점 순으로 정렬
      final sorted = appState.getSortedWishlistByRating(ascending: true);

      // Then: 평점 기준 오름차순으로 정렬되어야 함
      if (sorted.length > 1) {
        for (int i = 0; i < sorted.length - 1; i++) {
          expect(sorted[i].movie.voteAverage <= sorted[i + 1].movie.voteAverage,
                 true,
                 reason: '낮은 평점 순 정렬이 올바르지 않음');
        }
      }
    });

    test('장르로 필터링', () {
      // Given: 특정 장르 (더미데이터에 있는 장르)
      const genre = "SF";

      // When: 해당 장르로 필터링
      final filtered = appState.getWishlistByGenre(genre);

      // Then: 해당 장르를 포함하는 영화만 반환되어야 함
      for (final item in filtered) {
        expect(item.movie.genres.contains(genre), true,
            reason: '${item.movie.title}에 "$genre" 장르가 없음');
      }
    });

    test('존재하지 않는 장르로 필터링 시 빈 리스트 반환', () {
      // Given: 존재하지 않는 장르
      const genre = "존재하지않는장르";

      // When: 해당 장르로 필터링
      final filtered = appState.getWishlistByGenre(genre);

      // Then: 빈 리스트가 반환되어야 함
      expect(filtered, isEmpty);
    });

    test('위시리스트에 여러 영화 추가 후 정렬 확인', () {
      // Given: 여러 영화 추가
      final movie1 = Movie(
        id: "111111",
        title: "A 영화",
        posterUrl: "https://test1.jpg",
        genres: ["액션"],
        releaseDate: DateTime.now().toIso8601String().split('T')[0],
        runtime: 100,
        voteAverage: 4.5,
        isRecent: false,
      );
      final movie2 = Movie(
        id: "222222",
        title: "B 영화",
        posterUrl: "https://test2.jpg",
        genres: ["드라마"],
        releaseDate: DateTime.now().toIso8601String().split('T')[0],
        runtime: 120,
        voteAverage: 3.5,
        isRecent: false,
      );

      appState.addToWishlist(movie1);
      appState.addToWishlist(movie2);

      // When: 제목 순으로 정렬
      final sorted = appState.getSortedWishlistByTitle(ascending: true);

      // Then: 정렬이 올바르게 작동해야 함
      expect(sorted.length, greaterThanOrEqualTo(2));
    });

    test('위시리스트 기본 정렬이 최신순인지 확인', () {
      // When: 기본 위시리스트 조회
      final wishlist = appState.wishlist;

      // Then: savedAt 기준 내림차순(최신순)으로 정렬되어 있어야 함
      if (wishlist.length > 1) {
        for (int i = 0; i < wishlist.length - 1; i++) {
          expect(wishlist[i].savedAt.isAfter(wishlist[i + 1].savedAt) ||
                 wishlist[i].savedAt.isAtSameMomentAs(wishlist[i + 1].savedAt),
                 true,
                 reason: '기본 정렬이 최신순이 아님');
        }
      }
    });

    test('위시리스트 통합 테스트 (추가 → 확인 → 제거)', () {
      // Given: 테스트 영화
      final movie = Movie(
        id: "TEST123",
        title: "통합 테스트 영화",
        posterUrl: "https://test.jpg",
        genres: ["코미디"],
        releaseDate: DateTime.now().toIso8601String().split('T')[0],
        runtime: 90,
        voteAverage: 4.0,
        isRecent: false,
      );

      // When: 위시리스트에 추가
      appState.addToWishlist(movie);

      // Then: 추가 확인
      expect(appState.isInWishlist(movie.id), true);
      expect(appState.getWishlistItemByMovieId(movie.id), isNotNull);
      expect(appState.wishlistMovies.any((m) => m.id == movie.id), true);

      // When: 위시리스트에서 제거
      appState.removeFromWishlist(movie.id);

      // Then: 제거 확인
      expect(appState.isInWishlist(movie.id), false);
      expect(appState.getWishlistItemByMovieId(movie.id), isNull);
    });
  });
}
