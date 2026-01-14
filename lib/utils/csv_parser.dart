import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/lottecinema_data.dart';
import '../models/megabox_data.dart';

/// CSV 파일을 파싱하는 유틸리티 클래스
/// 
/// 앱 시작 시 한 번만 로드하고 메모리에 캐싱합니다.
class CsvParser {
  // 캐싱된 데이터 (롯데시네마)
  static List<LotteCinemaMovie>? _cachedNowMovies;
  static List<LotteCinemaMovie>? _cachedUpcomingMovies;
  static List<LotteCinemaTheater>? _cachedTheaters;
  
  // 캐싱된 데이터 (메가박스)
  static List<MegaboxMovie>? _cachedMegaboxMovies;
  static List<MegaboxTheater>? _cachedMegaboxTheaters;

  /// 현재 상영 중인 영화 목록을 가져옵니다.
  /// 
  /// 첫 호출 시 CSV 파일을 로드하고 캐싱합니다.
  /// 이후 호출 시 캐시된 데이터를 반환합니다.
  static Future<List<LotteCinemaMovie>> getNowMovies() async {
    if (_cachedNowMovies != null) {
      return _cachedNowMovies!;
    }

    try {
      final content = await rootBundle.loadString('assets/lottecinema/movie_now.csv');
      _cachedNowMovies = _parseMovies(content);
      return _cachedNowMovies!;
    } catch (e) {
      debugPrint('❌ CSV 파싱 오류 (movie_now.csv): $e');
      return [];
    }
  }

  /// 개봉 예정 영화 목록을 가져옵니다.
  /// 
  /// 첫 호출 시 CSV 파일을 로드하고 캐싱합니다.
  /// 이후 호출 시 캐시된 데이터를 반환합니다.
  static Future<List<LotteCinemaMovie>> getUpcomingMovies() async {
    if (_cachedUpcomingMovies != null) {
      return _cachedUpcomingMovies!;
    }

    try {
      final content = await rootBundle.loadString('assets/lottecinema/movie_upcoming.csv');
      _cachedUpcomingMovies = _parseMovies(content);
      return _cachedUpcomingMovies!;
    } catch (e) {
      debugPrint('❌ CSV 파싱 오류 (movie_upcoming.csv): $e');
      return [];
    }
  }

  /// 모든 상영 중인 영화 목록을 가져옵니다 (현재 상영 + 개봉 예정).
  /// 
  /// Returns 현재 상영 중인 영화와 개봉 예정 영화를 합친 목록
  static Future<List<LotteCinemaMovie>> getAllMovies() async {
    final now = await getNowMovies();
    final upcoming = await getUpcomingMovies();
    return [...now, ...upcoming];
  }

  /// 영화관 목록을 가져옵니다.
  /// 
  /// 첫 호출 시 CSV 파일을 로드하고 캐싱합니다.
  /// 이후 호출 시 캐시된 데이터를 반환합니다.
  static Future<List<LotteCinemaTheater>> getTheaters() async {
    if (_cachedTheaters != null) {
      return _cachedTheaters!;
    }

    try {
      final content = await rootBundle.loadString('assets/lottecinema/theater.csv');
      _cachedTheaters = _parseTheaters(content);
      return _cachedTheaters!;
    } catch (e) {
      debugPrint('❌ CSV 파싱 오류 (theater.csv): $e');
      return [];
    }
  }

  /// 영화관 이름으로 영화관 정보를 찾습니다.
  /// 
  /// [theaterName] 찾을 영화관 이름 (예: "대전센트럴", "롯데시네마 대전센트럴")
  /// Returns 영화관 정보 (없으면 null)
  static Future<LotteCinemaTheater?> findTheaterByName(String theaterName) async {
    final theaters = await getTheaters();
    
    // "롯데시네마" 또는 "롯데" 접두사 제거 (CSV에는 영화관 이름만 저장되어 있음)
    final normalizedName = theaterName
        .replaceAll('롯데시네마', '')
        .replaceAll('롯데', '')
        .trim();
    
    // 1. 정확한 매칭 우선 (원본 이름)
    for (final theater in theaters) {
      if (theater.element == theaterName) {
        return theater;
      }
    }
    
    // 2. 정확한 매칭 (접두사 제거 후)
    for (final theater in theaters) {
      if (theater.element == normalizedName) {
        return theater;
      }
    }
    
    // 3. 부분 매칭 (가장 긴 매칭을 우선 선택)
    LotteCinemaTheater? bestMatch;
    int bestMatchLength = 0;
    
    for (final theater in theaters) {
      // CSV 영화관 이름이 검색어에 포함되어 있는지
      if (normalizedName.contains(theater.element)) {
        // 더 긴 매칭을 우선 선택
        if (theater.element.length > bestMatchLength) {
          bestMatch = theater;
          bestMatchLength = theater.element.length;
        }
      }
      // 검색어가 CSV 영화관 이름에 포함되어 있는지
      else if (theater.element.contains(normalizedName)) {
        // 더 긴 매칭을 우선 선택
        if (normalizedName.length > bestMatchLength) {
          bestMatch = theater;
          bestMatchLength = normalizedName.length;
        }
      }
    }
    
    return bestMatch;
  }

