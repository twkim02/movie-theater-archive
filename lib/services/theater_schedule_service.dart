import 'package:flutter/foundation.dart';
import '../models/theater.dart';
import '../api/lottecinema_client.dart';
import '../utils/csv_parser.dart';
import '../services/movie_title_matcher.dart';

/// 영화관 상영 시간표 서비스
/// 
/// 롯데시네마 영화관의 상영 시간표를 가져오는 서비스입니다.
class TheaterScheduleService {
  // 캐시: 같은 영화, 같은 영화관, 같은 날짜에 대한 요청은 5분간 캐싱
  static final Map<String, _CachedSchedule> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// 롯데시네마 영화관의 상영 시간표를 가져옵니다.
  /// 
  /// [theaterName] 영화관 이름 (예: "롯데시네마 대전센트럴", "대전센트럴")
  /// [movieTitle] 영화 제목
  /// [date] 상영일
  /// 
  /// Returns 상영 시간표 목록 (롯데시네마가 아니거나 실패 시 빈 리스트)
  static Future<List<Showtime>> getLotteCinemaSchedule({
    required String theaterName,
    required String movieTitle,
    required DateTime date,
  }) async {
    // 롯데시네마가 아닌 경우 빈 리스트 반환
    if (!_isLotteCinema(theaterName)) {
      return [];
    }

    try {
      // 캐시 키 생성
      final cacheKey = _buildCacheKey(theaterName, movieTitle, date);
      
      // 캐시 확인
      final cached = _cache[cacheKey];
      if (cached != null && !cached.isExpired) {
        debugPrint('✅ 캐시에서 상영 시간표 가져옴: $cacheKey');
        return cached.showtimes;
      }

      // 1. 영화 제목으로 롯데시네마 movieNo 찾기
      final movie = await MovieTitleMatcher.findLotteCinemaMovie(movieTitle);
      if (movie == null) {
        debugPrint('⚠️ 롯데시네마 영화를 찾을 수 없음: $movieTitle');
        return [];
      }

      // 2. 영화관 정보로 cinemaID 찾기
      final theater = await CsvParser.findTheaterByName(theaterName);
      if (theater == null) {
        debugPrint('⚠️ 롯데시네마 영화관을 찾을 수 없음: $theaterName');
        return [];
      }

      // 3. 날짜 포맷팅
      final playDate = _formatDate(date);

      // 4. API 호출하여 상영 시간표 가져오기
      final client = LotteCinemaClient();
      final schedules = await client.getMovieSchedule(
        cinemaId: theater.cinemaIdString,
        movieNo: movie.movieNo,
        playDate: playDate,
      );

      // 5. Showtime 리스트로 변환
      final showtimes = schedules.map((schedule) {
        return Showtime(
          start: schedule.startTime,
          end: schedule.endTime,
          screen: schedule.screenNameKR,
        );
      }).toList();

      // 캐시에 저장
      _cache[cacheKey] = _CachedSchedule(
        showtimes: showtimes,
        cachedAt: DateTime.now(),
      );

      debugPrint('✅ 롯데시네마 상영 시간표 가져옴: ${showtimes.length}개 (${theaterName}, ${movieTitle}, $playDate)');
      return showtimes;
    } catch (e) {
      debugPrint('❌ 롯데시네마 상영 시간표 가져오기 실패: $e');
      // 에러 발생 시 빈 리스트 반환 (조용히 처리)
      return [];
    }
  }

  /// 영화관 이름에 "롯데시네마"가 포함되어 있는지 확인합니다.
  static bool _isLotteCinema(String theaterName) {
    final normalized = theaterName.toLowerCase();
    return normalized.contains('롯데시네마') || normalized.contains('롯데');
  }

  /// 캐시 키를 생성합니다.
  /// 
  /// 형식: "theaterName_movieTitle_date"
  static String _buildCacheKey(String theaterName, String movieTitle, DateTime date) {
    final dateStr = _formatDate(date);
    return '${theaterName}_${movieTitle}_$dateStr';
  }

  /// 날짜를 YYYY-MM-DD 형식으로 포맷팅합니다.
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 캐시를 초기화합니다.
  /// 
  /// 테스트나 메모리 관리 시 사용합니다.
  static void clearCache() {
    _cache.clear();
  }

  /// 만료된 캐시를 정리합니다.
  /// 
  /// 주기적으로 호출하여 메모리를 관리합니다.
  static void cleanExpiredCache() {
    _cache.removeWhere((key, value) => value.isExpired);
  }
}

/// 캐시된 상영 시간표 정보
class _CachedSchedule {
  final List<Showtime> showtimes;
  final DateTime cachedAt;

  _CachedSchedule({
    required this.showtimes,
    required this.cachedAt,
  });

  /// 캐시가 만료되었는지 확인합니다.
  bool get isExpired {
    final now = DateTime.now();
    return now.difference(cachedAt) > TheaterScheduleService._cacheDuration;
  }
}
