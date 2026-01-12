import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/movie.dart';
import '../models/record.dart';
import '../repositories/tag_repository.dart';
import 'dart:convert';

/// 영화 정보를 저장하는 SQLite 데이터베이스 헬퍼 클래스
/// 
/// 영화, 사용자, 기록, 태그, 위시리스트 정보를 저장합니다.
class MovieDatabase {
  static Database? _database;
  static const String _databaseName = 'movie_diary.db';
  static const int _databaseVersion = 2;

  // 테이블 이름 (다른 클래스에서도 사용 가능하도록 public)
  static const String tableMovies = 'movies';
  static const String tableUsers = 'users';
  static const String tableRecords = 'records';
  static const String tableTags = 'tags';
  static const String tableRecordTags = 'record_tags';
  static const String tableWishlist = 'wishlist';

  /// 데이터베이스 인스턴스를 반환합니다.
  /// 없으면 생성하고, 있으면 기존 인스턴스를 반환합니다.
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 데이터베이스를 초기화합니다.
  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        // 외래 키 제약 조건 활성화
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  /// 데이터베이스 테이블을 생성합니다.
  static Future<void> _onCreate(Database db, int version) async {
    // Movies 테이블 생성
    await db.execute('''
      CREATE TABLE ${tableMovies} (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        poster_url TEXT,
        release_date TEXT,
        runtime INTEGER,
        vote_average REAL,
        is_recent INTEGER NOT NULL DEFAULT 0,
        genres TEXT,
        last_updated INTEGER NOT NULL
      )
    ''');

    // Users 테이블 생성
    await db.execute('''
      CREATE TABLE ${tableUsers} (
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        nickname TEXT NOT NULL,
        email TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    // Tags 테이블 생성
    await db.execute('''
      CREATE TABLE ${tableTags} (
        tag_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    // Records 테이블 생성
    await db.execute('''
      CREATE TABLE ${tableRecords} (
        record_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        movie_id TEXT NOT NULL,
        rating REAL NOT NULL,
        watch_date TEXT NOT NULL,
        one_liner TEXT,
        detailed_review TEXT,
        photo_path TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES ${tableUsers}(user_id) ON DELETE CASCADE,
        FOREIGN KEY (movie_id) REFERENCES ${tableMovies}(id) ON DELETE CASCADE
      )
    ''');

    // Record_Tags 매핑 테이블 생성
    await db.execute('''
      CREATE TABLE ${tableRecordTags} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        record_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        FOREIGN KEY (record_id) REFERENCES ${tableRecords}(record_id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES ${tableTags}(tag_id) ON DELETE CASCADE,
        UNIQUE(record_id, tag_id)
      )
    ''');

    // Wishlist 테이블 생성
    await db.execute('''
      CREATE TABLE ${tableWishlist} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        movie_id TEXT NOT NULL,
        saved_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES ${tableUsers}(user_id) ON DELETE CASCADE,
        FOREIGN KEY (movie_id) REFERENCES ${tableMovies}(id) ON DELETE CASCADE,
        UNIQUE(user_id, movie_id)
      )
    ''');

    // 인덱스 생성
    await _createIndexes(db);
  }

  /// 인덱스를 생성합니다.
  /// [onlyNewTables]가 true이면 새로 추가된 테이블의 인덱스만 생성합니다.
  static Future<void> _createIndexes(Database db, {bool onlyNewTables = false}) async {
    if (!onlyNewTables) {
      // Movies 테이블 인덱스 (기존 테이블)
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_movies_title ON ${tableMovies}(title)
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_movies_is_recent ON ${tableMovies}(is_recent)
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_movies_release_date ON ${tableMovies}(release_date)
      ''');
    }

    // Records 테이블 인덱스 (새 테이블)
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_records_user_id ON ${tableRecords}(user_id)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_records_movie_id ON ${tableRecords}(movie_id)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_records_watch_date ON ${tableRecords}(watch_date)
    ''');

    // Wishlist 테이블 인덱스 (새 테이블)
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_wishlist_user_id ON ${tableWishlist}(user_id)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_wishlist_movie_id ON ${tableWishlist}(movie_id)
    ''');

    // Record_Tags 테이블 인덱스 (새 테이블)
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_record_tags_record_id ON ${tableRecordTags}(record_id)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_record_tags_tag_id ON ${tableRecordTags}(tag_id)
    ''');
  }

  /// 데이터베이스 업그레이드 로직
  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // 버전 1에서 2로 업그레이드: 새 테이블 추가
    if (oldVersion < 2) {
      // Users 테이블 생성
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${tableUsers} (
          user_id INTEGER PRIMARY KEY AUTOINCREMENT,
          nickname TEXT NOT NULL,
          email TEXT,
          created_at INTEGER NOT NULL
        )
      ''');

      // Tags 테이블 생성
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${tableTags} (
          tag_id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE
        )
      ''');

      // Records 테이블 생성
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${tableRecords} (
          record_id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          movie_id TEXT NOT NULL,
          rating REAL NOT NULL,
          watch_date TEXT NOT NULL,
          one_liner TEXT,
          detailed_review TEXT,
          photo_path TEXT,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (user_id) REFERENCES ${tableUsers}(user_id) ON DELETE CASCADE,
          FOREIGN KEY (movie_id) REFERENCES ${tableMovies}(id) ON DELETE CASCADE
        )
      ''');

      // Record_Tags 매핑 테이블 생성
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${tableRecordTags} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          record_id INTEGER NOT NULL,
          tag_id INTEGER NOT NULL,
          FOREIGN KEY (record_id) REFERENCES ${tableRecords}(record_id) ON DELETE CASCADE,
          FOREIGN KEY (tag_id) REFERENCES ${tableTags}(tag_id) ON DELETE CASCADE,
          UNIQUE(record_id, tag_id)
        )
      ''');

