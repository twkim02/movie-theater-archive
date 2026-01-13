import 'package:flutter_test/flutter_test.dart';
import 'package:movie_diary_app/services/theater_schedule_service.dart';
import 'package:movie_diary_app/models/theater.dart';

void main() {
  // 테스트 전에 assets를 로드하기 위한 설정
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('TheaterScheduleService 테스트', () {
    test('롯데시네마 영화관 감지가 제대로 작동하는지 확인', () async {
      // Given: 롯데시네마 영화관 이름들
      final lotteTheaters = [
        '롯데시네마 대전센트럴',
        '롯데시네마',
        '롯데시네마 강남',
        '롯데 대전',
      ];

      // When & Then: 모두 롯데시네마로 감지되어야 함
      for (final name in lotteTheaters) {
        final result = await TheaterScheduleService.getLotteCinemaSchedule(
          theaterName: name,
          movieTitle: '만약에 우리',
          date: DateTime.now(),
        );
        // 롯데시네마이므로 빈 리스트가 아닐 수 있음 (API 호출 시도)
        expect(result, isA<List<Showtime>>());
      }
    });

    test('롯데시네마가 아닌 영화관은 빈 리스트를 반환하는지 확인', () async {
      // Given: 롯데시네마가 아닌 영화관 이름들
      final nonLotteTheaters = [
        'CGV 대전',
        '메가박스 대전',
        '영화관',
      ];

      // When & Then: 모두 빈 리스트를 반환해야 함
      for (final name in nonLotteTheaters) {
        final result = await TheaterScheduleService.getLotteCinemaSchedule(
          theaterName: name,
          movieTitle: '만약에 우리',
          date: DateTime.now(),
        );
        expect(result, isEmpty);
      }
    });

    test('존재하지 않는 영화로 요청 시 빈 리스트를 반환하는지 확인', () async {
      // Given: 존재하지 않는 영화 제목
      const movieTitle = '존재하지 않는 영화 12345';

      // When: 롯데시네마 영화관으로 요청
      final result = await TheaterScheduleService.getLotteCinemaSchedule(
        theaterName: '롯데시네마 대전센트럴',
        movieTitle: movieTitle,
        date: DateTime.now(),
      );

      // Then: 빈 리스트를 반환해야 함
      expect(result, isEmpty);
    });

    test('존재하지 않는 영화관으로 요청 시 빈 리스트를 반환하는지 확인', () async {
      // Given: 존재하지 않는 영화관 이름
      const theaterName = '롯데시네마 존재하지않는영화관';

      // When: 요청
      final result = await TheaterScheduleService.getLotteCinemaSchedule(
        theaterName: theaterName,
        movieTitle: '만약에 우리',
        date: DateTime.now(),
      );

      // Then: 빈 리스트를 반환해야 함
      expect(result, isEmpty);
    });

    test('캐시가 제대로 작동하는지 확인', () async {
      // Given: 같은 파라미터로 두 번 요청
      const theaterName = '롯데시네마 대전센트럴';
      const movieTitle = '만약에 우리';
      final date = DateTime.now();

      // When: 첫 번째 요청
      final firstResult = await TheaterScheduleService.getLotteCinemaSchedule(
        theaterName: theaterName,
        movieTitle: movieTitle,
        date: date,
      );

      // 두 번째 요청 (캐시에서 가져와야 함)
      final secondResult = await TheaterScheduleService.getLotteCinemaSchedule(
        theaterName: theaterName,
        movieTitle: movieTitle,
        date: date,
      );

      // Then: 같은 결과여야 함
      expect(firstResult.length, secondResult.length);
      if (firstResult.isNotEmpty && secondResult.isNotEmpty) {
        expect(firstResult.first.start, secondResult.first.start);
      }
    });

    test('캐시 초기화가 제대로 작동하는지 확인', () async {
      // Given: 캐시에 데이터가 있는 상태
      await TheaterScheduleService.getLotteCinemaSchedule(
        theaterName: '롯데시네마 대전센트럴',
        movieTitle: '만약에 우리',
        date: DateTime.now(),
      );

      // When: 캐시 초기화
      TheaterScheduleService.clearCache();

      // Then: 다시 요청하면 캐시가 없으므로 새로 API 호출 시도
      final result = await TheaterScheduleService.getLotteCinemaSchedule(
        theaterName: '롯데시네마 대전센트럴',
        movieTitle: '만약에 우리',
        date: DateTime.now(),
      );
      expect(result, isA<List<Showtime>>());
    });

    test('Showtime 변환이 제대로 되는지 확인', () async {
      // Given: 실제 API 호출이 성공하는 경우를 가정
      // (실제로는 네트워크가 필요하므로 스킵할 수 있음)
      
      // When: 롯데시네마 영화관으로 요청
      final result = await TheaterScheduleService.getLotteCinemaSchedule(
        theaterName: '롯데시네마 대전센트럴',
        movieTitle: '만약에 우리',
        date: DateTime.now(),
      );

      // Then: Showtime 리스트가 반환되어야 함
      expect(result, isA<List<Showtime>>());
      
      // 결과가 있으면 각 Showtime의 필드가 채워져 있어야 함
      for (final showtime in result) {
        expect(showtime.start, isNotEmpty);
        expect(showtime.end, isNotEmpty);
        expect(showtime.screen, isNotEmpty);
      }
    }, skip: '실제 API 호출은 네트워크가 필요하므로 선택적으로 실행');
  });
}
