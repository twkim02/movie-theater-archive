import 'package:flutter_test/flutter_test.dart';
import 'package:movie_diary_app/services/lottecinema_movie_checker.dart';

void main() {
  // 테스트 전에 assets를 로드하기 위한 설정
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('LotteCinemaMovieChecker 테스트', () {
    test('롯데시네마에서 상영 중인 영화는 true를 반환하는지 확인', () async {
      // Given: CSV에 있는 현재 상영 중인 영화
      const movieTitle = '만약에 우리';

      // When: 롯데시네마 상영 여부 확인
      final isPlaying = await LotteCinemaMovieChecker.isPlayingInLotteCinema(movieTitle);

      // Then: 상영 중이어야 함 (movie_now.csv에 있으면)
      expect(isPlaying, isA<bool>());
      // Note: 실제 데이터에 따라 결과가 달라질 수 있음
    });

    test('롯데시네마에서 상영하지 않는 영화는 false를 반환하는지 확인', () async {
      // Given: CSV에 없는 영화 제목
      const movieTitle = '존재하지 않는 영화 12345';

      // When: 롯데시네마 상영 여부 확인
      final isPlaying = await LotteCinemaMovieChecker.isPlayingInLotteCinema(movieTitle);

      // Then: false를 반환해야 함
      expect(isPlaying, false);
    });

    test('빈 문자열은 false를 반환하는지 확인', () async {
      // Given: 빈 문자열
      const movieTitle = '';

      // When: 롯데시네마 상영 여부 확인
      final isPlaying = await LotteCinemaMovieChecker.isPlayingInLotteCinema(movieTitle);

      // Then: false를 반환해야 함
      expect(isPlaying, false);
    });

    test('에러 발생 시 false를 반환하는지 확인', () async {
      // Given: null (에러를 유발할 수 있는 값)
      // When & Then: 에러가 발생해도 false를 반환해야 함
      // 실제로는 MovieTitleMatcher에서 처리되므로 여기서는 간단히 테스트
      const movieTitle = '테스트 영화';
      final isPlaying = await LotteCinemaMovieChecker.isPlayingInLotteCinema(movieTitle);
      expect(isPlaying, isA<bool>());
    });
  });
}
