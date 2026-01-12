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

/// 전체 기능 통합 테스트
/// 
/// 7단계: 정리 및 테스트
/// - 기록 추가/수정/삭제 테스트
/// - 위시리스트 추가/제거 테스트
/// - 태그 추가/제거 테스트
/// - 검색 및 필터 테스트
/// - 앱 재시작 후 데이터 유지 확인
void main() {
  // 테스트용 SQLite 초기화
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('전체 기능 통합 테스트', () {
    late Movie testMovie1;
    late Movie testMovie2;
    late Movie testMovie3;
    late int testUserId;

    setUp(() async {
      // 각 테스트 전에 DB 초기화
      await MovieDatabase.close();
      
      // 기본 사용자 및 태그 초기화
      await UserInitializationService.initializeAll();
      testUserId = UserInitializationService.getDefaultUserId();

      // 테스트 영화 생성 및 DB에 저장
      testMovie1 = Movie(
        id: "full_test_1",
        title: "전체 테스트 영화 1",
        posterUrl: "https://test1.jpg",
        genres: ["액션", "드라마"],
        releaseDate: "2024-01-01",
        runtime: 120,
        voteAverage: 4.5,
        isRecent: false,
      );
      testMovie2 = Movie(
        id: "full_test_2",
        title: "전체 테스트 영화 2",
        posterUrl: "https://test2.jpg",
        genres: ["SF", "스릴러"],
        releaseDate: "2024-02-01",
        runtime: 100,
        voteAverage: 3.8,
        isRecent: false,
      );
      testMovie3 = Movie(
        id: "full_test_3",
        title: "전체 테스트 영화 3",
        posterUrl: "https://test3.jpg",
        genres: ["코미디"],
        releaseDate: "2024-03-01",
        runtime: 90,
        voteAverage: 4.2,
        isRecent: false,
      );
      
      await MovieRepository.addMovie(testMovie1);
      await MovieRepository.addMovie(testMovie2);
      await MovieRepository.addMovie(testMovie3);
    });

    tearDown(() async {
      // 각 테스트 후 DB 정리
      await MovieDatabase.close();
    });

    test('기록 추가/수정/삭제 테스트', () async {
      // Given: 기록 추가
      final record = Record(
        id: 0,
        userId: testUserId,
        movie: testMovie1,
        rating: 4.5,
        watchDate: DateTime.now(),
        oneLiner: "초기 한줄평",
        detailedReview: "초기 상세 리뷰",
        tags: ["혼자", "OTT"],
        photoPaths: const [],
      );
      final recordId = await RecordRepository.addRecord(record);
      expect(recordId, greaterThan(0));

      // When: 기록 수정
      final updatedRecord = record.copyWith(
        id: recordId,
        rating: 5.0,
        oneLiner: "수정된 한줄평",
        tags: ["친구", "극장"],
      );
      await RecordRepository.updateRecord(updatedRecord);

      // Then: 수정된 내용 확인
      final recordAfter = await RecordRepository.getRecordById(recordId);
      expect(recordAfter, isNotNull);
      expect(recordAfter!.rating, 5.0);
      expect(recordAfter.oneLiner, "수정된 한줄평");
      expect(recordAfter.tags, containsAll(["친구", "극장"]));

      // When: 기록 삭제
      await RecordRepository.deleteRecord(recordId);

      // Then: 기록이 삭제되었는지 확인
      final deletedRecord = await RecordRepository.getRecordById(recordId);
      expect(deletedRecord, isNull);
    });

    test('위시리스트 추가/제거 테스트', () async {
      // Given: 위시리스트에 영화 추가
      await WishlistRepository.addToWishlist(testUserId, testMovie1.id);
      await WishlistRepository.addToWishlist(testUserId, testMovie2.id);

      // Then: 위시리스트에 포함되어 있는지 확인
      final isIn1 = await WishlistRepository.isInWishlist(testUserId, testMovie1.id);
      final isIn2 = await WishlistRepository.isInWishlist(testUserId, testMovie2.id);
      expect(isIn1, true);
      expect(isIn2, true);

      // When: 위시리스트에서 제거
      await WishlistRepository.removeFromWishlist(testUserId, testMovie1.id);

      // Then: 제거되었는지 확인
      final isInAfter = await WishlistRepository.isInWishlist(testUserId, testMovie1.id);
      expect(isInAfter, false);
      
      // 다른 영화는 여전히 존재해야 함
      final isIn2After = await WishlistRepository.isInWishlist(testUserId, testMovie2.id);
      expect(isIn2After, true);
    });

    test('태그 추가/제거 테스트', () async {
      // Given: 기록 추가
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

      // When: 태그 추가
      await TagRepository.addTagToRecord(recordId, "커스텀태그1");
      await TagRepository.addTagToRecord(recordId, "커스텀태그2");

      // Then: 태그가 추가되었는지 확인
      var tags = await TagRepository.getTagsByRecordId(recordId);
      expect(tags.length, 2);
      expect(tags, containsAll(["커스텀태그1", "커스텀태그2"]));

      // When: 태그 제거
      await TagRepository.removeTagFromRecord(recordId, "커스텀태그1");

      // Then: 태그가 제거되었는지 확인
      tags = await TagRepository.getTagsByRecordId(recordId);
      expect(tags.length, 1);
      expect(tags, contains("커스텀태그2"));
      expect(tags, isNot(contains("커스텀태그1")));

      // When: 태그 목록 일괄 설정
      await TagRepository.setTagsForRecord(recordId, ["태그A", "태그B", "태그C"]);

      // Then: 태그가 일괄 설정되었는지 확인
      tags = await TagRepository.getTagsByRecordId(recordId);
      expect(tags.length, 3);
      expect(tags, containsAll(["태그A", "태그B", "태그C"]));
    });

    test('검색 및 필터 테스트', () async {
      // Given: 여러 기록 추가
      final record1 = Record(
        id: 0,
        userId: testUserId,
        movie: testMovie1,
        rating: 4.5,
        watchDate: DateTime(2024, 1, 15),
        oneLiner: "액션 영화",
        detailedReview: null,
        tags: ["혼자", "OTT"],
        photoPaths: const [],
      );
      final record2 = Record(
        id: 0,
        userId: testUserId,
        movie: testMovie2,
        rating: 3.5,
        watchDate: DateTime(2024, 2, 20),
        oneLiner: "SF 영화",
        detailedReview: null,
        tags: ["친구", "극장"],
        photoPaths: const [],
      );
      final record3 = Record(
        id: 0,
        userId: testUserId,
        movie: testMovie3,
        rating: 5.0,
        watchDate: DateTime(2024, 3, 10),
        oneLiner: "코미디 영화",
        detailedReview: null,
        tags: ["가족"],
        photoPaths: const [],
      );
      await RecordRepository.addRecord(record1);
      await RecordRepository.addRecord(record2);
      await RecordRepository.addRecord(record3);

      // When: 제목으로 검색
      final searchByTitle = await RecordRepository.searchRecords("전체 테스트 영화 1");
      expect(searchByTitle.length, greaterThanOrEqualTo(1));
      expect(searchByTitle.any((r) => r.movie.id == testMovie1.id), true);

      // When: 태그로 검색 (태그는 검색에 포함되지 않으므로 한줄평으로 검색)
      // 검색 결과가 있을 수 있음 (한줄평에 "OTT"가 포함된 경우)

      // When: 한줄평으로 검색
      final searchByOneLiner2 = await RecordRepository.searchRecords("SF");
      expect(searchByOneLiner2.length, greaterThanOrEqualTo(1));
      expect(searchByOneLiner2.any((r) => r.oneLiner == "SF 영화"), true);

      // When: 기간 필터 적용
      final allRecords = await RecordRepository.getRecordsByUserId(testUserId);
      final filteredByDate = allRecords.where((r) {
        return !r.watchDate.isBefore(DateTime(2024, 2, 1)) &&
               !r.watchDate.isAfter(DateTime(2024, 2, 28));
      }).toList();
      expect(filteredByDate.length, 1);
      expect(filteredByDate.first.movie.id, testMovie2.id);

      // When: 별점 필터 적용
      final filteredByRating = allRecords.where((r) => r.rating >= 4.5).toList();
      expect(filteredByRating.length, 2); // record1 (4.5)와 record3 (5.0)
    });

    test('위시리스트 정렬 및 필터 테스트', () async {
      // Given: 여러 영화를 위시리스트에 추가
      await WishlistRepository.addToWishlist(testUserId, testMovie1.id);
      await Future.delayed(const Duration(milliseconds: 10));
      await WishlistRepository.addToWishlist(testUserId, testMovie2.id);
      await Future.delayed(const Duration(milliseconds: 10));
      await WishlistRepository.addToWishlist(testUserId, testMovie3.id);

      // When: 제목 순 정렬
      final sortedByTitle = await WishlistRepository.getWishlistSortedByTitle(
        testUserId,
        ascending: true,
      );
      expect(sortedByTitle.length, 3);
      expect(sortedByTitle.first.movie.title.compareTo(sortedByTitle.last.movie.title) <= 0, true);

      // When: 평점 순 정렬
      final sortedByRating = await WishlistRepository.getWishlistSortedByRating(
        testUserId,
        ascending: false,
      );
      expect(sortedByRating.length, 3);
      expect(sortedByRating.first.movie.voteAverage >= sortedByRating.last.movie.voteAverage, true);

      // When: 장르로 필터링
      final filteredByGenre = await WishlistRepository.getWishlistByGenre(
        testUserId,
        "액션",
      );
      expect(filteredByGenre.length, 1);
      expect(filteredByGenre.first.movie.genres, contains("액션"));
    });

    test('앱 재시작 후 데이터 유지 확인 (복합 시나리오)', () async {
      // Given: 다양한 데이터 추가
      // 1. 위시리스트
      await WishlistRepository.addToWishlist(testUserId, testMovie1.id);
      await WishlistRepository.addToWishlist(testUserId, testMovie2.id);
      
      // 2. 기록 (태그 포함)
      final record = Record(
        id: 0,
        userId: testUserId,
        movie: testMovie3,
        rating: 4.8,
        watchDate: DateTime.now(),
        oneLiner: "재시작 테스트",
        detailedReview: "상세 리뷰",
        tags: ["극장", "친구", "커스텀태그"],
        photoPaths: const [],
      );
      final recordId = await RecordRepository.addRecord(record);

      // When: DB를 닫았다가 다시 열기 (앱 재시작 시뮬레이션)
      await MovieDatabase.close();
      await MovieDatabase.database;

      // Then: 모든 데이터가 올바르게 복원되어야 함
      // 위시리스트 확인
      final wishlist = await WishlistRepository.getWishlist(testUserId);
      expect(wishlist.length, 2);
      expect(wishlist.any((item) => item.movie.id == testMovie1.id), true);
      expect(wishlist.any((item) => item.movie.id == testMovie2.id), true);

      // 기록 확인
      final records = await RecordRepository.getRecordsByUserId(testUserId);
      expect(records.length, 1);
      expect(records.first.id, recordId);
      expect(records.first.movie.id, testMovie3.id);
      expect(records.first.rating, 4.8);
      expect(records.first.oneLiner, "재시작 테스트");

      // 태그 확인
      final tags = await TagRepository.getTagsByRecordId(recordId);
      expect(tags.length, 3);
      expect(tags, containsAll(["극장", "친구", "커스텀태그"]));
    });

    test('기본 태그 초기화 확인', () async {
      // When: DB를 닫았다가 다시 열기
      await MovieDatabase.close();
      await MovieDatabase.database;

      // Then: 기본 태그들이 존재해야 함
      final allTags = await TagRepository.getAllTagNames();
      expect(allTags, contains("혼자"));
      expect(allTags, contains("친구"));
      expect(allTags, contains("가족"));
      expect(allTags, contains("극장"));
      expect(allTags, contains("OTT"));
    });

    test('중복 방지 테스트', () async {
      // Given: 위시리스트에 영화 추가
      await WishlistRepository.addToWishlist(testUserId, testMovie1.id);

      // When: 같은 영화를 다시 추가 시도
      await WishlistRepository.addToWishlist(testUserId, testMovie1.id);

      // Then: 중복 추가는 무시되어야 함 (또는 false 반환)
      final wishlist = await WishlistRepository.getWishlist(testUserId);
      expect(wishlist.where((item) => item.movie.id == testMovie1.id).length, 1);
    });
  });
}
