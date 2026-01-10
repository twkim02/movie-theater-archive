import 'package:flutter/foundation.dart';
import '../models/movie.dart';
import '../models/record.dart';
import '../data/dummy_movies.dart';
import '../data/dummy_record.dart';

/// 기록 정렬 옵션
enum RecordSortOption {
  latest, // 최신순 (관람일 기준 내림차순)
  rating, // 별점순 (별점 기준 내림차순)
  viewCount, // 많이 본 순 (같은 영화를 여러 번 본 경우)
}

/// 앱의 전역 상태를 관리하는 클래스
/// Provider 패턴과 함께 사용되며, 영화 리스트, 북마크 상태, 관람 기록을 관리합니다.
/// 
/// 사용 예시:
/// ```dart
/// final movies = context.watch<AppState>().movies;
/// final records = context.watch<AppState>().records;
/// final isBookmarked = context.read<AppState>().isBookmarked(movieId);
/// context.read<AppState>().toggleBookmark(movieId);
/// ```
class AppState extends ChangeNotifier {
  // 북마크된 영화 ID를 저장하는 Set
  final Set<String> _bookmarkedMovieIds = {};
  
  // 기록 관련 필터 및 정렬 상태
  RecordSortOption _recordSortOption = RecordSortOption.latest;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String _searchQuery = '';

  /// 모든 영화 리스트를 반환합니다.
  /// 더미데이터 예시.txt의 영화 정보를 기반으로 합니다.
  List<Movie> get movies => DummyMovies.getMovies();

  /// 북마크된 영화 ID 목록을 반환합니다.
  Set<String> get bookmarkedMovieIds => Set.unmodifiable(_bookmarkedMovieIds);

  /// 북마크된 영화 목록만 반환합니다. (위시리스트용)
  List<Movie> get bookmarkedMovies {
    return movies.where((movie) => _bookmarkedMovieIds.contains(movie.id)).toList();
  }

  /// 특정 영화가 북마크되어 있는지 확인합니다.
  /// 
  /// [movieId] 확인할 영화 ID
  /// Returns true if the movie is bookmarked, false otherwise
  bool isBookmarked(String movieId) {
    return _bookmarkedMovieIds.contains(movieId);
  }

  /// 영화의 북마크 상태를 토글합니다.
  /// 북마크되어 있으면 해제하고, 없으면 추가합니다.
  /// 
  /// [movieId] 토글할 영화 ID
  void toggleBookmark(String movieId) {
    if (_bookmarkedMovieIds.contains(movieId)) {
      _bookmarkedMovieIds.remove(movieId);
    } else {
      _bookmarkedMovieIds.add(movieId);
    }
    notifyListeners(); // UI 업데이트를 위해 리스너에게 알림
  }

  /// 특정 영화를 북마크에 추가합니다.
  /// 
  /// [movieId] 추가할 영화 ID
  void addBookmark(String movieId) {
    if (!_bookmarkedMovieIds.contains(movieId)) {
      _bookmarkedMovieIds.add(movieId);
      notifyListeners();
    }
  }

  /// 특정 영화를 북마크에서 제거합니다.
  /// 
  /// [movieId] 제거할 영화 ID
  void removeBookmark(String movieId) {
    if (_bookmarkedMovieIds.contains(movieId)) {
      _bookmarkedMovieIds.remove(movieId);
      notifyListeners();
    }
  }

  // ========== 기록(Records) 관련 기능 ==========

  /// 모든 관람 기록 리스트를 반환합니다.
  /// 더미데이터 예시.txt의 기록 정보를 기반으로 합니다.
  List<Record> get allRecords => DummyRecords.getRecords();

  /// 현재 필터 및 정렬 옵션이 적용된 관람 기록 리스트를 반환합니다.
  List<Record> get records {
    var filteredRecords = allRecords;

    // 기간 필터 적용
    if (_filterStartDate != null || _filterEndDate != null) {
      filteredRecords = filteredRecords.where((record) {
        if (_filterStartDate != null && record.watchDate.isBefore(_filterStartDate!)) {
          return false;
        }
        if (_filterEndDate != null && record.watchDate.isAfter(_filterEndDate!)) {
          return false;
        }
        return true;
      }).toList();
    }

    // 검색어 필터 적용 (제목 또는 태그)
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filteredRecords = filteredRecords.where((record) {
        // 영화 제목 검색
        if (record.movie.title.toLowerCase().contains(query)) {
          return true;
        }
        // 태그 검색
        if (record.tags.any((tag) => tag.toLowerCase().contains(query))) {
          return true;
        }
        // 한줄평 검색
        if (record.oneLiner?.toLowerCase().contains(query) ?? false) {
          return true;
        }
        return false;
      }).toList();
    }

