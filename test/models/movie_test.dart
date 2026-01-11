import 'package:flutter_test/flutter_test.dart';
import 'package:movie_diary_app/models/movie.dart';

void main() {
  group('Movie 모델 테스트', () {
    test('JSON에서 Movie 객체로 변환 (fromJson)', () {
      // Given: 더미데이터 예시.txt 형식의 JSON
      final json = {
        "id": "496243",
        "title": "기생충",
        "posterUrl": "https://image.tmdb.org/t/p/w500/test.jpg",
        "genres": ["코미디", "스릴러", "드라마"],
        "releaseDate": "2019-05-30",
        "runtime": 131,
        "voteAverage": 4.3,
        "isRecent": false,
      };

      // When: fromJson으로 변환
      final movie = Movie.fromJson(json);

      // Then: 모든 필드가 올바르게 변환되었는지 확인
      expect(movie.id, "496243");
      expect(movie.title, "기생충");
      expect(movie.posterUrl, "https://image.tmdb.org/t/p/w500/test.jpg");
      expect(movie.genres, ["코미디", "스릴러", "드라마"]);
      expect(movie.releaseDate, "2019-05-30");
      expect(movie.runtime, 131);
      expect(movie.voteAverage, 4.3);
      expect(movie.isRecent, false);
    });

    test('Movie 객체를 JSON으로 변환 (toJson)', () {
      // Given: Movie 객체 생성
      final movie = Movie(
        id: "496243",
        title: "기생충",
        posterUrl: "https://image.tmdb.org/t/p/w500/test.jpg",
        genres: ["코미디", "스릴러"],
        releaseDate: "2019-05-30",
        runtime: 131,
        voteAverage: 4.3,
        isRecent: false,
      );

      // When: toJson으로 변환
      final json = movie.toJson();

      // Then: 모든 필드가 올바르게 변환되었는지 확인
      expect(json['id'], "496243");
      expect(json['title'], "기생충");
      expect(json['posterUrl'], "https://image.tmdb.org/t/p/w500/test.jpg");
      expect(json['genres'], ["코미디", "스릴러"]);
      expect(json['releaseDate'], "2019-05-30"); // YYYY-MM-DD 형식
      expect(json['runtime'], 131);
      expect(json['voteAverage'], 4.3);
      expect(json['isRecent'], false);
    });

    test('fromJson과 toJson이 서로 호환되는지 확인 (Round-trip)', () {
      // Given: 원본 JSON
      final originalJson = {
        "id": "496243",
        "title": "기생충",
        "posterUrl": "https://image.tmdb.org/t/p/w500/test.jpg",
        "genres": ["코미디", "스릴러", "드라마"],
        "releaseDate": "2019-05-30",
        "runtime": 131,
        "voteAverage": 4.3,
        "isRecent": false,
      };

      // When: JSON → Movie → JSON 변환
      final movie = Movie.fromJson(originalJson);
      final convertedJson = movie.toJson();

      // Then: 원본과 변환된 JSON이 같아야 함
      expect(convertedJson['id'], originalJson['id']);
      expect(convertedJson['title'], originalJson['title']);
      expect(convertedJson['releaseDate'], originalJson['releaseDate']);
    });

    test('copyWith로 일부 필드만 변경', () {
      // Given: 원본 Movie
      final original = Movie(
        id: "496243",
        title: "기생충",
        posterUrl: "https://test.jpg",
        genres: ["드라마"],
        releaseDate: "2019-05-30",
        runtime: 131,
        voteAverage: 4.3,
        isRecent: false,
      );

      // When: copyWith로 일부 필드 변경
      final modified = original.copyWith(
        isRecent: true,
        voteAverage: 5.0,
      );

      // Then: 변경된 필드만 바뀌고 나머지는 유지
      expect(modified.id, original.id);
      expect(modified.title, original.title);
      expect(modified.isRecent, true); // 변경됨
      expect(modified.voteAverage, 5.0); // 변경됨
      expect(original.isRecent, false); // 원본은 그대로
    });

    test('null 안전성 테스트 (posterUrl이 null인 경우)', () {
      // Given: posterUrl이 null인 JSON
      final json = {
        "id": "123",
        "title": "테스트",
        "posterUrl": null, // null 값
        "genres": ["드라마"],
        "releaseDate": "2019-05-30",
        "runtime": 131,
        "voteAverage": 4.3,
        "isRecent": false,
      };

      // When: fromJson 실행
      final movie = Movie.fromJson(json);

      // Then: 빈 문자열로 기본값이 설정되어야 함
      expect(movie.posterUrl, "");
    });
  });
}
