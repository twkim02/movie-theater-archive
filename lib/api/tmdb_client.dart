import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

/// TMDb API 클라이언트
/// 
/// TMDb API를 호출하여 영화 정보를 가져오는 클래스입니다.
/// https://developers.themoviedb.org/3 참고
class TmdbClient {
  // TMDb API 기본 URL
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  
  // 이미지 기본 URL
  static const String _imageBaseUrl = 'https://image.tmdb.org/t/p/w500';
  
  // API 키 (env.json에서 로드)
  final String apiKey;
  
  // 언어 설정 (한국어)
  static const String _language = 'ko-KR';
  
  // 지역 설정 (한국)
  static const String _region = 'KR';

  TmdbClient({required this.apiKey});

  /// 포스터 이미지 URL을 생성합니다.
  /// 
  /// [posterPath] TMDb API에서 받은 poster_path (예: "/mSi0gskYpmf1FbXngM37s2HppXh.jpg")
  /// Returns 전체 이미지 URL
  static String buildImageUrl(String? posterPath) {
    if (posterPath == null || posterPath.isEmpty) {
      return '';
    }
    // poster_path가 이미 전체 URL인 경우
    if (posterPath.startsWith('http')) {
      return posterPath;
    }
    // 상대 경로인 경우
    return '$_imageBaseUrl$posterPath';
  }

  /// HTTP GET 요청을 수행합니다.
  Future<Map<String, dynamic>> _get(String endpoint, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$_baseUrl$endpoint').replace(
      queryParameters: {
        'api_key': apiKey,
        'language': _language,
        'region': _region,
        if (queryParams != null) ...queryParams,
      },
    );

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw TmdbException(
          'API 요청 실패: ${response.statusCode}',
          response.statusCode,
        );
      }
    } on SocketException {
      throw TmdbException('네트워크 연결 오류', 0);
    } on FormatException {
      throw TmdbException('응답 파싱 오류', 0);
    } catch (e) {
      throw TmdbException('알 수 없는 오류: $e', 0);
    }
  }

  /// 현재 상영 중인 영화 목록을 가져옵니다.
  /// 
  /// [page] 페이지 번호 (기본값: 1)
  /// Returns TMDb API 응답 (results 배열 포함)
  Future<TmdbMovieListResponse> getNowPlayingMovies({int page = 1}) async {
    final response = await _get(
      '/movie/now_playing',
      queryParams: {'page': page.toString()},
    );

    return TmdbMovieListResponse.fromJson(response);
  }

  /// 인기 영화 목록을 가져옵니다.
  /// 
  /// [page] 페이지 번호 (기본값: 1)
  /// Returns TMDb API 응답 (results 배열 포함)
  Future<TmdbMovieListResponse> getPopularMovies({int page = 1}) async {
    final response = await _get(
      '/movie/popular',
      queryParams: {'page': page.toString()},
    );

    return TmdbMovieListResponse.fromJson(response);
  }

  /// 최고 평점 영화 목록을 가져옵니다.
  /// 
  /// [page] 페이지 번호 (기본값: 1)
  /// Returns TMDb API 응답 (results 배열 포함)
  Future<TmdbMovieListResponse> getTopRatedMovies({int page = 1}) async {
    final response = await _get(
      '/movie/top_rated',
      queryParams: {'page': page.toString()},
    );

    return TmdbMovieListResponse.fromJson(response);
  }

  /// 영화 상세 정보를 가져옵니다.
  /// 
  /// [movieId] TMDb 영화 ID
  /// Returns 영화 상세 정보
  Future<TmdbMovieDetail> getMovieDetails(int movieId) async {
    final response = await _get('/movie/$movieId');
    return TmdbMovieDetail.fromJson(response);
  }

  /// 영화를 검색합니다.
  /// 
  /// [query] 검색어
  /// [page] 페이지 번호 (기본값: 1)
  /// Returns TMDb API 응답 (results 배열 포함)
  Future<TmdbMovieListResponse> searchMovies(String query, {int page = 1}) async {
    if (query.trim().isEmpty) {
      throw TmdbException('검색어를 입력해주세요', 0);
    }

    final response = await _get(
      '/search/movie',
      queryParams: {
        'query': query,
        'page': page.toString(),
      },
    );

    return TmdbMovieListResponse.fromJson(response);
  }

  /// 장르 목록을 가져옵니다.
  /// 
  /// Returns 장르 ID와 이름 매핑
  Future<Map<int, String>> getGenres() async {
    final response = await _get('/genre/movie/list');
    
    final genres = response['genres'] as List<dynamic>;
    final genreMap = <int, String>{};
    
    for (final genre in genres) {
      final id = genre['id'] as int;
      final name = genre['name'] as String;
      genreMap[id] = name;
    }
    
    return genreMap;
  }
}

