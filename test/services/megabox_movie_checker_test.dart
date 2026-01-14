import 'package:flutter_test/flutter_test.dart';
import 'package:movie_diary_app/services/megabox_movie_checker.dart';

void main() {
  // 테스트 전에 assets를 로드하기 위한 설정
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('MegaboxMovieChecker 테스트', () {
    test('메가박스에서 상영 중인 영화 확인', () async {
      // Given: 메가박스에서 상영 중인 영화 제목
      const movieTitle = '만약에 우리';

      // When: 메가박스 상영 여부 확인
      final result = await MegaboxMovieChecker.isPlayingInMegabox(movieTitle);

      // Then: true를 반환해야 함 (CSV에 있는 영화)
      expect(result, isTrue);
    });

    test('메가박스에서 상영하지 않는 영화 확인', () async {
      // Given: 메가박스에서 상영하지 않는 영화 제목
      const movieTitle = '존재하지 않는 영화 12345';

      // When: 메가박스 상영 여부 확인
      final result = await MegaboxMovieChecker.isPlayingInMegabox(movieTitle);

      // Then: false를 반환해야 함
      expect(result, isFalse);
    });

    test('다양한 영화 제목으로 테스트', () async {
      // Given: 다양한 영화 제목들
      final testCases = [
        ('프로젝트 Y', true), // CSV에 있는 영화
        ('존재하지 않는 영화', false), // CSV에 없는 영화
        ('만약에 우리', true), // CSV에 있는 영화
      ];

      // When & Then: 각 영화에 대해 상영 여부 확인
      for (final (title, expected) in testCases) {
        final result = await MegaboxMovieChecker.isPlayingInMegabox(title);
        expect(result, expected, reason: '영화 "$title"의 상영 여부가 예상과 다릅니다.');
      }
    });

    test('에러 발생 시 false 반환하는지 확인', () async {
      // Given: 빈 문자열 (에러 발생 가능)
      const movieTitle = '';

      // When: 메가박스 상영 여부 확인
      final result = await MegaboxMovieChecker.isPlayingInMegabox(movieTitle);

      // Then: false를 반환해야 함 (에러 발생 시 조용히 처리)
      expect(result, isFalse);
    });
  });
}
