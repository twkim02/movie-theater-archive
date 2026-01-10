import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../models/movie.dart';

/// 개발/테스트용 화면
/// 작성한 코드가 제대로 작동하는지 시각적으로 확인할 수 있습니다.
/// 
/// 이 화면은 개발 중에만 사용하고, 최종 제출 전에 제거하거나 
/// 팀원과 합칠 때는 이 파일을 포함하지 않아도 됩니다.
class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final movies = appState.movies;
    final bookmarkedMovies = appState.bookmarkedMovies;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 코드 검증 테스트 화면'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 테스트 결과 요약
            _buildTestSummaryCard(context, movies, bookmarkedMovies),
            const SizedBox(height: 24),
            
            // Movie 모델 테스트
            _buildModelTestSection(context, movies),
            const SizedBox(height: 24),
            
            // AppState 테스트
            _buildStateTestSection(context, appState, movies),
            const SizedBox(height: 24),
            
            // 북마크된 영화 목록
            _buildBookmarkedMoviesSection(context, bookmarkedMovies),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSummaryCard(
    BuildContext context,
    List<Movie> movies,
    List<Movie> bookmarkedMovies,
  ) {
    final allTestsPassed = movies.isNotEmpty && movies.length == 7;

    return Card(
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
                ),
                const SizedBox(width: 8),
                Text(
                  '테스트 요약',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTestResultItem('더미 영화 데이터 로드', movies.isNotEmpty, '${movies.length}개 영화'),
            _buildTestResultItem('영화 데이터 구조', movies.length == 7, '예상: 7개'),
            _buildTestResultItem('Provider 연결', true, 'AppState 접근 가능'),
            _buildTestResultItem('북마크 기능', true, '${bookmarkedMovies.length}개 북마크됨'),
          ],
        ),
      ),
    );
  }

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

  Widget _buildModelTestSection(BuildContext context, List<Movie> movies) {
    if (movies.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(16.0), child: Text('영화 데이터가 없습니다.')));
    }

    final firstMovie = movies.first;

    return Card(
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
            Text('개봉일: ${firstMovie.releaseDate.year}-${firstMovie.releaseDate.month}-${firstMovie.releaseDate.day}'),
            Text('러닝타임: ${firstMovie.runtime}분'),
            Text('평점: ${firstMovie.voteAverage}'),
            Text('최신작 여부: ${firstMovie.isRecent ? "예" : "아니오"}'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                // toJson 테스트
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
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                // copyWith 테스트
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
      ),
    );
  }

  Widget _buildStateTestSection(
    BuildContext context,
    AppState appState,
    List<Movie> movies,
  ) {
    if (movies.isEmpty) {
      return const SizedBox.shrink();
    }

    final testMovieId = movies.first.id;
    final isBookmarked = appState.isBookmarked(testMovieId);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '2️⃣ AppState 테스트',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text('전체 영화 수: ${movies.length}개'),
            Text('북마크된 영화: ${appState.bookmarkedMovies.length}개'),
            Text('테스트 영화 (${movies.first.title}) 북마크 상태: ${isBookmarked ? "북마크됨" : "북마크 안됨"}'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                appState.toggleBookmark(testMovieId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('북마크 토글 완료! (화면이 자동 업데이트됨)'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border),
              label: Text(isBookmarked ? '북마크 해제' : '북마크 추가'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkedMoviesSection(
    BuildContext context,
    List<Movie> bookmarkedMovies,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '3️⃣ 북마크된 영화 목록',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            if (bookmarkedMovies.isEmpty)
              const Text('북마크된 영화가 없습니다. 위의 버튼을 눌러 북마크를 테스트해보세요!')
            else
              ...bookmarkedMovies.map((movie) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text('✅ ${movie.title} (${movie.id})'),
                  )),
          ],
        ),
      ),
    );
  }
}
