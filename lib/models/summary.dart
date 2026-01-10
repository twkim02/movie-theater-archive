/// 장르 분포 항목 (장르 이름과 개수)
class GenreDistributionItem {
  final String name; // 장르 이름
  final int count; // 해당 장르를 본 횟수

  GenreDistributionItem({
    required this.name,
    required this.count,
  });

  factory GenreDistributionItem.fromJson(Map<String, dynamic> json) {
    return GenreDistributionItem(
      name: json['name'] as String,
      count: (json['count'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'count': count,
    };
  }

  @override
  String toString() => 'GenreDistributionItem(name: $name, count: $count)';
}

/// 관람 추이 항목 (날짜와 관람 횟수)
class ViewingTrendItem {
  final String date; // 날짜 (YYYY 또는 YYYY-MM 형식)
  final int count; // 해당 기간에 본 영화 수

  ViewingTrendItem({
    required this.date,
    required this.count,
  });

  factory ViewingTrendItem.fromJson(Map<String, dynamic> json) {
    return ViewingTrendItem(
      date: json['date'] as String,
      count: (json['count'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'count': count,
    };
  }

  @override
  String toString() => 'ViewingTrendItem(date: $date, count: $count)';
}

/// 요약 통계 정보
class StatisticsSummary {
  final int totalRecords; // 총 기록 수
  final double averageRating; // 평균 별점
  final String topGenre; // 최다 선호 장르

  StatisticsSummary({
    required this.totalRecords,
    required this.averageRating,
    required this.topGenre,
  });

  factory StatisticsSummary.fromJson(Map<String, dynamic> json) {
    return StatisticsSummary(
      totalRecords: (json['totalRecords'] as num).toInt(),
      averageRating: (json['averageRating'] as num).toDouble(),
      topGenre: json['topGenre'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalRecords': totalRecords,
      'averageRating': averageRating,
      'topGenre': topGenre,
    };
  }

  @override
  String toString() {
    return 'StatisticsSummary(totalRecords: $totalRecords, averageRating: $averageRating, topGenre: $topGenre)';
  }
}

/// 장르 분포 데이터 (전체/최근 1년/최근 3년)
class GenreDistribution {
  final List<GenreDistributionItem> all; // 전체 기간
  final List<GenreDistributionItem> recent1Year; // 최근 1년
  final List<GenreDistributionItem> recent3Years; // 최근 3년

  GenreDistribution({
    required this.all,
    required this.recent1Year,
    required this.recent3Years,
  });

  factory GenreDistribution.fromJson(Map<String, dynamic> json) {
    return GenreDistribution(
      all: (json['all'] as List<dynamic>)
          .map((item) => GenreDistributionItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      recent1Year: (json['recent1Year'] as List<dynamic>)
          .map((item) => GenreDistributionItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      recent3Years: (json['recent3Years'] as List<dynamic>)
          .map((item) => GenreDistributionItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'all': all.map((item) => item.toJson()).toList(),
      'recent1Year': recent1Year.map((item) => item.toJson()).toList(),
      'recent3Years': recent3Years.map((item) => item.toJson()).toList(),
    };
  }
}

/// 관람 추이 데이터 (연도별/월별)
class ViewingTrend {
  final List<ViewingTrendItem> yearly; // 연도별 관람 횟수
  final List<ViewingTrendItem> monthly; // 월별 관람 횟수

  ViewingTrend({
    required this.yearly,
    required this.monthly,
  });

  factory ViewingTrend.fromJson(Map<String, dynamic> json) {
    return ViewingTrend(
      yearly: (json['yearly'] as List<dynamic>)
          .map((item) => ViewingTrendItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      monthly: (json['monthly'] as List<dynamic>)
          .map((item) => ViewingTrendItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'yearly': yearly.map((item) => item.toJson()).toList(),
      'monthly': monthly.map((item) => item.toJson()).toList(),
    };
  }
}

/// 취향 분석 통계 데이터 (전체)
/// API_GUIDE.md와 더미데이터 예시.txt의 구조를 따릅니다.
class Statistics {
  final StatisticsSummary summary; // 요약 정보
  final GenreDistribution genreDistribution; // 장르 분포
  final ViewingTrend viewingTrend; // 관람 추이

  Statistics({
    required this.summary,
    required this.genreDistribution,
    required this.viewingTrend,
  });

  factory Statistics.fromJson(Map<String, dynamic> json) {
    return Statistics(
      summary: StatisticsSummary.fromJson(json['summary'] as Map<String, dynamic>),
      genreDistribution: GenreDistribution.fromJson(
        json['genreDistribution'] as Map<String, dynamic>,
      ),
      viewingTrend: ViewingTrend.fromJson(json['viewingTrend'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': summary.toJson(),
      'genreDistribution': genreDistribution.toJson(),
      'viewingTrend': viewingTrend.toJson(),
    };
  }

  @override
  String toString() {
    return 'Statistics(summary: $summary, genreCount: ${genreDistribution.all.length}, yearlyTrend: ${viewingTrend.yearly.length}, monthlyTrend: ${viewingTrend.monthly.length})';
  }
}