  /// 영화명으로 영화 정보를 찾습니다.
  /// 
  /// [movieName] 찾을 영화명
  /// Returns 영화 정보 (없으면 null)
  static Future<LotteCinemaMovie?> findMovieByName(String movieName) async {
    final allMovies = await getAllMovies();
    
    // 정확한 매칭 우선
    for (final movie in allMovies) {
      if (movie.movieName == movieName) {
        return movie;
      }
    }
    
    // 부분 매칭
    for (final movie in allMovies) {
      if (movie.movieName.contains(movieName) || 
          movieName.contains(movie.movieName)) {
        return movie;
      }
    }
    
    return null;
  }

  // ========== 메가박스 관련 메서드 ==========
  
  /// 메가박스 영화 목록을 가져옵니다.
  /// 
  /// 첫 호출 시 CSV 파일을 로드하고 캐싱합니다.
  /// 이후 호출 시 캐시된 데이터를 반환합니다.
  static Future<List<MegaboxMovie>> getMegaboxMovies() async {
    if (_cachedMegaboxMovies != null) {
      return _cachedMegaboxMovies!;
    }

    try {
      final content = await rootBundle.loadString('assets/megabox/movie.csv');
      _cachedMegaboxMovies = _parseMegaboxMovies(content);
      return _cachedMegaboxMovies!;
    } catch (e) {
      debugPrint('❌ CSV 파싱 오류 (megabox/movie.csv): $e');
      return [];
    }
  }

  /// 메가박스 영화관 목록을 가져옵니다.
  /// 
  /// 첫 호출 시 CSV 파일을 로드하고 캐싱합니다.
  /// 이후 호출 시 캐시된 데이터를 반환합니다.
  static Future<List<MegaboxTheater>> getMegaboxTheaters() async {
    if (_cachedMegaboxTheaters != null) {
      return _cachedMegaboxTheaters!;
    }

    try {
      final content = await rootBundle.loadString('assets/megabox/theater.csv');
      _cachedMegaboxTheaters = _parseMegaboxTheaters(content);
      return _cachedMegaboxTheaters!;
    } catch (e) {
      debugPrint('❌ CSV 파싱 오류 (megabox/theater.csv): $e');
      return [];
    }
  }

  /// 메가박스 영화관 이름으로 영화관 정보를 찾습니다.
  /// 
  /// [theaterName] 찾을 영화관 이름 (예: "대전중앙로", "메가박스 대전중앙로")
  /// Returns 영화관 정보 (없으면 null)
  static Future<MegaboxTheater?> findMegaboxTheaterByName(String theaterName) async {
    final theaters = await getMegaboxTheaters();
    
    // "메가박스" 접두사 제거 (CSV에는 영화관 이름만 저장되어 있음)
    final normalizedName = theaterName
        .replaceAll('메가박스', '')
        .replaceAll('메가', '')
        .trim();
    
    // 1. 정확한 매칭 우선 (원본 이름)
    for (final theater in theaters) {
      if (theater.brchNm == theaterName) {
        return theater;
      }
    }
    
    // 2. 정확한 매칭 (접두사 제거 후)
    for (final theater in theaters) {
      if (theater.brchNm == normalizedName) {
        return theater;
      }
    }
    
    // 3. 부분 매칭 (가장 긴 매칭을 우선 선택)
    MegaboxTheater? bestMatch;
    int bestMatchLength = 0;
    
    for (final theater in theaters) {
      // CSV 영화관 이름이 검색어에 포함되어 있는지
      if (normalizedName.contains(theater.brchNm)) {
        // 더 긴 매칭을 우선 선택
        if (theater.brchNm.length > bestMatchLength) {
          bestMatch = theater;
          bestMatchLength = theater.brchNm.length;
        }
      }
      // 검색어가 CSV 영화관 이름에 포함되어 있는지
      else if (theater.brchNm.contains(normalizedName)) {
        // 더 긴 매칭을 우선 선택
        if (normalizedName.length > bestMatchLength) {
          bestMatch = theater;
          bestMatchLength = normalizedName.length;
        }
      }
    }
    
    return bestMatch;
  }

