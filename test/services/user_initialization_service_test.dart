import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:movie_diary_app/database/movie_database.dart';
import 'package:movie_diary_app/services/user_initialization_service.dart';
import 'package:movie_diary_app/repositories/tag_repository.dart';

void main() {
  // 테스트용 SQLite 초기화
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('UserInitializationService 테스트', () {
    setUp(() async {
      // 각 테스트 전에 DB 초기화 및 정리
      await MovieDatabase.close();
      final db = await MovieDatabase.database;
      
      // 기존 사용자 삭제
      await db.delete(MovieDatabase.tableUsers);
      
      // SQLite 시퀀스 리셋 (AUTOINCREMENT를 1로 리셋)
      await db.rawUpdate('DELETE FROM sqlite_sequence WHERE name = ?', [MovieDatabase.tableUsers]);
    });

    tearDown(() async {
      // 각 테스트 후 DB 정리
      await MovieDatabase.close();
    });

    test('기본 사용자 초기화', () async {
      // When: 기본 사용자 초기화
      final userId = await UserInitializationService.initializeDefaultUser();

      // Then: 사용자 ID가 1이어야 함
      expect(userId, 1);

      // Then: 사용자가 존재해야 함
      final user = await MovieDatabase.getUserById(1);
      expect(user, isNotNull);
      expect(user!['nickname'], 'Guest');
      expect(user['email'], isNull);
    });

    test('기본 사용자 중복 생성 방지', () async {
      // Given: 기본 사용자 생성
      await UserInitializationService.initializeDefaultUser();

      // When: 다시 초기화 시도
      final userId = await UserInitializationService.initializeDefaultUser();

      // Then: 같은 사용자 ID가 반환되어야 함
      expect(userId, 1);

      // Then: 사용자가 하나만 있어야 함
      final db = await MovieDatabase.database;
      final users = await db.query(MovieDatabase.tableUsers);
      expect(users.length, 1);
    });

    test('기본 사용자 ID 반환', () {
      // When: 기본 사용자 ID 조회
      final userId = UserInitializationService.getDefaultUserId();

      // Then: 항상 1이어야 함
      expect(userId, 1);
    });

    test('기본 사용자 존재 확인', () async {
      // Given: 기본 사용자가 없는 상태
      // When: 존재 확인
      final existsBefore = await UserInitializationService.hasDefaultUser();

      // Then: 존재하지 않아야 함
      expect(existsBefore, false);

      // Given: 기본 사용자 생성
      await UserInitializationService.initializeDefaultUser();

      // When: 존재 확인
      final existsAfter = await UserInitializationService.hasDefaultUser();

      // Then: 존재해야 함
      expect(existsAfter, true);
    });

    test('전체 초기화 (사용자 + 태그)', () async {
      // When: 전체 초기화
      await UserInitializationService.initializeAll();

      // Then: 기본 사용자가 생성되어야 함
      final user = await MovieDatabase.getUserById(1);
      expect(user, isNotNull);
      expect(user!['nickname'], 'Guest');

      // Then: 기본 태그들이 생성되어야 함
      final tagNames = await TagRepository.getAllTagNames();
      expect(tagNames, contains('혼자'));
      expect(tagNames, contains('친구'));
      expect(tagNames, contains('가족'));
      expect(tagNames, contains('극장'));
      expect(tagNames, contains('OTT'));
    });

    test('기본 사용자 정보 확인', () async {
      // Given: 기본 사용자 생성
      await UserInitializationService.initializeDefaultUser();

      // When: 사용자 정보 조회
      final user = await MovieDatabase.getUserById(1);

      // Then: 올바른 정보가 있어야 함
      expect(user, isNotNull);
      expect(user!['user_id'], 1);
      expect(user['nickname'], 'Guest');
      expect(user['email'], isNull);
      expect(user['created_at'], isNotNull);
    });

    test('여러 번 초기화해도 안전', () async {
      // When: 여러 번 초기화
      await UserInitializationService.initializeAll();
      await UserInitializationService.initializeAll();
      await UserInitializationService.initializeAll();

      // Then: 사용자가 하나만 있어야 함
      final db = await MovieDatabase.database;
      final users = await db.query(MovieDatabase.tableUsers);
      expect(users.length, 1);

      // Then: 기본 태그가 5개만 있어야 함
      final tagNames = await TagRepository.getAllTagNames();
      final defaultTags = ['혼자', '친구', '가족', '극장', 'OTT'];
      for (final tag in defaultTags) {
        expect(tagNames.where((t) => t == tag).length, 1);
      }
    });
  });
}
