import '../database/movie_database.dart';
import 'package:sqflite/sqflite.dart';

/// 태그 데이터를 관리하는 Repository 클래스
/// 
/// 태그의 조회, 생성, 기록과의 매핑을 처리합니다.
class TagRepository {
  /// 태그를 조회하거나 없으면 생성합니다.
  /// 
  /// [name] 태그 이름
  /// Returns 태그 ID
  static Future<int> getOrCreateTag(String name) async {
    final db = await MovieDatabase.database;

    // 먼저 조회
    final existing = await db.query(
      MovieDatabase.tableTags,
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      return existing.first['tag_id'] as int;
    }

    // 없으면 생성
    final tagId = await db.insert(
      MovieDatabase.tableTags,
      {'name': name},
    );

    return tagId;
  }

  /// 모든 태그를 조회합니다.
  /// 
  /// Returns 태그 목록 (Map: tag_id, name)
  static Future<List<Map<String, dynamic>>> getAllTags() async {
    final db = await MovieDatabase.database;
    return await db.query(
      MovieDatabase.tableTags,
      orderBy: 'name ASC',
    );
  }

  /// 태그 이름 목록을 반환합니다.
  /// 
  /// Returns 태그 이름 리스트
  static Future<List<String>> getAllTagNames() async {
    final tags = await getAllTags();
    return tags.map((tag) => tag['name'] as String).toList();
  }

  /// 특정 기록의 태그를 조회합니다.
  /// 
  /// [recordId] 기록 ID
  /// Returns 태그 이름 리스트
  static Future<List<String>> getTagsByRecordId(int recordId) async {
    final db = await MovieDatabase.database;

    // JOIN으로 태그 이름 가져오기
    final result = await db.rawQuery('''
      SELECT t.name
      FROM ${MovieDatabase.tableTags} t
      INNER JOIN ${MovieDatabase.tableRecordTags} rt ON t.tag_id = rt.tag_id
      WHERE rt.record_id = ?
      ORDER BY t.name ASC
    ''', [recordId]);

    return result.map((row) => row['name'] as String).toList();
  }

  /// 기록에 태그를 추가합니다.
  /// 
  /// [recordId] 기록 ID
  /// [tagName] 태그 이름
  /// 태그가 없으면 자동 생성됩니다.
  static Future<void> addTagToRecord(int recordId, String tagName) async {
    final db = await MovieDatabase.database;

    // 태그 조회 또는 생성
    final tagId = await getOrCreateTag(tagName);

    // 매핑 추가 (이미 있으면 무시)
    try {
      await db.insert(
        MovieDatabase.tableRecordTags,
        {
          'record_id': recordId,
          'tag_id': tagId,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } catch (e) {
      // UNIQUE 제약 위반 시 무시 (이미 매핑되어 있음)
    }
  }

  /// 기록에서 태그를 제거합니다.
  /// 
  /// [recordId] 기록 ID
  /// [tagName] 태그 이름
  static Future<void> removeTagFromRecord(int recordId, String tagName) async {
    final db = await MovieDatabase.database;

    // 태그 ID 조회
    final tag = await db.query(
      MovieDatabase.tableTags,
      where: 'name = ?',
      whereArgs: [tagName],
      limit: 1,
    );

    if (tag.isEmpty) return; // 태그가 없으면 스킵

    final tagId = tag.first['tag_id'] as int;

    // 매핑 제거
    await db.delete(
      MovieDatabase.tableRecordTags,
      where: 'record_id = ? AND tag_id = ?',
      whereArgs: [recordId, tagId],
    );
  }

  /// 기록의 모든 태그를 제거합니다.
  /// 
  /// [recordId] 기록 ID
  static Future<void> removeAllTagsFromRecord(int recordId) async {
    final db = await MovieDatabase.database;
    await db.delete(
      MovieDatabase.tableRecordTags,
      where: 'record_id = ?',
      whereArgs: [recordId],
    );
  }

  /// 기록에 태그 목록을 설정합니다 (기존 태그를 모두 제거하고 새로 추가).
  /// 
  /// [recordId] 기록 ID
  /// [tagNames] 태그 이름 리스트
  static Future<void> setTagsForRecord(int recordId, List<String> tagNames) async {
    // 기존 태그 모두 제거
    await removeAllTagsFromRecord(recordId);

    // 새 태그 추가
    for (final tagName in tagNames) {
      await addTagToRecord(recordId, tagName);
    }
  }

  /// 기본 태그들을 초기화합니다.
  /// 
  /// 기본 태그: "혼자", "친구", "가족", "극장", "OTT"
  static Future<void> initializeDefaultTags() async {
    const defaultTags = ['혼자', '친구', '가족', '극장', 'OTT'];

    for (final tagName in defaultTags) {
      await getOrCreateTag(tagName);
    }
  }

  /// 태그 ID로 태그 이름을 조회합니다.
  /// 
  /// [tagId] 태그 ID
  /// Returns 태그 이름 (없으면 null)
  static Future<String?> getTagNameById(int tagId) async {
    final db = await MovieDatabase.database;
    final result = await db.query(
      MovieDatabase.tableTags,
      where: 'tag_id = ?',
      whereArgs: [tagId],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return result.first['name'] as String;
  }

  /// 태그를 삭제합니다.
  /// 
  /// [tagName] 태그 이름
  /// 주의: 기록에 사용 중인 태그는 삭제할 수 없습니다 (외래 키 제약).
  static Future<bool> deleteTag(String tagName) async {
    final db = await MovieDatabase.database;

    // 태그 ID 조회
    final tag = await db.query(
      MovieDatabase.tableTags,
      where: 'name = ?',
      whereArgs: [tagName],
      limit: 1,
    );

    if (tag.isEmpty) return false;

    final tagId = tag.first['tag_id'] as int;

    // 기록에 사용 중인지 확인
    final recordTags = await db.query(
      MovieDatabase.tableRecordTags,
      where: 'tag_id = ?',
      whereArgs: [tagId],
      limit: 1,
    );

    if (recordTags.isNotEmpty) {
      // 사용 중인 태그는 삭제할 수 없음
      return false;
    }

    // 태그 삭제
    await db.delete(
      MovieDatabase.tableTags,
      where: 'tag_id = ?',
      whereArgs: [tagId],
    );

    return true;
  }

  /// 태그 사용 횟수를 반환합니다.
  /// 
  /// [tagName] 태그 이름
  /// Returns 해당 태그를 사용한 기록 개수
  static Future<int> getTagUsageCount(String tagName) async {
    final db = await MovieDatabase.database;

    // 태그 ID 조회
    final tag = await db.query(
      MovieDatabase.tableTags,
      where: 'name = ?',
      whereArgs: [tagName],
      limit: 1,
    );

    if (tag.isEmpty) return 0;

    final tagId = tag.first['tag_id'] as int;

    // 사용 횟수 조회
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${MovieDatabase.tableRecordTags} WHERE tag_id = ?',
      [tagId],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }
}
