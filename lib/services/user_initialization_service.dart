import '../database/movie_database.dart';
import '../repositories/tag_repository.dart';

/// 사용자 초기화 서비스
/// 
/// 앱 최초 실행 시 기본 사용자(Guest)와 기본 태그를 초기화합니다.
class UserInitializationService {
  /// 기본 사용자 ID (항상 1)
  static const int defaultUserId = 1;

  /// 기본 사용자(Guest)를 초기화합니다.
  /// 
  /// 이미 존재하면 생성하지 않습니다.
  /// Returns 사용자 ID (항상 1)
  static Future<int> initializeDefaultUser() async {
    return await MovieDatabase.createDefaultUser();
  }

  /// 기본 사용자 ID를 반환합니다.
  /// 
  /// Returns 기본 사용자 ID (항상 1)
  static int getDefaultUserId() {
    return defaultUserId;
  }

  /// 기본 사용자가 존재하는지 확인합니다.
  /// 
  /// Returns 기본 사용자가 있으면 true
  static Future<bool> hasDefaultUser() async {
    return await MovieDatabase.hasDefaultUser();
  }

  /// 앱 초기화 시 필요한 모든 기본 데이터를 초기화합니다.
  /// 
  /// - 기본 사용자(Guest) 생성
  /// - 기본 태그 초기화
  static Future<void> initializeAll() async {
    // 기본 사용자 생성
    await initializeDefaultUser();

    // 기본 태그 초기화
    await TagRepository.initializeDefaultTags();
  }
}