/// TMDb API 예외 클래스
class TmdbException implements Exception {
  final String message;
  final int statusCode;

  TmdbException(this.message, this.statusCode);

  @override
  String toString() => 'TmdbException: $message (Status: $statusCode)';
}

/// TMDb 영화 목록 응답 모델
class TmdbMovieListResponse {
  final int page;
  final List<TmdbMovie> results;
  final int totalPages;
  final int totalResults;

  TmdbMovieListResponse({
    required this.page,
    required this.results,
    required this.totalPages,
    required this.totalResults,
  });

  factory TmdbMovieListResponse.fromJson(Map<String, dynamic> json) {
    return TmdbMovieListResponse(
      page: json['page'] as int? ?? 1,
      results: (json['results'] as List<dynamic>?)
              ?.map((item) => TmdbMovie.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalPages: json['total_pages'] as int? ?? 1,
      totalResults: json['total_results'] as int? ?? 0,
    );
  }
}

/// TMDb 영화 기본 정보 모델
class TmdbMovie {
  final int id;
  final String title;
  final String? posterPath;
  final String? releaseDate;
  final double? voteAverage;
  final List<int> genreIds;
  final int? runtime;

  TmdbMovie({
    required this.id,
    required this.title,
    this.posterPath,
    this.releaseDate,
    this.voteAverage,
    required this.genreIds,
    this.runtime,
  });

  factory TmdbMovie.fromJson(Map<String, dynamic> json) {
    return TmdbMovie(
      id: json['id'] as int,
      title: json['title'] as String? ?? json['original_title'] as String? ?? '',
      posterPath: json['poster_path'] as String?,
      releaseDate: json['release_date'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      genreIds: (json['genre_ids'] as List<dynamic>?)
              ?.map((id) => id as int)
              .toList() ??
          [],
      runtime: json['runtime'] as int?,
    );
  }
}

/// TMDb 영화 상세 정보 모델
class TmdbMovieDetail extends TmdbMovie {
  final String? overview;
  final List<TmdbGenre> genres;

  TmdbMovieDetail({
    required super.id,
    required super.title,
    super.posterPath,
    super.releaseDate,
    super.voteAverage,
    required super.genreIds,
    super.runtime,
    this.overview,
    required this.genres,
  });

  factory TmdbMovieDetail.fromJson(Map<String, dynamic> json) {
    return TmdbMovieDetail(
      id: json['id'] as int,
      title: json['title'] as String? ?? json['original_title'] as String? ?? '',
      posterPath: json['poster_path'] as String?,
      releaseDate: json['release_date'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      genreIds: (json['genres'] as List<dynamic>?)
              ?.map((g) => g['id'] as int)
              .toList() ??
          [],
      runtime: json['runtime'] as int?,
      overview: json['overview'] as String?,
      genres: (json['genres'] as List<dynamic>?)
              ?.map((g) => TmdbGenre.fromJson(g as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// TMDb 장르 모델
class TmdbGenre {
  final int id;
  final String name;

  TmdbGenre({
    required this.id,
    required this.name,
  });

  factory TmdbGenre.fromJson(Map<String, dynamic> json) {
    return TmdbGenre(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}