      // Wishlist 테이블 생성
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${tableWishlist} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          movie_id TEXT NOT NULL,
          saved_at INTEGER NOT NULL,
          FOREIGN KEY (user_id) REFERENCES ${tableUsers}(user_id) ON DELETE CASCADE,
          FOREIGN KEY (movie_id) REFERENCES ${tableMovies}(id) ON DELETE CASCADE,
          UNIQUE(user_id, movie_id)
        )
      ''');

      // 새 테이블의 인덱스만 생성 (기존 movies 인덱스는 이미 존재)
      await _createIndexes(db, onlyNewTables: true);
    }

    // 향후 버전 업그레이드 시 여기에 추가
    // if (oldVersion < 3) {
    //   // 버전 3 마이그레이션 로직
    // }
  }

  /// Movie 객체를 DB 저장용 Map으로 변환
  static Map<String, dynamic> _movieToMap(Movie movie) {
    return {
      'id': movie.id,
      'title': movie.title,
      'poster_url': movie.posterUrl,
      'release_date': movie.releaseDate,
      'runtime': movie.runtime,
      'vote_average': movie.voteAverage,
      'is_recent': movie.isRecent ? 1 : 0,
      'genres': jsonEncode(movie.genres), // List<String>을 JSON 문자열로 변환
      'last_updated': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// DB Map을 Movie 객체로 변환
  static Movie _mapToMovie(Map<String, dynamic> map) {
    return Movie(
      id: map['id'] as String,
      title: map['title'] as String,
      posterUrl: map['poster_url'] as String? ?? '',
      releaseDate: map['release_date'] as String? ?? '',
      runtime: map['runtime'] as int? ?? 0,
      voteAverage: (map['vote_average'] as num?)?.toDouble() ?? 0.0,
      isRecent: (map['is_recent'] as int? ?? 0) == 1,
      genres: map['genres'] != null
          ? List<String>.from(jsonDecode(map['genres'] as String))
          : [],
    );
  }

  /// 영화를 데이터베이스에 추가합니다.
  /// 이미 존재하면 업데이트합니다.
  static Future<void> insertMovie(Movie movie) async {
    final db = await database;
    await db.insert(
      tableMovies,
      _movieToMap(movie),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 여러 영화를 일괄 추가합니다.
  /// 트랜잭션을 사용하여 성능을 최적화합니다.
  static Future<void> insertMovies(List<Movie> movies) async {
    final db = await database;
    final batch = db.batch();

    for (final movie in movies) {
      batch.insert(
        tableMovies,
        _movieToMap(movie),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// ID로 영화를 조회합니다.
  static Future<Movie?> getMovieById(String id) async {
    final db = await database;
    final maps = await db.query(
      tableMovies,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return _mapToMovie(maps.first);
  }

  /// 모든 영화를 조회합니다.
  static Future<List<Movie>> getAllMovies() async {
    final db = await database;
    final maps = await db.query(
      tableMovies,
      orderBy: 'release_date DESC',
    );

    return maps.map((map) => _mapToMovie(map)).toList();
  }

  /// 최근 상영 중인 영화를 조회합니다.
  static Future<List<Movie>> getRecentMovies() async {
    final db = await database;
    final maps = await db.query(
      tableMovies,
      where: 'is_recent = ?',
      whereArgs: [1],
      orderBy: 'release_date DESC',
    );

    return maps.map((map) => _mapToMovie(map)).toList();
  }

  /// 과거 영화(최근 상영 아님)를 조회합니다.
  static Future<List<Movie>> getNonRecentMovies() async {
    final db = await database;
    final maps = await db.query(
      tableMovies,
      where: 'is_recent = ?',
      whereArgs: [0],
      orderBy: 'release_date DESC',
    );

    return maps.map((map) => _mapToMovie(map)).toList();
  }

  /// 제목으로 영화를 검색합니다.
  static Future<List<Movie>> searchMovies(String query) async {
    final db = await database;
    final maps = await db.query(
      tableMovies,
      where: 'title LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'release_date DESC',
    );

    return maps.map((map) => _mapToMovie(map)).toList();
  }

  /// 영화 정보를 업데이트합니다.
  static Future<void> updateMovie(Movie movie) async {
    final db = await database;
    await db.update(
      tableMovies,
      _movieToMap(movie),
      where: 'id = ?',
      whereArgs: [movie.id],
    );
  }

  /// 영화를 삭제합니다.
  static Future<void> deleteMovie(String id) async {
    final db = await database;
    await db.delete(
      tableMovies,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 모든 영화를 삭제합니다.
  /// 주의: 이 메서드는 모든 데이터를 삭제합니다.
  static Future<void> deleteAllMovies() async {
    final db = await database;
    await db.delete(tableMovies);
  }

  /// 영화 개수를 반환합니다.
  static Future<int> getMovieCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM ${tableMovies}');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 최근 상영 영화의 is_recent 플래그를 업데이트합니다.
  /// 더 이상 상영 중이 아닌 영화는 is_recent = 0으로 설정합니다.
  static Future<void> updateRecentFlag(List<String> recentMovieIds) async {
    final db = await database;

    // 모든 영화의 is_recent를 0으로 설정
    await db.update(
      tableMovies,
      {'is_recent': 0},
    );

    // 최근 상영 중인 영화만 1로 설정
    if (recentMovieIds.isNotEmpty) {
      final placeholders = recentMovieIds.map((_) => '?').join(',');
      await db.rawUpdate(
        'UPDATE ${tableMovies} SET is_recent = 1 WHERE id IN ($placeholders)',
        recentMovieIds,
      );
    }
  }

  // ========== Record 관련 메서드 ==========

  /// Record 객체를 DB 저장용 Map으로 변환
  static Map<String, dynamic> _recordToMap(Record record) {
    return {
      'record_id': record.id,
      'user_id': record.userId,
      'movie_id': record.movie.id,
      'rating': record.rating,
      'watch_date': record.watchDate.toIso8601String().split('T')[0], // YYYY-MM-DD
      'one_liner': record.oneLiner,
      'detailed_review': record.detailedReview,
      'photo_path': record.photoUrl,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// DB Map을 Record 객체로 변환 (태그는 별도로 조회 필요)
  static Future<Record> _mapToRecord(
    Map<String, dynamic> map,
    Movie movie,
  ) async {
    // 태그는 TagRepository에서 조회
    final recordId = map['record_id'] as int;
    final tagNames = await TagRepository.getTagsByRecordId(recordId);

    return Record(
      id: recordId,
      userId: map['user_id'] as int,
      rating: (map['rating'] as num).toDouble(),
      watchDate: DateTime.parse(map['watch_date'] as String),
      oneLiner: map['one_liner'] as String?,
      detailedReview: map['detailed_review'] as String?,
      tags: tagNames,
      photoUrl: map['photo_path'] as String?,
      movie: movie,
    );
  }

  /// 기록을 데이터베이스에 추가합니다.
  /// 
  /// [record] 추가할 기록
  /// Returns 생성된 기록 ID
  static Future<int> insertRecord(Record record) async {
    final db = await database;

    // 기록 추가
    final recordMap = _recordToMap(record);
    // record_id는 자동 생성되므로 제거
    recordMap.remove('record_id');
    
    final recordId = await db.insert(
      tableRecords,
      recordMap,
    );

    // 태그 매핑 추가
    if (record.tags.isNotEmpty) {
      for (final tagName in record.tags) {
        await TagRepository.addTagToRecord(recordId, tagName);
      }
    }

    return recordId;
  }

  /// ID로 기록을 조회합니다.
  /// 
  /// [recordId] 기록 ID
  /// Returns Record 객체 (없으면 null)
  static Future<Record?> getRecordById(int recordId) async {
    final db = await database;
    final maps = await db.query(
      tableRecords,
      where: 'record_id = ?',
      whereArgs: [recordId],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final map = maps.first;
    final movieId = map['movie_id'] as String;
    final movie = await getMovieById(movieId);
    if (movie == null) return null;

    return await _mapToRecord(map, movie);
  }

  /// 모든 기록을 조회합니다.
  /// 
  /// Returns 기록 목록 (관람일 기준 내림차순)
  static Future<List<Record>> getAllRecords() async {
    final db = await database;
    final maps = await db.query(
      tableRecords,
      orderBy: 'watch_date DESC, created_at DESC',
    );

    final records = <Record>[];
    for (final map in maps) {
      final movieId = map['movie_id'] as String;
      final movie = await getMovieById(movieId);
      if (movie != null) {
        final record = await _mapToRecord(map, movie);
        records.add(record);
      }
    }

    return records;
  }

  /// 사용자별 기록을 조회합니다.
  /// 
  /// [userId] 사용자 ID
  /// Returns 기록 목록 (관람일 기준 내림차순)
  static Future<List<Record>> getRecordsByUserId(int userId) async {
    final db = await database;
    final maps = await db.query(
      tableRecords,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'watch_date DESC, created_at DESC',
    );

    final records = <Record>[];
    for (final map in maps) {
      final movieId = map['movie_id'] as String;
      final movie = await getMovieById(movieId);
      if (movie != null) {
        final record = await _mapToRecord(map, movie);
        records.add(record);
      }
    }

    return records;
  }

  /// 영화별 기록을 조회합니다.
  /// 
  /// [movieId] 영화 ID
  /// Returns 기록 목록 (관람일 기준 내림차순)
  static Future<List<Record>> getRecordsByMovieId(String movieId) async {
    final db = await database;
    final maps = await db.query(
      tableRecords,
      where: 'movie_id = ?',
      whereArgs: [movieId],
      orderBy: 'watch_date DESC, created_at DESC',
    );

    final movie = await getMovieById(movieId);
    if (movie == null) return [];

    final records = <Record>[];
    for (final map in maps) {
      final record = await _mapToRecord(map, movie);
      records.add(record);
    }

    return records;
  }

  /// 기록을 업데이트합니다.
  /// 
  /// [record] 업데이트할 기록
  static Future<void> updateRecord(Record record) async {
    final db = await database;
    final recordMap = _recordToMap(record);

    await db.update(
      tableRecords,
      recordMap,
      where: 'record_id = ?',
      whereArgs: [record.id],
    );

    // 태그 업데이트
    await TagRepository.setTagsForRecord(record.id, record.tags);
  }

  /// 기록을 삭제합니다.
  /// 
  /// [recordId] 기록 ID
  /// 태그 매핑은 CASCADE로 자동 삭제됩니다.
  static Future<void> deleteRecord(int recordId) async {
    final db = await database;
    await db.delete(
      tableRecords,
      where: 'record_id = ?',
      whereArgs: [recordId],
    );
  }

  /// 제목 또는 한줄평으로 기록을 검색합니다.
  /// 
  /// [query] 검색어
  /// Returns 검색 결과 기록 목록
  static Future<List<Record>> searchRecords(String query) async {
    if (query.trim().isEmpty) return [];

    final db = await database;
    
    // 영화 제목으로 검색
    final movies = await searchMovies(query);
    final movieIds = movies.map((m) => m.id).toList();

    // 한줄평으로 검색
    final maps = await db.query(
      tableRecords,
      where: 'one_liner LIKE ?',
      whereArgs: ['%$query%'],
    );

    // 영화 ID로 검색
    List<Map<String, dynamic>> movieRecords = [];
    if (movieIds.isNotEmpty) {
      final placeholders = movieIds.map((_) => '?').join(',');
      movieRecords = await db.rawQuery(
        'SELECT * FROM ${tableRecords} WHERE movie_id IN ($placeholders)',
        movieIds,
      );
    }

    // 중복 제거
    final allMaps = <int, Map<String, dynamic>>{};
    for (final map in maps) {
      allMaps[map['record_id'] as int] = map;
    }
    for (final map in movieRecords) {
      allMaps[map['record_id'] as int] = map;
    }

    final records = <Record>[];
    for (final map in allMaps.values) {
      final movieId = map['movie_id'] as String;
      final movie = await getMovieById(movieId);
      if (movie != null) {
        final record = await _mapToRecord(map, movie);
        records.add(record);
      }
    }

    return records;
  }

  /// 기간으로 기록을 필터링합니다.
  /// 
  /// [startDate] 시작일 (null이면 제한 없음)
  /// [endDate] 종료일 (null이면 제한 없음)
  /// Returns 필터링된 기록 목록
  static Future<List<Record>> getRecordsByDateRange(
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    final db = await database;
    
    String? where;
    List<dynamic>? whereArgs;

    if (startDate != null && endDate != null) {
      where = 'watch_date >= ? AND watch_date <= ?';
      whereArgs = [
        startDate.toIso8601String().split('T')[0],
        endDate.toIso8601String().split('T')[0],
      ];
    } else if (startDate != null) {
      where = 'watch_date >= ?';
      whereArgs = [startDate.toIso8601String().split('T')[0]];
    } else if (endDate != null) {
      where = 'watch_date <= ?';
      whereArgs = [endDate.toIso8601String().split('T')[0]];
    }

    final maps = await db.query(
      tableRecords,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'watch_date DESC, created_at DESC',
    );

    final records = <Record>[];
    for (final map in maps) {
      final movieId = map['movie_id'] as String;
      final movie = await getMovieById(movieId);
      if (movie != null) {
        final record = await _mapToRecord(map, movie);
        records.add(record);
      }
    }

    return records;
  }

  /// 태그로 기록을 조회합니다.
  /// 
  /// [tagName] 태그 이름
  /// Returns 해당 태그가 있는 기록 목록
  static Future<List<Record>> getRecordsByTag(String tagName) async {
    final db = await database;

    // 태그 ID 조회
    final tags = await db.query(
      tableTags,
      where: 'name = ?',
      whereArgs: [tagName],
      limit: 1,
    );

    if (tags.isEmpty) return [];

    final tagId = tags.first['tag_id'] as int;

    // 태그가 있는 기록 ID 조회
    final recordTags = await db.query(
      tableRecordTags,
      where: 'tag_id = ?',
      whereArgs: [tagId],
    );

    if (recordTags.isEmpty) return [];

    final recordIds = recordTags.map((rt) => rt['record_id'] as int).toList();
    final placeholders = recordIds.map((_) => '?').join(',');

    // 기록 조회
    final maps = await db.rawQuery(
      'SELECT * FROM ${tableRecords} WHERE record_id IN ($placeholders) ORDER BY watch_date DESC',
      recordIds,
    );

    final records = <Record>[];
    for (final map in maps) {
      final movieId = map['movie_id'] as String;
      final movie = await getMovieById(movieId);
      if (movie != null) {
        final record = await _mapToRecord(map, movie);
        records.add(record);
      }
    }

    return records;
  }

  /// 데이터베이스를 닫습니다.
  /// 주로 테스트나 앱 종료 시 사용합니다.
  static Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
