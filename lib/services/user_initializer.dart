import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/user_repository.dart';

/// 사용자 초기화 서비스
/// 
/// 앱 최초 실행 시 기본 사용자(Guest)를 생성하고 관리합니다.
class UserInitializer {
  /// SharedPreferences 키
  static const String _defaultUserIdKey = 'default_user_id';

  /// 기본 사용자 ID를 가져옵니다.
  /// 
  /// Returns 사용자 ID (없으면 null)
  static Future<int?> getDefaultUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_defaultUserIdKey);
    return userId;
  }

  /// 기본 사용자 ID를 저장합니다.
  /// 
  /// [userId] 저장할 사용자 ID
  static Future<void> setDefaultUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_defaultUserIdKey, userId);
  }

  /// 기본 사용자를 초기화합니다.
  /// 
  /// 이미 초기화되어 있으면 기존 사용자 ID를 반환하고,
  /// 없으면 새로 생성합니다.
  /// 
  /// Returns 기본 사용자 ID
  static Future<int> initializeDefaultUser() async {
    try {
      // 기존 사용자 ID 확인
      final existingUserId = await getDefaultUserId();
      if (existingUserId != null) {
        // 기존 사용자가 존재하는지 확인
        final user = await UserRepository.getUserById(existingUserId);
        if (user != null) {
          debugPrint('기본 사용자 이미 존재: ID=$existingUserId');
          return existingUserId;
        } else {
          // 사용자가 삭제된 경우 플래그 제거
          await _clearDefaultUserId();
        }
      }

      // 기본 사용자 생성 또는 조회
      debugPrint('기본 사용자 초기화 시작...');
      final userId = await UserRepository.getOrCreateDefaultUser();
      
      // 사용자 ID 저장
      await setDefaultUserId(userId);
      
      debugPrint('기본 사용자 초기화 완료: ID=$userId');
      return userId;
    } catch (e) {
      debugPrint('기본 사용자 초기화 실패: $e');
      rethrow;
    }
  }

  /// 기본 사용자 ID를 초기화합니다.
  /// 
  /// 주의: 이 메서드는 SharedPreferences의 플래그만 제거합니다.
  /// 실제 사용자 데이터는 삭제하지 않습니다.
  static Future<void> _clearDefaultUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_defaultUserIdKey);
  }

  /// 기본 사용자가 초기화되었는지 확인합니다.
  /// 
  /// Returns 초기화되었으면 true
  static Future<bool> isInitialized() async {
    final userId = await getDefaultUserId();
    if (userId == null) return false;
    
    // 실제로 사용자가 존재하는지 확인
    final user = await UserRepository.getUserById(userId);
    return user != null;
  }
}
