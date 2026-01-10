import 'package:flutter_test/flutter_test.dart';
import 'package:movie_diary_app/data/dummy_movies.dart';
import 'package:movie_diary_app/models/movie.dart';

void main() {
  group('DummyMovies 테스트', () {
    test('더미 영화 데이터가 올바르게 로드되는지 확인', () {
      // When: 더미 영화 목록 가져오기
      final movies = DummyMovies.getMovies();

      // Then: 7개의 영화가 있어야 함 (더미데이터 예시.txt 기준)
      expect(movies.length, 7);
    });

    test('각 영화의 필수 필드가 모두 채워져 있는지 확인', () {
      // When: 더미 영화 목록 가져오기
      final movies = DummyMovies.getMovies();

      // Then: 모든 영화의 필수 필드 확인
      for (final movie in movies) {
        expect(movie.id.isNotEmpty, true, reason: '${movie.title}의 id가 비어있음');
        expect(movie.title.isNotEmpty, true, reason: '${movie.title}의 title이 비어있음');
        expect(movie.posterUrl.isNotEmpty, true, reason: '${movie.title}의 posterUrl이 비어있음');
        expect(movie.genres.isNotEmpty, true, reason: '${movie.title}의 genres가 비어있음');
        expect(movie.runtime, greaterThan(0), reason: '${movie.title}의 runtime이 0보다 커야 함');
        expect(movie.voteAverage, greaterThanOrEqualTo(0), reason: '${movie.title}의 voteAverage가 0 이상이어야 함');
      }
    });

    test('더미데이터에 포함된 특정 영화가 있는지 확인', () {
      // Given: 더미데이터 예시.txt에 있는 영화들
      final expectedTitles = [
        "기생충",
        "어쩔수가없다",
        "아바타: 불과 재",
        "극장판 귀멸의 칼날: 무한성편",
        "탑건: 매버릭",
        "미키 17",
        "광해, 왕이 된 남자",
      ];

      // When: 더미 영화 목록 가져오기
      final movies = DummyMovies.getMovies();
      final actualTitles = movies.map((m) => m.title).toList();

      // Then: 예상된 모든 영화가 포함되어 있어야 함
      for (final expectedTitle in expectedTitles) {
        expect(actualTitles.contains(expectedTitle), true, 
            reason: '$expectedTitle가 더미데이터에 없음');
      }
    });

    test('모든 영화의 ID가 고유한지 확인', () {
      // When: 더미 영화 목록 가져오기
      final movies = DummyMovies.getMovies();
      final ids = movies.map((m) => m.id).toList();

      // Then: 모든 ID가 고유해야 함 (Set으로 변환하면 중복이 제거됨)
      expect(ids.toSet().length, ids.length, 
          reason: '중복된 영화 ID가 있습니다');
    });
  });
}
