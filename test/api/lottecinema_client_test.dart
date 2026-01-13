import 'package:flutter_test/flutter_test.dart';
import 'package:movie_diary_app/api/lottecinema_client.dart';
import 'package:movie_diary_app/models/lottecinema_data.dart';

void main() {
  group('LotteCinemaClient 테스트', () {
    late LotteCinemaClient client;

    setUp(() {
      client = LotteCinemaClient();
    });

    test('클라이언트 인스턴스가 생성되는지 확인', () {
      // When: 클라이언트 생성
      final client = LotteCinemaClient();

      // Then: 인스턴스가 생성되어야 함
      expect(client, isNotNull);
    });

    test('잘못된 파라미터로 API 호출 시 빈 리스트를 반환하는지 확인', () async {
      // Given: 잘못된 파라미터
      const cinemaId = 'invalid|cinema|id';
      const movieNo = '99999';
      const playDate = '2026-01-13';

      // When: API 호출
      final schedules = await client.getMovieSchedule(
        cinemaId: cinemaId,
        movieNo: movieNo,
        playDate: playDate,
      );

      // Then: 빈 리스트를 반환해야 함 (에러 처리 확인)
      expect(schedules, isA<List<LotteCinemaSchedule>>());
      // Note: 실제 API 호출이 실패하더라도 빈 리스트를 반환해야 함
    }, skip: '실제 API 호출은 네트워크가 필요하므로 스킵');

    test('LotteCinemaSchedule 모델이 올바르게 생성되는지 확인', () {
      // Given: JSON 데이터
      final json = {
        'MovieNameKR': '만약에 우리',
        'StartTime': '17:30',
        'EndTime': '19:34',
        'ScreenNameKR': '4관',
        'TotalSeatCount': 200,
        'BookingSeatCount': 50,
      };

      // When: 모델 생성
      final schedule = LotteCinemaSchedule.fromJson(json);

      // Then: 모든 필드가 올바르게 설정되어야 함
      expect(schedule.movieNameKR, '만약에 우리');
      expect(schedule.startTime, '17:30');
      expect(schedule.endTime, '19:34');
      expect(schedule.screenNameKR, '4관');
      expect(schedule.totalSeatCount, 200);
      expect(schedule.bookingSeatCount, 50);
      expect(schedule.availableSeatCount, 150); // 200 - 50
    });

    test('LotteCinemaSchedule의 availableSeatCount가 올바르게 계산되는지 확인', () {
      // Given: 좌석 정보
      final json = {
        'MovieNameKR': '테스트 영화',
        'StartTime': '10:00',
        'EndTime': '12:00',
        'ScreenNameKR': '1관',
        'TotalSeatCount': 100,
        'BookingSeatCount': 30,
      };

      // When: 모델 생성
      final schedule = LotteCinemaSchedule.fromJson(json);

      // Then: 잔여 좌석 수가 올바르게 계산되어야 함
      expect(schedule.availableSeatCount, 70); // 100 - 30
    });

    test('LotteCinemaTheater의 cinemaIdString이 올바르게 생성되는지 확인', () {
      // Given: 영화관 정보
      final theater = LotteCinemaTheater(
        divisionCode: '1',
        detailDivisionCode: '0003',
        cinemaID: '4008',
        element: '대전센트럴',
      );

      // When: cinemaIdString 가져오기
      final cinemaIdString = theater.cinemaIdString;

      // Then: 올바른 형식이어야 함
      expect(cinemaIdString, '1|0003|4008');
    });
  });
}
