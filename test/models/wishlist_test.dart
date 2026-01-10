import 'package:flutter_test/flutter_test.dart';
import 'package:movie_diary_app/models/wishlist.dart';
import 'package:movie_diary_app/models/movie.dart';

void main() {
  group('WishlistItem 모델 테스트', () {
    late Movie testMovie;

    setUp(() {
      // 테스트용 Movie 객체 생성
      testMovie = Movie(
        id: "696506",
        title: "미키 17",
        posterUrl: "https://image.tmdb.org/t/p/w500/test.jpg",
        genres: ["SF", "코미디", "모험"],
        releaseDate: DateTime.parse("2025-02-28"),
        runtime: 137,
        voteAverage: 3.4,
        isRecent: false,
      );
    });

    test('JSON에서 WishlistItem 객체로 변환 (fromJson with Movie)', () {
      // Given: 더미데이터 예시.txt 형식의 JSON
      final json = {
        "id": "696506",
        "title": "미키 17",
        "posterUrl": "https://image.tmdb.org/t/p/w500/test.jpg",
        "genres": ["SF", "코미디", "모험"],
        "rating": 3.4,
        "savedAt": "2026-01-05T10:00:00Z",
      };

      // When: fromJson으로 변환 (Movie 객체 제공)
      final wishlistItem = WishlistItem.fromJson(json, movie: testMovie);

      // Then: 모든 필드가 올바르게 변환되었는지 확인
      expect(wishlistItem.movie.id, "696506");
      expect(wishlistItem.movie.title, "미키 17");
      expect(wishlistItem.savedAt, DateTime.parse("2026-01-05T10:00:00Z"));
    });

    test('JSON에서 Movie 없이 WishlistItem 객체로 변환', () {
      // Given: Movie 객체 없이 JSON만 제공
      final json = {
        "id": "696506",
        "title": "미키 17",
        "posterUrl": "https://image.tmdb.org/t/p/w500/test.jpg",
        "genres": ["SF", "코미디", "모험"],
        "rating": 3.4,
        "savedAt": "2026-01-05T10:00:00Z",
      };

      // When: fromJson으로 변환 (Movie 객체 없음)
      final wishlistItem = WishlistItem.fromJson(json);

      // Then: JSON에서 Movie 정보를 파싱하여 생성되어야 함
      expect(wishlistItem.movie.id, "696506");
      expect(wishlistItem.movie.title, "미키 17");
      expect(wishlistItem.movie.voteAverage, 3.4);
      expect(wishlistItem.savedAt, DateTime.parse("2026-01-05T10:00:00Z"));
    });

    test('savedAt이 없는 경우 현재 시간으로 설정', () {
      // Given: savedAt이 없는 JSON
      final json = {
        "id": "696506",
        "title": "미키 17",
        "rating": 3.4,
      };

      // When: fromJson으로 변환
      final beforeTime = DateTime.now();
      final wishlistItem = WishlistItem.fromJson(json, movie: testMovie);
      final afterTime = DateTime.now();

      // Then: 현재 시간으로 설정되어야 함
      expect(wishlistItem.savedAt.isAfter(beforeTime.subtract(const Duration(seconds: 1))), true);
      expect(wishlistItem.savedAt.isBefore(afterTime.add(const Duration(seconds: 1))), true);
    });

    test('WishlistItem 객체를 JSON으로 변환 (toJson)', () {
      // Given: WishlistItem 객체 생성
      final savedAt = DateTime.parse("2026-01-05T10:00:00Z");
      final wishlistItem = WishlistItem(
        movie: testMovie,
        savedAt: savedAt,
      );

      // When: toJson으로 변환
      final json = wishlistItem.toJson();

      // Then: 모든 필드가 올바르게 변환되었는지 확인
      expect(json['id'], "696506");
      expect(json['title'], "미키 17");
      expect(json['posterUrl'], "https://image.tmdb.org/t/p/w500/test.jpg");
      expect(json['genres'], ["SF", "코미디", "모험"]);
      expect(json['rating'], 3.4);
      expect(json['savedAt'], savedAt.toIso8601String());
    });

    test('fromJson과 toJson이 서로 호환되는지 확인 (Round-trip)', () {
      // Given: 원본 JSON
      final originalJson = {
        "id": "696506",
        "title": "미키 17",
        "posterUrl": "https://image.tmdb.org/t/p/w500/test.jpg",
        "genres": ["SF", "코미디", "모험"],
        "rating": 3.4,
        "savedAt": "2026-01-05T10:00:00Z",
      };

      // When: JSON → WishlistItem → JSON 변환
      final wishlistItem = WishlistItem.fromJson(originalJson, movie: testMovie);
      final convertedJson = wishlistItem.toJson();

      // Then: 원본과 변환된 JSON의 주요 필드가 같아야 함
      expect(convertedJson['id'], originalJson['id']);
      expect(convertedJson['title'], originalJson['title']);
      expect(convertedJson['rating'], originalJson['rating']);
    });

    test('copyWith로 일부 필드만 변경', () {
      // Given: 원본 WishlistItem
      final originalSavedAt = DateTime.parse("2026-01-05T10:00:00Z");
      final original = WishlistItem(
        movie: testMovie,
        savedAt: originalSavedAt,
      );

      // When: copyWith로 savedAt 변경
      final newSavedAt = DateTime.parse("2026-01-06T10:00:00Z");
      final modified = original.copyWith(savedAt: newSavedAt);

      // Then: 변경된 필드만 바뀌고 나머지는 유지
      expect(modified.movie.id, original.movie.id);
      expect(modified.savedAt, newSavedAt); // 변경됨
      expect(original.savedAt, originalSavedAt); // 원본은 그대로
    });

    test('toString 메서드 테스트', () {
      // Given: WishlistItem 객체
      final savedAt = DateTime.parse("2026-01-05T10:00:00Z");
      final wishlistItem = WishlistItem(
        movie: testMovie,
        savedAt: savedAt,
      );

      // When: toString 호출
      final str = wishlistItem.toString();

      // Then: 주요 정보가 포함되어 있어야 함
      expect(str, contains('미키 17')); // movie title
      expect(str, contains('WishlistItem'));
    });

    test('ISO 8601 형식의 savedAt 파싱', () {
      // Given: 다양한 ISO 8601 형식
      final testCases = [
        "2026-01-05T10:00:00Z",
        "2026-01-05T10:00:00.000Z",
        "2026-01-05T10:00:00+00:00",
      ];

      for (final dateStr in testCases) {
        final json = {
          "id": "696506",
          "title": "미키 17",
          "rating": 3.4,
          "savedAt": dateStr,
        };

        // When: fromJson으로 변환
        final wishlistItem = WishlistItem.fromJson(json, movie: testMovie);

        // Then: 올바르게 파싱되어야 함
        expect(wishlistItem.savedAt.year, 2026);
        expect(wishlistItem.savedAt.month, 1);
        expect(wishlistItem.savedAt.day, 5);
      }
    });
  });
}
