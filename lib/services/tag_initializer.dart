import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/tag_repository.dart';

/// 태그 초기화 서비스
/// 
/// 앱 최초 실행 시 기본 태그를 생성합니다.
class TagInitializer {
  /// SharedPreferences 키
  static const String _tagsInitializedKey = 'tags_initialized';

  /// 기본 태그 목록
  static const List<String> _defaultTags = [
    '혼자',
    '친구',
    '가족',
    '극장',
    'OTT',
  ];

  /// 태그가 초기화되었는지 확인합니다.
  /// 
  /// Returns 초기화되었으면 true
  static Future<bool> isInitialized() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tagsInitializedKey) ?? false;
  }

  /// 태그 초기화 플래그를 설정합니다.
  static Future<void> setInitialized(bool initialized) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tagsInitializedKey, initialized);
  }

  /// 기본 태그를 초기화합니다.
  /// 
  /// 이미 초기화되어 있으면 스킵하고,
  /// 없으면 기본 태그들을 생성합니다.
  /// 
  /// Returns 생성된 태그 개수
  static Future<int> initializeDefaultTags() async {
    try {
      // 이미 초기화되었는지 확인
      final isInitialized = await TagInitializer.isInitialized();
      if (isInitialized) {
        debugPrint('기본 태그 이미 초기화됨');
        return 0;
      }

      debugPrint('기본 태그 초기화 시작...');
      int createdCount = 0;

      // 각 기본 태그 생성
      for (final tagName in _defaultTags) {
        try {
          // getOrCreateTag는 이미 존재하면 기존 ID를 반환
          await TagRepository.getOrCreateTag(tagName);
          createdCount++;
          debugPrint('태그 생성: $tagName');
        } catch (e) {
          debugPrint('태그 생성 실패 ($tagName): $e');
          // 계속 진행
        }
      }

      // 초기화 완료 플래그 저장
      await setInitialized(true);
      
      debugPrint('기본 태그 초기화 완료: $createdCount개 생성됨');
      return createdCount;
    } catch (e) {
      debugPrint('기본 태그 초기화 실패: $e');
      rethrow;
    }
  }

  /// 태그 초기화를 재설정합니다.
  /// 
  /// 주의: 이 메서드는 플래그만 제거합니다.
  /// 실제 태그 데이터는 삭제하지 않습니다.
  static Future<void> reset() async {
    await setInitialized(false);
    debugPrint('태그 초기화 플래그 제거됨');
  }

  /// 모든 기본 태그가 존재하는지 확인합니다.
  /// 
  /// Returns 모든 태그가 존재하면 true
  static Future<bool> verifyDefaultTags() async {
    for (final tagName in _defaultTags) {
      final tag = await TagRepository.getTagByName(tagName);
      if (tag == null) {
        return false;
      }
    }
    return true;
  }
}
