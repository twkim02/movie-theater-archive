import 'package:flutter_test/flutter_test.dart';
import 'package:movie_diary_app/models/summary.dart';

void main() {
  group('StatisticsSummary 모델 테스트', () {
    test('JSON에서 StatisticsSummary 객체로 변환', () {
      // Given: 더미데이터 예시.txt 형식의 JSON
      final json = {
        "totalRecords": 7,
        "averageRating": 4.1,
        "topGenre": "판타지",
      };

      // When: fromJson으로 변환
      final summary = StatisticsSummary.fromJson(json);

      // Then: 모든 필드가 올바르게 변환되었는지 확인
      expect(summary.totalRecords, 7);
      expect(summary.averageRating, 4.1);
      expect(summary.topGenre, "판타지");
    });

    test('StatisticsSummary 객체를 JSON으로 변환', () {
      // Given: StatisticsSummary 객체
      final summary = StatisticsSummary(
        totalRecords: 7,
        averageRating: 4.1,
        topGenre: "판타지",
      );

      // When: toJson으로 변환
      final json = summary.toJson();

      // Then: 모든 필드가 올바르게 변환되었는지 확인
      expect(json['totalRecords'], 7);
      expect(json['averageRating'], 4.1);
      expect(json['topGenre'], "판타지");
    });

    test('fromJson과 toJson이 서로 호환되는지 확인 (Round-trip)', () {
      // Given: 원본 JSON
      final originalJson = {
        "totalRecords": 7,
        "averageRating": 4.1,
        "topGenre": "판타지",
      };

      // When: JSON → StatisticsSummary → JSON 변환
      final summary = StatisticsSummary.fromJson(originalJson);
      final convertedJson = summary.toJson();

      // Then: 원본과 변환된 JSON이 같아야 함
      expect(convertedJson['totalRecords'], originalJson['totalRecords']);
      expect(convertedJson['averageRating'], originalJson['averageRating']);
      expect(convertedJson['topGenre'], originalJson['topGenre']);
    });
  });

  group('GenreDistributionItem 모델 테스트', () {
    test('JSON에서 GenreDistributionItem 객체로 변환', () {
      // Given: 더미데이터 예시.txt 형식의 JSON
      final json = {
        "name": "판타지",
        "count": 4,
      };

      // When: fromJson으로 변환
      final item = GenreDistributionItem.fromJson(json);

      // Then: 모든 필드가 올바르게 변환되었는지 확인
      expect(item.name, "판타지");
      expect(item.count, 4);
    });

    test('GenreDistributionItem 객체를 JSON으로 변환', () {
      // Given: GenreDistributionItem 객체
      final item = GenreDistributionItem(name: "액션", count: 3);

      // When: toJson으로 변환
      final json = item.toJson();

      // Then: 모든 필드가 올바르게 변환되었는지 확인
      expect(json['name'], "액션");
      expect(json['count'], 3);
    });
  });

  group('ViewingTrendItem 모델 테스트', () {
    test('JSON에서 ViewingTrendItem 객체로 변환 (연도)', () {
      // Given: 연도별 추이 JSON
      final json = {
        "date": "2026",
        "count": 4,
      };

      // When: fromJson으로 변환
      final item = ViewingTrendItem.fromJson(json);

      // Then: 모든 필드가 올바르게 변환되었는지 확인
      expect(item.date, "2026");
      expect(item.count, 4);
    });

    test('JSON에서 ViewingTrendItem 객체로 변환 (월)', () {
      // Given: 월별 추이 JSON
      final json = {
        "date": "2026-01",
        "count": 4,
      };

      // When: fromJson으로 변환
      final item = ViewingTrendItem.fromJson(json);

      // Then: 모든 필드가 올바르게 변환되었는지 확인
      expect(item.date, "2026-01");
      expect(item.count, 4);
    });

    test('ViewingTrendItem 객체를 JSON으로 변환', () {
      // Given: ViewingTrendItem 객체
      final item = ViewingTrendItem(date: "2025-10", count: 1);

      // When: toJson으로 변환
      final json = item.toJson();

      // Then: 모든 필드가 올바르게 변환되었는지 확인
      expect(json['date'], "2025-10");
      expect(json['count'], 1);
    });
  });

  group('GenreDistribution 모델 테스트', () {
    test('JSON에서 GenreDistribution 객체로 변환', () {
      // Given: 더미데이터 예시.txt 형식의 JSON
      final json = {
        "all": [
          {"name": "판타지", "count": 4},
          {"name": "액션", "count": 3},
        ],
        "recent1Year": [
          {"name": "판타지", "count": 4},
        ],
        "recent3Years": [
          {"name": "판타지", "count": 4},
          {"name": "액션", "count": 3},
        ],
      };

      // When: fromJson으로 변환
      final distribution = GenreDistribution.fromJson(json);

      // Then: 모든 필드가 올바르게 변환되었는지 확인
      expect(distribution.all.length, 2);
      expect(distribution.all[0].name, "판타지");
      expect(distribution.recent1Year.length, 1);
      expect(distribution.recent3Years.length, 2);
    });

    test('GenreDistribution 객체를 JSON으로 변환', () {
      // Given: GenreDistribution 객체
      final distribution = GenreDistribution(
        all: [
          GenreDistributionItem(name: "판타지", count: 4),
          GenreDistributionItem(name: "액션", count: 3),
        ],
        recent1Year: [
          GenreDistributionItem(name: "판타지", count: 4),
        ],
        recent3Years: [
          GenreDistributionItem(name: "판타지", count: 4),
        ],
      );

      // When: toJson으로 변환
      final json = distribution.toJson();

      // Then: 모든 필드가 올바르게 변환되었는지 확인
      expect(json['all'], isA<List>());
      expect(json['recent1Year'], isA<List>());
      expect(json['recent3Years'], isA<List>());
      expect((json['all'] as List).length, 2);
    });
  });

  group('ViewingTrend 모델 테스트', () {
    test('JSON에서 ViewingTrend 객체로 변환', () {
      // Given: 더미데이터 예시.txt 형식의 JSON
      final json = {
        "yearly": [
          {"date": "2025", "count": 3},
          {"date": "2026", "count": 4},
        ],
        "monthly": [
          {"date": "2025-10", "count": 1},
          {"date": "2026-01", "count": 4},
        ],
      };

      // When: fromJson으로 변환
      final trend = ViewingTrend.fromJson(json);

      // Then: 모든 필드가 올바르게 변환되었는지 확인
      expect(trend.yearly.length, 2);
      expect(trend.yearly[0].date, "2025");
      expect(trend.monthly.length, 2);
      expect(trend.monthly[0].date, "2025-10");
    });

    test('ViewingTrend 객체를 JSON으로 변환', () {
      // Given: ViewingTrend 객체
      final trend = ViewingTrend(
        yearly: [
          ViewingTrendItem(date: "2025", count: 3),
          ViewingTrendItem(date: "2026", count: 4),
        ],
        monthly: [
          ViewingTrendItem(date: "2025-10", count: 1),
        ],
      );

      // When: toJson으로 변환
      final json = trend.toJson();

      // Then: 모든 필드가 올바르게 변환되었는지 확인
      expect(json['yearly'], isA<List>());
      expect(json['monthly'], isA<List>());
      expect((json['yearly'] as List).length, 2);
    });
  });

  group('Statistics 모델 테스트', () {
    test('JSON에서 Statistics 객체로 변환', () {
      // Given: 더미데이터 예시.txt 형식의 전체 JSON
      final json = {
        "summary": {
          "totalRecords": 7,
          "averageRating": 4.1,
          "topGenre": "판타지"
        },
        "genreDistribution": {
          "all": [
            {"name": "판타지", "count": 4},
            {"name": "액션", "count": 3},
          ],
          "recent1Year": [
            {"name": "판타지", "count": 4},
          ],
          "recent3Years": [
            {"name": "판타지", "count": 4},
          ]
        },
        "viewingTrend": {
          "yearly": [
            {"date": "2025", "count": 3},
            {"date": "2026", "count": 4}
          ],
          "monthly": [
            {"date": "2025-10", "count": 1},
            {"date": "2026-01", "count": 4}
          ]
        }
      };

      // When: fromJson으로 변환
      final statistics = Statistics.fromJson(json);

      // Then: 모든 필드가 올바르게 변환되었는지 확인
      expect(statistics.summary.totalRecords, 7);
      expect(statistics.summary.averageRating, 4.1);
      expect(statistics.summary.topGenre, "판타지");
      expect(statistics.genreDistribution.all.length, 2);
      expect(statistics.viewingTrend.yearly.length, 2);
      expect(statistics.viewingTrend.monthly.length, 2);
    });

    test('Statistics 객체를 JSON으로 변환', () {
      // Given: Statistics 객체
      final statistics = Statistics(
        summary: StatisticsSummary(
          totalRecords: 7,
          averageRating: 4.1,
          topGenre: "판타지",
        ),
        genreDistribution: GenreDistribution(
          all: [GenreDistributionItem(name: "판타지", count: 4)],
          recent1Year: [GenreDistributionItem(name: "판타지", count: 4)],
          recent3Years: [GenreDistributionItem(name: "판타지", count: 4)],
        ),
        viewingTrend: ViewingTrend(
          yearly: [ViewingTrendItem(date: "2026", count: 4)],
          monthly: [ViewingTrendItem(date: "2026-01", count: 4)],
        ),
      );

      // When: toJson으로 변환
      final json = statistics.toJson();

      // Then: 모든 필드가 올바르게 변환되었는지 확인
      expect(json['summary'], isA<Map<String, dynamic>>());
      expect(json['genreDistribution'], isA<Map<String, dynamic>>());
      expect(json['viewingTrend'], isA<Map<String, dynamic>>());
      expect(json['summary']['totalRecords'], 7);
    });

    test('fromJson과 toJson이 서로 호환되는지 확인 (Round-trip)', () {
      // Given: 원본 JSON
      final originalJson = {
        "summary": {
          "totalRecords": 7,
          "averageRating": 4.1,
          "topGenre": "판타지"
        },
        "genreDistribution": {
          "all": [
            {"name": "판타지", "count": 4}
          ],
          "recent1Year": [
            {"name": "판타지", "count": 4}
          ],
          "recent3Years": [
            {"name": "판타지", "count": 4}
          ]
        },
        "viewingTrend": {
          "yearly": [
            {"date": "2026", "count": 4}
          ],
          "monthly": [
            {"date": "2026-01", "count": 4}
          ]
        }
      };

      // When: JSON → Statistics → JSON 변환
      final statistics = Statistics.fromJson(originalJson);
      final convertedJson = statistics.toJson();

      // Then: 원본과 변환된 JSON의 주요 필드가 같아야 함
      final originalSummary = originalJson['summary'] as Map<String, dynamic>;
      final convertedSummary = convertedJson['summary'] as Map<String, dynamic>;
      expect(convertedSummary['totalRecords'], originalSummary['totalRecords']);
      expect(convertedSummary['averageRating'], originalSummary['averageRating']);
    });
  });
}
