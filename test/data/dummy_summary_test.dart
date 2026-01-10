import 'package:flutter_test/flutter_test.dart';
import 'package:movie_diary_app/data/dummy_summary.dart';
import 'package:movie_diary_app/models/summary.dart';

void main() {
  group('DummySummary 테스트', () {
    test('더미 통계 데이터가 올바르게 로드되는지 확인', () {
      // When: 더미 통계 데이터 가져오기
      final statistics = DummySummary.getStatistics();

      // Then: 모든 필드가 채워져 있어야 함
      expect(statistics, isNotNull);
      expect(statistics.summary, isNotNull);
      expect(statistics.genreDistribution, isNotNull);
      expect(statistics.viewingTrend, isNotNull);
    });

    test('요약 정보(Summary)가 올바른지 확인', () {
      // When: 더미 통계 데이터 가져오기
      final statistics = DummySummary.getStatistics();
      final summary = statistics.summary;

      // Then: 더미데이터 예시.txt와 일치해야 함
      expect(summary.totalRecords, 7);
      expect(summary.averageRating, 4.1);
      expect(summary.topGenre, "판타지");
    });

    test('장르 분포 데이터가 올바른지 확인', () {
      // When: 더미 통계 데이터 가져오기
      final statistics = DummySummary.getStatistics();
      final genreDist = statistics.genreDistribution;

      // Then: 각 기간별 장르 분포가 있어야 함
      expect(genreDist.all.isNotEmpty, true);
      expect(genreDist.recent1Year.isNotEmpty, true);
      expect(genreDist.recent3Years.isNotEmpty, true);

      // 전체 기간에 9개 장르가 있어야 함 (더미데이터 기준)
      expect(genreDist.all.length, 9);
      
      // 최근 1년에 5개 장르가 있어야 함
      expect(genreDist.recent1Year.length, 5);
      
      // 최근 3년에 5개 장르가 있어야 함
      expect(genreDist.recent3Years.length, 5);
    });

    test('장르 분포 항목의 필수 필드가 모두 채워져 있는지 확인', () {
      // When: 더미 통계 데이터 가져오기
      final statistics = DummySummary.getStatistics();
      final allGenres = statistics.genreDistribution.all;

      // Then: 모든 장르 분포 항목의 필수 필드 확인
      for (final genre in allGenres) {
        expect(genre.name.isNotEmpty, true, reason: '장르 이름이 비어있음');
        expect(genre.count, greaterThan(0), reason: '${genre.name}의 count가 0보다 커야 함');
      }
    });

    test('더미데이터에 포함된 특정 장르가 있는지 확인', () {
      // Given: 더미데이터 예시.txt에 있는 장르들
      final expectedGenres = ["판타지", "액션", "SF", "모험", "코미디", "스릴러", "드라마", "애니메이션", "범죄"];

      // When: 더미 통계 데이터 가져오기
      final statistics = DummySummary.getStatistics();
      final allGenres = statistics.genreDistribution.all;
      final actualGenreNames = allGenres.map((g) => g.name).toList();

      // Then: 예상된 모든 장르가 포함되어 있어야 함
      for (final expectedGenre in expectedGenres) {
        expect(actualGenreNames.contains(expectedGenre), true,
            reason: '장르 "$expectedGenre"가 더미데이터에 없음');
      }
    });

    test('관람 추이 데이터가 올바른지 확인', () {
      // When: 더미 통계 데이터 가져오기
      final statistics = DummySummary.getStatistics();
      final viewingTrend = statistics.viewingTrend;

      // Then: 연도별과 월별 추이가 있어야 함
      expect(viewingTrend.yearly.isNotEmpty, true);
      expect(viewingTrend.monthly.isNotEmpty, true);

      // 연도별에 2개 항목이 있어야 함 (더미데이터 기준)
      expect(viewingTrend.yearly.length, 2);
      
      // 월별에 4개 항목이 있어야 함
      expect(viewingTrend.monthly.length, 4);
    });

    test('관람 추이 항목의 필수 필드가 모두 채워져 있는지 확인', () {
      // When: 더미 통계 데이터 가져오기
      final statistics = DummySummary.getStatistics();
      final yearlyTrend = statistics.viewingTrend.yearly;
      final monthlyTrend = statistics.viewingTrend.monthly;

      // Then: 모든 추이 항목의 필수 필드 확인
      for (final trend in yearlyTrend) {
        expect(trend.date.isNotEmpty, true, reason: '연도 추이의 date가 비어있음');
        expect(trend.count, greaterThanOrEqualTo(0), reason: '${trend.date}의 count가 0 이상이어야 함');
      }

      for (final trend in monthlyTrend) {
        expect(trend.date.isNotEmpty, true, reason: '월별 추이의 date가 비어있음');
        expect(trend.count, greaterThanOrEqualTo(0), reason: '${trend.date}의 count가 0 이상이어야 함');
      }
    });

    test('더미데이터에 포함된 특정 연도/월이 있는지 확인', () {
      // Given: 더미데이터 예시.txt에 있는 연도와 월
      final expectedYears = ["2025", "2026"];
      final expectedMonths = ["2025-10", "2025-11", "2025-12", "2026-01"];

      // When: 더미 통계 데이터 가져오기
      final statistics = DummySummary.getStatistics();
      final yearlyDates = statistics.viewingTrend.yearly.map((t) => t.date).toList();
      final monthlyDates = statistics.viewingTrend.monthly.map((t) => t.date).toList();

      // Then: 예상된 모든 연도가 포함되어 있어야 함
      for (final expectedYear in expectedYears) {
        expect(yearlyDates.contains(expectedYear), true,
            reason: '연도 "$expectedYear"가 더미데이터에 없음');
      }

      // 예상된 모든 월이 포함되어 있어야 함
      for (final expectedMonth in expectedMonths) {
        expect(monthlyDates.contains(expectedMonth), true,
            reason: '월 "$expectedMonth"가 더미데이터에 없음');
      }
    });

    test('장르 분포의 count 합계가 기록 수와 일치하는지 확인', () {
      // When: 더미 통계 데이터 가져오기
      final statistics = DummySummary.getStatistics();
      final totalRecords = statistics.summary.totalRecords;

      // Then: 전체 장르 분포의 count 합계가 기록 수와 비슷해야 함
      // (한 기록에 여러 장르가 있을 수 있으므로 정확히 일치하지 않을 수 있음)
      final allGenresTotal = statistics.genreDistribution.all
          .map((g) => g.count)
          .reduce((a, b) => a + b);

      // 최소한 기록 수보다는 크거나 같아야 함 (한 영화에 여러 장르)
      expect(allGenresTotal, greaterThanOrEqualTo(totalRecords));
    });

    test('월별 추이의 count 합계가 연도별 추이와 일치하는지 확인', () {
      // When: 더미 통계 데이터 가져오기
      final statistics = DummySummary.getStatistics();
      final yearlyTotal = statistics.viewingTrend.yearly
          .map((t) => t.count)
          .reduce((a, b) => a + b);
      final monthlyTotal = statistics.viewingTrend.monthly
          .map((t) => t.count)
          .reduce((a, b) => a + b);

      // Then: 월별 합계가 연도별 합계와 일치해야 함
      expect(monthlyTotal, yearlyTotal);
    });
  });
}
