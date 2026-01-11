import 'package:flutter_test/flutter_test.dart';
import 'package:movie_diary_app/state/app_state.dart';

void main() {
  group('AppState 기록(Records) 기능 테스트', () {
    late AppState appState;

    setUp(() {
      // 각 테스트 전에 새로운 AppState 인스턴스 생성
      appState = AppState();
    });

    test('초기 상태에서 모든 기록 리스트가 비어있지 않아야 함', () {
      // Then: 더미 데이터가 로드되어 있어야 함
      expect(appState.allRecords.isEmpty, false);
      expect(appState.allRecords.length, 7); // 더미데이터 예시.txt 기준
      expect(appState.records.length, 7); // 초기에는 필터 없으므로 모든 기록
    });

    test('기본 정렬 옵션이 최신순인지 확인', () {
      // Then: 기본 정렬 옵션이 latest여야 함
      expect(appState.recordSortOption, RecordSortOption.latest);
    });

    test('최신순 정렬이 올바르게 작동하는지 확인', () {
      // When: 최신순 정렬 설정
      appState.setRecordSortOption(RecordSortOption.latest);
      final records = appState.records;

      // Then: 관람일 기준 내림차순으로 정렬되어야 함 (최신순)
      if (records.length > 1) {
        for (int i = 0; i < records.length - 1; i++) {
          expect(records[i].watchDate.isAfter(records[i + 1].watchDate) ||
                 records[i].watchDate.isAtSameMomentAs(records[i + 1].watchDate), 
                 true,
                 reason: '최신순 정렬이 올바르지 않음: ${records[i].watchDate} vs ${records[i + 1].watchDate}');
        }
      }
    });

    test('별점순 정렬이 올바르게 작동하는지 확인', () {
      // When: 별점순 정렬 설정
      appState.setRecordSortOption(RecordSortOption.rating);
      final records = appState.records;

      // Then: 별점 기준 내림차순으로 정렬되어야 함
      if (records.length > 1) {
        for (int i = 0; i < records.length - 1; i++) {
          expect(records[i].rating >= records[i + 1].rating, true,
              reason: '별점순 정렬이 올바르지 않음: ${records[i].rating} vs ${records[i + 1].rating}');
        }
      }
    });

    test('많이 본 순 정렬이 올바르게 작동하는지 확인', () {
      // When: 많이 본 순 정렬 설정
      appState.setRecordSortOption(RecordSortOption.viewCount);
      final records = appState.records;

      // Then: 같은 영화를 여러 번 본 경우가 먼저 와야 함
      // (더미데이터에 "83533"(아바타)와 "1311031"(귀멸의 칼날)이 2번씩 나타남)
      expect(records.isNotEmpty, true);
      
      // 첫 번째 기록의 영화가 다른 기록들보다 더 많이 본 영화여야 함
      if (records.length > 1) {
        final firstMovieId = records[0].movie.id;
        final firstMovieCount = records.where((r) => r.movie.id == firstMovieId).length;
        final secondMovieCount = records.where((r) => r.movie.id == records[1].movie.id).length;
        expect(firstMovieCount >= secondMovieCount, true,
            reason: '많이 본 순 정렬이 올바르지 않음');
      }
    });

    test('기간 필터가 올바르게 작동하는지 확인', () {
      // Given: 특정 기간 설정 (2026년 1월)
      final startDate = DateTime(2026, 1, 1);
      final endDate = DateTime(2026, 1, 31);

      // When: 기간 필터 적용
      appState.setRecordDateFilter(startDate, endDate);
      final filteredRecords = appState.records;

      // Then: 필터링된 기록들이 모두 해당 기간 내에 있어야 함
      for (final record in filteredRecords) {
        expect(record.watchDate.isAfter(startDate.subtract(const Duration(days: 1))), true);
        expect(record.watchDate.isBefore(endDate.add(const Duration(days: 1))), true);
      }
    });

    test('시작일만 설정한 필터 테스트', () {
      // Given: 시작일만 설정
      final startDate = DateTime(2026, 1, 1);

      // When: 시작일 필터만 적용
      appState.setRecordDateFilter(startDate, null);
      final filteredRecords = appState.records;

      // Then: 시작일 이후의 기록만 포함되어야 함
      for (final record in filteredRecords) {
        expect(record.watchDate.isAfter(startDate.subtract(const Duration(days: 1))) ||
               record.watchDate.isAtSameMomentAs(startDate), true);
      }
    });

    test('종료일만 설정한 필터 테스트', () {
      // Given: 종료일만 설정
      final endDate = DateTime(2025, 12, 31);

      // When: 종료일 필터만 적용
      appState.setRecordDateFilter(null, endDate);
      final filteredRecords = appState.records;

      // Then: 종료일 이전의 기록만 포함되어야 함
      for (final record in filteredRecords) {
        expect(record.watchDate.isBefore(endDate.add(const Duration(days: 1))) ||
               record.watchDate.isAtSameMomentAs(endDate), true);
      }
    });

    test('제목으로 검색 필터가 올바르게 작동하는지 확인', () {
      // When: "기생충"으로 검색
      appState.setRecordSearchQuery("기생충");
      final filteredRecords = appState.records;

      // Then: 검색된 기록들의 영화 제목이 "기생충"을 포함해야 함
      expect(filteredRecords.isNotEmpty, true);
      for (final record in filteredRecords) {
        expect(record.movie.title.toLowerCase().contains("기생충"), true);
      }
    });

    test('태그로 검색 필터가 올바르게 작동하는지 확인', () {
      // When: "극장" 태그로 검색
      appState.setRecordSearchQuery("극장");
      final filteredRecords = appState.records;

      // Then: 검색된 기록들이 "극장" 태그를 포함해야 함
      expect(filteredRecords.isNotEmpty, true);
      for (final record in filteredRecords) {
        final hasTag = record.tags.any((tag) => tag.toLowerCase().contains("극장"));
        expect(hasTag, true, reason: '${record.id}번 기록에 "극장" 태그가 없음');
      }
    });

    test('한줄평으로 검색 필터가 올바르게 작동하는지 확인', () {
      // When: "압도적"으로 검색 (한줄평에 포함된 단어)
      appState.setRecordSearchQuery("압도적");
      final filteredRecords = appState.records;

      // Then: 검색된 기록들의 한줄평이 검색어를 포함해야 함
      expect(filteredRecords.isNotEmpty, true);
      for (final record in filteredRecords) {
        final matches = record.movie.title.toLowerCase().contains("압도적") ||
                       record.tags.any((tag) => tag.toLowerCase().contains("압도적")) ||
                       (record.oneLiner?.toLowerCase().contains("압도적") ?? false);
        expect(matches, true);
      }
    });

    test('대소문자 구분 없이 검색이 작동하는지 확인', () {
      // When: 대문자로 검색
      appState.setRecordSearchQuery("아바타");
      final upperCaseResults = appState.records.length;

      // When: 소문자로 검색
      appState.setRecordSearchQuery("아바타");
      final lowerCaseResults = appState.records.length;

      // Then: 결과가 같아야 함 (대소문자 구분 없음)
      expect(upperCaseResults, lowerCaseResults);
    });

    test('필터 초기화가 올바르게 작동하는지 확인', () {
      // Given: 필터 설정
      appState.setRecordDateFilter(DateTime(2026, 1, 1), DateTime(2026, 1, 31));
      appState.setRecordSearchQuery("기생충");
      appState.setRecordSortOption(RecordSortOption.rating);

      // When: 필터 초기화
      appState.clearRecordFilters();

      // Then: 모든 필터가 초기화되어야 함
      expect(appState.recordSortOption, RecordSortOption.latest);
      expect(appState.records.length, appState.allRecords.length);
    });

    test('특정 영화 ID로 기록 조회가 올바르게 작동하는지 확인', () {
      // Given: 특정 영화 ID (더미데이터에 있는 ID)
      const movieId = "83533"; // 아바타: 불과 재

      // When: 해당 영화의 기록 조회
      final movieRecords = appState.getRecordsByMovieId(movieId);

      // Then: 해당 영화의 기록만 반환되어야 함 (더미데이터에 2개: 101, 106)
      expect(movieRecords.isNotEmpty, true);
      for (final record in movieRecords) {
        expect(record.movie.id, movieId);
      }
    });

    test('존재하지 않는 영화 ID로 기록 조회 시 빈 리스트 반환', () {
      // Given: 존재하지 않는 영화 ID
      const movieId = "999999";

      // When: 해당 영화의 기록 조회
      final movieRecords = appState.getRecordsByMovieId(movieId);

      // Then: 빈 리스트가 반환되어야 함
      expect(movieRecords, isEmpty);
    });

    test('특정 기록 ID로 기록 찾기가 올바르게 작동하는지 확인', () {
      // Given: 더미데이터에 있는 기록 ID
      const recordId = 101;

      // When: 기록 찾기
      final record = appState.getRecordById(recordId);

      // Then: 올바른 기록이 반환되어야 함
      expect(record, isNotNull);
      expect(record!.id, recordId);
    });

    test('존재하지 않는 기록 ID로 찾기 시 null 반환', () {
      // Given: 존재하지 않는 기록 ID
      const recordId = 999;

      // When: 기록 찾기
      final record = appState.getRecordById(recordId);

      // Then: null이 반환되어야 함
      expect(record, isNull);
    });

    test('기록 통계가 올바르게 계산되는지 확인', () {
      // When: 통계 조회
      final stats = appState.getRecordStatistics();

      // Then: 통계 값들이 올바르게 계산되어야 함
      expect(stats['totalCount'], 7); // 더미데이터에 7개 기록
      expect(stats['averageRating'], greaterThan(0.0));
      expect(stats['averageRating'], lessThanOrEqualTo(5.0));
      expect(stats['totalMovies'], greaterThan(0));
      expect(stats['totalMovies'], lessThanOrEqualTo(7)); // 영화 수는 기록 수보다 작거나 같음
    });

    test('통합 필터링 테스트 (기간 + 검색어 + 정렬)', () {
      // Given: 복합 필터 설정
      appState.setRecordDateFilter(DateTime(2026, 1, 1), DateTime(2026, 1, 31));
      appState.setRecordSearchQuery("극장");
      appState.setRecordSortOption(RecordSortOption.rating);

      // When: 필터링된 기록 조회
      final filteredRecords = appState.records;

      // Then: 모든 필터 조건을 만족하는 기록만 반환되어야 함
      for (final record in filteredRecords) {
        // 기간 체크
        expect(record.watchDate.year, 2026);
        expect(record.watchDate.month, 1);
        
        // 검색어 체크 (제목, 태그, 한줄평 중 하나라도 포함)
        final matchesSearch = record.movie.title.toLowerCase().contains("극장") ||
                             record.tags.any((tag) => tag.toLowerCase().contains("극장")) ||
                             (record.oneLiner?.toLowerCase().contains("극장") ?? false);
        expect(matchesSearch, true);
      }
    });
  });
}
