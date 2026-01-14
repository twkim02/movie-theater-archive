import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/wishlist.dart';
import '../api/tmdb_client.dart';
import '../api/tmdb_mapper.dart';
import '../utils/env_loader.dart';
import '../models/movie.dart';
import '../repositories/movie_repository.dart';
import '../services/movie_db_initializer.dart';
import '../services/movie_initialization_service.dart';
import '../services/movie_update_service.dart';
import '../utils/csv_parser.dart';
import '../services/movie_title_matcher.dart';
import '../api/lottecinema_client.dart';
import '../models/lottecinema_data.dart';
import '../services/theater_schedule_service.dart';
import '../models/theater.dart';
import '../services/lottecinema_movie_checker.dart';
import '../widgets/theater_card.dart';
import '../api/megabox_client.dart';
import '../models/megabox_data.dart';
import '../services/megabox_movie_checker.dart';

/// 개발/테스트용 화면
/// 작성한 코드가 제대로 작동하는지 시각적으로 확인할 수 있습니다.
/// 
/// 이 화면은 개발 중에만 사용하고, 최종 제출 전에 제거하거나 
/// 팀원과 합칠 때는 이 파일을 포함하지 않아도 됩니다.
class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 코드 검증 테스트 화면'),
        backgroundColor: Colors.blue.shade700,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.check_circle), text: '요약'),
            Tab(icon: Icon(Icons.movie), text: '영화'),
            Tab(icon: Icon(Icons.history), text: '기록'),
            Tab(icon: Icon(Icons.favorite), text: '위시리스트'),
            Tab(icon: Icon(Icons.bar_chart), text: '통계'),
            Tab(icon: Icon(Icons.cloud), text: 'TMDb API'),
            Tab(icon: Icon(Icons.storage), text: 'DB 테스트'),
            Tab(icon: Icon(Icons.theater_comedy), text: '롯데시네마'),
            Tab(icon: Icon(Icons.movie_filter), text: '메가박스'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryTab(context, appState),
          _buildMoviesTab(context, appState),
          _buildRecordsTab(context, appState),
          _buildWishlistTab(context, appState),
          _buildStatisticsTab(context, appState),
          _buildTmdbApiTab(context),
          _buildDbTestTab(context, appState),
          _buildLotteCinemaTab(context),
          _buildMegaboxTab(context),
        ],
      ),
    );
  }

  // ========== 요약 탭 ==========
  Widget _buildSummaryTab(BuildContext context, AppState appState) {
    final movies = appState.movies;
    final records = appState.allRecords;
    final wishlist = appState.wishlist;
    final allTestsPassed = movies.isNotEmpty && 
                          records.isNotEmpty && 
                          wishlist.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 전체 테스트 결과 카드
          Card(
            color: allTestsPassed ? Colors.green.shade50 : Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        allTestsPassed ? Icons.check_circle : Icons.error,
                        color: allTestsPassed ? Colors.green : Colors.red,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '전체 테스트 요약',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTestResultItem('✅ 영화 데이터', movies.isNotEmpty, '${movies.length}개 영화'),
                  _buildTestResultItem('✅ 기록 데이터', records.isNotEmpty, '${records.length}개 기록'),
                  _buildTestResultItem('✅ 위시리스트', wishlist.isNotEmpty, '${wishlist.length}개 아이템'),
                  _buildTestResultItem('✅ 통계 데이터', true, '로드 완료'),
                  _buildTestResultItem('✅ Provider 연결', true, 'AppState 접근 가능'),
                  const Divider(height: 32),
                  Text(
                    '각 탭에서 상세 기능을 테스트할 수 있습니다.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== 영화 탭 ==========
  Widget _buildMoviesTab(BuildContext context, AppState appState) {
    final movies = appState.movies;
    final bookmarkedMovies = appState.bookmarkedMovies;

    if (movies.isEmpty) {
      return const Center(child: Text('영화 데이터가 없습니다.'));
    }

    final firstMovie = movies.first;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Movie 모델 테스트
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1️⃣ Movie 모델 테스트',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('영화 제목: ${firstMovie.title}'),
                  Text('ID: ${firstMovie.id}'),
                  Text('장르: ${firstMovie.genres.join(", ")}'),
                  Text('개봉일: ${firstMovie.releaseDate}'),
                  Text('러닝타임: ${firstMovie.runtime}분'),
                  Text('평점: ${firstMovie.voteAverage}'),
                  Text('최신작 여부: ${firstMovie.isRecent ? "예" : "아니오"}'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          final json = firstMovie.toJson();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('JSON 변환 성공! (keys: ${json.keys.length}개)'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.code),
                        label: const Text('toJson() 테스트'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          final modified = firstMovie.copyWith(isRecent: !firstMovie.isRecent);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('copyWith 성공! isRecent: ${modified.isRecent}'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('copyWith() 테스트'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // 북마크 기능 테스트
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '2️⃣ 북마크 기능 테스트',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('전체 영화 수: ${movies.length}개'),
                  Text('북마크된 영화: ${bookmarkedMovies.length}개'),
                  Text('테스트 영화 (${firstMovie.title}) 북마크 상태: ${appState.isBookmarked(firstMovie.id) ? "북마크됨" : "북마크 안됨"}'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await appState.toggleBookmark(firstMovie.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('북마크 토글 완료! (화면이 자동 업데이트됨)'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    icon: Icon(appState.isBookmarked(firstMovie.id) ? Icons.bookmark : Icons.bookmark_border),
                    label: Text(appState.isBookmarked(firstMovie.id) ? '북마크 해제' : '북마크 추가'),
                  ),
                  const SizedBox(height: 16),
                  if (bookmarkedMovies.isNotEmpty) ...[
                    const Text('북마크된 영화 목록:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...bookmarkedMovies.take(5).map((movie) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text('✅ ${movie.title} (${movie.id})'),
                    )),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== 기록 탭 ==========
  Widget _buildRecordsTab(BuildContext context, AppState appState) {
    final allRecords = appState.allRecords;
    final filteredRecords = appState.records;
    final recordStats = appState.getRecordStatistics();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 기록 통계
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📊 기록 통계',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatItem('전체 기록 수', '${recordStats['totalCount']}개'),
                  _buildStatItem('평균 별점', '${recordStats['averageRating']?.toStringAsFixed(1)}점'),
                  _buildStatItem('본 영화 수', '${recordStats['totalMovies']}개'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 정렬 옵션 테스트
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1️⃣ 기록 정렬 테스트',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('현재 정렬: ${_getSortOptionName(appState.recordSortOption)}'),
                  Text('필터된 기록 수: ${filteredRecords.length}개 / 전체 ${allRecords.length}개'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          appState.setRecordSortOption(RecordSortOption.latest);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('최신순으로 정렬됨')),
                          );
                        },
                        child: const Text('최신순'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          appState.setRecordSortOption(RecordSortOption.rating);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('별점순으로 정렬됨')),
                          );
                        },
                        child: const Text('별점순'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          appState.setRecordSortOption(RecordSortOption.viewCount);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('많이 본 순으로 정렬됨')),
                          );
                        },
                        child: const Text('많이 본 순'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 필터 테스트
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '2️⃣ 기록 필터 테스트',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '검색어 (제목/태그/한줄평)',
                      border: OutlineInputBorder(),
                      hintText: '예: 가족, 액션',
                    ),
                    onChanged: (value) {
                      appState.setRecordSearchQuery(value);
                    },
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      appState.clearRecordFilters();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('필터 초기화됨')),
                      );
                    },
                    child: const Text('필터 초기화'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 기록 목록
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '3️⃣ 기록 목록 (최대 5개 표시)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  if (filteredRecords.isEmpty)
                    const Text('기록이 없습니다.')
                  else
                    ...filteredRecords.take(5).map((record) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.movie.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('별점: ${record.rating}점 | 관람일: ${_formatDate(record.watchDate)}'),
                          if (record.oneLiner != null)
                            Text('한줄평: ${record.oneLiner}'),
                          if (record.tags.isNotEmpty)
                            Text('태그: ${record.tags.join(", ")}'),
                          const Divider(),
                        ],
                      ),
                    )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== 위시리스트 탭 ==========
  Widget _buildWishlistTab(BuildContext context, AppState appState) {
    final wishlist = appState.wishlist;
    // 위시리스트에 없는 영화 필터링 (동기적으로 처리)
    final bookmarkedIds = appState.bookmarkedMovieIds;
    final availableMovies = appState.movies.where((m) => !bookmarkedIds.contains(m.id)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 위시리스트 통계
          Card(
            color: Colors.pink.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📊 위시리스트 통계',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatItem('전체 위시리스트', '${appState.wishlistCount}개'),
                  _buildStatItem('로드 상태', appState.isWishlistLoaded ? '로드 완료' : '로딩 중'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 위시리스트 추가/제거 테스트
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1️⃣ 위시리스트 추가/제거 테스트',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  if (availableMovies.isEmpty)
                    const Text('추가할 수 있는 영화가 없습니다.')
                  else ...[
                    Text('영화 추가 테스트 (${availableMovies.length}개 영화 중 선택):'),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: availableMovies.length > 5 ? 5 : availableMovies.length,
                        itemBuilder: (context, index) {
                          final movie = availableMovies[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ElevatedButton(
                              onPressed: () async {
                                try {
                                  await appState.addToWishlist(movie);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${movie.title}을(를) 위시리스트에 추가했습니다.')),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('추가 실패: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Text(movie.title, textAlign: TextAlign.center),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 위시리스트 정렬 테스트
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '2️⃣ 위시리스트 정렬 테스트',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          final sorted = appState.getSortedWishlistByDate(ascending: false);
                          _showSortedWishlist(context, '최신순', sorted);
                        },
                        child: const Text('날짜순 (최신)'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final sorted = appState.getSortedWishlistByTitle(ascending: true);
                          _showSortedWishlist(context, '제목순 (가나다)', sorted);
                        },
                        child: const Text('제목순'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final sorted = appState.getSortedWishlistByRating(ascending: false);
                          _showSortedWishlist(context, '평점순 (높은 순)', sorted);
                        },
                        child: const Text('평점순'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 위시리스트 목록
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '3️⃣ 위시리스트 목록 (최대 5개 표시)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  if (wishlist.isEmpty)
                    const Text('위시리스트가 비어있습니다.')
                  else
                    ...wishlist.take(5).map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.movie.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text('찜한 날짜: ${_formatDate(item.savedAt)}'),
                                Text('평점: ${item.movie.displayVoteAverage}점'),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              try {
                                await appState.removeFromWishlist(item.movie.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${item.movie.title}을(를) 위시리스트에서 제거했습니다.')),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('제거 실패: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== 통계 탭 ==========
  Widget _buildStatisticsTab(BuildContext context, AppState appState) {
    final statistics = appState.statistics;
    final calculatedSummary = appState.calculateSummaryFromRecords();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 요약 통계
          Card(
            color: Colors.purple.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📊 요약 통계',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildStatItem('전체 기록 수', '${statistics.summary.totalRecords}개'),
                  _buildStatItem('평균 별점', '${statistics.summary.averageRating}점'),
                  _buildStatItem('최다 선호 장르', statistics.summary.topGenre),
                  const SizedBox(height: 16),
                  Text(
                    '실제 기록 데이터 기반 계산:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  _buildStatItem('계산된 기록 수', '${calculatedSummary.totalRecords}개'),
                  _buildStatItem('계산된 평균 별점', '${calculatedSummary.averageRating.toStringAsFixed(1)}점'),
                  _buildStatItem('계산된 최다 장르', calculatedSummary.topGenre),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 장르 분포
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1️⃣ 장르 분포',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  
                  // 전체 기간
                  Text(
                    '전체 기간 (${statistics.genreDistribution.all.length}개 장르):',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...statistics.genreDistribution.all.take(5).map((item) => 
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Expanded(child: Text(item.name)),
                          Text('${item.count}회', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ),
                  if (statistics.genreDistribution.all.length > 5)
                    Text('... 외 ${statistics.genreDistribution.all.length - 5}개 장르'),

                  const SizedBox(height: 16),
                  
                  // 최근 1년
                  Text(
                    '최근 1년 (${statistics.genreDistribution.recent1Year.length}개 장르):',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...statistics.genreDistribution.recent1Year.take(3).map((item) => 
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Expanded(child: Text(item.name)),
                          Text('${item.count}회', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  
                  // 최근 3년
                  Text(
                    '최근 3년 (${statistics.genreDistribution.recent3Years.length}개 장르):',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...statistics.genreDistribution.recent3Years.take(3).map((item) => 
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Expanded(child: Text(item.name)),
                          Text('${item.count}회', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 관람 추이
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '2️⃣ 관람 추이',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  
                  // 연도별
                  Text(
                    '연도별 (${statistics.viewingTrend.yearly.length}개 연도):',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...statistics.viewingTrend.yearly.map((item) => 
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Expanded(child: Text('${item.date}년')),
                          Text('${item.count}회', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  
                  // 월별
                  Text(
                    '월별 (${statistics.viewingTrend.monthly.length}개 월):',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...statistics.viewingTrend.monthly.take(6).map((item) => 
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Expanded(child: Text(item.date)),
                          Text('${item.count}회', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ),
                  if (statistics.viewingTrend.monthly.length > 6)
                    Text('... 외 ${statistics.viewingTrend.monthly.length - 6}개 월'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== TMDb API 테스트 탭 ==========
  Widget _buildTmdbApiTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // API 키 확인
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔑 API 키 확인',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final apiKey = EnvLoader.tmdbApiKey;
                      if (apiKey == null || apiKey.isEmpty) {
                        return const Text(
                          '❌ API 키를 찾을 수 없습니다.\nenv.json 파일을 확인하세요.',
                          style: TextStyle(color: Colors.red),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('✅ API 키 로드 성공'),
                          const SizedBox(height: 4),
                          Text(
                            '키: ${apiKey.substring(0, 8)}...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 현재 상영 중인 영화 테스트
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1️⃣ 현재 상영 중인 영화',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _testNowPlayingMovies(context);
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('현재 상영 중인 영화 가져오기'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 인기 영화 테스트
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '2️⃣ 인기 영화',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _testPopularMovies(context);
                    },
                    icon: const Icon(Icons.star),
                    label: const Text('인기 영화 가져오기'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 영화 검색 테스트
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '3️⃣ 영화 검색',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: '검색어 입력',
                      hintText: '예: 기생충, 아바타',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) async {
                      if (value.trim().isNotEmpty) {
                        await _testSearchMovies(context, value.trim());
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _testSearchMovies(context, '기생충');
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('예시: "기생충" 검색'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 장르 목록 테스트
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '4️⃣ 장르 목록',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _testGenres(context);
                    },
                    icon: const Icon(Icons.category),
                    label: const Text('장르 목록 가져오기'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // TMDb API 테스트 메서드들
  Future<void> _testNowPlayingMovies(BuildContext context) async {
    final apiKey = EnvLoader.tmdbApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      _showError(context, 'API 키가 없습니다.');
      return;
    }

    try {
      _showLoading(context, '현재 상영 중인 영화를 가져오는 중...');
      
      final client = TmdbClient(apiKey: apiKey);
      
      // 장르 맵 먼저 로드
      final genreMap = await client.getGenres();
      TmdbMapper.setGenreMap(genreMap);
      
      // 현재 상영 중인 영화 가져오기
      final response = await client.getNowPlayingMovies();
      final movies = TmdbMapper.toMovieList(response.results, isRecent: true);
      
      Navigator.of(context).pop(); // 로딩 닫기
      
      _showMovieResults(
        context,
        '현재 상영 중인 영화',
        movies,
        '총 ${response.totalResults}개 영화 중 ${response.results.length}개 로드됨',
      );
    } catch (e) {
      Navigator.of(context).pop(); // 로딩 닫기
      _showError(context, '오류: $e');
    }
  }

  Future<void> _testPopularMovies(BuildContext context) async {
    final apiKey = EnvLoader.tmdbApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      _showError(context, 'API 키가 없습니다.');
      return;
    }

    try {
      _showLoading(context, '인기 영화를 가져오는 중...');
      
      final client = TmdbClient(apiKey: apiKey);
      
      // 장르 맵 먼저 로드
      final genreMap = await client.getGenres();
      TmdbMapper.setGenreMap(genreMap);
      
      // 인기 영화 가져오기
      final response = await client.getPopularMovies();
      final movies = TmdbMapper.toMovieList(response.results, isRecent: false);
      
      Navigator.of(context).pop(); // 로딩 닫기
      
      _showMovieResults(
        context,
        '인기 영화',
        movies,
        '총 ${response.totalResults}개 영화 중 ${response.results.length}개 로드됨',
      );
    } catch (e) {
      Navigator.of(context).pop(); // 로딩 닫기
      _showError(context, '오류: $e');
    }
  }

  Future<void> _testSearchMovies(BuildContext context, String query) async {
    final apiKey = EnvLoader.tmdbApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      _showError(context, 'API 키가 없습니다.');
      return;
    }

    try {
      _showLoading(context, '"$query" 검색 중...');
      
      final client = TmdbClient(apiKey: apiKey);
      
      // 장르 맵 먼저 로드
      final genreMap = await client.getGenres();
      TmdbMapper.setGenreMap(genreMap);
      
      // 영화 검색
      final response = await client.searchMovies(query);
      final movies = TmdbMapper.toMovieList(response.results);
      
      Navigator.of(context).pop(); // 로딩 닫기
      
      _showMovieResults(
        context,
        '검색 결과: "$query"',
        movies,
        '총 ${response.totalResults}개 결과 중 ${response.results.length}개 로드됨',
      );
    } catch (e) {
      Navigator.of(context).pop(); // 로딩 닫기
      _showError(context, '오류: $e');
    }
  }

  Future<void> _testGenres(BuildContext context) async {
    final apiKey = EnvLoader.tmdbApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      _showError(context, 'API 키가 없습니다.');
      return;
    }

    try {
      _showLoading(context, '장르 목록을 가져오는 중...');
      
      final client = TmdbClient(apiKey: apiKey);
      final genreMap = await client.getGenres();
      TmdbMapper.setGenreMap(genreMap);
      
      Navigator.of(context).pop(); // 로딩 닫기
      
      _showGenreResults(context, genreMap);
    } catch (e) {
      Navigator.of(context).pop(); // 로딩 닫기
      _showError(context, '오류: $e');
    }
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

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showMovieResults(
    BuildContext context,
    String title,
    List<Movie> movies,
    String summary,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                summary,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: movies.length > 10 ? 10 : movies.length,
                  itemBuilder: (context, index) {
                    final movie = movies[index];
                    return ListTile(
                      dense: true,
                      leading: movie.posterUrl.isNotEmpty
                          ? Image.network(
                              movie.posterUrl,
                              width: 50,
                              height: 75,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.movie),
                            )
                          : const Icon(Icons.movie),
                      title: Text(
                        movie.title,
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        '${movie.genres.join(", ")}\n평점: ${movie.displayVoteAverage} | ${movie.releaseDate}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  },
                ),
              ),
              if (movies.length > 10)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '... 외 ${movies.length - 10}개 영화',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
            ],
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

  void _showGenreResults(BuildContext context, Map<int, String> genreMap) {
    final sortedGenres = genreMap.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('장르 목록'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sortedGenres.length,
            itemBuilder: (context, index) {
              final entry = sortedGenres[index];
              return ListTile(
                dense: true,
                leading: Text(
                  '${entry.key}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                title: Text(entry.value),
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

  // ========== DB 테스트 탭 ==========
  Widget _buildDbTestTab(BuildContext context, AppState appState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DB 상태 확인
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💾 DB 상태',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  FutureBuilder<int>(
                    future: MovieRepository.getMovieCount(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text('로딩 중...');
                      }
                      if (snapshot.hasError) {
                        return Text('오류: ${snapshot.error}');
                      }
                      return Text('저장된 영화 수: ${snapshot.data ?? 0}개');
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 더미 데이터로 초기화
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1️⃣ 더미 데이터로 DB 초기화',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('더미 데이터를 DB에 저장합니다.'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      _showLoading(context, '더미 데이터 저장 중...');
                      try {
                        final count = await MovieDbInitializer.initializeWithDummyData();
                        Navigator.of(context).pop(); // 로딩 닫기
                        appState.refreshMovies(); // 영화 리스트 새로고침
                        _showSuccess(context, '$count개의 영화가 저장되었습니다.');
                      } catch (e) {
                        Navigator.of(context).pop(); // 로딩 닫기
                        _showError(context, '오류: $e');
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('더미 데이터 저장'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // TMDb API로 초기화
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '2️⃣ TMDb API로 영화 초기화',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'TMDb API를 통해 현재 상영 중인 영화와 인기 영화를 가져와 DB에 저장합니다.\n'
                    '이미 DB에 있는 영화는 스킵됩니다.',
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      _showLoading(context, 'TMDb API에서 영화 가져오는 중...\n시간이 걸릴 수 있습니다.');
                      try {
                        final count = await MovieInitializationService.initializeMovies();
                        Navigator.of(context).pop(); // 로딩 닫기
                        await appState.refreshMovies(); // 영화 리스트 새로고침
                        _showSuccess(context, 'TMDb API 초기화 완료!\n$count개의 영화가 저장되었습니다.');
                      } catch (e) {
                        Navigator.of(context).pop(); // 로딩 닫기
                        _showError(context, '오류: $e');
                      }
                    },
                    icon: const Icon(Icons.cloud_download),
                    label: const Text('TMDb API로 초기화'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // DB에서 영화 조회
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '3️⃣ DB에서 영화 조회',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      _showLoading(context, '영화 조회 중...');
                      try {
                        final movies = await MovieRepository.getAllMovies();
                        Navigator.of(context).pop(); // 로딩 닫기
                        _showMovieResults(
                          context,
                          'DB에서 조회한 영화',
                          movies,
                          '총 ${movies.length}개 영화',
                        );
                      } catch (e) {
                        Navigator.of(context).pop(); // 로기 닫기
                        _showError(context, '오류: $e');
                      }
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('전체 영화 조회'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      _showLoading(context, '최근 상영 영화 조회 중...');
                      try {
                        final movies = await MovieRepository.getRecentMovies();
                        Navigator.of(context).pop(); // 로딩 닫기
                        _showMovieResults(
                          context,
                          '최근 상영 중인 영화',
                          movies,
                          '총 ${movies.length}개 영화',
                        );
                      } catch (e) {
                        Navigator.of(context).pop(); // 로딩 닫기
                        _showError(context, '오류: $e');
                      }
                    },
                    icon: const Icon(Icons.movie),
                    label: const Text('최근 상영 영화 조회'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // DB 새로고침
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '4️⃣ 영화 리스트 새로고침',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('AppState의 영화 리스트를 DB에서 다시 로드합니다.'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      _showLoading(context, '새로고침 중...');
                      try {
                        await appState.refreshMovies();
                        Navigator.of(context).pop(); // 로딩 닫기
                        _showSuccess(context, '영화 리스트가 새로고침되었습니다.');
                      } catch (e) {
                        Navigator.of(context).pop(); // 로딩 닫기
                        _showError(context, '오류: $e');
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('새로고침'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 러닝타임 업데이트
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '5️⃣ 러닝타임 업데이트',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'DB에 저장된 영화 중 러닝타임이 0인 영화들의 상세 정보를 TMDb API에서 가져와서 업데이트합니다.\n'
                    '시간이 걸릴 수 있습니다.',
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      _showLoading(context, '러닝타임 업데이트 중...\n시간이 걸릴 수 있습니다.');
                      try {
                        final count = await MovieInitializationService.updateMovieRuntimes();
                        Navigator.of(context).pop(); // 로딩 닫기
                        await appState.refreshMovies(); // 영화 리스트 새로고침
                        _showSuccess(context, '러닝타임 업데이트 완료!\n$count개의 영화가 업데이트되었습니다.');
                      } catch (e) {
                        Navigator.of(context).pop(); // 로딩 닫기
                        _showError(context, '오류: $e');
                      }
                    },
                    icon: const Icon(Icons.update),
                    label: const Text('러닝타임 업데이트'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 영화 갱신 (현재 상영 중인 영화 업데이트)
          Card(
            color: Colors.purple.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '7️⃣ 현재 상영 영화 갱신',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  FutureBuilder<String>(
                    future: MovieUpdateService.getLastUpdateTimeFormatted(),
                    builder: (context, snapshot) {
                      final lastUpdate = snapshot.data ?? '로딩 중...';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('마지막 갱신: $lastUpdate'),
                          const SizedBox(height: 8),
                          FutureBuilder<bool>(
                            future: MovieUpdateService.shouldUpdate(),
                            builder: (context, snapshot) {
                              final shouldUpdate = snapshot.data ?? false;
                              return Text(
                                shouldUpdate
                                    ? '⚠️ 24시간 경과 - 갱신 필요'
                                    : '✅ 최근에 갱신됨',
                                style: TextStyle(
                                  color: shouldUpdate ? Colors.orange : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '현재 상영 중인 영화 정보를 TMDb API에서 가져와서 업데이트합니다.\n'
                    '스마트 업데이트: 새 영화만 추가하고, 더 이상 상영 중이 아닌 영화는 is_recent 플래그만 변경합니다.',
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      _showLoading(context, '영화 갱신 중...\n시간이 걸릴 수 있습니다.');
                      try {
                        final count = await MovieUpdateService.updateNowPlayingMovies();
                        Navigator.of(context).pop(); // 로딩 닫기
                        await appState.refreshMovies(); // 영화 리스트 새로고침
                        setState(() {}); // UI 새로고침 (마지막 갱신 시간 표시 업데이트)
                        _showSuccess(context, '영화 갱신 완료!\n$count개의 새 영화가 추가되었습니다.');
                      } catch (e) {
                        Navigator.of(context).pop(); // 로딩 닫기
                        _showError(context, '오류: $e');
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('영화 갱신 실행'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // DB 초기화 (모든 데이터 삭제)
          Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ DB 초기화 (위험)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    '모든 영화 데이터를 삭제합니다. 더미 데이터는 추가하지 않습니다.',
                    style: TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('정말 삭제하시겠습니까?'),
                          content: const Text('모든 영화 데이터가 삭제됩니다.\n더미 데이터는 추가되지 않습니다.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('취소'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('삭제', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        _showLoading(context, 'DB 초기화 중...');
                        try {
                          await MovieDbInitializer.clearDatabase();
                          await appState.refreshMovies();
                          Navigator.of(context).pop(); // 로딩 닫기
                          _showSuccess(context, '모든 영화 데이터가 삭제되었습니다.');
                        } catch (e) {
                          Navigator.of(context).pop(); // 로딩 닫기
                          _showError(context, '오류: $e');
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('DB 초기화 (삭제만)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ========== 헬퍼 메서드 ==========
  Widget _buildTestResultItem(String label, bool passed, String detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check : Icons.close,
            size: 20,
            color: passed ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(
            detail,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _getSortOptionName(RecordSortOption option) {
    switch (option) {
      case RecordSortOption.latest:
        return '최신순';
      case RecordSortOption.rating:
        return '별점순';
      case RecordSortOption.viewCount:
        return '많이 본 순';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showSortedWishlist(BuildContext context, String title, List<WishlistItem> sorted) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('정렬 결과: $title'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sorted.length > 10 ? 10 : sorted.length,
            itemBuilder: (context, index) {
              final item = sorted[index];
              return ListTile(
                title: Text(item.movie.title),
                subtitle: Text('${_formatDate(item.savedAt)} | 평점: ${item.movie.displayVoteAverage}점'),
                dense: true,
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

  // ========== 롯데시네마 테스트 탭 ==========
  Widget _buildLotteCinemaTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '롯데시네마 통합 테스트',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // CSV 파서 테스트
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '1. CSV 파서 테스트',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<LotteCinemaMovie>>(
                    future: CsvParser.getNowMovies(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      if (snapshot.hasError) {
                        return Text('오류: ${snapshot.error}');
                      }
                      final movies = snapshot.data ?? [];
                      return _buildTestResultItem(
                        '현재 상영 중인 영화 목록',
                        movies.isNotEmpty,
                        '${movies.length}개',
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<List<LotteCinemaTheater>>(
                    future: CsvParser.getTheaters(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      if (snapshot.hasError) {
                        return Text('오류: ${snapshot.error}');
                      }
                      final theaters = snapshot.data ?? [];
                      return _buildTestResultItem(
                        '영화관 목록',
                        theaters.isNotEmpty,
                        '${theaters.length}개',
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<LotteCinemaTheater?>(
                    future: CsvParser.findTheaterByName('대전센트럴'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      final theater = snapshot.data;
                      return _buildTestResultItem(
                        '영화관 검색 (대전센트럴)',
                        theater != null,
                        theater?.element ?? '없음',
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 영화 제목 매칭 테스트
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '2. 영화 제목 매칭 테스트',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<LotteCinemaMovie?>(
                    future: MovieTitleMatcher.findLotteCinemaMovie('만약에 우리'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      final movie = snapshot.data;
                      return _buildTestResultItem(
                        '정확한 매칭 (만약에 우리)',
                        movie != null,
                        movie?.movieName ?? '없음',
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<LotteCinemaMovie?>(
                    future: MovieTitleMatcher.findLotteCinemaMovie('아바타'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      final movie = snapshot.data;
                      return _buildTestResultItem(
                        '부분 매칭 (아바타)',
                        movie != null,
                        movie?.movieName ?? '없음',
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<bool>(
                    future: MovieTitleMatcher.isPlayingInLotteCinema('만약에 우리'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      final isPlaying = snapshot.data ?? false;
                      return _buildTestResultItem(
                        '상영 여부 확인',
                        true,
                        isPlaying ? '상영 중' : '상영 안 함',
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 상영 시간표 서비스 테스트
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '3. 상영 시간표 서비스 테스트',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<Map<String, dynamic>>(
                    future: () async {
                      // 오늘과 내일 날짜 준비
                      final today = DateTime.now();
                      final tomorrow = today.add(const Duration(days: 1));
                      
                      // 병렬로 두 날짜의 상영 시간표 가져오기 (캐싱 활용)
                      final results = await Future.wait([
                        TheaterScheduleService.getLotteCinemaSchedule(
                          theaterName: '롯데시네마 대전센트럴',
                          movieTitle: '만약에 우리',
                          date: today,
                        ),
                        TheaterScheduleService.getLotteCinemaSchedule(
                          theaterName: '롯데시네마 대전센트럴',
                          movieTitle: '만약에 우리',
                          date: tomorrow,
                        ),
                      ]);
                      
                      return {
                        'today': results[0],
                        'tomorrow': results[1],
                        'todayDate': today,
                        'tomorrowDate': tomorrow,
                      };
                    }(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      if (snapshot.hasError) {
                        return Text('오류: ${snapshot.error}');
                      }
                      
                      final data = snapshot.data ?? {};
                      final todayShowtimes = (data['today'] as List<Showtime>?) ?? [];
                      final tomorrowShowtimes = (data['tomorrow'] as List<Showtime>?) ?? [];
                      final totalCount = todayShowtimes.length + tomorrowShowtimes.length;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTestResultItem(
                            '롯데시네마 상영 시간표 가져오기',
                            true,
                            '총 ${totalCount}개 (오늘: ${todayShowtimes.length}개, 내일: ${tomorrowShowtimes.length}개)',
                          ),
                          if (todayShowtimes.isNotEmpty || tomorrowShowtimes.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                final todayDate = data['todayDate'] as DateTime? ?? DateTime.now();
                                final tomorrowDate = data['tomorrowDate'] as DateTime? ?? todayDate.add(const Duration(days: 1));
                                
                                String formatDate(DateTime d) {
                                  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                                }
                                
                                _showShowtimesDialog(
                                  context,
                                  todayShowtimes,
                                  tomorrowShowtimes,
                                  formatDate(todayDate),
                                  formatDate(tomorrowDate),
                                );
                              },
                              icon: const Icon(Icons.schedule, size: 18),
                              label: const Text('상영 시간표 상세 보기'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade50,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<List<Showtime>>(
                    future: TheaterScheduleService.getLotteCinemaSchedule(
                      theaterName: 'CGV 대전',
                      movieTitle: '만약에 우리',
                      date: DateTime.now(),
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      final showtimes = snapshot.data ?? [];
                      return _buildTestResultItem(
                        'CGV 영화관 (롯데시네마 아님)',
                        showtimes.isEmpty,
                        showtimes.isEmpty ? '빈 리스트 (정상)' : '${showtimes.length}개',
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // API 클라이언트 테스트
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '3. 롯데시네마 API 클라이언트 테스트',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      _showLoading(context, '상영 시간표 가져오는 중...');
                      try {
                        final client = LotteCinemaClient();
                        final today = DateTime.now();
                        final tomorrow = today.add(const Duration(days: 1));
                        
                        // 날짜 포맷팅 헬퍼 함수
                        String formatDate(DateTime date) {
                          return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                        }
                        
                        final todayDate = formatDate(today);
                        final tomorrowDate = formatDate(tomorrow);
                        
                        // 대전센트럴 영화관 찾기
                        final theater = await CsvParser.findTheaterByName('대전센트럴');
                        if (theater == null) {
                          Navigator.of(context).pop();
                          _showError(context, '대전센트럴 영화관을 찾을 수 없습니다.');
                          return;
                        }
                        
                        // 만약에 우리 영화 찾기
                        final movie = await MovieTitleMatcher.findLotteCinemaMovie('만약에 우리');
                        if (movie == null) {
                          Navigator.of(context).pop();
                          _showError(context, '만약에 우리 영화를 찾을 수 없습니다.');
                          return;
                        }
                        
                        // 오늘과 내일 상영 시간표 가져오기
                        final todaySchedules = await client.getMovieSchedule(
                          cinemaId: theater.cinemaIdString,
                          movieNo: movie.movieNo,
                          playDate: todayDate,
                        );
                        
                        final tomorrowSchedules = await client.getMovieSchedule(
                          cinemaId: theater.cinemaIdString,
                          movieNo: movie.movieNo,
                          playDate: tomorrowDate,
                        );
                        
                        Navigator.of(context).pop();
                        
                        final totalSchedules = todaySchedules.length + tomorrowSchedules.length;
                        
                        if (totalSchedules == 0) {
                          _showError(context, '상영 시간표가 없습니다.\n(네트워크 오류이거나 해당 날짜에 상영하지 않을 수 있습니다.)');
                        } else {
                          _showSuccess(context, '총 ${totalSchedules}개의 상영 시간표를 가져왔습니다!\n(오늘: ${todaySchedules.length}개, 내일: ${tomorrowSchedules.length}개)');
                          // 상세 정보 표시 (오늘과 내일 구분)
                          _showSchedules(context, todaySchedules, tomorrowSchedules, todayDate, tomorrowDate);
                        }
                      } catch (e) {
                        Navigator.of(context).pop();
                        _showError(context, '오류: $e');
                      }
                    },
                    icon: const Icon(Icons.schedule),
                    label: const Text('상영 시간표 가져오기 (대전센트럴, 만약에 우리)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade100,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 롯데시네마 상영 여부 확인 테스트 (4단계)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '4. 롯데시네마 상영 여부 확인 테스트 (TMDb 초기화)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<bool>(
                    future: LotteCinemaMovieChecker.isPlayingInLotteCinema('만약에 우리'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      final isPlaying = snapshot.data ?? false;
                      return _buildTestResultItem(
                        '롯데시네마 상영 여부 확인 (만약에 우리)',
                        true,
                        isPlaying ? '상영 중' : '상영 안 함',
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<bool>(
                    future: LotteCinemaMovieChecker.isPlayingInLotteCinema('존재하지 않는 영화'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      final isPlaying = snapshot.data ?? false;
                      return _buildTestResultItem(
                        '존재하지 않는 영화',
                        !isPlaying,
                        isPlaying ? '상영 중' : '상영 안 함 (정상)',
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '💡 TMDb 초기화 시 롯데시네마 상영 여부를 확인하여\n   isRecent 플래그를 보완합니다.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 5단계: UI 통합 및 최적화 테스트
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '5. UI 통합 및 최적화 테스트',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  // TheaterCard 위젯 테스트
                  const Text(
                    '5.1 TheaterCard 위젯 테스트',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  
                  // 롯데시네마 영화관 카드 (상영 시간표 있음)
                  FutureBuilder<List<Showtime>>(
                    future: TheaterScheduleService.getLotteCinemaSchedule(
                      theaterName: '롯데시네마 대전센트럴',
                      movieTitle: '만약에 우리',
                      date: DateTime.now(),
                    ),
                    builder: (context, snapshot) {
                      final showtimes = snapshot.data ?? [];
                      final lotteTheater = Theater(
                        id: 'test_lotte',
                        name: '롯데시네마 대전센트럴',
                        address: '대전광역시 중구 중앙로 101',
                        lat: 36.3281,
                        lng: 127.4225,
                        distanceKm: 1.2,
                        showtimes: showtimes,
                        bookingUrl: 'https://search.naver.com/search.naver?query=롯데시네마+대전센트럴',
                      );
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '롯데시네마 영화관 (상영 시간표 있음):',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          TheaterCard(t: lotteTheater),
                          const SizedBox(height: 8),
                          _buildTestResultItem(
                            '롯데시네마 라벨 표시',
                            lotteTheater.name.contains('롯데'),
                            lotteTheater.showtimes.isNotEmpty ? '실시간 상영 시간표 표시됨' : '상영 시간표 없음',
                          ),
                        ],
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // CGV 영화관 카드 (상영 시간표 없음)
                  const Text(
                    'CGV 영화관 (상영 시간표 없음):',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TheaterCard(
                    t: Theater(
                      id: 'test_cgv',
                      name: 'CGV 대전',
                      address: '대전광역시 중구 중앙로 102',
                      lat: 36.3282,
                      lng: 127.4226,
                      distanceKm: 1.5,
                      showtimes: const [],
                      bookingUrl: 'https://search.naver.com/search.naver?query=CGV+대전',
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 캐시 관리 테스트
                  const Text(
                    '5.2 캐시 관리 테스트',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  
                  StatefulBuilder(
                    builder: (context, setState) {
                      final cacheStats = TheaterScheduleService.getCacheStats();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTestResultItem(
                            '캐시 통계',
                            true,
                            '전체: ${cacheStats['total']}개, 유효: ${cacheStats['valid']}개, 만료: ${cacheStats['expired']}개',
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  TheaterScheduleService.cleanExpiredCache();
                                  final newStats = TheaterScheduleService.getCacheStats();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('만료된 캐시 정리 완료! (유효: ${newStats['valid']}개)'),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                  setState(() {}); // 화면 새로고침
                                },
                                icon: const Icon(Icons.cleaning_services, size: 18),
                                label: const Text('만료된 캐시 정리'),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  TheaterScheduleService.clearCache();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('캐시 전체 초기화 완료!'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  setState(() {}); // 화면 새로고침
                                },
                                icon: const Icon(Icons.delete_outline, size: 18),
                                label: const Text('캐시 전체 초기화'),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 에러 처리 테스트
                  const Text(
                    '5.3 에러 처리 테스트',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  
                  FutureBuilder<List<Showtime>>(
                    future: TheaterScheduleService.getLotteCinemaSchedule(
                      theaterName: '존재하지 않는 영화관',
                      movieTitle: '존재하지 않는 영화',
                      date: DateTime.now(),
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      final showtimes = snapshot.data ?? [];
                      return _buildTestResultItem(
                        '에러 발생 시 빈 리스트 반환',
                        showtimes.isEmpty,
                        showtimes.isEmpty ? '정상 (빈 리스트)' : '오류 (${showtimes.length}개)',
                      );
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  FutureBuilder<List<Showtime>>(
                    future: TheaterScheduleService.getLotteCinemaSchedule(
                      theaterName: 'CGV 대전',
                      movieTitle: '만약에 우리',
                      date: DateTime.now(),
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      final showtimes = snapshot.data ?? [];
                      return _buildTestResultItem(
                        '롯데시네마가 아닌 영화관 처리',
                        showtimes.isEmpty,
                        showtimes.isEmpty ? '정상 (빈 리스트)' : '오류 (${showtimes.length}개)',
                      );
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  const Text(
                    '💡 에러 발생 시 앱이 멈추지 않고 조용히 처리됩니다.\n   네트워크 오류나 API 오류 시에도 빈 리스트를 반환합니다.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== 메가박스 테스트 탭 ==========
  Widget _buildMegaboxTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '메가박스 통합 테스트',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // CSV 파서 테스트
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '1. CSV 파서 테스트',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<MegaboxMovie>>(
                    future: CsvParser.getMegaboxMovies(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      if (snapshot.hasError) {
                        return Text('오류: ${snapshot.error}');
                      }
                      final movies = snapshot.data ?? [];
                      return _buildTestResultItem(
                        '메가박스 영화 목록',
                        movies.isNotEmpty,
                        '${movies.length}개',
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<List<MegaboxTheater>>(
                    future: CsvParser.getMegaboxTheaters(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      if (snapshot.hasError) {
                        return Text('오류: ${snapshot.error}');
                      }
                      final theaters = snapshot.data ?? [];
                      return _buildTestResultItem(
                        '메가박스 영화관 목록',
                        theaters.isNotEmpty,
                        '${theaters.length}개',
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<MegaboxTheater?>(
                    future: CsvParser.findMegaboxTheaterByName('대전중앙로'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      final theater = snapshot.data;
                      return _buildTestResultItem(
                        '영화관 검색 (대전중앙로)',
                        theater != null,
                        theater?.brchNm ?? '없음',
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 영화 제목 매칭 테스트
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '2. 영화 제목 매칭 테스트',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<MegaboxMovie?>(
                    future: MovieTitleMatcher.findMegaboxMovie('만약에 우리'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      final movie = snapshot.data;
                      return _buildTestResultItem(
                        '정확한 매칭 (만약에 우리)',
                        movie != null,
                        movie?.movieNm ?? '없음',
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<MegaboxMovie?>(
                    future: MovieTitleMatcher.findMegaboxMovie('아바타'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      final movie = snapshot.data;
                      return _buildTestResultItem(
                        '부분 매칭 (아바타)',
                        movie != null,
                        movie?.movieNm ?? '없음',
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<bool>(
                    future: MovieTitleMatcher.isPlayingInMegabox('만약에 우리'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      final isPlaying = snapshot.data ?? false;
                      return _buildTestResultItem(
                        '상영 여부 확인',
                        true,
                        isPlaying ? '상영 중' : '상영 안 함',
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 메가박스 API 클라이언트 테스트
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '3. 메가박스 API 클라이언트 테스트',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      _showLoading(context, '상영 시간표 가져오는 중...');
                      try {
                        final client = MegaboxClient();
                        final today = DateTime.now();
                        final tomorrow = today.add(const Duration(days: 1));
                        
                        // 날짜 포맷팅 헬퍼 함수 (YYYYMMDD 형식)
                        String formatDate(DateTime date) {
                          return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
                        }
                        
                        final todayDate = formatDate(today);
                        final tomorrowDate = formatDate(tomorrow);
                        
                        // 대전중앙로 영화관 찾기
                        final theater = await CsvParser.findMegaboxTheaterByName('대전중앙로');
                        if (theater == null) {
                          Navigator.of(context).pop();
                          _showError(context, '대전중앙로 영화관을 찾을 수 없습니다.');
                          return;
                        }
                        
                        // 만약에 우리 영화 찾기
                        final movie = await MovieTitleMatcher.findMegaboxMovie('만약에 우리');
                        if (movie == null) {
                          Navigator.of(context).pop();
                          _showError(context, '만약에 우리 영화를 찾을 수 없습니다.');
                          return;
                        }
                        
                        // 오늘과 내일 상영 시간표 가져오기
                        final todaySchedules = await client.getMovieSchedule(
                          brchNo: theater.brchNo,
                          movieNo: movie.movieNo,
                          playDe: todayDate,
                        );
                        
                        final tomorrowSchedules = await client.getMovieSchedule(
                          brchNo: theater.brchNo,
                          movieNo: movie.movieNo,
                          playDe: tomorrowDate,
                        );
                        
                        Navigator.of(context).pop();
                        
                        final totalSchedules = todaySchedules.length + tomorrowSchedules.length;
                        
                        if (totalSchedules == 0) {
                          _showError(context, '상영 시간표가 없습니다.\n(네트워크 오류이거나 해당 날짜에 상영하지 않을 수 있습니다.)');
                        } else {
                          _showSuccess(context, '총 ${totalSchedules}개의 상영 시간표를 가져왔습니다!\n(오늘: ${todaySchedules.length}개, 내일: ${tomorrowSchedules.length}개)');
                          // 상세 정보 표시 (오늘과 내일 구분)
                          _showMegaboxSchedules(context, todaySchedules, tomorrowSchedules, todayDate, tomorrowDate);
                        }
                      } catch (e) {
                        Navigator.of(context).pop();
                        _showError(context, '오류: $e');
                      }
                    },
                    icon: const Icon(Icons.schedule),
                    label: const Text('상영 시간표 가져오기 (대전중앙로, 만약에 우리)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade100,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 상영 시간표 서비스 테스트 (3단계)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '4. 상영 시간표 서비스 테스트 (3단계)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<Map<String, dynamic>>(
                    future: () async {
                      // 오늘과 내일 날짜 준비
                      final today = DateTime.now();
                      final tomorrow = today.add(const Duration(days: 1));
                      
                      // 병렬로 두 날짜의 상영 시간표 가져오기 (캐싱 활용)
                      final results = await Future.wait([
                        TheaterScheduleService.getMegaboxSchedule(
                          theaterName: '메가박스 대전중앙로',
                          movieTitle: '만약에 우리',
                          date: today,
                        ),
                        TheaterScheduleService.getMegaboxSchedule(
                          theaterName: '메가박스 대전중앙로',
                          movieTitle: '만약에 우리',
                          date: tomorrow,
                        ),
                      ]);
                      
                      return {
                        'today': results[0],
                        'tomorrow': results[1],
                        'todayDate': today,
                        'tomorrowDate': tomorrow,
                      };
                    }(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      if (snapshot.hasError) {
                        return Text('오류: ${snapshot.error}');
                      }
                      
                      final data = snapshot.data ?? {};
                      final todayShowtimes = (data['today'] as List<Showtime>?) ?? [];
                      final tomorrowShowtimes = (data['tomorrow'] as List<Showtime>?) ?? [];
                      final totalCount = todayShowtimes.length + tomorrowShowtimes.length;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTestResultItem(
                            '메가박스 상영 시간표 가져오기',
                            true,
                            '총 ${totalCount}개 (오늘: ${todayShowtimes.length}개, 내일: ${tomorrowShowtimes.length}개)',
                          ),
                          if (todayShowtimes.isNotEmpty || tomorrowShowtimes.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                final todayDate = data['todayDate'] as DateTime? ?? DateTime.now();
                                final tomorrowDate = data['tomorrowDate'] as DateTime? ?? todayDate.add(const Duration(days: 1));
                                
                                String formatDate(DateTime d) {
                                  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                                }
                                
                                _showShowtimesDialog(
                                  context,
                                  todayShowtimes,
                                  tomorrowShowtimes,
                                  formatDate(todayDate),
                                  formatDate(tomorrowDate),
                                );
                              },
                              icon: const Icon(Icons.schedule, size: 18),
                              label: const Text('상영 시간표 상세 보기'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade50,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<List<Showtime>>(
                    future: TheaterScheduleService.getSchedule(
                      theaterName: '메가박스 대전중앙로',
                      movieTitle: '만약에 우리',
                      date: DateTime.now(),
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      final showtimes = snapshot.data ?? [];
                      return _buildTestResultItem(
                        '통합 메서드 (getSchedule)',
                        true,
                        '${showtimes.length}개',
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<List<Showtime>>(
                    future: TheaterScheduleService.getSchedule(
                      theaterName: 'CGV 대전',
                      movieTitle: '만약에 우리',
                      date: DateTime.now(),
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      final showtimes = snapshot.data ?? [];
                      return _buildTestResultItem(
                        'CGV 영화관 (메가박스 아님)',
                        showtimes.isEmpty,
                        showtimes.isEmpty ? '빈 리스트 (정상)' : '${showtimes.length}개',
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<List<Showtime>>(
                    future: TheaterScheduleService.getSchedule(
                      theaterName: '롯데시네마 대전센트럴',
                      movieTitle: '만약에 우리',
                      date: DateTime.now(),
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      final showtimes = snapshot.data ?? [];
                      return _buildTestResultItem(
                        '롯데시네마 영화관 (통합 메서드)',
                        true,
                        '${showtimes.length}개',
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 메가박스 영화 확인 서비스 테스트 (4단계)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '5. 메가박스 영화 확인 서비스 테스트 (4단계)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<bool>(
                    future: MegaboxMovieChecker.isPlayingInMegabox('만약에 우리'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      final isPlaying = snapshot.data ?? false;
                      return _buildTestResultItem(
                        '메가박스 상영 여부 확인 (만약에 우리)',
                        isPlaying,
                        isPlaying ? '상영 중' : '상영 안 함',
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<bool>(
                    future: MegaboxMovieChecker.isPlayingInMegabox('프로젝트 Y'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      final isPlaying = snapshot.data ?? false;
                      return _buildTestResultItem(
                        '메가박스 상영 여부 확인 (프로젝트 Y)',
                        isPlaying,
                        isPlaying ? '상영 중' : '상영 안 함',
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<bool>(
                    future: MegaboxMovieChecker.isPlayingInMegabox('존재하지 않는 영화 12345'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      final isPlaying = snapshot.data ?? false;
                      return _buildTestResultItem(
                        '메가박스 상영 여부 확인 (존재하지 않는 영화)',
                        !isPlaying,
                        !isPlaying ? '정상 (상영 안 함)' : '오류 (상영 중으로 표시됨)',
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '롯데시네마 + 메가박스 통합 확인',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<Map<String, bool>>(
                    future: () async {
                      final isLotte = await LotteCinemaMovieChecker.isPlayingInLotteCinema('만약에 우리');
                      final isMegabox = await MegaboxMovieChecker.isPlayingInMegabox('만약에 우리');
                      return {
                        'lotte': isLotte,
                        'megabox': isMegabox,
                      };
                    }(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      final data = snapshot.data ?? {};
                      final isLotte = data['lotte'] ?? false;
                      final isMegabox = data['megabox'] ?? false;
                      final isPlaying = isLotte || isMegabox;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTestResultItem(
                            '롯데시네마 상영 여부',
                            true,
                            isLotte ? '상영 중' : '상영 안 함',
                          ),
                          const SizedBox(height: 8),
                          _buildTestResultItem(
                            '메가박스 상영 여부',
                            true,
                            isMegabox ? '상영 중' : '상영 안 함',
                          ),
                          const SizedBox(height: 8),
                          _buildTestResultItem(
                            '통합 확인 (둘 중 하나라도 상영 중)',
                            isPlaying,
                            isPlaying ? '상영 중 (isRecent = true)' : '상영 안 함 (isRecent = false)',
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 추가 테스트: 다양한 케이스
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '6. 추가 테스트 케이스',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  // 다양한 영화 제목 매칭 테스트
                  const Text(
                    '4.1 다양한 영화 제목 매칭',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  
                  FutureBuilder<MegaboxMovie?>(
                    future: MovieTitleMatcher.findMegaboxMovie('프로젝트 Y'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      final movie = snapshot.data;
                      return _buildTestResultItem(
                        '다른 영화 매칭 (프로젝트 Y)',
                        movie != null,
                        movie?.movieNm ?? '없음',
                      );
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  FutureBuilder<MegaboxMovie?>(
                    future: MovieTitleMatcher.findMegaboxMovie('존재하지 않는 영화 12345'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      final movie = snapshot.data;
                      return _buildTestResultItem(
                        '존재하지 않는 영화',
                        movie == null,
                        movie == null ? '정상 (없음)' : '오류 (${movie.movieNm})',
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 다양한 영화관 검색 테스트
                  const Text(
                    '4.2 다양한 영화관 검색',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  
                  FutureBuilder<MegaboxTheater?>(
                    future: CsvParser.findMegaboxTheaterByName('강남'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      final theater = snapshot.data;
                      return _buildTestResultItem(
                        '영화관 검색 (강남)',
                        theater != null,
                        theater?.brchNm ?? '없음',
                      );
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  FutureBuilder<MegaboxTheater?>(
                    future: CsvParser.findMegaboxTheaterByName('메가박스 대전'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      final theater = snapshot.data;
                      return _buildTestResultItem(
                        '영화관 검색 (메가박스 대전)',
                        theater != null,
                        theater?.brchNm ?? '없음',
                      );
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  FutureBuilder<MegaboxTheater?>(
                    future: CsvParser.findMegaboxTheaterByName('존재하지 않는 영화관'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      final theater = snapshot.data;
                      return _buildTestResultItem(
                        '존재하지 않는 영화관',
                        theater == null,
                        theater == null ? '정상 (없음)' : '오류 (${theater.brchNm})',
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 에러 처리 테스트
                  const Text(
                    '4.3 에러 처리 테스트',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  
                  ElevatedButton.icon(
                    onPressed: () async {
                      _showLoading(context, '에러 처리 테스트 중...');
                      try {
                        final client = MegaboxClient();
                        // 존재하지 않는 영화관과 영화로 테스트
                        final schedules = await client.getMovieSchedule(
                          brchNo: '9999', // 존재하지 않는 영화관
                          movieNo: '99999999', // 존재하지 않는 영화
                          playDe: '20260114',
                        );
                        Navigator.of(context).pop();
                        _showSuccess(context, '에러 처리 정상: 빈 리스트 반환 (${schedules.length}개)');
                      } catch (e) {
                        Navigator.of(context).pop();
                        _showError(context, '에러 처리 실패: $e');
                      }
                    },
                    icon: const Icon(Icons.error_outline, size: 18),
                    label: const Text('에러 처리 테스트 (존재하지 않는 데이터)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade100,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  const Text(
                    '💡 에러 발생 시 앱이 멈추지 않고 조용히 처리됩니다.\n   빈 리스트를 반환하여 앱이 정상적으로 동작합니다.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMegaboxSchedules(
    BuildContext context,
    List<MegaboxSchedule> todaySchedules,
    List<MegaboxSchedule> tomorrowSchedules,
    String todayDate,
    String tomorrowDate,
  ) {
    // 날짜 포맷팅 (YYYYMMDD -> YYYY-MM-DD)
    String formatDate(String dateStr) {
      if (dateStr.length == 8) {
        return '${dateStr.substring(0, 4)}-${dateStr.substring(4, 6)}-${dateStr.substring(6, 8)}';
      }
      return dateStr;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('상영 시간표'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              // 오늘 상영 시간표
              if (todaySchedules.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 8),
                  child: Text(
                    '📅 ${formatDate(todayDate)} (오늘)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                ...todaySchedules.map((schedule) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text('${schedule.playStartTime} ~ ${schedule.playEndTime}'),
                        subtitle: Text(
                            '${schedule.theabExpoNm} | 잔여: ${schedule.restSeatCnt}/${schedule.totSeatCnt}석'),
                      ),
                    )),
                const SizedBox(height: 16),
              ],
              
              // 내일 상영 시간표
              if (tomorrowSchedules.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 8),
                  child: Text(
                    '📅 ${formatDate(tomorrowDate)} (내일)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                ...tomorrowSchedules.map((schedule) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text('${schedule.playStartTime} ~ ${schedule.playEndTime}'),
                        subtitle: Text(
                            '${schedule.theabExpoNm} | 잔여: ${schedule.restSeatCnt}/${schedule.totSeatCnt}석'),
                      ),
                    )),
              ],
              
              if (todaySchedules.isEmpty && tomorrowSchedules.isEmpty)
                const Text('상영 시간표가 없습니다.'),
            ],
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

  void _showSchedules(
    BuildContext context,
    List<LotteCinemaSchedule> todaySchedules,
    List<LotteCinemaSchedule> tomorrowSchedules,
    String todayDate,
    String tomorrowDate,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('상영 시간표'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              // 오늘 상영 시간표
              if (todaySchedules.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 8),
                  child: Text(
                    '📅 $todayDate (오늘)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                ...todaySchedules.map((schedule) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text('${schedule.startTime} ~ ${schedule.endTime}'),
                        subtitle: Text(
                            '${schedule.screenNameKR} | 잔여: ${schedule.availableSeatCount}/${schedule.totalSeatCount}석'),
                      ),
                    )),
                const SizedBox(height: 16),
              ],
              
              // 내일 상영 시간표
              if (tomorrowSchedules.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 8),
                  child: Text(
                    '📅 $tomorrowDate (내일)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                ...tomorrowSchedules.map((schedule) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text('${schedule.startTime} ~ ${schedule.endTime}'),
                        subtitle: Text(
                            '${schedule.screenNameKR} | 잔여: ${schedule.availableSeatCount}/${schedule.totalSeatCount}석'),
                      ),
                    )),
              ],
              
              // 둘 다 비어있는 경우
              if (todaySchedules.isEmpty && tomorrowSchedules.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    '상영 시간표가 없습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
            ],
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

  void _showShowtimesDialog(
    BuildContext context,
    List<Showtime> todayShowtimes,
    List<Showtime> tomorrowShowtimes,
    String todayDate,
    String tomorrowDate,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('상영 시간표 (TheaterScheduleService)'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              // 오늘 상영 시간표
              if (todayShowtimes.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 8),
                  child: Text(
                    '📅 $todayDate (오늘)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                ...todayShowtimes.map((showtime) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text('${showtime.start} ~ ${showtime.end}'),
                        subtitle: Text('${showtime.screen}'),
                      ),
                    )),
                const SizedBox(height: 16),
              ],
              
              // 내일 상영 시간표
              if (tomorrowShowtimes.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 8),
                  child: Text(
                    '📅 $tomorrowDate (내일)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                ...tomorrowShowtimes.map((showtime) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text('${showtime.start} ~ ${showtime.end}'),
                        subtitle: Text('${showtime.screen}'),
                      ),
                    )),
              ],
              
              // 둘 다 비어있는 경우
              if (todayShowtimes.isEmpty && tomorrowShowtimes.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    '상영 시간표가 없습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
            ],
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
}
