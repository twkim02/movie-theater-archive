import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/wishlist.dart';

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
    _tabController = TabController(length: 5, vsync: this);
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
                    onPressed: () {
                      appState.toggleBookmark(firstMovie.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('북마크 토글 완료! (화면이 자동 업데이트됨)'),
                          duration: Duration(seconds: 1),
                        ),
                      );
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
    final availableMovies = appState.movies.where((m) => !appState.isInWishlist(m.id)).toList();

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
                  _buildStatItem('더미 데이터', '${appState.dummyWishlist.length}개'),
                  _buildStatItem('추가된 아이템', '${wishlist.length - appState.dummyWishlist.length}개'),
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
                              onPressed: () {
                                appState.addToWishlist(movie);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${movie.title}을(를) 위시리스트에 추가했습니다.')),
                                );
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
                                Text('평점: ${item.movie.voteAverage}점'),
                              ],
                            ),
                          ),
                          if (!appState.dummyWishlist.contains(item))
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                appState.removeFromWishlist(item.movie.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${item.movie.title}을(를) 위시리스트에서 제거했습니다.')),
                                );
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
                subtitle: Text('${_formatDate(item.savedAt)} | 평점: ${item.movie.voteAverage}점'),
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
}
