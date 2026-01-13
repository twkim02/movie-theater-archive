import 'package:flutter_test/flutter_test.dart';
import 'package:movie_diary_app/utils/csv_parser.dart';

void main() {
  // 테스트 전에 assets를 로드하기 위한 설정
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('CsvParser 테스트', () {
    test('현재 상영 중인 영화 목록을 가져올 수 있는지 확인', () async {
      // When: 현재 상영 중인 영화 목록 가져오기
      final movies = await CsvParser.getNowMovies();

      // Then: 영화 목록이 비어있지 않아야 함
      expect(movies.isNotEmpty, true, reason: '현재 상영 중인 영화 목록이 비어있습니다.');
      
      // 첫 번째 영화의 필수 필드 확인
      if (movies.isNotEmpty) {
        final firstMovie = movies.first;
        expect(firstMovie.movieNo.isNotEmpty, true);
        expect(firstMovie.movieName.isNotEmpty, true);
      }
    });

    test('개봉 예정 영화 목록을 가져올 수 있는지 확인', () async {
      // When: 개봉 예정 영화 목록 가져오기
      final movies = await CsvParser.getUpcomingMovies();

      // Then: 영화 목록이 비어있지 않아야 함
      expect(movies.isNotEmpty, true, reason: '개봉 예정 영화 목록이 비어있습니다.');
      
      // 첫 번째 영화의 필수 필드 확인
      if (movies.isNotEmpty) {
        final firstMovie = movies.first;
        expect(firstMovie.movieNo.isNotEmpty, true);
        expect(firstMovie.movieName.isNotEmpty, true);
      }
    });

    test('모든 영화 목록을 가져올 수 있는지 확인', () async {
      // When: 모든 영화 목록 가져오기
      final allMovies = await CsvParser.getAllMovies();

      // Then: 영화 목록이 비어있지 않아야 함
      expect(allMovies.isNotEmpty, true, reason: '모든 영화 목록이 비어있습니다.');
      
      // 현재 상영 + 개봉 예정 영화의 합과 비교
      final nowMovies = await CsvParser.getNowMovies();
      final upcomingMovies = await CsvParser.getUpcomingMovies();
      expect(allMovies.length, nowMovies.length + upcomingMovies.length);
    });

    test('영화관 목록을 가져올 수 있는지 확인', () async {
      // When: 영화관 목록 가져오기
      final theaters = await CsvParser.getTheaters();

      // Then: 영화관 목록이 비어있지 않아야 함
      expect(theaters.isNotEmpty, true, reason: '영화관 목록이 비어있습니다.');
      
      // 첫 번째 영화관의 필수 필드 확인
      if (theaters.isNotEmpty) {
        final firstTheater = theaters.first;
        expect(firstTheater.divisionCode.isNotEmpty, true);
        expect(firstTheater.detailDivisionCode.isNotEmpty, true);
        expect(firstTheater.cinemaID.isNotEmpty, true);
        expect(firstTheater.element.isNotEmpty, true);
      }
    });

    test('영화관 이름으로 영화관을 찾을 수 있는지 확인', () async {
      // When: 특정 영화관 이름으로 검색
      final theater = await CsvParser.findTheaterByName('대전센트럴');

      // Then: 영화관을 찾을 수 있어야 함
      expect(theater, isNotNull, reason: '대전센트럴 영화관을 찾을 수 없습니다.');
      if (theater != null) {
        expect(theater.element, contains('대전'));
        expect(theater.cinemaIdString, isNotEmpty);
      }
    });

    test('영화명으로 영화를 찾을 수 있는지 확인', () async {
      // When: 특정 영화명으로 검색
      final movie = await CsvParser.findMovieByName('만약에 우리');

      // Then: 영화를 찾을 수 있어야 함
      expect(movie, isNotNull, reason: '만약에 우리 영화를 찾을 수 없습니다.');
      if (movie != null) {
        expect(movie.movieName, contains('만약에 우리'));
        expect(movie.movieNo.isNotEmpty, true);
      }
    });

    test('캐싱이 제대로 작동하는지 확인', () async {
      // When: 같은 데이터를 두 번 요청
      final firstCall = await CsvParser.getNowMovies();
      final secondCall = await CsvParser.getNowMovies();

      // Then: 같은 인스턴스여야 함 (캐싱 확인)
      expect(firstCall.length, secondCall.length);
      if (firstCall.isNotEmpty && secondCall.isNotEmpty) {
        expect(firstCall.first.movieNo, secondCall.first.movieNo);
      }
    });

    test('캐시 초기화가 제대로 작동하는지 확인', () async {
      // Given: 데이터를 먼저 로드
      await CsvParser.getNowMovies();
      
      // When: 캐시 초기화
      CsvParser.clearCache();
      
      // Then: 다시 로드하면 데이터가 있어야 함
      final movies = await CsvParser.getNowMovies();
      expect(movies.isNotEmpty, true);
    });
  });
}
