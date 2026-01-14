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

import '../widgets/paper_scaffold.dart';
import '../widgets/muvieory_header.dart';
import '../widgets/movie_card.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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

  Future<void> _searchMoviesFromTmdb(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final apiKey = EnvLoader.tmdbApiKey;
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('TMDb API 키가 없습니다.');
      }

      final client = TmdbClient(apiKey: apiKey);

      if (TmdbMapper.genreMap == null) {
        final genreMap = await client.getGenres();
        TmdbMapper.setGenreMap(genreMap);
      }

      final response = await client.searchMovies(query, page: 1);
      final top5 = response.results.take(5).toList();
      final movies = TmdbMapper.toMovieList(top5, isRecent: false);

      setState(() {
        _searchResults = movies;
        _isSearching = false;
      });

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
      if (mounted) _showSnack('검색 실패: $e');
    }
  }

  Future<void> _addMovieToDatabase(Movie movie, AppState appState) async {
    try {
      final existing = await MovieRepository.getMovieById(movie.id);
      if (existing != null) {
        _showSnack('이미 DB에 있는 영화입니다.');
        return;
      }

      _showLoading(context, '영화 상세 정보를 가져오는 중...');

      try {
        final apiKey = EnvLoader.tmdbApiKey;
        if (apiKey == null || apiKey.isEmpty) {
          throw Exception('TMDb API 키가 없습니다.');
        }

        final client = TmdbClient(apiKey: apiKey);

        if (TmdbMapper.genreMap == null) {
          final genreMap = await client.getGenres();
          TmdbMapper.setGenreMap(genreMap);
        }

        final movieId = int.tryParse(movie.id);
        if (movieId == null) throw Exception('유효하지 않은 영화 ID입니다.');

        final detail = await client.getMovieDetails(movieId);

        final movieWithDetails = TmdbMapper.toMovieFromDetail(
          detail,
          isRecent: movie.isRecent,
        );

        if (mounted) Navigator.of(context).pop();

        await MovieRepository.addMovie(movieWithDetails);
        await appState.refreshMovies();

        _showSnack('"${movieWithDetails.title}"이(가) 추가되었습니다.');
      } catch (e) {
        if (mounted) Navigator.of(context).pop();
        rethrow;
      }
    } catch (e) {
      _showSnack('영화 추가 실패: $e');
    }
  }

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
                subtitle: movie.releaseDate.isNotEmpty
                    ? Text('개봉일: ${movie.releaseDate}')
                    : null,
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
      backgroundColor: Colors.transparent,
      body: PaperScaffold(
        child: Consumer<AppState>(
          builder: (context, appState, _) {
            final savedIds = appState.bookmarkedMovieIds;

            if (isLoadingMovies) {
              return const Center(child: CircularProgressIndicator());
            }

            // 빈 상태 / 미로드 상태
            if (isEmpty || notLoaded) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                children: [
                  MuvieoryHeader(
                    big: true,
                    onTapSetting: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TestScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  _SearchBar(
                    controller: _searchController,
                    isSearching: _isSearching,
                    onChanged: (v) => setState(() => _query = v),
                    onSubmit: (value) {
                      if (value.trim().isNotEmpty) _searchMoviesFromTmdb(value);
                    },
                    onTapSearch: () {
                      if (_query.trim().isNotEmpty) _searchMoviesFromTmdb(_query);
                    },
                  ),
                  const SizedBox(height: 26),

                  _PaperInfoCard(
                    title: isEmpty ? 'DB에 영화 데이터가 없습니다' : 'DB에서 영화 데이터를 로드하지 못했습니다',
                    subtitle: '더미 데이터를 DB에 저장하여 시작할 수 있습니다.',
                    buttonText: '더미 데이터로 DB 초기화',
                    onPressed: () async {
                      _showLoading(context, 'DB 초기화 중...');
                      try {
                        final count = await MovieDbInitializer.initializeWithDummyData();
                        await appState.refreshMovies();
                        if (mounted) Navigator.of(context).pop();
                        _showSnack('$count개의 영화가 저장되었습니다!');
                      } catch (e) {
                        if (mounted) Navigator.of(context).pop();
                        _showSnack('오류: $e');
                      }
                    },
                  ),
                ],
              );
            }

            // 정상 상태
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              children: [
                MuvieoryHeader(
                  big: true,
                  onTapSetting: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TestScreen()),
                    );
                  },
                ),
                const SizedBox(height: 10),

                _SearchBar(
                  controller: _searchController,
                  isSearching: _isSearching,
                  onChanged: (v) => setState(() => _query = v),
                  onSubmit: (value) {
                    if (value.trim().isNotEmpty) _searchMoviesFromTmdb(value);
                  },
                  onTapSearch: () {
                    if (_query.trim().isNotEmpty) _searchMoviesFromTmdb(_query);
                  },
                ),

                const SizedBox(height: 18),

                const _SectionTitle('최근 상영 중인 영화'),
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
                    children: recentMovies.map((m) {
                      return MovieCard(
                        movie: m,
                        isSaved: savedIds.contains(m.id),
                        showTheaterButton: true,
                        onPressDiary: () => openAddRecordSheet(context, m),
                        onPressTheater: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => TheaterScreen(movie: m)),
                          );
                        },
                        onToggleSave: () => appState.toggleBookmark(m.id),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 18),

                const _SectionTitle('모든 영화'),
                const SizedBox(height: 12),

                if (allMovies.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      "검색 결과가 없어요.",
                      style: TextStyle(color: textSecondary, fontWeight: FontWeight.w600),
                    ),
                  )
                else
                  Column(
                    children: allMovies.map((m) {
                      return MovieCard(
                        movie: m,
                        isSaved: savedIds.contains(m.id),
                        showTheaterButton: false,
                        onPressDiary: () => openAddRecordSheet(context, m),
                        onPressTheater: null,
                        onToggleSave: () => appState.toggleBookmark(m.id),
                      );
                    }).toList(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: Color(0xFF3A2E2E),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSearching;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmit;
  final VoidCallback onTapSearch;

  const _SearchBar({
    required this.controller,
    required this.isSearching,
    required this.onChanged,
    required this.onSubmit,
    required this.onTapSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7EE).withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 20, color: Colors.black54),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: onSubmit,
              decoration: const InputDecoration(
                isDense: true,
                hintText: "영화 제목을 검색해보세요",
                border: InputBorder.none,
              ),
            ),
          ),
          if (isSearching)
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
              onPressed: onTapSearch,
              tooltip: '검색',
            ),
        ],
      ),
    );
  }
}

class _PaperInfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;

  const _PaperInfoCard({
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7EE).withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          Icon(Icons.storage, size: 56, color: Colors.deepPurple.withOpacity(0.75)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: const Color(0xFFB9A7E8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
