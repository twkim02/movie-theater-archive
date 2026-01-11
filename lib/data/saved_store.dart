import 'package:flutter/foundation.dart';

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
