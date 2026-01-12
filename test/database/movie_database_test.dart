import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:movie_diary_app/database/movie_database.dart';
import 'package:movie_diary_app/models/movie.dart';

void main() {
  // 테스트용 SQLite 초기화
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('MovieDatabase 스키마 확장 테스트', () {
    late Database db;

    setUp(() async {
      // 각 테스트 전에 새 DB 인스턴스 생성
      db = await MovieDatabase.database;
    });

    tearDown(() async {
      // 각 테스트 후 DB 닫기
      await MovieDatabase.close();
    });

    test('DB 버전이 2인지 확인', () async {
      // When: DB 버전 확인
      final version = await db.getVersion();
      
      // Then: DB 버전이 2여야 함
      expect(version, 2);
    });

    test('모든 테이블이 생성되었는지 확인', () async {
      // When: 모든 테이블 목록 조회
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
      );

      final tableNames = tables.map((t) => t['name'] as String).toList();

      // Then: 필요한 모든 테이블이 존재해야 함
      expect(tableNames, contains(MovieDatabase.tableMovies));
      expect(tableNames, contains(MovieDatabase.tableUsers));
      expect(tableNames, contains(MovieDatabase.tableRecords));
      expect(tableNames, contains(MovieDatabase.tableTags));
      expect(tableNames, contains(MovieDatabase.tableRecordTags));
      expect(tableNames, contains(MovieDatabase.tableWishlist));
    });

    test('users 테이블 스키마 확인', () async {
      // When: users 테이블 스키마 조회
      final schema = await db.rawQuery(
        "PRAGMA table_info(${MovieDatabase.tableUsers})",
      );

      final columns = schema.map((s) => s['name'] as String).toList();

      // Then: 필요한 컬럼들이 모두 있어야 함
      expect(columns, contains('user_id'));
      expect(columns, contains('nickname'));
      expect(columns, contains('email'));
      expect(columns, contains('created_at'));
    });

    test('records 테이블 스키마 확인', () async {
      // When: records 테이블 스키마 조회
      final schema = await db.rawQuery(
        "PRAGMA table_info(${MovieDatabase.tableRecords})",
      );

      final columns = schema.map((s) => s['name'] as String).toList();

      // Then: 필요한 컬럼들이 모두 있어야 함
      expect(columns, contains('record_id'));
      expect(columns, contains('user_id'));
      expect(columns, contains('movie_id'));
      expect(columns, contains('rating'));
      expect(columns, contains('watch_date'));
      expect(columns, contains('one_liner'));
      expect(columns, contains('detailed_review'));
      expect(columns, contains('photo_path'));
      expect(columns, contains('created_at'));
    });

    test('tags 테이블 스키마 확인', () async {
      // When: tags 테이블 스키마 조회
      final schema = await db.rawQuery(
        "PRAGMA table_info(${MovieDatabase.tableTags})",
      );

      final columns = schema.map((s) => s['name'] as String).toList();

      // Then: 필요한 컬럼들이 모두 있어야 함
      expect(columns, contains('tag_id'));
      expect(columns, contains('name'));
    });

    test('record_tags 테이블 스키마 확인', () async {
      // When: record_tags 테이블 스키마 조회
      final schema = await db.rawQuery(
        "PRAGMA table_info(${MovieDatabase.tableRecordTags})",
      );

      final columns = schema.map((s) => s['name'] as String).toList();

      // Then: 필요한 컬럼들이 모두 있어야 함
      expect(columns, contains('id'));
      expect(columns, contains('record_id'));
      expect(columns, contains('tag_id'));
    });

    test('wishlist 테이블 스키마 확인', () async {
      // When: wishlist 테이블 스키마 조회
      final schema = await db.rawQuery(
        "PRAGMA table_info(${MovieDatabase.tableWishlist})",
      );

      final columns = schema.map((s) => s['name'] as String).toList();

      // Then: 필요한 컬럼들이 모두 있어야 함
      expect(columns, contains('id'));
      expect(columns, contains('user_id'));
      expect(columns, contains('movie_id'));
      expect(columns, contains('saved_at'));
    });

    test('인덱스가 제대로 생성되었는지 확인', () async {
      // When: 인덱스 목록 조회
      final indexes = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND name NOT LIKE 'sqlite_%'",
      );

      final indexNames = indexes.map((i) => i['name'] as String).toList();

      // Then: 필요한 인덱스들이 모두 있어야 함
      // Movies 테이블 인덱스
      expect(indexNames, contains('idx_movies_title'));
      expect(indexNames, contains('idx_movies_is_recent'));
      expect(indexNames, contains('idx_movies_release_date'));

      // Records 테이블 인덱스
      expect(indexNames, contains('idx_records_user_id'));
      expect(indexNames, contains('idx_records_movie_id'));
      expect(indexNames, contains('idx_records_watch_date'));

      // Wishlist 테이블 인덱스
      expect(indexNames, contains('idx_wishlist_user_id'));
      expect(indexNames, contains('idx_wishlist_movie_id'));

      // Record_Tags 테이블 인덱스
      expect(indexNames, contains('idx_record_tags_record_id'));
      expect(indexNames, contains('idx_record_tags_tag_id'));
    });

    test('외래 키 제약 조건이 활성화되어 있는지 확인', () async {
      // When: 외래 키 설정 확인
      final result = await db.rawQuery('PRAGMA foreign_keys');
      final foreignKeysEnabled = (result.first['foreign_keys'] as int) == 1;

      // Then: 외래 키가 활성화되어 있어야 함
      expect(foreignKeysEnabled, true);
    });

    test('records 테이블의 외래 키 제약 확인', () async {
      // Given: movies 테이블에 영화가 있어야 함
      final testMovie = Movie(
        id: 'test_movie_1',
        title: '테스트 영화',
        posterUrl: 'https://example.com/poster.jpg',
        genres: ['액션'],
        releaseDate: '2024-01-01',
        runtime: 120,
        voteAverage: 4.5,
        isRecent: false,
      );
      await MovieDatabase.insertMovie(testMovie);

      // Given: users 테이블에 사용자가 있어야 함
      await db.insert(
        MovieDatabase.tableUsers,
        {
          'nickname': '테스트 사용자',
          'email': null,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
      );

      // When: 유효한 외래 키로 기록 추가
      final recordId = await db.insert(
        MovieDatabase.tableRecords,
        {
          'user_id': 1,
          'movie_id': 'test_movie_1',
          'rating': 4.5,
          'watch_date': '2024-01-01',
          'one_liner': '테스트 한줄평',
          'detailed_review': null,
          'photo_path': null,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
      );

      // Then: 기록이 성공적으로 추가되어야 함
      expect(recordId, greaterThan(0));

      // When: 존재하지 않는 movie_id로 기록 추가 시도
      // Then: 외래 키 제약으로 인해 실패해야 함
      expect(
        () async => await db.insert(
          MovieDatabase.tableRecords,
          {
            'user_id': 1,
            'movie_id': 'nonexistent_movie',
            'rating': 4.5,
            'watch_date': '2024-01-01',
            'created_at': DateTime.now().millisecondsSinceEpoch,
          },
        ),
        throwsException,
      );
    });

    test('wishlist 테이블의 UNIQUE 제약 확인', () async {
      // Given: movies 테이블에 영화가 있어야 함
      final testMovie = Movie(
        id: 'test_movie_2',
        title: '테스트 영화 2',
        posterUrl: 'https://example.com/poster2.jpg',
        genres: ['드라마'],
        releaseDate: '2024-02-01',
        runtime: 110,
        voteAverage: 4.0,
        isRecent: false,
      );
      await MovieDatabase.insertMovie(testMovie);

      // Given: users 테이블에 사용자가 있어야 함
      await db.insert(
        MovieDatabase.tableUsers,
        {
          'nickname': '테스트 사용자 2',
          'email': null,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
      );

      // When: 위시리스트에 영화 추가
      final wishlistId1 = await db.insert(
        MovieDatabase.tableWishlist,
        {
          'user_id': 1,
          'movie_id': 'test_movie_2',
          'saved_at': DateTime.now().millisecondsSinceEpoch,
        },
      );

      // Then: 성공적으로 추가되어야 함
      expect(wishlistId1, greaterThan(0));

      // When: 같은 사용자가 같은 영화를 다시 추가 시도
      // Then: UNIQUE 제약으로 인해 실패해야 함
      expect(
        () async => await db.insert(
          MovieDatabase.tableWishlist,
          {
            'user_id': 1,
            'movie_id': 'test_movie_2',
            'saved_at': DateTime.now().millisecondsSinceEpoch,
          },
        ),
        throwsException,
      );
    });

    test('record_tags 테이블의 UNIQUE 제약 확인', () async {
      // Given: movies 테이블에 영화가 있어야 함
      final testMovie = Movie(
        id: 'test_movie_for_tags',
        title: '태그 테스트 영화',
        posterUrl: 'https://example.com/poster.jpg',
        genres: ['액션'],
        releaseDate: '2024-01-01',
        runtime: 120,
        voteAverage: 4.5,
        isRecent: false,
      );
      await MovieDatabase.insertMovie(testMovie);

      // Given: users 테이블에 사용자가 있어야 함
      final userId = await db.insert(
        MovieDatabase.tableUsers,
        {
          'nickname': '태그 테스트 사용자',
          'email': null,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
      );

      // Given: records 테이블에 기록이 있어야 함
      final recordId = await db.insert(
        MovieDatabase.tableRecords,
        {
          'user_id': userId,
          'movie_id': 'test_movie_for_tags',
          'rating': 4.5,
          'watch_date': '2024-01-01',
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
      );

      // Given: tags 테이블에 태그가 있어야 함 (고유한 이름 사용 - 타임스탬프 포함)
      final uniqueTagName = '테스트 태그 ${DateTime.now().millisecondsSinceEpoch}';
      final tagId1 = await db.insert(
        MovieDatabase.tableTags,
        {'name': uniqueTagName},
      );

      // When: 기록에 태그 추가
      final recordTagId1 = await db.insert(
        MovieDatabase.tableRecordTags,
        {
          'record_id': recordId,
          'tag_id': tagId1,
        },
      );

      // Then: 성공적으로 추가되어야 함
      expect(recordTagId1, greaterThan(0));

      // When: 같은 기록에 같은 태그를 다시 추가 시도
      // Then: UNIQUE 제약으로 인해 실패해야 함
      expect(
        () async => await db.insert(
          MovieDatabase.tableRecordTags,
          {
            'record_id': recordId,
            'tag_id': tagId1,
          },
        ),
        throwsException,
      );
    });

    test('CASCADE 삭제가 작동하는지 확인', () async {
      // Given: 영화, 사용자, 기록이 존재
      final testMovie = Movie(
        id: 'test_movie_3',
        title: '테스트 영화 3',
        posterUrl: 'https://example.com/poster3.jpg',
        genres: ['코미디'],
        releaseDate: '2024-03-01',
        runtime: 100,
        voteAverage: 3.5,
        isRecent: false,
      );
      await MovieDatabase.insertMovie(testMovie);

      final userId = await db.insert(
        MovieDatabase.tableUsers,
        {
          'nickname': '테스트 사용자 3',
          'email': null,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
      );

      final recordId = await db.insert(
        MovieDatabase.tableRecords,
        {
          'user_id': userId,
          'movie_id': 'test_movie_3',
          'rating': 3.5,
          'watch_date': '2024-03-01',
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
      );

      // When: 영화 삭제
      await MovieDatabase.deleteMovie('test_movie_3');

      // Then: 관련 기록도 함께 삭제되어야 함 (CASCADE)
      final remainingRecords = await db.query(
        MovieDatabase.tableRecords,
        where: 'record_id = ?',
        whereArgs: [recordId],
      );
      expect(remainingRecords.isEmpty, true);
    });
  });
}
