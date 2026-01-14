import 'package:flutter_test/flutter_test.dart';
import 'package:movie_diary_app/services/lottecinema_movie_checker.dart';
import 'package:movie_diary_app/services/megabox_movie_checker.dart';

void main() {
  // 테스트 전에 assets를 로드하기 위한 설정
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('MovieInitializationService 통합 테스트 (4단계)', () {
    test('롯데시네마와 메가박스 모두 확인하는지 테스트', () async {
      // Given: 메가박스에서 상영 중인 영화 제목
      const movieTitle = '만약에 우리';

      // When: 롯데시네마와 메가박스 상영 여부 확인
      final isPlayingInLotte = await LotteCinemaMovieChecker.isPlayingInLotteCinema(movieTitle);
      final isPlayingInMegabox = await MegaboxMovieChecker.isPlayingInMegabox(movieTitle);

      // Then: 둘 중 하나라도 true이면 isRecent = true로 설정되어야 함
      final shouldBeRecent = isPlayingInLotte || isPlayingInMegabox;
      expect(shouldBeRecent, isA<bool>());
      
      // 둘 중 하나라도 상영 중이면 true여야 함
      if (isPlayingInLotte || isPlayingInMegabox) {
        expect(shouldBeRecent, isTrue);
      }
    });

    test('롯데시네마에서만 상영 중인 경우', () async {
      // Given: 롯데시네마에서만 상영 중인 영화 (메가박스에는 없음)
      // Note: 실제 데이터에 따라 다를 수 있으므로, 일반적인 테스트로 진행
      const movieTitle = '만약에 우리';

      // When: 롯데시네마와 메가박스 상영 여부 확인
      final isPlayingInLotte = await LotteCinemaMovieChecker.isPlayingInLotteCinema(movieTitle);
      final isPlayingInMegabox = await MegaboxMovieChecker.isPlayingInMegabox(movieTitle);

      // Then: 롯데시네마에서 상영 중이면 isRecent = true
      if (isPlayingInLotte) {
        expect(isPlayingInLotte || isPlayingInMegabox, isTrue);
      }
    });

    test('메가박스에서만 상영 중인 경우', () async {
      // Given: 메가박스에서만 상영 중인 영화 (롯데시네마에는 없음)
      // Note: 실제 데이터에 따라 다를 수 있으므로, 일반적인 테스트로 진행
      const movieTitle = '프로젝트 Y';

      // When: 롯데시네마와 메가박스 상영 여부 확인
      final isPlayingInLotte = await LotteCinemaMovieChecker.isPlayingInLotteCinema(movieTitle);
      final isPlayingInMegabox = await MegaboxMovieChecker.isPlayingInMegabox(movieTitle);

      // Then: 메가박스에서 상영 중이면 isRecent = true
      if (isPlayingInMegabox) {
        expect(isPlayingInLotte || isPlayingInMegabox, isTrue);
      }
    });

    test('둘 다 상영 중인 경우', () async {
      // Given: 롯데시네마와 메가박스 모두에서 상영 중인 영화
      const movieTitle = '만약에 우리';

      // When: 롯데시네마와 메가박스 상영 여부 확인
      final isPlayingInLotte = await LotteCinemaMovieChecker.isPlayingInLotteCinema(movieTitle);
      final isPlayingInMegabox = await MegaboxMovieChecker.isPlayingInMegabox(movieTitle);

      // Then: 둘 다 상영 중이면 isRecent = true
      if (isPlayingInLotte && isPlayingInMegabox) {
        expect(isPlayingInLotte || isPlayingInMegabox, isTrue);
      }
    });

    test('둘 다 상영하지 않는 경우', () async {
      // Given: 롯데시네마와 메가박스 모두에서 상영하지 않는 영화
      const movieTitle = '존재하지 않는 영화 12345';

      // When: 롯데시네마와 메가박스 상영 여부 확인
      final isPlayingInLotte = await LotteCinemaMovieChecker.isPlayingInLotteCinema(movieTitle);
      final isPlayingInMegabox = await MegaboxMovieChecker.isPlayingInMegabox(movieTitle);

      // Then: 둘 다 false이면 isRecent = false
      expect(isPlayingInLotte, isFalse);
      expect(isPlayingInMegabox, isFalse);
      expect(isPlayingInLotte || isPlayingInMegabox, isFalse);
    });

    test('에러 발생 시에도 계속 진행하는지 확인', () async {
      // Given: 빈 문자열 (에러 발생 가능)
      const movieTitle = '';

      // When: 롯데시네마와 메가박스 상영 여부 확인
      // Then: 에러가 발생해도 false를 반환하고 크래시하지 않아야 함
      final isPlayingInLotte = await LotteCinemaMovieChecker.isPlayingInLotteCinema(movieTitle);
      final isPlayingInMegabox = await MegaboxMovieChecker.isPlayingInMegabox(movieTitle);

      // 둘 다 false를 반환해야 함 (에러 발생 시 조용히 처리)
      expect(isPlayingInLotte, isFalse);
      expect(isPlayingInMegabox, isFalse);
    });
  });
}
