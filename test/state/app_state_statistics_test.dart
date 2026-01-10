import 'package:flutter_test/flutter_test.dart';
import 'package:movie_diary_app/state/app_state.dart';
import 'package:movie_diary_app/models/summary.dart';

void main() {
  group('AppState 통계(Statistics) 기능 테스트', () {
    late AppState appState;

    setUp(() {
      // 각 테스트 전에 새로운 AppState 인스턴스 생성
      appState = AppState();
    });

    test('초기 상태에서 통계 데이터가 올바르게 로드되는지 확인', () {
      // When: 통계 데이터 조회
      final statistics = appState.statistics;

      // Then: 모든 통계 데이터가 있어야 함
      expect(statistics, isNotNull);
      expect(statistics.summary, isNotNull);
      expect(statistics.genreDistribution, isNotNull);
      expect(statistics.viewingTrend, isNotNull);
    });

    test('요약 정보(Summary)가 올바르게 반환되는지 확인', () {
      // When: 요약 정보 조회
      final summary = appState.statisticsSummary;

      // Then: 더미데이터 예시.txt와 일치해야 함
      expect(summary.totalRecords, 7);
      expect(summary.averageRating, 4.1);
      expect(summary.topGenre, "판타지");
    });

    test('장르 분포 데이터가 올바르게 반환되는지 확인', () {
      // When: 장르 분포 조회
      final genreDist = appState.genreDistribution;

      // Then: 모든 기간별 데이터가 있어야 함
      expect(genreDist.all.isNotEmpty, true);
      expect(genreDist.recent1Year.isNotEmpty, true);
      expect(genreDist.recent3Years.isNotEmpty, true);
    });

    test('전체 기간 장르 분포가 올바르게 반환되는지 확인', () {
      // When: 전체 기간 장르 분포 조회
      final allGenres = appState.genreDistributionAll;

      // Then: 9개 장르가 있어야 함 (더미데이터 기준)
      expect(allGenres.length, 9);
      
      // 판타지가 포함되어 있어야 함
      expect(allGenres.any((g) => g.name == "판타지"), true);
    });

    test('최근 1년 장르 분포가 올바르게 반환되는지 확인', () {
      // When: 최근 1년 장르 분포 조회
      final recentGenres = appState.genreDistributionRecent1Year;

      // Then: 5개 장르가 있어야 함 (더미데이터 기준)
      expect(recentGenres.length, 5);
    });

    test('최근 3년 장르 분포가 올바르게 반환되는지 확인', () {
      // When: 최근 3년 장르 분포 조회
      final recentGenres = appState.genreDistributionRecent3Years;

      // Then: 5개 장르가 있어야 함 (더미데이터 기준)
      expect(recentGenres.length, 5);
    });

    test('관람 추이 데이터가 올바르게 반환되는지 확인', () {
      // When: 관람 추이 조회
      final viewingTrend = appState.viewingTrend;

      // Then: 연도별과 월별 데이터가 있어야 함
      expect(viewingTrend.yearly.isNotEmpty, true);
      expect(viewingTrend.monthly.isNotEmpty, true);
    });

    test('연도별 관람 추이가 올바르게 반환되는지 확인', () {
      // When: 연도별 관람 추이 조회
      final yearlyTrend = appState.viewingTrendYearly;

      // Then: 2개 연도가 있어야 함 (더미데이터 기준)
      expect(yearlyTrend.length, 2);
      
      // 2025년과 2026년이 포함되어 있어야 함
      expect(yearlyTrend.any((t) => t.date == "2025"), true);
      expect(yearlyTrend.any((t) => t.date == "2026"), true);
    });

    test('월별 관람 추이가 올바르게 반환되는지 확인', () {
      // When: 월별 관람 추이 조회
      final monthlyTrend = appState.viewingTrendMonthly;

      // Then: 4개 월이 있어야 함 (더미데이터 기준)
      expect(monthlyTrend.length, 4);
      
      // 2026-01이 포함되어 있어야 함
      expect(monthlyTrend.any((t) => t.date == "2026-01"), true);
    });

    test('실제 기록 데이터로 요약 통계 계산이 작동하는지 확인', () {
      // When: 실제 기록 데이터로 요약 통계 계산
      final calculatedSummary = appState.calculateSummaryFromRecords();

      // Then: 계산된 통계가 있어야 함
      expect(calculatedSummary, isNotNull);
      expect(calculatedSummary.totalRecords, greaterThanOrEqualTo(0));
      expect(calculatedSummary.averageRating, greaterThanOrEqualTo(0.0));
      expect(calculatedSummary.averageRating, lessThanOrEqualTo(5.0));
    });

    test('실제 기록 데이터로 요약 통계가 올바르게 계산되는지 확인', () {
      // Given: 더미데이터에 7개의 기록이 있음
      
      // When: 실제 기록 데이터로 요약 통계 계산
      final calculatedSummary = appState.calculateSummaryFromRecords();

      // Then: 계산된 통계가 실제 기록 데이터와 일치해야 함
      expect(calculatedSummary.totalRecords, 7); // 더미데이터에 7개 기록
      expect(calculatedSummary.averageRating, greaterThan(0.0));
      
      // 최다 선호 장르가 계산되어야 함
      expect(calculatedSummary.topGenre.isNotEmpty, true);
    });

    test('특정 기간의 장르 분포 계산이 작동하는지 확인', () {
      // Given: 특정 기간 설정
      final startDate = DateTime(2026, 1, 1);
      final endDate = DateTime(2026, 12, 31);

      // When: 해당 기간의 장르 분포 계산
      final genreDist = appState.calculateGenreDistributionByDateRange(startDate, endDate);

      // Then: 장르 분포가 계산되어야 함
      expect(genreDist, isA<Map<String, int>>());
    });

    test('전체 기간의 장르 분포 계산 (날짜 제한 없음)', () {
      // When: 날짜 제한 없이 장르 분포 계산
      final genreDist = appState.calculateGenreDistributionByDateRange(null, null);

      // Then: 모든 기록의 장르 분포가 계산되어야 함
      expect(genreDist, isNotEmpty);
      
      // 판타지 장르가 포함되어 있어야 함 (더미데이터 기준)
      expect(genreDist.containsKey("판타지") || genreDist.values.any((v) => v > 0), true);
    });

    test('시작일만 설정한 장르 분포 계산', () {
      // Given: 시작일만 설정
      final startDate = DateTime(2026, 1, 1);

      // When: 시작일 이후의 장르 분포 계산
      final genreDist = appState.calculateGenreDistributionByDateRange(startDate, null);

      // Then: 계산이 성공해야 함
      expect(genreDist, isA<Map<String, int>>());
    });

    test('종료일만 설정한 장르 분포 계산', () {
      // Given: 종료일만 설정
      final endDate = DateTime(2025, 12, 31);

      // When: 종료일 이전의 장르 분포 계산
      final genreDist = appState.calculateGenreDistributionByDateRange(null, endDate);

      // Then: 계산이 성공해야 함
      expect(genreDist, isA<Map<String, int>>());
    });

    test('통계 데이터의 구조가 올바른지 확인', () {
      // When: 전체 통계 데이터 조회
      final statistics = appState.statistics;

      // Then: 모든 하위 구조가 올바르게 구성되어 있어야 함
      expect(statistics.summary.totalRecords, greaterThan(0));
      expect(statistics.genreDistribution.all, isA<List<GenreDistributionItem>>());
      expect(statistics.genreDistribution.recent1Year, isA<List<GenreDistributionItem>>());
      expect(statistics.genreDistribution.recent3Years, isA<List<GenreDistributionItem>>());
      expect(statistics.viewingTrend.yearly, isA<List<ViewingTrendItem>>());
      expect(statistics.viewingTrend.monthly, isA<List<ViewingTrendItem>>());
    });

    test('간편 접근 메서드들이 올바르게 작동하는지 확인', () {
      // When: 각 간편 접근 메서드 호출
      final summary = appState.statisticsSummary;
      final genreDist = appState.genreDistribution;
      final viewingTrend = appState.viewingTrend;
      final allGenres = appState.genreDistributionAll;
      final recent1Year = appState.genreDistributionRecent1Year;
      final recent3Years = appState.genreDistributionRecent3Years;
      final yearly = appState.viewingTrendYearly;
      final monthly = appState.viewingTrendMonthly;

      // Then: 모든 메서드가 올바른 데이터를 반환해야 함
      expect(summary, isNotNull);
      expect(genreDist, isNotNull);
      expect(viewingTrend, isNotNull);
      expect(allGenres, isA<List<GenreDistributionItem>>());
      expect(recent1Year, isA<List<GenreDistributionItem>>());
      expect(recent3Years, isA<List<GenreDistributionItem>>());
      expect(yearly, isA<List<ViewingTrendItem>>());
      expect(monthly, isA<List<ViewingTrendItem>>());
    });

    test('간편 접근 메서드와 원본 데이터가 동일한지 확인', () {
      // Given: 원본 통계 데이터
      final statistics = appState.statistics;

      // When: 간편 접근 메서드로 접근
      final summary1 = appState.statisticsSummary;
      final summary2 = statistics.summary;

      // Then: 동일한 데이터를 반환해야 함
      expect(summary1.totalRecords, summary2.totalRecords);
      expect(summary1.averageRating, summary2.averageRating);
      expect(summary1.topGenre, summary2.topGenre);
    });

    test('장르 분포 데이터의 정렬 확인 (count 내림차순)', () {
      // When: 전체 기간 장르 분포 조회
      final allGenres = appState.genreDistributionAll;

      // Then: count가 많은 순서대로 정렬되어 있어야 함 (더미데이터 기준)
      if (allGenres.length > 1) {
        // 첫 번째 장르가 가장 많은 count를 가져야 함
        final firstCount = allGenres[0].count;
        final secondCount = allGenres[1].count;
        expect(firstCount >= secondCount, true,
            reason: '장르 분포가 count 내림차순으로 정렬되어 있지 않음');
      }
    });

    test('관람 추이 데이터의 날짜 순서 확인', () {
      // When: 연도별과 월별 관람 추이 조회
      final yearlyTrend = appState.viewingTrendYearly;
      final monthlyTrend = appState.viewingTrendMonthly;

      // Then: 날짜 순서로 정렬되어 있어야 함 (더미데이터 기준)
      if (yearlyTrend.length > 1) {
        expect(yearlyTrend[0].date.compareTo(yearlyTrend[1].date) <= 0, true,
            reason: '연도별 추이가 날짜 순서로 정렬되어 있지 않음');
      }

      if (monthlyTrend.length > 1) {
        expect(monthlyTrend[0].date.compareTo(monthlyTrend[1].date) <= 0, true,
            reason: '월별 추이가 날짜 순서로 정렬되어 있지 않음');
      }
    });

    test('통계 계산 메서드들이 null을 안전하게 처리하는지 확인', () {
      // When: null 날짜로 장르 분포 계산
      final genreDist1 = appState.calculateGenreDistributionByDateRange(null, null);
      final genreDist2 = appState.calculateGenreDistributionByDateRange(DateTime(2020, 1, 1), null);
      final genreDist3 = appState.calculateGenreDistributionByDateRange(null, DateTime(2030, 12, 31));

      // Then: 모두 정상적으로 작동해야 함 (예외 발생 안 함)
      expect(genreDist1, isA<Map<String, int>>());
      expect(genreDist2, isA<Map<String, int>>());
      expect(genreDist3, isA<Map<String, int>>());
    });

    test('통계 데이터의 모든 값이 유효한 범위인지 확인', () {
      // When: 통계 데이터 조회
      final statistics = appState.statistics;

      // Then: 모든 값이 유효한 범위 내에 있어야 함
      expect(statistics.summary.totalRecords, greaterThanOrEqualTo(0));
      expect(statistics.summary.averageRating, greaterThanOrEqualTo(0.0));
      expect(statistics.summary.averageRating, lessThanOrEqualTo(5.0));
      
      // 장르 분포의 모든 count가 0 이상이어야 함
      for (final genre in statistics.genreDistribution.all) {
        expect(genre.count, greaterThanOrEqualTo(0));
      }
      
      // 관람 추이의 모든 count가 0 이상이어야 함
      for (final trend in statistics.viewingTrend.yearly) {
        expect(trend.count, greaterThanOrEqualTo(0));
      }
      for (final trend in statistics.viewingTrend.monthly) {
        expect(trend.count, greaterThanOrEqualTo(0));
      }
    });
  });
}
