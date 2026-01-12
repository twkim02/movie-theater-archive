import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:movie_diary_app/state/app_state.dart';
import 'package:movie_diary_app/models/movie.dart';
import 'package:movie_diary_app/database/movie_database.dart';
import 'package:movie_diary_app/repositories/movie_repository.dart';
import 'package:movie_diary_app/services/user_initialization_service.dart';

void main() {
  // 테스트용 SQLite 초기화
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('AppState 위시리스트(Wishlist) 기능 테스트', () {
    late AppState appState;
    late Movie testMovie1;
    late Movie testMovie2;
    late Movie testMovie3;

    setUp(() async {
      // 각 테스트 전에 DB 초기화
      await MovieDatabase.close();
      
      // 새로운 AppState 인스턴스 생성
      appState = AppState();
      
      // 기본 사용자 및 태그 초기화
      await UserInitializationService.initializeAll();
      
      // 테스트 영화 생성 및 DB에 저장
      testMovie1 = Movie(
        id: "test_wishlist_1",
        title: "테스트 영화 1",
        posterUrl: "https://test1.jpg",
        genres: ["액션"],
        releaseDate: DateTime.now().toIso8601String().split('T')[0],
        runtime: 120,
        voteAverage: 4.0,
        isRecent: false,
      );
      testMovie2 = Movie(
        id: "test_wishlist_2",
        title: "테스트 영화 2",
        posterUrl: "https://test2.jpg",
        genres: ["드라마", "SF"],
        releaseDate: DateTime.now().toIso8601String().split('T')[0],
        runtime: 100,
        voteAverage: 3.5,
        isRecent: false,
      );
      testMovie3 = Movie(
        id: "test_wishlist_3",
        title: "A 영화",
        posterUrl: "https://test3.jpg",
        genres: ["코미디"],
        releaseDate: DateTime.now().toIso8601String().split('T')[0],
        runtime: 90,
        voteAverage: 4.5,
        isRecent: false,
      );
      
      // 영화를 DB에 저장
      await MovieRepository.addMovie(testMovie1);
      await MovieRepository.addMovie(testMovie2);
      await MovieRepository.addMovie(testMovie3);
      
      // 위시리스트 로드
      await appState.loadWishlistFromDatabase();
    });

    tearDown(() async {
      // 각 테스트 후 DB 정리
      await MovieDatabase.close();
    });

    test('초기 상태에서 위시리스트 리스트가 비어있어야 함', () async {
      // When: 위시리스트 로드
      await appState.loadWishlistFromDatabase();
      
      // Then: 초기에는 비어있어야 함 (DB에 아무것도 없음)
      expect(appState.wishlist.isEmpty, true);
      expect(appState.wishlistCount, 0);
    });

    test('위시리스트에 영화 추가', () async {
      // Given: 영화 객체 (이미 DB에 저장됨)
      
      // When: 위시리스트에 추가
      final beforeCount = appState.wishlistCount;
      await appState.addToWishlist(testMovie1);
      
      // Then: 위시리스트 개수가 증가해야 함
      expect(appState.wishlistCount, beforeCount + 1);
      expect(await appState.isBookmarkedAsync(testMovie1.id), true);
    });

    test('이미 위시리스트에 있는 영화를 추가하면 중복되지 않음', () async {
      // Given: 위시리스트에 추가된 영화
      await appState.addToWishlist(testMovie1);
      final beforeCount = appState.wishlistCount;

      // When: 같은 영화를 다시 추가 시도
      await appState.addToWishlist(testMovie1);

      // Then: 개수가 증가하지 않아야 함
      expect(appState.wishlistCount, beforeCount);
    });

    test('위시리스트에서 영화 제거', () async {
      // Given: 위시리스트에 추가된 영화
      await appState.addToWishlist(testMovie2);
      expect(await appState.isBookmarkedAsync(testMovie2.id), true);

      // When: 위시리스트에서 제거
      final beforeCount = appState.wishlistCount;
      await appState.removeFromWishlist(testMovie2.id);

      // Then: 제거되어야 함
      expect(appState.wishlistCount, beforeCount - 1);
      expect(await appState.isBookmarkedAsync(testMovie2.id), false);
    });

    test('특정 영화 ID로 위시리스트 아이템 찾기', () async {
      // Given: 위시리스트에 추가된 영화
      await appState.addToWishlist(testMovie1);
      final movieId = testMovie1.id;

      // When: 위시리스트 아이템 찾기
      final foundItem = appState.getWishlistItemByMovieId(movieId);

      // Then: 올바른 아이템이 반환되어야 함
      expect(foundItem, isNotNull);
      expect(foundItem!.movie.id, movieId);
      expect(foundItem.movie.title, testMovie1.title);
    });

    test('존재하지 않는 영화 ID로 찾기 시 null 반환', () {
      // Given: 존재하지 않는 영화 ID
      const movieId = "999999";

      // When: 위시리스트 아이템 찾기
      final foundItem = appState.getWishlistItemByMovieId(movieId);

      // Then: null이 반환되어야 함
      expect(foundItem, isNull);
    });

    test('위시리스트 영화 목록만 반환', () async {
      // Given: 위시리스트에 영화 추가
      await appState.addToWishlist(testMovie1);
      await appState.addToWishlist(testMovie2);
      
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

    test('날짜 순 정렬 (최신순)', () async {
      // Given: 여러 영화 추가
      await appState.addToWishlist(testMovie1);
      await Future.delayed(const Duration(milliseconds: 10)); // 시간 차이를 위해
      await appState.addToWishlist(testMovie2);
      
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

    test('날짜 순 정렬 (오래된 순)', () async {
      // Given: 여러 영화 추가
      await appState.addToWishlist(testMovie1);
      await Future.delayed(const Duration(milliseconds: 10)); // 시간 차이를 위해
      await appState.addToWishlist(testMovie2);
      
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

    test('제목 순 정렬 (가나다 순)', () async {
      // Given: 여러 영화 추가
      await appState.addToWishlist(testMovie1);
      await appState.addToWishlist(testMovie2);
      await appState.addToWishlist(testMovie3);
      
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

    test('제목 순 정렬 (역순)', () async {
      // Given: 여러 영화 추가
      await appState.addToWishlist(testMovie1);
      await appState.addToWishlist(testMovie2);
      await appState.addToWishlist(testMovie3);
      
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

    test('평점 순 정렬 (높은 평점 순)', () async {
      // Given: 여러 영화 추가
      await appState.addToWishlist(testMovie1);
      await appState.addToWishlist(testMovie2);
      await appState.addToWishlist(testMovie3);
      
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

    test('평점 순 정렬 (낮은 평점 순)', () async {
      // Given: 여러 영화 추가
      await appState.addToWishlist(testMovie1);
      await appState.addToWishlist(testMovie2);
      await appState.addToWishlist(testMovie3);
      
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

    test('장르로 필터링', () async {
      // Given: 여러 영화 추가
      await appState.addToWishlist(testMovie1); // 액션
      await appState.addToWishlist(testMovie2); // 드라마, SF
      await appState.addToWishlist(testMovie3); // 코미디
      
      // When: SF 장르로 필터링
      const genre = "SF";
      final filtered = appState.getWishlistByGenre(genre);

      // Then: 해당 장르를 포함하는 영화만 반환되어야 함
      for (final item in filtered) {
        expect(item.movie.genres.contains(genre), true,
            reason: '${item.movie.title}에 "$genre" 장르가 없음');
      }
    });

    test('존재하지 않는 장르로 필터링 시 빈 리스트 반환', () async {
      // Given: 위시리스트에 영화 추가
      await appState.addToWishlist(testMovie1);
      
      // Given: 존재하지 않는 장르
      const genre = "존재하지않는장르";

      // When: 해당 장르로 필터링
      final filtered = appState.getWishlistByGenre(genre);

      // Then: 빈 리스트가 반환되어야 함
      expect(filtered, isEmpty);
    });

    test('위시리스트에 여러 영화 추가 후 정렬 확인', () async {
      // Given: 여러 영화 추가
      await appState.addToWishlist(testMovie1);
      await appState.addToWishlist(testMovie2);
      await appState.addToWishlist(testMovie3);

      // When: 제목 순으로 정렬
      final sorted = appState.getSortedWishlistByTitle(ascending: true);

      // Then: 정렬이 올바르게 작동해야 함
      expect(sorted.length, greaterThanOrEqualTo(3));
    });

    test('위시리스트 기본 정렬이 최신순인지 확인', () async {
      // Given: 여러 영화 추가
      await appState.addToWishlist(testMovie1);
      await Future.delayed(const Duration(milliseconds: 10));
      await appState.addToWishlist(testMovie2);
      
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

    test('위시리스트 통합 테스트 (추가 → 확인 → 제거)', () async {
      // Given: 테스트 영화 (이미 DB에 저장됨)

      // When: 위시리스트에 추가
      await appState.addToWishlist(testMovie1);

      // Then: 추가 확인
      expect(await appState.isBookmarkedAsync(testMovie1.id), true);
      expect(appState.getWishlistItemByMovieId(testMovie1.id), isNotNull);
      expect(appState.wishlistMovies.any((m) => m.id == testMovie1.id), true);

      // When: 위시리스트에서 제거
      await appState.removeFromWishlist(testMovie1.id);

      // Then: 제거 확인
      expect(await appState.isBookmarkedAsync(testMovie1.id), false);
      expect(appState.getWishlistItemByMovieId(testMovie1.id), isNull);
    });

    test('북마크 토글 기능', () async {
      // Given: 영화 ID
      final movieId = testMovie1.id;

      // When: 북마크 토글 (추가)
      await appState.toggleBookmark(movieId);

      // Then: 북마크됨
      expect(await appState.isBookmarkedAsync(movieId), true);

      // When: 다시 토글 (제거)
      await appState.toggleBookmark(movieId);

      // Then: 북마크 해제됨
      expect(await appState.isBookmarkedAsync(movieId), false);
    });
  });
}
