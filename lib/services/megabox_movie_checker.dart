import 'package:flutter/foundation.dart';
import 'movie_title_matcher.dart';

/// 메가박스 상영 여부 확인 서비스
/// 
/// TMDb에서 가져온 영화가 메가박스에서 상영 중인지 확인하는 서비스입니다.
class MegaboxMovieChecker {
  /// 영화가 메가박스에서 상영 중인지 확인합니다.
  /// 
  /// [movieTitle] TMDb 영화 제목
  /// Returns 상영 중이면 true
  static Future<bool> isPlayingInMegabox(String movieTitle) async {
    try {
      return await MovieTitleMatcher.isPlayingInMegabox(movieTitle);
    } catch (e) {
      debugPrint('⚠️ 메가박스 상영 여부 확인 오류: $e');
      // 에러 발생 시 false 반환 (조용히 처리)
      return false;
    }
  }
}