    // 정렬 적용
    switch (_recordSortOption) {
      case RecordSortOption.latest:
        filteredRecords.sort((a, b) => b.watchDate.compareTo(a.watchDate));
        break;
      case RecordSortOption.rating:
        filteredRecords.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case RecordSortOption.viewCount:
        // 같은 영화를 여러 번 본 경우를 계산하여 정렬
        final movieViewCount = <String, int>{};
        for (final record in filteredRecords) {
          movieViewCount[record.movie.id] = (movieViewCount[record.movie.id] ?? 0) + 1;
        }
        filteredRecords.sort((a, b) {
          final countA = movieViewCount[a.movie.id] ?? 0;
          final countB = movieViewCount[b.movie.id] ?? 0;
          if (countA != countB) {
            return countB.compareTo(countA);
          }
          // 같으면 최신순
          return b.watchDate.compareTo(a.watchDate);
        });
        break;
    }

    return filteredRecords;
  }

  /// 기록 정렬 옵션을 설정합니다.
  /// 
  /// [sortOption] 정렬 옵션 (latest, rating, viewCount)
  void setRecordSortOption(RecordSortOption sortOption) {
    if (_recordSortOption != sortOption) {
      _recordSortOption = sortOption;
      notifyListeners();
    }
  }

  /// 현재 기록 정렬 옵션을 반환합니다.
  RecordSortOption get recordSortOption => _recordSortOption;

  /// 기록 필터 기간을 설정합니다.
  /// 
  /// [startDate] 시작일 (null이면 제한 없음)
  /// [endDate] 종료일 (null이면 제한 없음)
  void setRecordDateFilter(DateTime? startDate, DateTime? endDate) {
    if (_filterStartDate != startDate || _filterEndDate != endDate) {
      _filterStartDate = startDate;
      _filterEndDate = endDate;
      notifyListeners();
    }
  }

  /// 기록 검색어를 설정합니다.
  /// 
  /// [query] 검색어 (제목 또는 태그로 검색)
  void setRecordSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  /// 현재 설정된 기록 필터를 초기화합니다.
  void clearRecordFilters() {
    _filterStartDate = null;
    _filterEndDate = null;
    _searchQuery = '';
    _recordSortOption = RecordSortOption.latest;
    notifyListeners();
  }

  /// 특정 영화에 대한 기록 목록을 반환합니다.
  /// 
  /// [movieId] 영화 ID
  List<Record> getRecordsByMovieId(String movieId) {
    return allRecords.where((record) => record.movie.id == movieId).toList();
  }

  /// 특정 기록 ID로 기록을 찾습니다.
  /// 
  /// [recordId] 기록 ID
  Record? getRecordById(int recordId) {
    try {
      return allRecords.firstWhere((record) => record.id == recordId);
    } catch (e) {
      return null;
    }
  }

  /// 기록 통계를 반환합니다.
  /// 
  /// Returns Map containing:
  /// - 'totalCount': 전체 기록 수
  /// - 'averageRating': 평균 별점
  /// - 'totalMovies': 본 영화 수 (중복 제외)
  Map<String, dynamic> getRecordStatistics() {
    final allRecordsList = allRecords;
    if (allRecordsList.isEmpty) {
      return {
        'totalCount': 0,
        'averageRating': 0.0,
        'totalMovies': 0,
      };
    }

    final totalCount = allRecordsList.length;
    final averageRating = allRecordsList
            .map((r) => r.rating)
            .reduce((a, b) => a + b) /
        totalCount;
    final uniqueMovieIds = allRecordsList.map((r) => r.movie.id).toSet();
    final totalMovies = uniqueMovieIds.length;

    return {
      'totalCount': totalCount,
      'averageRating': averageRating,
      'totalMovies': totalMovies,
    };
  }
}
