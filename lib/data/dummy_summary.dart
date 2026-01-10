import '../models/summary.dart';

/// 더미 통계(취향 분석) 데이터를 제공하는 클래스
/// 더미데이터 예시.txt 파일의 통계 정보를 기반으로 합니다.
class DummySummary {
  /// 더미 통계 데이터를 반환합니다.
  /// 더미데이터 예시.txt 파일의 통계 정보를 기반으로 합니다.
  static Statistics getStatistics() {
    return Statistics.fromJson({
      "summary": {
        "totalRecords": 7,
        "averageRating": 4.1,
        "topGenre": "판타지"
      },
      "genreDistribution": {
        "all": [
          {"name": "판타지", "count": 4},
          {"name": "액션", "count": 3},
          {"name": "SF", "count": 2},
          {"name": "모험", "count": 2},
          {"name": "코미디", "count": 2},
          {"name": "스릴러", "count": 2},
          {"name": "드라마", "count": 2},
          {"name": "애니메이션", "count": 2},
          {"name": "범죄", "count": 1}
        ],
        "recent1Year": [
          {"name": "판타지", "count": 4},
          {"name": "액션", "count": 3},
          {"name": "SF", "count": 2},
          {"name": "모험", "count": 2},
          {"name": "코미디", "count": 2}
        ],
        "recent3Years": [
          {"name": "판타지", "count": 4},
          {"name": "액션", "count": 3},
          {"name": "SF", "count": 2},
          {"name": "모험", "count": 2},
          {"name": "코미디", "count": 2}
        ]
      },
      "viewingTrend": {
        "yearly": [
          {"date": "2025", "count": 3},
          {"date": "2026", "count": 4}
        ],
        "monthly": [
          {"date": "2025-10", "count": 1},
          {"date": "2025-11", "count": 1},
          {"date": "2025-12", "count": 1},
          {"date": "2026-01", "count": 4}
        ]
      }
    });
  }
}
