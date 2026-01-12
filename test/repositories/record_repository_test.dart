import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:movie_diary_app/database/movie_database.dart';
import 'package:movie_diary_app/repositories/record_repository.dart';
import 'package:movie_diary_app/repositories/tag_repository.dart';
import 'package:movie_diary_app/repositories/movie_repository.dart';
import 'package:movie_diary_app/models/record.dart';
import 'package:movie_diary_app/models/movie.dart';

void main() {
  // 테스트용 SQLite 초기화
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('RecordRepository 테스트', () {
    late Movie testMovie;
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
      testMovie = Movie(
        id: 'test_movie_record',
        title: '테스트 영화',
        posterUrl: 'https://example.com/poster.jpg',
        genres: ['액션'],
        releaseDate: '2024-01-01',
        runtime: 120,
        voteAverage: 4.5,
        isRecent: false,
      );
      await MovieRepository.addMovie(testMovie);
    });

    tearDown(() async {
      // 각 테스트 후 DB 정리
      await MovieDatabase.close();
    });

    test('기록 추가 및 조회', () async {
      // Given: 기록 생성
      final record = Record(
        id: 0, // DB에서 자동 생성
        userId: testUserId,
        rating: 4.5,
        watchDate: DateTime(2024, 1, 15),
        oneLiner: '재미있는 영화',
        detailedReview: '상세 리뷰 내용',
        tags: ['혼자', '극장'],
        photoUrl: null,
        movie: testMovie,
      );

      // When: 기록 추가
      final recordId = await RecordRepository.addRecord(record);

      // Then: 기록 ID가 생성되어야 함
      expect(recordId, greaterThan(0));

      // When: 기록 조회
      final retrievedRecord = await RecordRepository.getRecordById(recordId);

      // Then: 기록이 올바르게 조회되어야 함
      expect(retrievedRecord, isNotNull);
      expect(retrievedRecord!.userId, testUserId);
      expect(retrievedRecord.rating, 4.5);
      expect(retrievedRecord.oneLiner, '재미있는 영화');
      expect(retrievedRecord.detailedReview, '상세 리뷰 내용');
      expect(retrievedRecord.tags, containsAll(['혼자', '극장']));
      expect(retrievedRecord.movie.id, testMovie.id);
    });

    test('모든 기록 조회', () async {
      // Given: 여러 기록 추가
      final record1 = Record(
        id: 0,
        userId: testUserId,
        rating: 4.0,
        watchDate: DateTime(2024, 1, 10),
        tags: [],
        movie: testMovie,
      );
      final record2 = Record(
        id: 0,
        userId: testUserId,
        rating: 5.0,
        watchDate: DateTime(2024, 1, 20),
        tags: [],
        movie: testMovie,
      );

      await RecordRepository.addRecord(record1);
      await RecordRepository.addRecord(record2);

      // When: 모든 기록 조회
      final records = await RecordRepository.getAllRecords();

      // Then: 기록이 2개 이상 있어야 함 (관람일 기준 내림차순)
      expect(records.length, greaterThanOrEqualTo(2));
      expect(records.first.watchDate.isAfter(records[1].watchDate) ||
          records.first.watchDate.isAtSameMomentAs(records[1].watchDate),
          true);
    });

    test('기록 업데이트', () async {
      // Given: 기록 추가
      final record = Record(
        id: 0,
        userId: testUserId,
        rating: 3.0,
        watchDate: DateTime(2024, 1, 15),
        oneLiner: '원래 한줄평',
        tags: ['혼자'],
        movie: testMovie,
      );
      final recordId = await RecordRepository.addRecord(record);

      // When: 기록 업데이트
      final updatedRecord = Record(
        id: recordId,
        userId: testUserId,
        rating: 4.5,
        watchDate: DateTime(2024, 1, 15),
        oneLiner: '수정된 한줄평',
        tags: ['혼자', '극장'],
        movie: testMovie,
      );
      await RecordRepository.updateRecord(updatedRecord);

      // Then: 업데이트된 내용 확인
      final retrieved = await RecordRepository.getRecordById(recordId);
      expect(retrieved, isNotNull);
      expect(retrieved!.rating, 4.5);
      expect(retrieved.oneLiner, '수정된 한줄평');
      expect(retrieved.tags, containsAll(['혼자', '극장']));
    });

    test('기록 삭제', () async {
      // Given: 기록 추가
      final record = Record(
        id: 0,
        userId: testUserId,
        rating: 4.0,
        watchDate: DateTime(2024, 1, 15),
        tags: [],
        movie: testMovie,
      );
      final recordId = await RecordRepository.addRecord(record);

      // When: 기록 삭제
      await RecordRepository.deleteRecord(recordId);

      // Then: 기록이 삭제되어야 함
      final retrieved = await RecordRepository.getRecordById(recordId);
      expect(retrieved, isNull);
    });

    test('기록 검색 (제목)', () async {
      // Given: 여러 기록 추가
      final record1 = Record(
        id: 0,
        userId: testUserId,
        rating: 4.0,
        watchDate: DateTime(2024, 1, 10),
        oneLiner: '좋은 영화',
        tags: [],
        movie: testMovie,
      );
      await RecordRepository.addRecord(record1);

      // When: 제목으로 검색
      final results = await RecordRepository.searchRecords('테스트');

      // Then: 검색 결과가 있어야 함
      expect(results.length, greaterThan(0));
      expect(results.any((r) => r.movie.title.contains('테스트')), true);
    });

    test('기록 검색 (한줄평)', () async {
      // Given: 기록 추가
      final record = Record(
        id: 0,
        userId: testUserId,
        rating: 4.0,
        watchDate: DateTime(2024, 1, 10),
        oneLiner: '감동적인 영화였습니다',
        tags: [],
        movie: testMovie,
      );
      await RecordRepository.addRecord(record);

      // When: 한줄평으로 검색
      final results = await RecordRepository.searchRecords('감동');

      // Then: 검색 결과가 있어야 함
      expect(results.length, greaterThan(0));
      expect(
        results.any((r) => r.oneLiner?.contains('감동') ?? false),
        true,
      );
    });

    test('기간 필터링', () async {
      // Given: 여러 날짜의 기록 추가
      final record1 = Record(
        id: 0,
        userId: testUserId,
        rating: 4.0,
        watchDate: DateTime(2024, 1, 10),
        tags: [],
        movie: testMovie,
      );
      final record2 = Record(
        id: 0,
        userId: testUserId,
        rating: 5.0,
        watchDate: DateTime(2024, 2, 10),
        tags: [],
        movie: testMovie,
      );
      await RecordRepository.addRecord(record1);
      await RecordRepository.addRecord(record2);

      // When: 1월 기록만 필터링
      final results = await RecordRepository.getRecordsByDateRange(
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 31),
      );

      // Then: 1월 기록만 조회되어야 함
      expect(results.length, greaterThan(0));
      expect(
        results.every((r) =>
            r.watchDate.isAfter(DateTime(2023, 12, 31)) &&
            r.watchDate.isBefore(DateTime(2024, 2, 1))),
        true,
      );
    });

    test('태그로 기록 조회', () async {
      // Given: 태그가 있는 기록 추가
      final record = Record(
        id: 0,
        userId: testUserId,
        rating: 4.0,
        watchDate: DateTime(2024, 1, 15),
        tags: ['혼자', '극장'],
        movie: testMovie,
      );
      await RecordRepository.addRecord(record);

      // When: 태그로 검색
      final results = await RecordRepository.getRecordsByTag('혼자');

      // Then: 해당 태그가 있는 기록이 조회되어야 함
      expect(results.length, greaterThan(0));
      expect(results.any((r) => r.tags.contains('혼자')), true);
    });

    test('기록 개수 조회', () async {
      // Given: 기록 추가
      final record1 = Record(
        id: 0,
        userId: testUserId,
        rating: 4.0,
        watchDate: DateTime(2024, 1, 10),
        tags: [],
        movie: testMovie,
      );
      final record2 = Record(
        id: 0,
        userId: testUserId,
        rating: 5.0,
        watchDate: DateTime(2024, 1, 20),
        tags: [],
        movie: testMovie,
      );
      await RecordRepository.addRecord(record1);
      await RecordRepository.addRecord(record2);

      // When: 기록 개수 조회
      final count = await RecordRepository.getRecordCount();

      // Then: 개수가 올바르게 반환되어야 함
      expect(count, greaterThanOrEqualTo(2));
    });

    test('평균 별점 계산', () async {
      // Given: 여러 별점의 기록 추가
      final record1 = Record(
        id: 0,
        userId: testUserId,
        rating: 4.0,
        watchDate: DateTime(2024, 1, 10),
        tags: [],
        movie: testMovie,
      );
      final record2 = Record(
        id: 0,
        userId: testUserId,
        rating: 5.0,
        watchDate: DateTime(2024, 1, 20),
        tags: [],
        movie: testMovie,
      );
      await RecordRepository.addRecord(record1);
      await RecordRepository.addRecord(record2);

      // When: 평균 별점 계산
      final average = await RecordRepository.getAverageRating();

      // Then: 평균이 올바르게 계산되어야 함
      expect(average, greaterThan(0));
      expect(average, lessThanOrEqualTo(5.0));
    });

    test('태그 자동 생성', () async {
      // Given: 존재하지 않는 태그를 가진 기록
      final record = Record(
        id: 0,
        userId: testUserId,
        rating: 4.0,
        watchDate: DateTime(2024, 1, 15),
        tags: ['새로운태그'],
        movie: testMovie,
      );

      // When: 기록 추가
      await RecordRepository.addRecord(record);

      // Then: 태그가 자동 생성되어야 함
      final allTags = await TagRepository.getAllTagNames();
      expect(allTags, contains('새로운태그'));
    });
  });
}
