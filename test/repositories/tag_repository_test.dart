import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:movie_diary_app/database/movie_database.dart';
import 'package:movie_diary_app/repositories/tag_repository.dart';
import 'package:movie_diary_app/repositories/record_repository.dart';
import 'package:movie_diary_app/repositories/movie_repository.dart';
import 'package:movie_diary_app/models/record.dart';
import 'package:movie_diary_app/models/movie.dart';

void main() {
  // 테스트용 SQLite 초기화
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('TagRepository 테스트', () {
    late Movie testMovie;
    late int testUserId;
    late int testRecordId;

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
        id: 'test_movie_tag',
        title: '테스트 영화',
        posterUrl: 'https://example.com/poster.jpg',
        genres: ['액션'],
        releaseDate: '2024-01-01',
        runtime: 120,
        voteAverage: 4.5,
        isRecent: false,
      );
      await MovieRepository.addMovie(testMovie);

      // 테스트 기록 생성
      final record = Record(
        id: 0,
        userId: testUserId,
        rating: 4.0,
        watchDate: DateTime(2024, 1, 15),
        tags: [],
        movie: testMovie,
      );
      testRecordId = await RecordRepository.addRecord(record);
    });

    tearDown(() async {
      // 각 테스트 후 DB 정리
      await MovieDatabase.close();
    });

    test('태그 조회 또는 생성', () async {
      // When: 존재하지 않는 태그 조회/생성
      final tagId1 = await TagRepository.getOrCreateTag('새로운태그');

      // Then: 태그가 생성되어야 함
      expect(tagId1, greaterThan(0));

      // When: 같은 태그를 다시 조회/생성
      final tagId2 = await TagRepository.getOrCreateTag('새로운태그');

      // Then: 같은 태그 ID가 반환되어야 함
      expect(tagId1, tagId2);
    });

    test('모든 태그 조회', () async {
      // Given: 여러 태그 생성
      await TagRepository.getOrCreateTag('태그1');
      await TagRepository.getOrCreateTag('태그2');
      await TagRepository.getOrCreateTag('태그3');

      // When: 모든 태그 조회
      final tags = await TagRepository.getAllTags();

      // Then: 태그가 조회되어야 함
      expect(tags.length, greaterThanOrEqualTo(3));
      final tagNames = tags.map((t) => t['name'] as String).toList();
      expect(tagNames, contains('태그1'));
      expect(tagNames, contains('태그2'));
      expect(tagNames, contains('태그3'));
    });

    test('태그 이름 목록 조회', () async {
      // Given: 태그 생성
      await TagRepository.getOrCreateTag('태그A');
      await TagRepository.getOrCreateTag('태그B');

      // When: 태그 이름 목록 조회
      final tagNames = await TagRepository.getAllTagNames();

      // Then: 태그 이름이 포함되어야 함
      expect(tagNames, contains('태그A'));
      expect(tagNames, contains('태그B'));
    });

    test('기록에 태그 추가', () async {
      // When: 기록에 태그 추가
      await TagRepository.addTagToRecord(testRecordId, '테스트태그');

      // Then: 기록의 태그에 포함되어야 함
      final tags = await TagRepository.getTagsByRecordId(testRecordId);
      expect(tags, contains('테스트태그'));
    });

    test('기록에서 태그 제거', () async {
      // Given: 기록에 태그 추가
      await TagRepository.addTagToRecord(testRecordId, '제거할태그');

      // When: 태그 제거
      await TagRepository.removeTagFromRecord(testRecordId, '제거할태그');

      // Then: 기록의 태그에서 제거되어야 함
      final tags = await TagRepository.getTagsByRecordId(testRecordId);
      expect(tags, isNot(contains('제거할태그')));
    });

    test('기록의 모든 태그 제거', () async {
      // Given: 기록에 여러 태그 추가
      await TagRepository.addTagToRecord(testRecordId, '태그1');
      await TagRepository.addTagToRecord(testRecordId, '태그2');
      await TagRepository.addTagToRecord(testRecordId, '태그3');

      // When: 모든 태그 제거
      await TagRepository.removeAllTagsFromRecord(testRecordId);

      // Then: 기록에 태그가 없어야 함
      final tags = await TagRepository.getTagsByRecordId(testRecordId);
      expect(tags.isEmpty, true);
    });

    test('기록에 태그 목록 설정', () async {
      // Given: 기록에 기존 태그 추가
      await TagRepository.addTagToRecord(testRecordId, '기존태그');

      // When: 새로운 태그 목록 설정
      await TagRepository.setTagsForRecord(testRecordId, ['새태그1', '새태그2']);

      // Then: 기존 태그는 제거되고 새 태그만 있어야 함
      final tags = await TagRepository.getTagsByRecordId(testRecordId);
      expect(tags.length, 2);
      expect(tags, containsAll(['새태그1', '새태그2']));
      expect(tags, isNot(contains('기존태그')));
    });

    test('기본 태그 초기화', () async {
      // When: 기본 태그 초기화
      await TagRepository.initializeDefaultTags();

      // Then: 기본 태그들이 생성되어야 함
      final tagNames = await TagRepository.getAllTagNames();
      expect(tagNames, contains('혼자'));
      expect(tagNames, contains('친구'));
      expect(tagNames, contains('가족'));
      expect(tagNames, contains('극장'));
      expect(tagNames, contains('OTT'));
    });

    test('태그 ID로 태그 이름 조회', () async {
      // Given: 태그 생성
      final tagId = await TagRepository.getOrCreateTag('조회태그');

      // When: 태그 ID로 이름 조회
      final tagName = await TagRepository.getTagNameById(tagId);

      // Then: 태그 이름이 올바르게 반환되어야 함
      expect(tagName, '조회태그');
    });

    test('사용하지 않는 태그 삭제', () async {
      // Given: 사용하지 않는 태그 생성
      final tagId = await TagRepository.getOrCreateTag('삭제할태그');

      // When: 태그 삭제
      final deleted = await TagRepository.deleteTag('삭제할태그');

      // Then: 삭제되어야 함
      expect(deleted, true);
      final tagName = await TagRepository.getTagNameById(tagId);
      expect(tagName, isNull);
    });

    test('사용 중인 태그 삭제 실패', () async {
      // Given: 기록에 태그 추가
      await TagRepository.addTagToRecord(testRecordId, '사용중태그');

      // When: 사용 중인 태그 삭제 시도
      final deleted = await TagRepository.deleteTag('사용중태그');

      // Then: 삭제되지 않아야 함
      expect(deleted, false);
      final tagNames = await TagRepository.getAllTagNames();
      expect(tagNames, contains('사용중태그'));
    });

    test('태그 사용 횟수 조회', () async {
      // Given: 태그 생성 및 여러 기록에 추가
      await TagRepository.addTagToRecord(testRecordId, '사용횟수태그');

      // 다른 기록 생성
      final record2 = Record(
        id: 0,
        userId: testUserId,
        rating: 4.5,
        watchDate: DateTime(2024, 1, 20),
        tags: [],
        movie: testMovie,
      );
      final recordId2 = await RecordRepository.addRecord(record2);
      await TagRepository.addTagToRecord(recordId2, '사용횟수태그');

      // When: 태그 사용 횟수 조회
      final count = await TagRepository.getTagUsageCount('사용횟수태그');

      // Then: 사용 횟수가 올바르게 반환되어야 함
      expect(count, 2);
    });

    test('기록에 태그 중복 추가 방지', () async {
      // Given: 기록에 태그 추가
      await TagRepository.addTagToRecord(testRecordId, '중복태그');

      // When: 같은 태그를 다시 추가 시도
      await TagRepository.addTagToRecord(testRecordId, '중복태그');

      // Then: 태그가 하나만 있어야 함
      final tags = await TagRepository.getTagsByRecordId(testRecordId);
      expect(tags.where((t) => t == '중복태그').length, 1);
    });

    test('존재하지 않는 태그 제거 시 에러 없음', () async {
      // When: 존재하지 않는 태그 제거 시도
      // Then: 에러가 발생하지 않아야 함
      await TagRepository.removeTagFromRecord(testRecordId, '존재하지않는태그');
    });
  });
}
