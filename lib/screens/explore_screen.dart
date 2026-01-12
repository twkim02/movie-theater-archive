import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../models/movie.dart';
import '../widgets/add_record_sheet.dart';
import '../data/saved_store.dart';
import '../state/app_state.dart';
import 'test_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = "";

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

  List<Movie> _applySearch(List<Movie> movies) {
    final q = _query.trim();
    if (q.isEmpty) return movies;
    return movies.where((m) => m.title.contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final allMoviesList = appState.movies;
    final recentMovies = _applySearch(allMoviesList.where((m) => m.isRecent).toList());
    final allMovies = _applySearch(allMoviesList.where((m) => !m.isRecent).toList());

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          '무비어리',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'TMDb API 테스트',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TestScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<Set<String>>(
        valueListenable: SavedStore.savedIds,
        builder: (context, savedIds, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Text(
                '탐색',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 10),

              // 검색창
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    isDense: true,
                    icon: Icon(Icons.search, size: 20),
                    hintText: "영화 제목을 검색해보세요",
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // 최근 상영 섹션 헤더
              Row(
                children: [
                  Text(
                    '최근 상영 중인 영화',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
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
                          showTheaterButton: true, // ✅ 최근 상영만 영화관 보기 노출
                          onPressDiary: () => openAddRecordSheet(context, m),
                          onPressTheater: () => _showSnack('영화관 보기: ${m.title}'),
                          onToggleSave: () => SavedStore.toggle(m.id), // ✅ 팝업 없음
                        ),
                      )
                      .toList(),
                ),

              const SizedBox(height: 20),

              // 모든 영화 섹션 헤더
              Text(
                '모든 영화',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
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
                  children: allMovies
                      .map(
                        (m) => MovieCard(
                          movie: m,
                          isSaved: savedIds.contains(m.id),
                          showTheaterButton: false, // ✅ 모든 영화는 영화관 보기 없음
                          onPressDiary: () => openAddRecordSheet(context, m),
                          onPressTheater: null,
                          onToggleSave: () => SavedStore.toggle(m.id), // ✅ 팝업 없음
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

  /// ✅ 최근 상영만 영화관 보기 버튼 노출
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
            // 포스터
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

            // 오른쪽 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목 + 북마크
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

                  // 메타(장르/연도/러닝타임)
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

                  // 사람들 평점
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

                  // 버튼
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
