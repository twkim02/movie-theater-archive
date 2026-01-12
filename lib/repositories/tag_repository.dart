import '../database/movie_database.dart';

/// 태그 데이터를 관리하는 Repository 클래스
/// 
/// DB와의 상호작용을 추상화하여 비즈니스 로직과 데이터 접근을 분리합니다.
class TagRepository {
  /// 태그를 조회하거나 생성합니다.
  /// 
  /// [name] 태그 이름
  /// Returns 태그 ID
  static Future<int> getOrCreateTag(String name) async {
    return await MovieDatabase.getOrCreateTag(name);
  }

  /// 이름으로 태그를 조회합니다.
  /// 
  /// [name] 태그 이름
  /// Returns 태그 정보 (없으면 null)
  static Future<Map<String, dynamic>?> getTagByName(String name) async {
    return await MovieDatabase.getTagByName(name);
  }

  /// 모든 태그를 조회합니다.
  /// 
  /// Returns 태그 목록
  static Future<List<Map<String, dynamic>>> getAllTags() async {
    return await MovieDatabase.getAllTags();
  }

  /// 태그를 생성합니다.
  /// 
  /// [name] 태그 이름
  /// Returns 생성된 태그 ID
  static Future<int> createTag(String name) async {
    return await MovieDatabase.insertTag(name);
  }
}
