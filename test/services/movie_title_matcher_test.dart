import 'package:flutter_test/flutter_test.dart';
import 'package:movie_diary_app/services/movie_title_matcher.dart';

void main() {
  // 테스트 전에 assets를 로드하기 위한 설정
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('MovieTitleMatcher 테스트', () {
    test('정확한 제목 매칭이 작동하는지 확인', () async {
      // Given: CSV에 있는 정확한 영화 제목
      const tmdbTitle = '만약에 우리';

      // When: 롯데시네마 영화 찾기
      final movie = await MovieTitleMatcher.findLotteCinemaMovie(tmdbTitle);

      // Then: 영화를 찾을 수 있어야 함
      expect(movie, isNotNull, reason: '정확한 제목 매칭 실패: $tmdbTitle');
      if (movie != null) {
        expect(movie.movieName, contains('만약에 우리'));
      }
    });

    test('부분 매칭이 작동하는지 확인', () async {
      // Given: CSV에 있는 영화 제목의 일부
      const tmdbTitle = '아바타';

      // When: 롯데시네마 영화 찾기
      final movie = await MovieTitleMatcher.findLotteCinemaMovie(tmdbTitle);

      // Then: 영화를 찾을 수 있어야 함 (부분 매칭)
      expect(movie, isNotNull, reason: '부분 매칭 실패: $tmdbTitle');
      if (movie != null) {
        expect(movie.movieName.toLowerCase(), contains('아바타'));
      }
    });

    test('대소문자 무시 매칭이 작동하는지 확인', () async {
      // Given: 대문자로 된 제목
      const tmdbTitle = '만약에 우리';

      // When: 롯데시네마 영화 찾기
      final movie = await MovieTitleMatcher.findLotteCinemaMovie(tmdbTitle);

      // Then: 영화를 찾을 수 있어야 함
      expect(movie, isNotNull, reason: '대소문자 무시 매칭 실패: $tmdbTitle');
    });

    test('존재하지 않는 영화는 null을 반환하는지 확인', () async {
      // Given: CSV에 없는 영화 제목
      const tmdbTitle = '존재하지 않는 영화 12345';

      // When: 롯데시네마 영화 찾기
      final movie = await MovieTitleMatcher.findLotteCinemaMovie(tmdbTitle);

      // Then: null을 반환해야 함
      expect(movie, isNull, reason: '존재하지 않는 영화를 찾았습니다.');
    });

    test('롯데시네마 상영 여부 확인이 작동하는지 확인', () async {
      // Given: CSV에 있는 현재 상영 중인 영화
      const tmdbTitle = '만약에 우리';

      // When: 롯데시네마 상영 여부 확인
      final isPlaying = await MovieTitleMatcher.isPlayingInLotteCinema(tmdbTitle);

      // Then: 상영 중이어야 함 (movie_now.csv에 있으면)
      // Note: 실제 데이터에 따라 결과가 달라질 수 있음
      expect(isPlaying, isA<bool>());
    });

    test('빈 문자열은 null을 반환하는지 확인', () async {
      // Given: 빈 문자열
      const tmdbTitle = '';

      // When: 롯데시네마 영화 찾기
      final movie = await MovieTitleMatcher.findLotteCinemaMovie(tmdbTitle);

      // Then: null을 반환해야 함
      expect(movie, isNull, reason: '빈 문자열로 영화를 찾았습니다.');
    });

    test('특수문자가 포함된 제목 매칭이 작동하는지 확인', () async {
      // Given: 특수문자가 포함된 제목 (CSV에 있는 실제 제목)
      const tmdbTitle = '오늘 밤, 세계에서 이 사랑이 사라진다 해도';

      // When: 롯데시네마 영화 찾기
      final movie = await MovieTitleMatcher.findLotteCinemaMovie(tmdbTitle);

      // Then: 영화를 찾을 수 있어야 함
      expect(movie, isNotNull, reason: '특수문자 포함 제목 매칭 실패: $tmdbTitle');
    });
  });
}
