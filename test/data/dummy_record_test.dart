import 'package:flutter_test/flutter_test.dart';
import 'package:movie_diary_app/data/dummy_record.dart';
import 'package:movie_diary_app/models/record.dart';

void main() {
  group('DummyRecords 테스트', () {
    test('더미 기록 데이터가 올바르게 로드되는지 확인', () {
      // When: 더미 기록 목록 가져오기
      final records = DummyRecords.getRecords();

      // Then: 7개의 기록이 있어야 함 (더미데이터 예시.txt 기준)
      expect(records.length, 7);
    });

    test('각 기록의 필수 필드가 모두 채워져 있는지 확인', () {
      // When: 더미 기록 목록 가져오기
      final records = DummyRecords.getRecords();

      // Then: 모든 기록의 필수 필드 확인
      for (final record in records) {
        expect(record.id, greaterThan(0), reason: '${record.id}번 기록의 id가 유효하지 않음');
        expect(record.userId, greaterThan(0), reason: '${record.id}번 기록의 userId가 유효하지 않음');
        expect(record.rating, greaterThanOrEqualTo(0.0), reason: '${record.id}번 기록의 rating이 0 이상이어야 함');
        expect(record.rating, lessThanOrEqualTo(5.0), reason: '${record.id}번 기록의 rating이 5 이하여야 함');
        expect(record.watchDate, isNotNull, reason: '${record.id}번 기록의 watchDate가 null임');
        expect(record.tags, isNotNull, reason: '${record.id}번 기록의 tags가 null임');
        expect(record.movie, isNotNull, reason: '${record.id}번 기록의 movie가 null임');
        expect(record.movie.id.isNotEmpty, true, reason: '${record.id}번 기록의 movie.id가 비어있음');
        expect(record.movie.title.isNotEmpty, true, reason: '${record.id}번 기록의 movie.title이 비어있음');
      }
    });

    test('더미데이터에 포함된 특정 기록이 있는지 확인', () {
      // Given: 더미데이터 예시.txt에 있는 기록 ID들
      final expectedIds = [101, 102, 103, 104, 105, 106, 107];

      // When: 더미 기록 목록 가져오기
      final records = DummyRecords.getRecords();
      final actualIds = records.map((r) => r.id).toList();

      // Then: 예상된 모든 기록 ID가 포함되어 있어야 함
      for (final expectedId in expectedIds) {
        expect(actualIds.contains(expectedId), true, 
            reason: 'ID $expectedId가 더미데이터에 없음');
      }
    });

    test('모든 기록의 ID가 고유한지 확인', () {
      // When: 더미 기록 목록 가져오기
      final records = DummyRecords.getRecords();
      final ids = records.map((r) => r.id).toList();

      // Then: 모든 ID가 고유해야 함 (Set으로 변환하면 중복이 제거됨)
      expect(ids.toSet().length, ids.length, 
          reason: '중복된 기록 ID가 있습니다');
    });

    test('특정 영화에 대한 기록이 올바르게 연결되어 있는지 확인', () {
      // Given: 더미데이터 예시.txt에 있는 영화 ID들
      final movieIds = ["83533", "496243", "1311031", "639988", "361743"];

      // When: 더미 기록 목록 가져오기
      final records = DummyRecords.getRecords();

      // Then: 모든 기록의 movie.id가 실제 더미 영화 데이터에 존재해야 함
      for (final record in records) {
        expect(movieIds.contains(record.movie.id), true,
            reason: '${record.id}번 기록의 영화 ID ${record.movie.id}가 더미 영화 데이터에 없음');
      }
    });

    test('기록의 태그가 올바르게 설정되어 있는지 확인', () {
      // When: 더미 기록 목록 가져오기
      final records = DummyRecords.getRecords();

      // Then: 모든 기록에 최소 1개 이상의 태그가 있어야 함 (더미데이터 기준)
      for (final record in records) {
        expect(record.tags.isNotEmpty, true,
            reason: '${record.id}번 기록에 태그가 없음');
      }
    });

    test('기록의 rating 범위가 올바른지 확인', () {
      // When: 더미 기록 목록 가져오기
      final records = DummyRecords.getRecords();

      // Then: 모든 rating이 0.0 ~ 5.0 범위 내에 있어야 함
      for (final record in records) {
        expect(record.rating >= 0.0 && record.rating <= 5.0, true,
            reason: '${record.id}번 기록의 rating ${record.rating}이 유효 범위를 벗어남');
      }
    });

    test('관람일이 올바른 형식인지 확인', () {
      // When: 더미 기록 목록 가져오기
      final records = DummyRecords.getRecords();

      // Then: 모든 watchDate가 유효한 날짜여야 함
      for (final record in records) {
        expect(record.watchDate.year, greaterThan(2000),
            reason: '${record.id}번 기록의 관람일이 유효하지 않음');
        expect(record.watchDate.year, lessThanOrEqualTo(2030),
            reason: '${record.id}번 기록의 관람일이 미래가 너무 멈');
      }
    });
  });
}
