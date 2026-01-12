import 'package:flutter/foundation.dart';
import '../models/movie.dart';
import '../models/record.dart';
import '../models/wishlist.dart';
import '../models/summary.dart';
import '../data/dummy_movies.dart';
import '../data/dummy_record.dart';
import '../data/dummy_wishlist.dart';
import '../data/dummy_summary.dart';
import '../repositories/movie_repository.dart';

/// 기록 정렬 옵션
enum RecordSortOption {
  latest, // 최신순 (관람일 기준 내림차순)
  rating, // 별점순 (별점 기준 내림차순)
  viewCount, // 많이 본 순 (같은 영화를 여러 번 본 경우)
}

/// 앱의 전역 상태를 관리하는 클래스
/// Provider 패턴과 함께 사용되며, 영화 리스트, 북마크 상태, 관람 기록, 위시리스트, 통계를 관리합니다.
/// 
/// 사용 예시:
/// ```dart
/// final movies = context.watch<AppState>().movies;
/// final records = context.watch<AppState>().records;
/// final wishlist = context.watch<AppState>().wishlist;
/// final statistics = context.watch<AppState>().statistics;
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
  
  // 위시리스트 관련 상태
  // 동적으로 추가된 위시리스트 아이템들을 저장 (더미데이터 외 추가된 항목)
  final List<WishlistItem> _customWishlistItems = [];

  // 영화 리스트 캐시 (DB에서 로드한 데이터)
  List<Movie> _movies = [];
  bool _moviesLoaded = false;

  /// 모든 영화 리스트를 반환합니다.
  /// DB에서 로드한 데이터를 반환하며, 아직 로드되지 않았으면 더미 데이터를 반환합니다.
  List<Movie> get movies {
    if (_moviesLoaded && _movies.isNotEmpty) {
      return _movies;
    }
    // DB가 아직 로드되지 않았으면 더미 데이터 반환 (fallback)
    return DummyMovies.getMovies();
  }

  /// 영화 리스트를 DB에서 로드합니다.
  /// 
  /// 앱 시작 시 한 번 호출하여 DB에서 영화 데이터를 로드합니다.
  Future<void> loadMoviesFromDatabase() async {
    try {
      _movies = await MovieRepository.getAllMovies();
      _moviesLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('영화 로드 실패: $e');
      // 에러 발생 시 더미 데이터 사용
      _movies = DummyMovies.getMovies();
      _moviesLoaded = false;
    }
  }

  /// 영화 리스트를 새로고침합니다.
  /// 
  /// DB에서 최신 데이터를 다시 로드합니다.
  Future<void> refreshMovies() async {
    await loadMoviesFromDatabase();
  }

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

  // ========== 위시리스트(Wishlist) 관련 기능 ==========

  /// 모든 위시리스트 아이템 리스트를 반환합니다.
  /// 더미데이터와 동적으로 추가된 아이템을 모두 포함합니다.
  /// 더미데이터 예시.txt의 위시리스트 정보를 기반으로 합니다.
  List<WishlistItem> get wishlist {
    // 더미데이터와 동적으로 추가된 아이템을 합침
    final allItems = <WishlistItem>[];
    allItems.addAll(DummyWishlist.getWishlist());
    allItems.addAll(_customWishlistItems);
    
    // savedAt 기준 내림차순 정렬 (최신순)
    allItems.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    
    return allItems;
  }

  /// 더미데이터에 포함된 위시리스트만 반환합니다.
  List<WishlistItem> get dummyWishlist => DummyWishlist.getWishlist();

  /// 특정 영화가 위시리스트에 있는지 확인합니다.
  /// 
  /// [movieId] 확인할 영화 ID
  /// Returns true if the movie is in wishlist, false otherwise
  bool isInWishlist(String movieId) {
    return wishlist.any((item) => item.movie.id == movieId);
  }

  /// 위시리스트에 영화를 추가합니다.
  /// 이미 있으면 추가하지 않습니다.
  /// 
  /// [movie] 추가할 영화
  void addToWishlist(Movie movie) {
    // 이미 위시리스트에 있는지 확인
    if (isInWishlist(movie.id)) {
      return;
    }

    // 새로운 WishlistItem 생성 (현재 시간으로 savedAt 설정)
    final newItem = WishlistItem(
      movie: movie,
      savedAt: DateTime.now(),
    );

    _customWishlistItems.add(newItem);
    notifyListeners();
  }

  /// 위시리스트에서 영화를 제거합니다.
  /// 
  /// [movieId] 제거할 영화 ID
  void removeFromWishlist(String movieId) {
    // 더미데이터는 제거할 수 없으므로, 동적으로 추가된 아이템만 제거
    final beforeLength = _customWishlistItems.length;
    _customWishlistItems.removeWhere(
      (item) => item.movie.id == movieId,
    );
    final afterLength = _customWishlistItems.length;
    
    // 실제로 제거된 경우에만 UI 업데이트
    if (beforeLength > afterLength) {
      notifyListeners();
    }
  }

  /// 특정 영화 ID로 위시리스트 아이템을 찾습니다.
  /// 
  /// [movieId] 찾을 영화 ID
  /// Returns WishlistItem if found, null otherwise
  WishlistItem? getWishlistItemByMovieId(String movieId) {
    try {
      return wishlist.firstWhere((item) => item.movie.id == movieId);
    } catch (e) {
      return null;
    }
  }

  /// 위시리스트의 총 개수를 반환합니다.
  int get wishlistCount => wishlist.length;

  /// 위시리스트에 포함된 영화 목록만 반환합니다 (Movie 객체 리스트).
  /// UI에서 그리드 뷰로 표시할 때 사용할 수 있습니다.
  List<Movie> get wishlistMovies {
    return wishlist.map((item) => item.movie).toList();
  }

  /// 위시리스트를 날짜 순으로 정렬된 리스트로 반환합니다.
  /// 
  /// [ascending] true면 오름차순(오래된 순), false면 내림차순(최신순, 기본값)
  List<WishlistItem> getSortedWishlistByDate({bool ascending = false}) {
    final items = List<WishlistItem>.from(wishlist);
    items.sort((a, b) {
      final comparison = a.savedAt.compareTo(b.savedAt);
      return ascending ? comparison : -comparison;
    });
    return items;
  }

  /// 위시리스트를 영화 제목 순으로 정렬된 리스트로 반환합니다.
  /// 
  /// [ascending] true면 오름차순(가나다 순), false면 내림차순
  List<WishlistItem> getSortedWishlistByTitle({bool ascending = true}) {
    final items = List<WishlistItem>.from(wishlist);
    items.sort((a, b) {
      final comparison = a.movie.title.compareTo(b.movie.title);
      return ascending ? comparison : -comparison;
    });
    return items;
  }

  /// 위시리스트를 영화 평점 순으로 정렬된 리스트로 반환합니다.
  /// 
  /// [ascending] true면 오름차순(낮은 평점 순), false면 내림차순(높은 평점 순, 기본값)
  List<WishlistItem> getSortedWishlistByRating({bool ascending = false}) {
    final items = List<WishlistItem>.from(wishlist);
    items.sort((a, b) {
      final comparison = a.movie.voteAverage.compareTo(b.movie.voteAverage);
      return ascending ? comparison : -comparison;
    });
    return items;
  }

  /// 위시리스트에서 특정 장르의 영화만 필터링하여 반환합니다.
  /// 
  /// [genre] 필터링할 장르
  List<WishlistItem> getWishlistByGenre(String genre) {
    return wishlist.where((item) => item.movie.genres.contains(genre)).toList();
  }

  // ========== 통계(Statistics) 관련 기능 ==========

  /// 취향 분석 통계 데이터를 반환합니다.
  /// 더미데이터 예시.txt의 통계 정보를 기반으로 합니다.
  /// 
  /// 현재는 더미 데이터를 반환하지만, 향후 실제 기록 데이터를 기반으로 계산하도록 확장 가능합니다.
  Statistics get statistics => DummySummary.getStatistics();

  /// 요약 통계 정보를 반환합니다 (간편 접근용).
  /// statistics.summary와 동일한 데이터입니다.
  StatisticsSummary get statisticsSummary => statistics.summary;

  /// 장르 분포 데이터를 반환합니다 (간편 접근용).
  /// statistics.genreDistribution과 동일한 데이터입니다.
  GenreDistribution get genreDistribution => statistics.genreDistribution;

  /// 관람 추이 데이터를 반환합니다 (간편 접근용).
  /// statistics.viewingTrend와 동일한 데이터입니다.
  ViewingTrend get viewingTrend => statistics.viewingTrend;

  /// 전체 기간 장르 분포를 반환합니다 (간편 접근용).
  List<GenreDistributionItem> get genreDistributionAll => statistics.genreDistribution.all;

  /// 최근 1년 장르 분포를 반환합니다 (간편 접근용).
  List<GenreDistributionItem> get genreDistributionRecent1Year =>
      statistics.genreDistribution.recent1Year;

  /// 최근 3년 장르 분포를 반환합니다 (간편 접근용).
  List<GenreDistributionItem> get genreDistributionRecent3Years =>
      statistics.genreDistribution.recent3Years;

  /// 연도별 관람 추이를 반환합니다 (간편 접근용).
  List<ViewingTrendItem> get viewingTrendYearly => statistics.viewingTrend.yearly;

  /// 월별 관람 추이를 반환합니다 (간편 접근용).
  List<ViewingTrendItem> get viewingTrendMonthly => statistics.viewingTrend.monthly;

  /// 실제 기록 데이터를 기반으로 통계를 계산합니다.
  /// 향후 더미 데이터 대신 실제 데이터로 통계를 생성할 때 사용합니다.
  /// 
  /// 현재는 더미 데이터를 반환하지만, 실제 기록 데이터를 분석하는 로직으로 확장 가능합니다.
  Statistics calculateStatisticsFromRecords() {
    // 현재는 더미 데이터 반환
    // 향후 실제 기록 데이터를 기반으로 통계 계산 구현 가능
    return DummySummary.getStatistics();
  }

  /// 특정 기간의 장르 분포를 계산합니다.
  /// 
  /// [startDate] 시작일 (null이면 제한 없음)
  /// [endDate] 종료일 (null이면 제한 없음)
  /// Returns 해당 기간의 장르별 기록 수
  Map<String, int> calculateGenreDistributionByDateRange(
    DateTime? startDate,
    DateTime? endDate,
  ) {
    var filteredRecords = allRecords;

    // 기간 필터 적용
    if (startDate != null || endDate != null) {
      filteredRecords = filteredRecords.where((record) {
        if (startDate != null && record.watchDate.isBefore(startDate)) {
          return false;
        }
        if (endDate != null && record.watchDate.isAfter(endDate)) {
          return false;
        }
        return true;
      }).toList();
    }

    // 장르별 개수 계산
    final genreCount = <String, int>{};
    for (final record in filteredRecords) {
      for (final genre in record.movie.genres) {
        genreCount[genre] = (genreCount[genre] ?? 0) + 1;
      }
    }

    return genreCount;
  }

  /// 실제 기록 데이터를 기반으로 요약 통계를 계산합니다.
  /// 
  /// Returns 계산된 요약 통계 (더미 데이터와 다를 수 있음)
  StatisticsSummary calculateSummaryFromRecords() {
    final allRecordsList = allRecords;
    
    if (allRecordsList.isEmpty) {
      return StatisticsSummary(
        totalRecords: 0,
        averageRating: 0.0,
        topGenre: '',
      );
    }

    final totalRecords = allRecordsList.length;
    final averageRating = allRecordsList
            .map((r) => r.rating)
            .reduce((a, b) => a + b) /
        totalRecords;

    // 최다 선호 장르 계산
    final genreCount = <String, int>{};
    for (final record in allRecordsList) {
      for (final genre in record.movie.genres) {
        genreCount[genre] = (genreCount[genre] ?? 0) + 1;
      }
    }

    String topGenre = '';
    int maxCount = 0;
    genreCount.forEach((genre, count) {
      if (count > maxCount) {
        maxCount = count;
        topGenre = genre;
      }
    });

    return StatisticsSummary(
      totalRecords: totalRecords,
      averageRating: averageRating,
      topGenre: topGenre.isEmpty ? '없음' : topGenre,
    );
  }
}
