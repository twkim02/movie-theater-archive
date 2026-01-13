import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/colors.dart';
import '../models/movie.dart';
import '../widgets/add_record_sheet.dart';
import '../state/app_state.dart';
import '../services/movie_db_initializer.dart';
import '../api/tmdb_client.dart';
import '../api/tmdb_mapper.dart';
import '../utils/env_loader.dart';
import '../repositories/movie_repository.dart';
import 'test_screen.dart';
import 'theater_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = "";
  List<Movie> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void _showLoading(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  /// TMDb API를 사용하여 영화를 검색합니다.
  Future<void> _searchMoviesFromTmdb(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final apiKey = EnvLoader.tmdbApiKey;
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('TMDb API 키가 없습니다.');
      }

      final client = TmdbClient(apiKey: apiKey);

      // 장르 맵 로드 (필요한 경우)
      if (TmdbMapper.genreMap == null) {
        final genreMap = await client.getGenres();
        TmdbMapper.setGenreMap(genreMap);
      }

      // TMDb 검색 API 호출
      final response = await client.searchMovies(query, page: 1);

      // 상위 5개만 선택
      final top5 = response.results.take(5).toList();

      // Movie 모델로 변환
      final movies = TmdbMapper.toMovieList(top5, isRecent: false);

      setState(() {
        _searchResults = movies;
        _isSearching = false;
      });

      // 검색 결과가 있으면 다이얼로그 표시
      if (movies.isNotEmpty && mounted) {
        _showSearchResultsDialog(context, context.read<AppState>());
      } else if (movies.isEmpty && mounted) {
        _showSnack('검색 결과가 없습니다.');
      }
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      if (mounted) {
        _showSnack('검색 실패: $e');
      }
    }
  }

  /// 검색 결과에서 영화를 선택하여 DB에 추가합니다.
  Future<void> _addMovieToDatabase(Movie movie, AppState appState) async {
    try {
      // DB에 이미 있는지 확인
      final existing = await MovieRepository.getMovieById(movie.id);
      if (existing != null) {
        _showSnack('이미 DB에 있는 영화입니다.');
        return;
      }

      // 로딩 표시
      _showLoading(context, '영화 상세 정보를 가져오는 중...');

      try {
        final apiKey = EnvLoader.tmdbApiKey;
        if (apiKey == null || apiKey.isEmpty) {
          throw Exception('TMDb API 키가 없습니다.');
        }

        final client = TmdbClient(apiKey: apiKey);

        // 장르 맵 로드 (필요한 경우)
        if (TmdbMapper.genreMap == null) {
          final genreMap = await client.getGenres();
          TmdbMapper.setGenreMap(genreMap);
        }

        // 영화 상세 정보 가져오기 (runtime 등 포함)
        final movieId = int.tryParse(movie.id);
        if (movieId == null) {
          throw Exception('유효하지 않은 영화 ID입니다.');
        }

        final detail = await client.getMovieDetails(movieId);

        debugPrint(
            '🔍 TMDb API 응답 - ID: ${detail.id}, Title: ${detail.title}, Runtime: ${detail.runtime} (타입: ${detail.runtime.runtimeType})');

        // 상세 정보를 Movie 모델로 변환
        final movieWithDetails = TmdbMapper.toMovieFromDetail(
          detail,
          isRecent: movie.isRecent, // 기존 isRecent 값 유지
        );

        debugPrint(
            '✅ 변환된 Movie - ID: ${movieWithDetails.id}, Title: ${movieWithDetails.title}, Runtime: ${movieWithDetails.runtime}');

        // runtime이 0이면 경고 (TMDb API에서 runtime이 제공되지 않았을 수 있음)
        if (movieWithDetails.runtime == 0 && detail.runtime == null) {
          debugPrint(
              '⚠️ 경고: 영화 "${movieWithDetails.title}"의 runtime이 TMDb API에서 제공되지 않았습니다.');
        } else if (movieWithDetails.runtime == 0 &&
            detail.runtime != null &&
            detail.runtime! > 0) {
          debugPrint(
              '❌ 오류: 영화 "${movieWithDetails.title}"의 runtime이 변환 과정에서 0으로 설정되었습니다. 원본: ${detail.runtime}');
        }

        // 로딩 닫기
        Navigator.of(context).pop();

        // DB에 추가
        await MovieRepository.addMovie(movieWithDetails);

        // 디버깅: DB 저장 후 확인
        final savedMovie = await MovieRepository.getMovieById(movieWithDetails.id);
        if (savedMovie != null) {
          debugPrint(
              '💾 DB 저장 확인 - ID: ${savedMovie.id}, Title: ${savedMovie.title}, Runtime: ${savedMovie.runtime}');

          if (savedMovie.runtime == 0 &&
              detail.runtime != null &&
              detail.runtime! > 0) {
            debugPrint(
                '❌ 심각한 오류: DB에 저장된 runtime이 0입니다. 원본 TMDb runtime: ${detail.runtime}');
          }
        } else {
          debugPrint('❌ 오류: DB에서 영화를 찾을 수 없습니다.');
        }

        // AppState 새로고침
        await appState.refreshMovies();

        _showSnack('"${movieWithDetails.title}"이(가) 추가되었습니다.');
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop();
        }
        throw e;
      }
    } catch (e) {
      _showSnack('영화 추가 실패: $e');
    }
  }

  /// 검색 결과를 표시하는 다이얼로그를 엽니다.
  void _showSearchResultsDialog(BuildContext context, AppState appState) {
    if (_searchResults.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('검색 결과 (${_searchResults.length}개)'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final movie = _searchResults[index];
              return ListTile(
                title: Text(movie.title),
                subtitle:
                    movie.releaseDate.isNotEmpty ? Text('개봉일: ${movie.releaseDate}') : null,
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _addMovieToDatabase(movie, appState);
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  List<Movie> _applySearch(List<Movie> movies) {
    final q = _query.trim();
    if (q.isEmpty) return movies;
    return movies.where((m) => m.title.contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final allMoviesList = appState.movies;
    final isMoviesLoaded = appState.isMoviesLoaded;
    final isLoadingMovies = appState.isLoadingMovies;
    final recentMovies = _applySearch(allMoviesList.where((m) => m.isRecent).toList());
    final allMovies = _applySearch(allMoviesList.where((m) => !m.isRecent).toList());

    final bool isEmpty = allMoviesList.isEmpty && isMoviesLoaded;
    final bool notLoaded = !isMoviesLoaded && !isLoadingMovies;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('무비어리', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'TMDb API 테스트',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TestScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          final savedIds = appState.bookmarkedMovieIds;

          if (isEmpty || notLoaded) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Text('탐색',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary)),
                const SizedBox(height: 10),

                // 검색창
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _query = v),
                          onSubmitted: (value) {
                            if (value.trim().isNotEmpty) {
                              _searchMoviesFromTmdb(value);
                            }
                          },
                          decoration: const InputDecoration(
                            isDense: true,
                            icon: Icon(Icons.search, size: 20),
                            hintText: "영화 제목을 검색해보세요 (TMDb)",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (_isSearching)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.search, size: 20),
                          onPressed: () {
                            if (_query.trim().isNotEmpty) {
                              _searchMoviesFromTmdb(_query);
                            }
                          },
                          tooltip: '검색',
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Icon(Icons.storage, size: 64, color: Colors.blue.shade700),
                        const SizedBox(height: 16),
                        Text(
                          isEmpty ? 'DB에 영화 데이터가 없습니다' : 'DB에서 영화 데이터를 로드하지 못했습니다',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '더미 데이터를 DB에 저장하여 시작할 수 있습니다.',
                          style: TextStyle(fontSize: 13, color: textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () async {
                            _showLoading(context, 'DB 초기화 중...');
                            try {
                              final count = await MovieDbInitializer.initializeWithDummyData();
                              await appState.refreshMovies();
                              Navigator.of(context).pop();
                              _showSnack('$count개의 영화가 저장되었습니다!');
                            } catch (e) {
                              Navigator.of(context).pop();
                              _showSnack('오류: $e');
                            }
                          },
                          icon: const Icon(Icons.add_circle),
                          label: const Text('더미 데이터로 DB 초기화'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          if (isLoadingMovies) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Text('탐색',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary)),
              const SizedBox(height: 10),

              // 검색창
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _query = v),
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            _searchMoviesFromTmdb(value);
                          }
                        },
                        decoration: const InputDecoration(
                          isDense: true,
                          icon: Icon(Icons.search, size: 20),
                          hintText: "영화 제목을 검색해보세요 (TMDb)",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (_isSearching)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.search, size: 20),
                        onPressed: () {
                          if (_query.trim().isNotEmpty) {
                            _searchMoviesFromTmdb(_query);
                          }
                        },
                        tooltip: '검색',
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 최근 상영 섹션 헤더
              Row(
                children: [
                  Text('최근 상영 중인 영화',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.pinkAccent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (recentMovies.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    _query.trim().isEmpty ? "최근 상영 영화가 없어요." : "검색 결과가 없어요.",
                    style: TextStyle(color: textSecondary, fontWeight: FontWeight.w600),
                  ),
                )
              else
                Column(
                  children: recentMovies
                      .map(
                        (m) => MovieCard(
                          movie: m,
                          isSaved: savedIds.contains(m.id),
                          showTheaterButton: true,
                          onPressDiary: () => openAddRecordSheet(context, m),

                          // ✅ 여기 수정! 영화관 보기 버튼 → TheaterScreen으로 이동
                          onPressTheater: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TheaterScreen(movie: m),
                              ),
                            );
                          },

                          onToggleSave: () => appState.toggleBookmark(m.id),
                        ),
                      )
                      .toList(),
                ),

              const SizedBox(height: 20),

              Text('모든 영화',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary)),
              const SizedBox(height: 12),

              if (allMovies.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text("검색 결과가 없어요.",
                      style: TextStyle(color: textSecondary, fontWeight: FontWeight.w600)),
                )
              else
                Column(
                  children: allMovies
                      .map(
                        (m) => MovieCard(
                          movie: m,
                          isSaved: savedIds.contains(m.id),
                          showTheaterButton: false,
                          onPressDiary: () => openAddRecordSheet(context, m),
                          onPressTheater: null,
                          onToggleSave: () => appState.toggleBookmark(m.id),
                        ),
                      )
                      .toList(),
                ),
            ],
          );
        },
      ),
    );
  }
}

