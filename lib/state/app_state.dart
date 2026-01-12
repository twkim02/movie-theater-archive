import 'package:flutter/foundation.dart';
import '../models/movie.dart';
import '../models/record.dart';
import '../models/wishlist.dart';
import '../models/summary.dart';
import '../data/dummy_summary.dart';
import '../repositories/movie_repository.dart';
import '../repositories/record_repository.dart';
import '../repositories/wishlist_repository.dart';
import '../services/user_initialization_service.dart';

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
  // 기록 관련 필터 및 정렬 상태
  RecordSortOption _recordSortOption = RecordSortOption.latest;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  String _searchQuery = '';

  // 영화 리스트 캐시 (DB에서 로드한 데이터)
  List<Movie> _movies = [];
  bool _moviesLoaded = false;
  bool _isLoadingMovies = false;

  // 기록 리스트 캐시 (DB에서 로드한 데이터)
  List<Record> _records = [];
  bool _recordsLoaded = false;
  bool _isLoadingRecords = false;

  // 위시리스트 캐시 (DB에서 로드한 데이터)
  List<WishlistItem> _wishlist = [];
  bool _wishlistLoaded = false;
  bool _isLoadingWishlist = false;

  // 북마크 상태 캐시 (DB에서 로드한 데이터)
  Set<String> _bookmarkedMovieIds = {};
  bool _bookmarksLoaded = false;

  /// 영화 로드 상태를 반환합니다.
  bool get isMoviesLoaded => _moviesLoaded;

  /// 영화 로딩 중인지 반환합니다.
  bool get isLoadingMovies => _isLoadingMovies;

  /// 모든 영화 리스트를 반환합니다.
  /// DB에서 로드한 데이터를 반환합니다.
  /// DB가 비어있거나 로드되지 않았으면 빈 리스트를 반환합니다.
  List<Movie> get movies {
    if (_moviesLoaded) {
      return _movies;
    }
    // DB가 아직 로드되지 않았으면 빈 리스트 반환
    // (더미 데이터는 자동으로 보여주지 않음)
    return [];
  }

  /// 영화 리스트를 DB에서 로드합니다.
  /// 
  /// 앱 시작 시 한 번 호출하여 DB에서 영화 데이터를 로드합니다.
  Future<void> loadMoviesFromDatabase() async {
    if (_isLoadingMovies) return; // 이미 로딩 중이면 스킵
    
    _isLoadingMovies = true;
    notifyListeners();
    
    try {
      _movies = await MovieRepository.getAllMovies();
      _moviesLoaded = true;
    } catch (e) {
      debugPrint('영화 로드 실패: $e');
      _movies = [];
      _moviesLoaded = false;
    } finally {
      _isLoadingMovies = false;
      notifyListeners();
    }
  }

  /// 영화 리스트를 새로고침합니다.
  /// 
  /// DB에서 최신 데이터를 다시 로드합니다.
  Future<void> refreshMovies() async {
    await loadMoviesFromDatabase();
  }

  /// 북마크 로드 상태를 반환합니다.
  bool get isBookmarksLoaded => _bookmarksLoaded;

  /// 북마크된 영화 ID 목록을 반환합니다.
  Set<String> get bookmarkedMovieIds {
    if (_bookmarksLoaded) {
      return Set.unmodifiable(_bookmarkedMovieIds);
    }
    return <String>{};
  }

  /// 북마크된 영화 목록만 반환합니다. (위시리스트용)
  List<Movie> get bookmarkedMovies {
    return movies.where((movie) => _bookmarkedMovieIds.contains(movie.id)).toList();
  }

  /// 특정 영화가 북마크되어 있는지 확인합니다.
  /// 
  /// [movieId] 확인할 영화 ID
  /// Returns true if the movie is bookmarked, false otherwise
  bool isBookmarked(String movieId) {
    if (!_bookmarksLoaded) {
      // 로드되지 않았으면 DB에서 확인
      _checkBookmarkStatus(movieId);
      return false; // 비동기이므로 일단 false 반환
    }
    return _bookmarkedMovieIds.contains(movieId);
  }

  /// DB에서 북마크 상태를 확인합니다 (비동기).
  /// 
  /// [movieId] 확인할 영화 ID
  /// Returns true if the movie is bookmarked
  Future<bool> isBookmarkedAsync(String movieId) async {
    if (!_bookmarksLoaded) {
      await loadWishlistFromDatabase();
    }
    return _bookmarkedMovieIds.contains(movieId);
  }

  /// 북마크 상태를 확인합니다 (내부용).
  Future<void> _checkBookmarkStatus(String movieId) async {
    try {
      final defaultUserId = UserInitializationService.getDefaultUserId();
      final isIn = await WishlistRepository.isInWishlist(defaultUserId, movieId);
      if (isIn && !_bookmarkedMovieIds.contains(movieId)) {
        _bookmarkedMovieIds.add(movieId);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('북마크 상태 확인 실패: $e');
    }
  }

  /// 영화의 북마크 상태를 토글합니다.
  /// 북마크되어 있으면 해제하고, 없으면 추가합니다.
  /// 
  /// [movieId] 토글할 영화 ID
  /// DB에 저장하고 로컬 캐시를 업데이트합니다.
  Future<void> toggleBookmark(String movieId) async {
    try {
      final defaultUserId = UserInitializationService.getDefaultUserId();
      await WishlistRepository.toggleWishlist(defaultUserId, movieId);
      
      // 로컬 캐시 업데이트
      await loadWishlistFromDatabase();
    } catch (e) {
      debugPrint('북마크 토글 실패: $e');
      rethrow;
    }
  }

  /// 특정 영화를 북마크에 추가합니다.
  /// 
  /// [movieId] 추가할 영화 ID
  /// DB에 저장하고 로컬 캐시를 업데이트합니다.
  Future<void> addBookmark(String movieId) async {
    try {
      final defaultUserId = UserInitializationService.getDefaultUserId();
      await WishlistRepository.addToWishlist(defaultUserId, movieId);
      
      // 로컬 캐시 업데이트
      await loadWishlistFromDatabase();
    } catch (e) {
      debugPrint('북마크 추가 실패: $e');
      rethrow;
    }
  }

  /// 특정 영화를 북마크에서 제거합니다.
  /// 
  /// [movieId] 제거할 영화 ID
  /// DB에서 제거하고 로컬 캐시를 갱신합니다.
  Future<void> removeBookmark(String movieId) async {
    try {
      final defaultUserId = UserInitializationService.getDefaultUserId();
      await WishlistRepository.removeFromWishlist(defaultUserId, movieId);
      
      // 로컬 캐시 업데이트
      await loadWishlistFromDatabase();
    } catch (e) {
      debugPrint('북마크 제거 실패: $e');
      rethrow;
    }
  }

  // ========== 기록(Records) 관련 기능 ==========

  /// 기록 로드 상태를 반환합니다.
  bool get isRecordsLoaded => _recordsLoaded;

  /// 기록 로딩 중인지 반환합니다.
  bool get isLoadingRecords => _isLoadingRecords;

  /// 기록 리스트를 DB에서 로드합니다.
  /// 
  /// 앱 시작 시 또는 기록 추가/수정/삭제 후 호출합니다.
  Future<void> loadRecordsFromDatabase() async {
    if (_isLoadingRecords) return; // 이미 로딩 중이면 스킵

    _isLoadingRecords = true;
    notifyListeners();

    try {
      final defaultUserId = UserInitializationService.getDefaultUserId();
      _records = await RecordRepository.getRecordsByUserId(defaultUserId);
      _recordsLoaded = true;
    } catch (e) {
      debugPrint('기록 로드 실패: $e');
      _records = [];
      _recordsLoaded = false;
    } finally {
      _isLoadingRecords = false;
      notifyListeners();
    }
  }

  /// 기록 리스트를 새로고침합니다.
  /// 
  /// DB에서 최신 데이터를 다시 로드합니다.
  Future<void> refreshRecords() async {
    await loadRecordsFromDatabase();
  }

  /// 모든 관람 기록 리스트를 반환합니다.
  /// DB에서 로드한 데이터를 반환합니다.
  /// DB가 비어있거나 로드되지 않았으면 빈 리스트를 반환합니다.
  List<Record> get allRecords {
    if (_recordsLoaded) {
      return _records;
    }
    // DB가 아직 로드되지 않았으면 빈 리스트 반환
    return [];
  }

  /// 기록을 추가합니다.
  /// 
  /// [record] 추가할 기록
  /// DB에 저장하고 로컬 캐시를 업데이트합니다.
  Future<void> addRecord(Record record) async {
    try {
      final defaultUserId = UserInitializationService.getDefaultUserId();
      // userId를 기본 사용자로 설정
      final recordWithUserId = record.copyWith(userId: defaultUserId);
      
      await RecordRepository.addRecord(recordWithUserId);
      
      // 로컬 캐시 업데이트
      await loadRecordsFromDatabase();
    } catch (e) {
      debugPrint('기록 추가 실패: $e');
      rethrow;
    }
  }

  /// 기록을 업데이트합니다.
  /// 
  /// [record] 업데이트할 기록
  /// DB를 업데이트하고 로컬 캐시를 갱신합니다.
  Future<void> updateRecord(Record record) async {
    try {
      await RecordRepository.updateRecord(record);
      
      // 로컬 캐시 업데이트
      await loadRecordsFromDatabase();
    } catch (e) {
      debugPrint('기록 업데이트 실패: $e');
      rethrow;
    }
  }

  /// 기록을 삭제합니다.
  /// 
  /// [recordId] 삭제할 기록 ID
  /// DB에서 삭제하고 로컬 캐시를 갱신합니다.
  Future<void> deleteRecord(int recordId) async {
    try {
      await RecordRepository.deleteRecord(recordId);
      
      // 로컬 캐시 업데이트
      await loadRecordsFromDatabase();
    } catch (e) {
      debugPrint('기록 삭제 실패: $e');
      rethrow;
    }
  }

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

  /// DB에서 기록을 조회합니다 (비동기).
  /// 
  /// [recordId] 기록 ID
  /// Returns 기록 정보 (없으면 null)
  Future<Record?> getRecordByIdAsync(int recordId) async {
    return await RecordRepository.getRecordById(recordId);
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

  /// 위시리스트 로드 상태를 반환합니다.
  bool get isWishlistLoaded => _wishlistLoaded;

  /// 위시리스트 로딩 중인지 반환합니다.
  bool get isLoadingWishlist => _isLoadingWishlist;

  /// 위시리스트를 DB에서 로드합니다.
  /// 
  /// 앱 시작 시 또는 위시리스트 추가/제거 후 호출합니다.
  Future<void> loadWishlistFromDatabase() async {
    if (_isLoadingWishlist) return; // 이미 로딩 중이면 스킵

    _isLoadingWishlist = true;
    notifyListeners();

    try {
      final defaultUserId = UserInitializationService.getDefaultUserId();
      _wishlist = await WishlistRepository.getWishlist(defaultUserId);
      _wishlistLoaded = true;
      
      // 북마크 상태도 함께 업데이트
      _bookmarkedMovieIds = _wishlist.map((item) => item.movie.id).toSet();
      _bookmarksLoaded = true;
    } catch (e) {
      debugPrint('위시리스트 로드 실패: $e');
      _wishlist = [];
      _wishlistLoaded = false;
    } finally {
      _isLoadingWishlist = false;
      notifyListeners();
    }
  }

  /// 위시리스트를 새로고침합니다.
  /// 
  /// DB에서 최신 데이터를 다시 로드합니다.
  Future<void> refreshWishlist() async {
    await loadWishlistFromDatabase();
  }

  /// 모든 위시리스트 아이템 리스트를 반환합니다.
  /// DB에서 로드한 데이터를 반환합니다.
  /// DB가 비어있거나 로드되지 않았으면 빈 리스트를 반환합니다.
  List<WishlistItem> get wishlist {
    if (_wishlistLoaded) {
      return _wishlist;
    }
    // DB가 아직 로드되지 않았으면 빈 리스트 반환
    return [];
  }

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
  /// DB에 저장하고 로컬 캐시를 업데이트합니다.
  Future<void> addToWishlist(Movie movie) async {
    try {
      final defaultUserId = UserInitializationService.getDefaultUserId();
      await WishlistRepository.addToWishlist(defaultUserId, movie.id);
      
      // 로컬 캐시 업데이트
      await loadWishlistFromDatabase();
    } catch (e) {
      debugPrint('위시리스트 추가 실패: $e');
      rethrow;
    }
  }

  /// 위시리스트에서 영화를 제거합니다.
  /// 
  /// [movieId] 제거할 영화 ID
  /// DB에서 제거하고 로컬 캐시를 갱신합니다.
  Future<void> removeFromWishlist(String movieId) async {
    try {
      final defaultUserId = UserInitializationService.getDefaultUserId();
      await WishlistRepository.removeFromWishlist(defaultUserId, movieId);
      
      // 로컬 캐시 업데이트
      await loadWishlistFromDatabase();
    } catch (e) {
      debugPrint('위시리스트 제거 실패: $e');
      rethrow;
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
