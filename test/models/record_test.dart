import 'package:flutter_test/flutter_test.dart';
import 'package:movie_diary_app/models/record.dart';
import 'package:movie_diary_app/models/movie.dart';

void main() {
  group('Record 모델 테스트', () {
    late Movie testMovie;

    setUp(() {
      // 테스트용 Movie 객체 생성
      testMovie = Movie(
        id: "496243",
        title: "기생충",
        posterUrl: "https://image.tmdb.org/t/p/w500/test.jpg",
        genres: ["코미디", "스릴러", "드라마"],
        releaseDate: "2019-05-30",
        runtime: 131,
        voteAverage: 4.3,
        isRecent: false,
      );
    });

    test('JSON에서 Record 객체로 변환 (fromJson with Movie)', () {
      // Given: 더미데이터 예시.txt 형식의 JSON
      final json = {
        "id": 101,
        "userId": 1,
        "rating": 4.5,
        "watchDate": "2026-01-02",
        "oneLiner": "압도적인 영상미",
        "detailedReview": "정말 감동적인 영화였습니다.",
        "tags": ["가족", "극장"],
        "photoPaths:": "https://example.com/photo.jpg",
      };

      // When: fromJson으로 변환 (Movie 객체 제공)
      final record = Record.fromJson(json, movie: testMovie);

      // Then: 모든 필드가 올바르게 변환되었는지 확인
      expect(record.id, 101);
      expect(record.userId, 1);
      expect(record.rating, 4.5);
      expect(record.watchDate, DateTime.parse("2026-01-02"));
      expect(record.oneLiner, "압도적인 영상미");
      expect(record.detailedReview, "정말 감동적인 영화였습니다.");
      expect(record.tags, ["가족", "극장"]);
      expect(record.photoPaths, "https://example.com/photo.jpg");
      expect(record.movie.id, testMovie.id);
      expect(record.movie.title, testMovie.title);
    });

    test('선택적 필드가 null인 경우 처리', () {
      // Given: oneLiner, detailedReview, photoPaths이 없는 JSON
      final json = {
        "id": 102,
        "userId": 1,
        "rating": 5.0,
        "watchDate": "2026-01-05",
        "tags": ["혼자"],
      };

      // When: fromJson으로 변환
      final record = Record.fromJson(json, movie: testMovie);

      // Then: 선택적 필드는 null이어야 함
      expect(record.id, 102);
      expect(record.rating, 5.0);
      expect(record.oneLiner, isNull);
      expect(record.detailedReview, isNull);
      expect(record.photoPaths, isNull);
      expect(record.tags, ["혼자"]);
    });

    test('Record 객체를 JSON으로 변환 (toJson)', () {
      // Given: Record 객체 생성
      final record = Record(
        id: 101,
        userId: 1,
        rating: 4.5,
        watchDate: DateTime.parse("2026-01-02"),
        oneLiner: "압도적인 영상미",
        detailedReview: "정말 감동적인 영화였습니다.",
        tags: ["가족", "극장"],
        photoPaths: const [],
        movie: testMovie,
      );

      // When: toJson으로 변환
      final json = record.toJson();

      // Then: 모든 필드가 올바르게 변환되었는지 확인
      expect(json['id'], 101);
      expect(json['userId'], 1);
      expect(json['rating'], 4.5);
      expect(json['watchDate'], "2026-01-02"); // YYYY-MM-DD 형식
      expect(json['oneLiner'], "압도적인 영상미");
      expect(json['detailedReview'], "정말 감동적인 영화였습니다.");
      expect(json['tags'], ["가족", "극장"]);
      expect(json['photoPaths:'], "https://example.com/photo.jpg");
      expect(json['movie'], isA<Map<String, dynamic>>());
      expect(json['movie']['id'], testMovie.id);
      expect(json['movie']['title'], testMovie.title);
    });

    test('fromJson과 toJson이 서로 호환되는지 확인 (Round-trip)', () {
      // Given: 원본 JSON
      final originalJson = {
        "id": 101,
        "userId": 1,
        "rating": 4.5,
        "watchDate": "2026-01-02",
        "oneLiner": "압도적인 영상미",
        "tags": ["가족", "극장"],
      };

      // When: JSON → Record → JSON 변환
      final record = Record.fromJson(originalJson, movie: testMovie);
      final convertedJson = record.toJson();

      // Then: 원본과 변환된 JSON의 주요 필드가 같아야 함
      expect(convertedJson['id'], originalJson['id']);
      expect(convertedJson['userId'], originalJson['userId']);
      expect(convertedJson['rating'], originalJson['rating']);
      expect(convertedJson['watchDate'], originalJson['watchDate']);
    });

    test('copyWith로 일부 필드만 변경', () {
      // Given: 원본 Record
      final original = Record(
        id: 101,
        userId: 1,
        rating: 4.5,
        watchDate: DateTime.parse("2026-01-02"),
        oneLiner: "좋은 영화",
        tags: ["가족"],
        movie: testMovie,
      );

      // When: copyWith로 일부 필드 변경
      final modified = original.copyWith(
        rating: 5.0,
        tags: ["가족", "극장"],
      );

      // Then: 변경된 필드만 바뀌고 나머지는 유지
      expect(modified.id, original.id);
      expect(modified.userId, original.userId);
      expect(modified.rating, 5.0); // 변경됨
      expect(modified.tags, ["가족", "극장"]); // 변경됨
      expect(modified.oneLiner, original.oneLiner); // 유지
      expect(original.rating, 4.5); // 원본은 그대로
    });

    test('toString 메서드 테스트', () {
      // Given: Record 객체
      final record = Record(
        id: 101,
        userId: 1,
        rating: 4.5,
        watchDate: DateTime.parse("2026-01-02"),
        tags: ["가족"],
        movie: testMovie,
      );

      // When: toString 호출
      final str = record.toString();

      // Then: 주요 정보가 포함되어 있어야 함
      expect(str, contains('101')); // id
      expect(str, contains('기생충')); // movie title
      expect(str, contains('4.5')); // rating
    });

    test('태그가 빈 리스트인 경우 처리', () {
      // Given: tags가 빈 리스트인 JSON
      final json = {
        "id": 103,
        "userId": 1,
        "rating": 3.0,
        "watchDate": "2026-01-03",
        "tags": [],
      };

      // When: fromJson으로 변환
      final record = Record.fromJson(json, movie: testMovie);

      // Then: 빈 리스트로 처리되어야 함
      expect(record.tags, isEmpty);
    });
  });
}
