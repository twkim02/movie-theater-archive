import 'package:flutter/foundation.dart';
import 'movie_title_matcher.dart';

/// 롯데시네마 상영 여부 확인 서비스
/// 
/// TMDb에서 가져온 영화가 롯데시네마에서 상영 중인지 확인하는 서비스입니다.
class LotteCinemaMovieChecker {
  /// 영화가 롯데시네마에서 상영 중인지 확인합니다.
  /// 
  /// [movieTitle] TMDb 영화 제목
  /// Returns 상영 중이면 true
  static Future<bool> isPlayingInLotteCinema(String movieTitle) async {
    try {
      return await MovieTitleMatcher.isPlayingInLotteCinema(movieTitle);
    } catch (e) {
      debugPrint('⚠️ 롯데시네마 상영 여부 확인 오류: $e');
      // 에러 발생 시 false 반환 (조용히 처리)
      return false;
    }
  }
}
