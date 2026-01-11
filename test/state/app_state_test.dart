import 'package:flutter_test/flutter_test.dart';
import 'package:movie_diary_app/state/app_state.dart';

void main() {
  group('AppState 테스트', () {
    late AppState appState;

    setUp(() {
      // 각 테스트 전에 새로운 AppState 인스턴스 생성
      appState = AppState();
    });

    test('초기 상태에서 영화 리스트가 비어있지 않아야 함', () {
      // Then: 더미 데이터가 로드되어 있어야 함
      expect(appState.movies.isEmpty, false);
      expect(appState.movies.length, 7); // 더미데이터 예시.txt 기준
    });

    test('초기 상태에서 북마크 목록이 비어있어야 함', () {
      // Then: 북마크 목록이 비어있어야 함
      expect(appState.bookmarkedMovieIds.isEmpty, true);
      expect(appState.bookmarkedMovies.isEmpty, true);
    });

    test('북마크 추가 및 확인', () {
      // Given: 영화 ID
      final movieId = "496243"; // 기생충

      // When: 북마크 추가
      appState.addBookmark(movieId);

      // Then: 북마크 상태 확인
      expect(appState.isBookmarked(movieId), true);
      expect(appState.bookmarkedMovieIds.contains(movieId), true);
      expect(appState.bookmarkedMovies.length, 1);
      expect(appState.bookmarkedMovies.first.id, movieId);
    });

    test('북마크 토글 (추가 → 제거)', () {
      // Given: 영화 ID
      final movieId = "496243";

      // When: 북마크 토글 (추가)
      appState.toggleBookmark(movieId);

      // Then: 북마크됨
      expect(appState.isBookmarked(movieId), true);
      expect(appState.bookmarkedMovies.length, 1);

      // When: 다시 토글 (제거)
      appState.toggleBookmark(movieId);

      // Then: 북마크 해제됨
      expect(appState.isBookmarked(movieId), false);
      expect(appState.bookmarkedMovies.length, 0);
    });

    test('북마크 제거', () {
      // Given: 북마크된 영화
      final movieId = "496243";
      appState.addBookmark(movieId);
      expect(appState.isBookmarked(movieId), true);

      // When: 북마크 제거
      appState.removeBookmark(movieId);

      // Then: 북마크 해제됨
      expect(appState.isBookmarked(movieId), false);
      expect(appState.bookmarkedMovies.length, 0);
    });

    test('여러 영화 북마크 후 북마크된 영화만 반환', () {
      // Given: 여러 영화 ID
      final movieId1 = "496243"; // 기생충
      final movieId2 = "83533";  // 아바타: 불과 재
      final movieId3 = "361743"; // 탑건: 매버릭

      // When: 여러 영화 북마크
      appState.addBookmark(movieId1);
      appState.addBookmark(movieId2);
      appState.addBookmark(movieId3);

      // Then: 북마크된 영화만 반환
      expect(appState.bookmarkedMovies.length, 3);
      expect(appState.isBookmarked(movieId1), true);
      expect(appState.isBookmarked(movieId2), true);
      expect(appState.isBookmarked(movieId3), true);

      // 북마크되지 않은 영화는 false
      expect(appState.isBookmarked("999999"), false);
    });

    test('북마크된 영화 ID 목록이 불변(immutable)인지 확인', () {
      // Given: 북마크 추가
      appState.addBookmark("496243");
      final bookmarkedIds = appState.bookmarkedMovieIds;

      // When: 불변 Set에 추가 시도
      // Then: UnsupportedError 예외가 발생해야 함
      expect(() => bookmarkedIds.add("123"), throwsA(isA<UnsupportedError>()));
    });

    test('중복 북마크 추가는 무시되어야 함', () {
      // Given: 영화 ID
      final movieId = "496243";

      // When: 같은 영화를 두 번 북마크
      appState.addBookmark(movieId);
      appState.addBookmark(movieId); // 중복 추가

      // Then: 북마크는 하나만 있어야 함
      expect(appState.bookmarkedMovies.length, 1);
      expect(appState.bookmarkedMovieIds.length, 1);
    });
  });
}
