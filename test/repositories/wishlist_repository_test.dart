import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:movie_diary_app/database/movie_database.dart';
import 'package:movie_diary_app/repositories/wishlist_repository.dart';
import 'package:movie_diary_app/repositories/movie_repository.dart';
import 'package:movie_diary_app/models/movie.dart';

void main() {
  // 테스트용 SQLite 초기화
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('WishlistRepository 테스트', () {
    late Movie testMovie1;
    late Movie testMovie2;
    late int testUserId;

    setUp(() async {
      // 각 테스트 전에 DB 초기화
      await MovieDatabase.close();
      final db = await MovieDatabase.database;

      // 기본 사용자 생성
      testUserId = await db.insert(
        MovieDatabase.tableUsers,
        {
          'nickname': '테스트 사용자',
          'email': null,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
      );

      // 테스트 영화 생성
      testMovie1 = Movie(
        id: 'test_movie_wishlist_1',
        title: '테스트 영화 1',
        posterUrl: 'https://example.com/poster1.jpg',
        genres: ['액션'],
        releaseDate: '2024-01-01',
        runtime: 120,
        voteAverage: 4.5,
        isRecent: false,
      );
      testMovie2 = Movie(
        id: 'test_movie_wishlist_2',
        title: '테스트 영화 2',
        posterUrl: 'https://example.com/poster2.jpg',
        genres: ['드라마'],
        releaseDate: '2024-02-01',
        runtime: 110,
        voteAverage: 4.0,
        isRecent: false,
      );
      await MovieRepository.addMovie(testMovie1);
      await MovieRepository.addMovie(testMovie2);
    });

    tearDown(() async {
      // 각 테스트 후 DB 정리
      await MovieDatabase.close();
    });

    test('위시리스트 추가 및 조회', () async {
      // When: 위시리스트에 영화 추가
      await WishlistRepository.addToWishlist(testUserId, testMovie1.id);

      // Then: 위시리스트에 포함되어야 함
      final isIn = await WishlistRepository.isInWishlist(
        testUserId,
        testMovie1.id,
      );
      expect(isIn, true);

      // When: 위시리스트 조회
      final wishlist = await WishlistRepository.getWishlist(testUserId);

      // Then: 위시리스트에 영화가 있어야 함
      expect(wishlist.length, 1);
      expect(wishlist.first.movie.id, testMovie1.id);
      expect(wishlist.first.movie.title, testMovie1.title);
    });

    test('위시리스트 제거', () async {
      // Given: 위시리스트에 영화 추가
      await WishlistRepository.addToWishlist(testUserId, testMovie1.id);

      // When: 위시리스트에서 제거
      await WishlistRepository.removeFromWishlist(testUserId, testMovie1.id);

      // Then: 위시리스트에 없어야 함
      final isIn = await WishlistRepository.isInWishlist(
        testUserId,
        testMovie1.id,
      );
      expect(isIn, false);

      final wishlist = await WishlistRepository.getWishlist(testUserId);
      expect(wishlist.isEmpty, true);
    });

    test('위시리스트 토글', () async {
      // When: 처음 토글 (추가)
      final added = await WishlistRepository.toggleWishlist(
        testUserId,
        testMovie1.id,
      );

      // Then: 추가되었어야 함
      expect(added, true);
      expect(
        await WishlistRepository.isInWishlist(testUserId, testMovie1.id),
        true,
      );

      // When: 다시 토글 (제거)
      final removed = await WishlistRepository.toggleWishlist(
        testUserId,
        testMovie1.id,
      );

      // Then: 제거되었어야 함
      expect(removed, false);
      expect(
        await WishlistRepository.isInWishlist(testUserId, testMovie1.id),
        false,
      );
    });

    test('위시리스트 개수 조회', () async {
      // Given: 여러 영화를 위시리스트에 추가
      await WishlistRepository.addToWishlist(testUserId, testMovie1.id);
      await WishlistRepository.addToWishlist(testUserId, testMovie2.id);

      // When: 위시리스트 개수 조회
      final count = await WishlistRepository.getWishlistCount(testUserId);

      // Then: 개수가 올바르게 반환되어야 함
      expect(count, 2);
    });

    test('위시리스트 영화 ID 목록 조회', () async {
      // Given: 여러 영화를 위시리스트에 추가
      await WishlistRepository.addToWishlist(testUserId, testMovie1.id);
      await WishlistRepository.addToWishlist(testUserId, testMovie2.id);

      // When: 영화 ID 목록 조회
      final movieIds = await WishlistRepository.getWishlistMovieIds(testUserId);

      // Then: 영화 ID 목록이 올바르게 반환되어야 함
      expect(movieIds.length, 2);
      expect(movieIds, contains(testMovie1.id));
      expect(movieIds, contains(testMovie2.id));
    });

    test('위시리스트 중복 추가 방지', () async {
      // Given: 위시리스트에 영화 추가
      await WishlistRepository.addToWishlist(testUserId, testMovie1.id);

      // When: 같은 영화를 다시 추가 시도
      await WishlistRepository.addToWishlist(testUserId, testMovie1.id);

      // Then: 위시리스트에 하나만 있어야 함
      final count = await WishlistRepository.getWishlistCount(testUserId);
      expect(count, 1);
    });

    test('위시리스트 제목 순 정렬', () async {
      // Given: 여러 영화를 위시리스트에 추가
      await WishlistRepository.addToWishlist(testUserId, testMovie1.id);
      await WishlistRepository.addToWishlist(testUserId, testMovie2.id);

      // When: 제목 순으로 정렬 (오름차순)
      final sorted = await WishlistRepository.getWishlistSortedByTitle(
        testUserId,
        ascending: true,
      );

      // Then: 제목 순으로 정렬되어야 함
      expect(sorted.length, 2);
      expect(sorted.first.movie.title.compareTo(sorted.last.movie.title),
          lessThan(0));
    });

    test('위시리스트 평점 순 정렬', () async {
      // Given: 여러 영화를 위시리스트에 추가
      await WishlistRepository.addToWishlist(testUserId, testMovie1.id);
      await WishlistRepository.addToWishlist(testUserId, testMovie2.id);

      // When: 평점 순으로 정렬 (내림차순)
      final sorted = await WishlistRepository.getWishlistSortedByRating(
        testUserId,
        ascending: false,
      );

      // Then: 평점 순으로 정렬되어야 함
      expect(sorted.length, 2);
      expect(
        sorted.first.movie.voteAverage,
        greaterThanOrEqualTo(sorted.last.movie.voteAverage),
      );
    });

    test('위시리스트 장르 필터링', () async {
      // Given: 여러 영화를 위시리스트에 추가
      await WishlistRepository.addToWishlist(testUserId, testMovie1.id);
      await WishlistRepository.addToWishlist(testUserId, testMovie2.id);

      // When: 특정 장르로 필터링
      final filtered = await WishlistRepository.getWishlistByGenre(
        testUserId,
        '액션',
      );

      // Then: 해당 장르의 영화만 반환되어야 함
      expect(filtered.length, 1);
      expect(filtered.first.movie.genres, contains('액션'));
    });

    test('위시리스트 조회 시 최신순 정렬', () async {
      // Given: 여러 영화를 시간차를 두고 추가
      await WishlistRepository.addToWishlist(testUserId, testMovie1.id);
      await Future.delayed(const Duration(milliseconds: 10));
      await WishlistRepository.addToWishlist(testUserId, testMovie2.id);

      // When: 위시리스트 조회
      final wishlist = await WishlistRepository.getWishlist(testUserId);

      // Then: 최신순으로 정렬되어야 함 (나중에 추가한 것이 먼저)
      expect(wishlist.length, 2);
      expect(wishlist.first.movie.id, testMovie2.id);
      expect(wishlist.last.movie.id, testMovie1.id);
    });

    test('존재하지 않는 영화 추가 시 에러', () async {
      // When: 존재하지 않는 영화를 위시리스트에 추가 시도
      // Then: 에러가 발생해야 함
      expect(
        () async => await WishlistRepository.addToWishlist(
          testUserId,
          'nonexistent_movie',
        ),
        throwsException,
      );
    });
  });
}