  /// 메가박스 영화명으로 영화 정보를 찾습니다.
  /// 
  /// [movieNm] 찾을 영화명
  /// Returns 영화 정보 (없으면 null)
  static Future<MegaboxMovie?> findMegaboxMovieByName(String movieNm) async {
    final movies = await getMegaboxMovies();
    
    // 정확한 매칭 우선
    for (final movie in movies) {
      if (movie.movieNm == movieNm) {
        return movie;
      }
    }
    
    // 부분 매칭
    for (final movie in movies) {
      if (movie.movieNm.contains(movieNm) || 
          movieNm.contains(movie.movieNm)) {
        return movie;
      }
    }
    
    return null;
  }

  /// CSV 내용을 파싱하여 메가박스 영화 목록으로 변환합니다.
  static List<MegaboxMovie> _parseMegaboxMovies(String csvContent) {
    final lines = csvContent.split('\n');
    final movies = <MegaboxMovie>[];

    // 첫 줄은 헤더이므로 스킵
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // CSV 파싱 (쉼표로 분리, 따옴표 처리)
      final parts = _parseCsvLine(line);
      if (parts.length >= 2) {
        final movieNo = parts[0].trim();
        final movieNm = parts[1].trim();
        
        if (movieNo.isNotEmpty && movieNm.isNotEmpty) {
          movies.add(MegaboxMovie(
            movieNo: movieNo,
            movieNm: movieNm,
          ));
        }
      }
    }

    return movies;
  }

  /// CSV 내용을 파싱하여 메가박스 영화관 목록으로 변환합니다.
  static List<MegaboxTheater> _parseMegaboxTheaters(String csvContent) {
    final lines = csvContent.split('\n');
    final theaters = <MegaboxTheater>[];

    // 첫 줄은 헤더이므로 스킵
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // CSV 파싱 (쉼표로 분리)
      final parts = _parseCsvLine(line);
      if (parts.length >= 2) {
        final brchNo = parts[0].trim();
        final brchNm = parts[1].trim();
        
        if (brchNo.isNotEmpty && brchNm.isNotEmpty) {
          theaters.add(MegaboxTheater(
            brchNo: brchNo,
            brchNm: brchNm,
          ));
        }
      }
    }

    return theaters;
  }

  /// 캐시를 초기화합니다.
  /// 
  /// 테스트나 파일 업데이트 후 사용합니다.
  static void clearCache() {
    _cachedNowMovies = null;
    _cachedUpcomingMovies = null;
    _cachedTheaters = null;
    _cachedMegaboxMovies = null;
    _cachedMegaboxTheaters = null;
  }

  /// CSV 내용을 파싱하여 영화 목록으로 변환합니다.
  static List<LotteCinemaMovie> _parseMovies(String csvContent) {
    final lines = csvContent.split('\n');
    final movies = <LotteCinemaMovie>[];

    // 첫 줄은 헤더이므로 스킵
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // CSV 파싱 (쉼표로 분리, 따옴표 처리)
      final parts = _parseCsvLine(line);
      if (parts.length >= 2) {
        final movieNo = parts[0].trim();
        final movieName = parts[1].trim();
        
        if (movieNo.isNotEmpty && movieName.isNotEmpty) {
          movies.add(LotteCinemaMovie(
            movieNo: movieNo,
            movieName: movieName,
          ));
        }
      }
    }

    return movies;
  }

  /// CSV 내용을 파싱하여 영화관 목록으로 변환합니다.
  static List<LotteCinemaTheater> _parseTheaters(String csvContent) {
    final lines = csvContent.split('\n');
    final theaters = <LotteCinemaTheater>[];

    // 첫 줄은 헤더이므로 스킵
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // CSV 파싱 (쉼표로 분리)
      final parts = _parseCsvLine(line);
      if (parts.length >= 4) {
        final divisionCode = parts[0].trim();
        final detailDivisionCode = parts[1].trim();
        final cinemaID = parts[2].trim();
        final element = parts[3].trim();
        
        if (divisionCode.isNotEmpty && 
            detailDivisionCode.isNotEmpty && 
            cinemaID.isNotEmpty && 
            element.isNotEmpty) {
          theaters.add(LotteCinemaTheater(
            divisionCode: divisionCode,
            detailDivisionCode: detailDivisionCode,
            cinemaID: cinemaID,
            element: element,
          ));
        }
      }
    }

    return theaters;
  }

  /// CSV 라인을 파싱합니다 (쉼표로 분리, 따옴표 처리).
  /// 
  /// 따옴표로 감싸진 필드는 따옴표를 제거하고 내부 쉼표를 보존합니다.
  static List<String> _parseCsvLine(String line) {
    final result = <String>[];
    var current = '';
    var inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current);
        current = '';
      } else {
        current += char;
      }
    }
    
    result.add(current);
    return result;
  }
}
