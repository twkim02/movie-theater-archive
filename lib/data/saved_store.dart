import 'package:flutter/foundation.dart';

/// @deprecated 이 클래스는 더 이상 사용되지 않습니다.
/// DB 마이그레이션으로 인해 AppState와 WishlistRepository를 사용하세요.
/// 
/// 대체 방법:
/// - `AppState.toggleBookmark(String)` - 북마크 토글
/// - `AppState.isBookmarked(String)` - 북마크 확인
/// - `AppState.wishlist` - 위시리스트 조회
/// - `WishlistRepository` - 직접 DB 접근이 필요한 경우
@Deprecated('Use AppState and WishlistRepository instead')
class SavedStore {
  /// ✅ movieId만 저장 (가볍고 안전)
  static final ValueNotifier<Set<String>> savedIds = ValueNotifier<Set<String>>(<String>{});

  static bool isSaved(String movieId) => savedIds.value.contains(movieId);

  static void toggle(String movieId) {
    final next = Set<String>.from(savedIds.value);
    if (next.contains(movieId)) {
      next.remove(movieId);
    } else {
      next.add(movieId);
    }
    savedIds.value = next;
  }

  static void remove(String movieId) {
    if (!savedIds.value.contains(movieId)) return;
    final next = Set<String>.from(savedIds.value)..remove(movieId);
    savedIds.value = next;
  }

  static void clear() {
    savedIds.value = <String>{};
  }
}