class MovieCard extends StatelessWidget {
  final Movie movie;

  final VoidCallback? onPressDiary;
  final VoidCallback? onPressTheater;
  final VoidCallback? onToggleSave;
  final bool isSaved;

  final bool showTheaterButton;

  const MovieCard({
    super.key,
    required this.movie,
    this.onPressDiary,
    this.onPressTheater,
    this.onToggleSave,
    this.isSaved = false,
    this.showTheaterButton = true,
  });

  String get year {
    if (movie.releaseDate.length >= 4) return movie.releaseDate.substring(0, 4);
    return "";
  }

  @override
  Widget build(BuildContext context) {
    final genreText = movie.genres.take(2).join('·');
    final metaText = '$genreText · $year · ${movie.runtime}분';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0E3E8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                movie.posterUrl,
                width: 78,
                height: 110,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 78,
                  height: 110,
                  color: Colors.black12,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined, size: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          movie.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: onToggleSave,
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            isSaved ? Icons.bookmark : Icons.bookmark_border,
                            size: 20,
                            color: isSaved ? primaryColor : Colors.black45,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  Text(
                    metaText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Color(0xFFFFC107)),
                      const SizedBox(width: 4),
                      Text(
                        '사람들 평점 ${movie.voteAverage.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (showTheaterButton)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onPressDiary,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              '✍️일기 쓰기',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onPressTheater,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryColor,
                              minimumSize: const Size.fromHeight(40),
                              side: BorderSide(color: primaryColor.withValues(alpha: 0.55)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              '영화관 보기',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: onPressDiary,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          '✍️일기 쓰기',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
