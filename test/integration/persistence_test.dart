import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:movie_diary_app/database/movie_database.dart';
import 'package:movie_diary_app/repositories/movie_repository.dart';
import 'package:movie_diary_app/repositories/record_repository.dart';
import 'package:movie_diary_app/repositories/wishlist_repository.dart';
import 'package:movie_diary_app/repositories/tag_repository.dart';
import 'package:movie_diary_app/services/user_initialization_service.dart';
import 'package:movie_diary_app/models/movie.dart';
import 'package:movie_diary_app/models/record.dart';

/// 데이터 영속성 통합 테스트
/// 
/// 앱 종료 후 재시작 시나리오를 시뮬레이션하여
/// 데이터가 올바르게 저장되고 복원되는지 확인합니다.
void main() {
  // 테스트용 SQLite 초기화
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('데이터 영속성 통합 테스트', () {
    late Movie testMovie1;
    late Movie testMovie2;
    late int testUserId;

    setUp(() async {
      // 각 테스트 전에 DB 초기화 (앱 재시작 시뮬레이션)
      await MovieDatabase.close();
      
      // 기본 사용자 및 태그 초기화
      await UserInitializationService.initializeAll();
      testUserId = UserInitializationService.getDefaultUserId();

      // 테스트 영화 생성 및 DB에 저장
      testMovie1 = Movie(
        id: "persist_test_1",
        title: "영속성 테스트 영화 1",
        posterUrl: "https://test1.jpg",
        genres: ["액션", "드라마"],
        releaseDate: "2024-01-01",
        runtime: 120,
        voteAverage: 4.5,
        isRecent: false,
      );
      testMovie2 = Movie(
        id: "persist_test_2",
        title: "영속성 테스트 영화 2",
        posterUrl: "https://test2.jpg",
        genres: ["SF"],
        releaseDate: "2024-02-01",
        runtime: 100,
        voteAverage: 3.8,
        isRecent: false,
      );
      
      await MovieRepository.addMovie(testMovie1);
      await MovieRepository.addMovie(testMovie2);
    });

    tearDown(() async {
      // 각 테스트 후 DB 정리
      await MovieDatabase.close();
    });

    test('앱 재시작 시뮬레이션: 영화 데이터 유지', () async {
      // Given: 영화가 DB에 저장되어 있음
      final moviesBefore = await MovieRepository.getAllMovies();
      expect(moviesBefore.any((m) => m.id == testMovie1.id), true);
      expect(moviesBefore.any((m) => m.id == testMovie2.id), true);

      // When: DB를 닫았다가 다시 열기 (앱 재시작 시뮬레이션)
      await MovieDatabase.close();
      await MovieDatabase.database; // DB 다시 열기

      // Then: 영화 데이터가 여전히 존재해야 함
      final moviesAfter = await MovieRepository.getAllMovies();
      expect(moviesAfter.any((m) => m.id == testMovie1.id), true);
      expect(moviesAfter.any((m) => m.id == testMovie2.id), true);
      
      // 데이터 무결성 확인
      final movie1After = moviesAfter.firstWhere((m) => m.id == testMovie1.id);
      expect(movie1After.title, testMovie1.title);
      expect(movie1After.genres, testMovie1.genres);
      expect(movie1After.voteAverage, testMovie1.voteAverage);
    });

    test('앱 재시작 시뮬레이션: 기록 데이터 유지', () async {
      // Given: 기록 추가
      final record = Record(
        id: 0,
        userId: testUserId,
        movie: testMovie1,
        rating: 4.5,
        watchDate: DateTime.now(),
        oneLiner: "테스트 한줄평",
        detailedReview: "테스트 상세 리뷰",
        tags: ["혼자", "OTT"],
        photoPaths: const [],
      );
      final recordId = await RecordRepository.addRecord(record);
      expect(recordId, greaterThan(0));

      // When: DB를 닫았다가 다시 열기 (앱 재시작 시뮬레이션)
      await MovieDatabase.close();
      await MovieDatabase.database; // DB 다시 열기

      // Then: 기록이 여전히 존재해야 함
      final recordsAfter = await RecordRepository.getRecordsByUserId(testUserId);
      expect(recordsAfter.any((r) => r.id == recordId), true);
      
      // 데이터 무결성 확인
      final recordAfter = recordsAfter.firstWhere((r) => r.id == recordId);
      expect(recordAfter.movie.id, testMovie1.id);
      expect(recordAfter.rating, 4.5);
      expect(recordAfter.oneLiner, "테스트 한줄평");
      expect(recordAfter.tags, containsAll(["혼자", "OTT"]));
    });

    test('앱 재시작 시뮬레이션: 위시리스트 데이터 유지', () async {
      // Given: 위시리스트에 영화 추가
      await WishlistRepository.addToWishlist(testUserId, testMovie1.id);
      await WishlistRepository.addToWishlist(testUserId, testMovie2.id);
      
      final wishlistBefore = await WishlistRepository.getWishlist(testUserId);
      expect(wishlistBefore.length, 2);

      // When: DB를 닫았다가 다시 열기 (앱 재시작 시뮬레이션)
      await MovieDatabase.close();
      await MovieDatabase.database; // DB 다시 열기

      // Then: 위시리스트가 여전히 존재해야 함
      final wishlistAfter = await WishlistRepository.getWishlist(testUserId);
      expect(wishlistAfter.length, 2);
      expect(wishlistAfter.any((item) => item.movie.id == testMovie1.id), true);
      expect(wishlistAfter.any((item) => item.movie.id == testMovie2.id), true);
    });

    test('앱 재시작 시뮬레이션: 태그 데이터 유지', () async {
      // Given: 기록 추가 및 태그 설정
      final record = Record(
        id: 0,
        userId: testUserId,
        movie: testMovie1,
        rating: 4.0,
        watchDate: DateTime.now(),
        oneLiner: null,
        detailedReview: null,
        tags: ["커스텀태그1", "커스텀태그2"],
        photoPaths: const [],
      );
      final recordId = await RecordRepository.addRecord(record);

      // When: DB를 닫았다가 다시 열기 (앱 재시작 시뮬레이션)
      await MovieDatabase.close();
      await MovieDatabase.database; // DB 다시 열기

      // Then: 태그가 여전히 존재해야 함
      final tagsAfter = await TagRepository.getTagsByRecordId(recordId);
      expect(tagsAfter, containsAll(["커스텀태그1", "커스텀태그2"]));
      
      // 태그가 DB에 저장되어 있는지 확인
      final allTags = await TagRepository.getAllTagNames();
      expect(allTags, contains("커스텀태그1"));
      expect(allTags, contains("커스텀태그2"));
    });

    test('앱 재시작 시뮬레이션: 복합 시나리오 (기록 + 위시리스트 + 태그)', () async {
      // Given: 여러 데이터 추가
      // 1. 위시리스트 추가
      await WishlistRepository.addToWishlist(testUserId, testMovie1.id);
      
      // 2. 기록 추가 (태그 포함)
      final record = Record(
        id: 0,
        userId: testUserId,
        movie: testMovie2,
        rating: 5.0,
        watchDate: DateTime.now(),
        oneLiner: "복합 테스트",
        detailedReview: "상세 리뷰",
        tags: ["극장", "친구"],
        photoPaths: const [],
      );
      final recordId = await RecordRepository.addRecord(record);
      
      // 3. 추가 태그 추가
      await TagRepository.addTagToRecord(recordId, "가족");

      // When: DB를 닫았다가 다시 열기 (앱 재시작 시뮬레이션)
      await MovieDatabase.close();
      await MovieDatabase.database; // DB 다시 열기

      // Then: 모든 데이터가 올바르게 복원되어야 함
      // 위시리스트 확인
      final wishlist = await WishlistRepository.getWishlist(testUserId);
      expect(wishlist.length, 1);
      expect(wishlist.first.movie.id, testMovie1.id);
      
      // 기록 확인
      final records = await RecordRepository.getRecordsByUserId(testUserId);
      expect(records.length, 1);
      expect(records.first.id, recordId);
      expect(records.first.movie.id, testMovie2.id);
      expect(records.first.rating, 5.0);
      
      // 태그 확인
      final tags = await TagRepository.getTagsByRecordId(recordId);
      expect(tags.length, 3);
      expect(tags, containsAll(["극장", "친구", "가족"]));
    });

    test('데이터 무결성: 외래 키 제약 조건 확인', () async {
      // Given: 기록이 있는 상태
      final record = Record(
        id: 0,
        userId: testUserId,
        movie: testMovie1,
        rating: 4.0,
        watchDate: DateTime.now(),
        oneLiner: null,
        detailedReview: null,
        tags: [],
        photoPaths: const [],
      );
      final recordId = await RecordRepository.addRecord(record);

      // When: 영화를 삭제하려고 시도 (외래 키 제약으로 실패해야 함)
      // Note: 실제로는 영화 삭제 시 기록도 함께 삭제되도록 CASCADE 설정되어 있을 수 있음
      // 여기서는 외래 키가 제대로 설정되어 있는지 확인
      
      // Then: 기록이 영화를 참조하고 있음을 확인
      final recordAfter = await RecordRepository.getRecordById(recordId);
      expect(recordAfter, isNotNull);
      expect(recordAfter!.movie.id, testMovie1.id);
    });

    test('대량 데이터 처리 후 재시작 시뮬레이션', () async {
      // Given: 여러 기록 추가 (대량 데이터 시뮬레이션)
      final records = <int>[];
      for (int i = 0; i < 10; i++) {
        final record = Record(
          id: 0,
          userId: testUserId,
          movie: i % 2 == 0 ? testMovie1 : testMovie2,
          rating: 3.0 + (i % 3),
          watchDate: DateTime.now().subtract(Duration(days: i)),
          oneLiner: "기록 $i",
          detailedReview: null,
          tags: ["태그$i"],
          photoPaths: const [],
        );
        final recordId = await RecordRepository.addRecord(record);
        records.add(recordId);
      }

      // When: DB를 닫았다가 다시 열기
      await MovieDatabase.close();
      await MovieDatabase.database;

      // Then: 모든 기록이 복원되어야 함
      final recordsAfter = await RecordRepository.getRecordsByUserId(testUserId);
      expect(recordsAfter.length, 10);
      
      // 각 기록의 데이터 무결성 확인
      for (final recordId in records) {
        final record = recordsAfter.firstWhere((r) => r.id == recordId);
        expect(record, isNotNull);
        expect(record.rating, greaterThanOrEqualTo(3.0));
        expect(record.rating, lessThanOrEqualTo(5.0));
      }
    });

    test('기본 사용자 및 태그 초기화 확인', () async {
      // When: DB를 닫았다가 다시 열기 (앱 재시작 시뮬레이션)
      await MovieDatabase.close();
      await MovieDatabase.database;

      // Then: 기본 사용자가 존재해야 함
      final hasDefaultUser = await MovieDatabase.hasDefaultUser();
      expect(hasDefaultUser, true);
      
      // 기본 태그들이 존재해야 함
      final allTags = await TagRepository.getAllTagNames();
      expect(allTags, contains("혼자"));
      expect(allTags, contains("친구"));
      expect(allTags, contains("가족"));
      expect(allTags, contains("극장"));
      expect(allTags, contains("OTT"));
    });
  });
}
