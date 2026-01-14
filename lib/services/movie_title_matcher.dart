import 'package:flutter/foundation.dart';
import '../utils/csv_parser.dart';
import '../models/lottecinema_data.dart';
import '../models/megabox_data.dart';

/// 영화 제목 매칭 서비스
/// 
/// TMDb 영화 제목과 롯데시네마 영화명을 매칭하는 로직을 제공합니다.
class MovieTitleMatcher {
  /// TMDb 영화 제목으로 롯데시네마 영화 정보를 찾습니다.
  /// 
  /// [tmdbTitle] TMDb 영화 제목
  /// Returns 롯데시네마 영화 정보 (없으면 null)
  static Future<LotteCinemaMovie?> findLotteCinemaMovie(String tmdbTitle) async {
    if (tmdbTitle.trim().isEmpty) {
      return null;
    }

    try {
      // 모든 롯데시네마 영화 목록 가져오기
      final allMovies = await CsvParser.getAllMovies();
      
      if (allMovies.isEmpty) {
        debugPrint('⚠️ 롯데시네마 영화 목록이 비어있습니다.');
        return null;
      }

      // 정규화된 TMDb 제목
      final normalizedTmdb = _normalizeTitle(tmdbTitle);

      // 1단계: 정확한 매칭 (대소문자 무시, 공백 정규화)
      for (final movie in allMovies) {
        final normalizedLotte = _normalizeTitle(movie.movieName);
        if (normalizedTmdb == normalizedLotte) {
          debugPrint('✅ 정확한 매칭: "$tmdbTitle" ↔ "${movie.movieName}"');
          return movie;
        }
      }

      // 2단계: 부분 매칭 (한쪽이 다른 쪽을 포함)
      for (final movie in allMovies) {
        final normalizedLotte = _normalizeTitle(movie.movieName);
        
        // TMDb 제목이 롯데시네마 제목을 포함하거나, 그 반대
        if (normalizedTmdb.contains(normalizedLotte) || 
            normalizedLotte.contains(normalizedTmdb)) {
          // 너무 짧은 단어는 제외 (예: "2" 같은 것)
          if (normalizedLotte.length >= 3 && normalizedTmdb.length >= 3) {
            debugPrint('✅ 부분 매칭: "$tmdbTitle" ↔ "${movie.movieName}"');
            return movie;
          }
        }
      }

      // 3단계: 특수문자 제거 후 매칭
      final tmdbWithoutSpecial = _removeSpecialChars(normalizedTmdb);
      for (final movie in allMovies) {
        final lotteWithoutSpecial = _removeSpecialChars(_normalizeTitle(movie.movieName));
        if (tmdbWithoutSpecial == lotteWithoutSpecial) {
          debugPrint('✅ 특수문자 제거 후 매칭: "$tmdbTitle" ↔ "${movie.movieName}"');
          return movie;
        }
      }

      debugPrint('❌ 매칭 실패: "$tmdbTitle"');
      return null;
    } catch (e) {
      debugPrint('❌ 영화 제목 매칭 오류: $e');
      return null;
    }
  }

  /// 영화가 롯데시네마에서 상영 중인지 확인합니다.
  /// 
  /// [tmdbTitle] TMDb 영화 제목
  /// Returns 상영 중이면 true
  static Future<bool> isPlayingInLotteCinema(String tmdbTitle) async {
    final movie = await findLotteCinemaMovie(tmdbTitle);
    if (movie == null) {
      return false;
    }

    // 현재 상영 중인 영화 목록에서 확인
    final nowMovies = await CsvParser.getNowMovies();
    return nowMovies.any((m) => m.movieNo == movie.movieNo);
  }

  /// 제목을 정규화합니다 (공백 정규화, 대소문자 통일).
  /// 
  /// [title] 원본 제목
  /// Returns 정규화된 제목
  static String _normalizeTitle(String title) {
    return title
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ') // 여러 공백을 하나로
        .toLowerCase();
  }

  /// 특수문자를 제거합니다.
  /// 
  /// [title] 원본 제목
  /// Returns 특수문자가 제거된 제목
  static String _removeSpecialChars(String title) {
    return title.replaceAll(RegExp(r'[^\w\s가-힣]'), ''); // 영문, 숫자, 한글, 공백만 유지
  }

  // ========== 메가박스 관련 메서드 ==========

  /// TMDb 영화 제목으로 메가박스 영화 정보를 찾습니다.
  /// 
  /// [tmdbTitle] TMDb 영화 제목
  /// Returns 메가박스 영화 정보 (없으면 null)
  static Future<MegaboxMovie?> findMegaboxMovie(String tmdbTitle) async {
    if (tmdbTitle.trim().isEmpty) {
      return null;
    }

    try {
      // 모든 메가박스 영화 목록 가져오기
      final allMovies = await CsvParser.getMegaboxMovies();
      
      if (allMovies.isEmpty) {
        debugPrint('⚠️ 메가박스 영화 목록이 비어있습니다.');
        return null;
      }

      // 정규화된 TMDb 제목
      final normalizedTmdb = _normalizeTitle(tmdbTitle);

      // 1단계: 정확한 매칭 (대소문자 무시, 공백 정규화)
      for (final movie in allMovies) {
        final normalizedMegabox = _normalizeTitle(movie.movieNm);
        if (normalizedTmdb == normalizedMegabox) {
          debugPrint('✅ 정확한 매칭: "$tmdbTitle" ↔ "${movie.movieNm}"');
          return movie;
        }
      }

      // 2단계: 부분 매칭 (한쪽이 다른 쪽을 포함)
      for (final movie in allMovies) {
        final normalizedMegabox = _normalizeTitle(movie.movieNm);
        
        // TMDb 제목이 메가박스 제목을 포함하거나, 그 반대
        if (normalizedTmdb.contains(normalizedMegabox) || 
            normalizedMegabox.contains(normalizedTmdb)) {
          // 너무 짧은 단어는 제외 (예: "2" 같은 것)
          if (normalizedMegabox.length >= 3 && normalizedTmdb.length >= 3) {
            debugPrint('✅ 부분 매칭: "$tmdbTitle" ↔ "${movie.movieNm}"');
            return movie;
          }
        }
      }

      // 3단계: 특수문자 제거 후 매칭
      final tmdbWithoutSpecial = _removeSpecialChars(normalizedTmdb);
      for (final movie in allMovies) {
        final megaboxWithoutSpecial = _removeSpecialChars(_normalizeTitle(movie.movieNm));
        if (tmdbWithoutSpecial == megaboxWithoutSpecial) {
          debugPrint('✅ 특수문자 제거 후 매칭: "$tmdbTitle" ↔ "${movie.movieNm}"');
          return movie;
        }
      }

      debugPrint('❌ 매칭 실패: "$tmdbTitle"');
      return null;
    } catch (e) {
      debugPrint('❌ 영화 제목 매칭 오류: $e');
      return null;
    }
  }

  /// 영화가 메가박스에서 상영 중인지 확인합니다.
  /// 
  /// [tmdbTitle] TMDb 영화 제목
  /// Returns 상영 중이면 true
  static Future<bool> isPlayingInMegabox(String tmdbTitle) async {
    final movie = await findMegaboxMovie(tmdbTitle);
    if (movie == null) {
      return false;
    }

    // 메가박스는 movie.csv에 모든 상영 중인 영화가 포함되어 있음
    // (롯데시네마와 달리 now/upcoming 분리가 없음)
    return true;
  }
}
