import '../database/movie_database.dart';

/// 사용자 데이터를 관리하는 Repository 클래스
/// 
/// DB와의 상호작용을 추상화하여 비즈니스 로직과 데이터 접근을 분리합니다.
class UserRepository {
  /// 기본 사용자(Guest)를 조회하거나 생성합니다.
  /// 
  /// Returns 사용자 ID
  static Future<int> getOrCreateDefaultUser() async {
    return await MovieDatabase.getOrCreateDefaultUser();
  }

  /// ID로 사용자를 조회합니다.
  /// 
  /// [userId] 사용자 ID
  /// Returns 사용자 정보 (없으면 null)
  static Future<Map<String, dynamic>?> getUserById(int userId) async {
    return await MovieDatabase.getUserById(userId);
  }

  /// 사용자를 생성합니다.
  /// 
  /// [nickname] 닉네임
  /// [email] 이메일 (선택사항)
  /// Returns 생성된 사용자 ID
  static Future<int> createUser({
    required String nickname,
    String? email,
  }) async {
    return await MovieDatabase.insertUser(
      nickname: nickname,
      email: email,
    );
  }
}
