import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/movie.dart';
import 'dart:convert';

/// 영화 정보를 저장하는 SQLite 데이터베이스 헬퍼 클래스
class MovieDatabase {
  static Database? _database;
  static const String _databaseName = 'movie_diary.db';
  static const int _databaseVersion = 2; // 버전 2로 증가 (새 테이블 추가)

  // 테이블 이름 (public으로 노출하여 Repository에서 사용)
  static const String tableMovies = 'movies';
  static const String tableUsers = 'users';
  static const String tableRecords = 'records';
  static const String tableWishlist = 'wishlist';
  static const String tableTags = 'tags';
  static const String tableRecordTags = 'record_tags';

  // 내부에서 사용하는 private 변수 (하위 호환성)
  static const String _tableMovies = tableMovies;
  static const String _tableUsers = tableUsers;
  static const String _tableRecords = tableRecords;
  static const String _tableWishlist = tableWishlist;
  static const String _tableTags = tableTags;
  static const String _tableRecordTags = tableRecordTags;

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
    );
  }

  /// 데이터베이스 테이블을 생성합니다.
  static Future<void> _onCreate(Database db, int version) async {
    // 1. Movies 테이블 (기존)
    await db.execute('''
      CREATE TABLE $_tableMovies (
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

    // 2. Users 테이블
    await db.execute('''
      CREATE TABLE $_tableUsers (
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        nickname TEXT NOT NULL,
        email TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    // 3. Records 테이블
    await db.execute('''
      CREATE TABLE $_tableRecords (
        record_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        movie_id TEXT NOT NULL,
        rating REAL NOT NULL,
        watch_date TEXT NOT NULL,
        one_liner TEXT,
        detailed_review TEXT,
        photo_path TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES $_tableUsers(user_id) ON DELETE CASCADE,
        FOREIGN KEY (movie_id) REFERENCES $_tableMovies(id) ON DELETE CASCADE
      )
    ''');

    // 4. Wishlist 테이블
    await db.execute('''
      CREATE TABLE $_tableWishlist (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        movie_id TEXT NOT NULL,
        saved_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES $_tableUsers(user_id) ON DELETE CASCADE,
        FOREIGN KEY (movie_id) REFERENCES $_tableMovies(id) ON DELETE CASCADE,
        UNIQUE(user_id, movie_id)
      )
    ''');

    // 5. Tags 테이블
    await db.execute('''
      CREATE TABLE $_tableTags (
        tag_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    // 6. Record_Tags 테이블 (N:M 관계)
    await db.execute('''
      CREATE TABLE $_tableRecordTags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        record_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        FOREIGN KEY (record_id) REFERENCES $_tableRecords(record_id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES $_tableTags(tag_id) ON DELETE CASCADE,
        UNIQUE(record_id, tag_id)
      )
    ''');

    // 인덱스 생성 (성능 최적화)
    await _createIndexes(db);
  }

  /// 인덱스를 생성합니다.
  static Future<void> _createIndexes(Database db) async {
    // Movies 테이블 인덱스
    await db.execute('CREATE INDEX idx_movies_title ON $_tableMovies(title)');
    await db.execute('CREATE INDEX idx_movies_is_recent ON $_tableMovies(is_recent)');
    await db.execute('CREATE INDEX idx_movies_release_date ON $_tableMovies(release_date)');

    // Records 테이블 인덱스
    await db.execute('CREATE INDEX idx_records_user_id ON $_tableRecords(user_id)');
    await db.execute('CREATE INDEX idx_records_movie_id ON $_tableRecords(movie_id)');
    await db.execute('CREATE INDEX idx_records_watch_date ON $_tableRecords(watch_date)');
    await db.execute('CREATE INDEX idx_records_created_at ON $_tableRecords(created_at)');

    // Wishlist 테이블 인덱스
    await db.execute('CREATE INDEX idx_wishlist_user_id ON $_tableWishlist(user_id)');
    await db.execute('CREATE INDEX idx_wishlist_movie_id ON $_tableWishlist(movie_id)');

    // Record_Tags 테이블 인덱스
    await db.execute('CREATE INDEX idx_record_tags_record_id ON $_tableRecordTags(record_id)');
    await db.execute('CREATE INDEX idx_record_tags_tag_id ON $_tableRecordTags(tag_id)');
  }

  /// 데이터베이스 업그레이드 로직
  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // 버전 1 -> 2: 새 테이블 추가
    if (oldVersion < 2) {
      // 1. Users 테이블 생성
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_tableUsers (
          user_id INTEGER PRIMARY KEY AUTOINCREMENT,
          nickname TEXT NOT NULL,
          email TEXT,
          created_at INTEGER NOT NULL
        )
      ''');

      // 2. Records 테이블 생성
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_tableRecords (
          record_id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          movie_id TEXT NOT NULL,
          rating REAL NOT NULL,
          watch_date TEXT NOT NULL,
          one_liner TEXT,
          detailed_review TEXT,
          photo_path TEXT,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (user_id) REFERENCES $_tableUsers(user_id) ON DELETE CASCADE,
          FOREIGN KEY (movie_id) REFERENCES $_tableMovies(id) ON DELETE CASCADE
        )
      ''');

      // 3. Wishlist 테이블 생성
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_tableWishlist (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          movie_id TEXT NOT NULL,
          saved_at INTEGER NOT NULL,
          FOREIGN KEY (user_id) REFERENCES $_tableUsers(user_id) ON DELETE CASCADE,
          FOREIGN KEY (movie_id) REFERENCES $_tableMovies(id) ON DELETE CASCADE,
          UNIQUE(user_id, movie_id)
        )
      ''');

      // 4. Tags 테이블 생성
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_tableTags (
          tag_id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE
        )
      ''');

      // 5. Record_Tags 테이블 생성
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_tableRecordTags (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          record_id INTEGER NOT NULL,
          tag_id INTEGER NOT NULL,
          FOREIGN KEY (record_id) REFERENCES $_tableRecords(record_id) ON DELETE CASCADE,
          FOREIGN KEY (tag_id) REFERENCES $_tableTags(tag_id) ON DELETE CASCADE,
          UNIQUE(record_id, tag_id)
        )
      ''');

      // 인덱스 생성
      await _createIndexes(db);
    }

    // 향후 버전 업그레이드 로직은 여기에 추가
    // if (oldVersion < 3) { ... }
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
      _tableMovies,
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
        _tableMovies,
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
      _tableMovies,
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
      _tableMovies,
      orderBy: 'release_date DESC',
    );

    return maps.map((map) => _mapToMovie(map)).toList();
  }

  /// 최근 상영 중인 영화를 조회합니다.
  static Future<List<Movie>> getRecentMovies() async {
    final db = await database;
    final maps = await db.query(
      _tableMovies,
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
      _tableMovies,
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
      _tableMovies,
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
      _tableMovies,
      _movieToMap(movie),
      where: 'id = ?',
      whereArgs: [movie.id],
    );
  }

  /// 영화를 삭제합니다.
  static Future<void> deleteMovie(String id) async {
    final db = await database;
    await db.delete(
      _tableMovies,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 모든 영화를 삭제합니다.
  /// 주의: 이 메서드는 모든 데이터를 삭제합니다.
  static Future<void> deleteAllMovies() async {
    final db = await database;
    await db.delete(_tableMovies);
  }

  /// 영화 개수를 반환합니다.
  static Future<int> getMovieCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $_tableMovies');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 최근 상영 영화의 is_recent 플래그를 업데이트합니다.
  /// 더 이상 상영 중이 아닌 영화는 is_recent = 0으로 설정합니다.
  static Future<void> updateRecentFlag(List<String> recentMovieIds) async {
    final db = await database;

    // 모든 영화의 is_recent를 0으로 설정
    await db.update(
      _tableMovies,
      {'is_recent': 0},
    );

    // 최근 상영 중인 영화만 1로 설정
    if (recentMovieIds.isNotEmpty) {
      final placeholders = recentMovieIds.map((_) => '?').join(',');
      await db.rawUpdate(
        'UPDATE $_tableMovies SET is_recent = 1 WHERE id IN ($placeholders)',
        recentMovieIds,
      );
    }
  }

  /// 데이터베이스를 닫습니다.
  /// 주로 테스트나 앱 종료 시 사용합니다.
  static Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  // ========== Users 테이블 관련 메서드 ==========

  /// 사용자를 추가합니다.
  static Future<int> insertUser({
    required String nickname,
    String? email,
  }) async {
    final db = await database;
    return await db.insert(
      _tableUsers,
      {
        'nickname': nickname,
        'email': email,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// ID로 사용자를 조회합니다.
  static Future<Map<String, dynamic>?> getUserById(int userId) async {
    final db = await database;
    final maps = await db.query(
      _tableUsers,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return maps.isEmpty ? null : maps.first;
  }

  /// 기본 사용자(Guest)를 조회하거나 생성합니다.
  static Future<int> getOrCreateDefaultUser() async {
    final db = await database;
    // 기본 사용자 조회 (nickname이 "Guest"인 사용자)
    final maps = await db.query(
      _tableUsers,
      where: 'nickname = ?',
      whereArgs: ['Guest'],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return maps.first['user_id'] as int;
    }

    // 없으면 생성
    return await insertUser(nickname: 'Guest');
  }

  // ========== Records 테이블 관련 메서드 ==========

  /// 기록을 추가합니다.
  /// Returns 생성된 record_id
  static Future<int> insertRecord({
    required int userId,
    required String movieId,
    required double rating,
    required String watchDate, // YYYY-MM-DD 형식
    String? oneLiner,
    String? detailedReview,
    String? photoPath,
  }) async {
    final db = await database;
    return await db.insert(
      _tableRecords,
      {
        'user_id': userId,
        'movie_id': movieId,
        'rating': rating,
        'watch_date': watchDate,
        'one_liner': oneLiner,
        'detailed_review': detailedReview,
        'photo_path': photoPath,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  /// ID로 기록을 조회합니다.
  static Future<Map<String, dynamic>?> getRecordById(int recordId) async {
    final db = await database;
    final maps = await db.query(
      _tableRecords,
      where: 'record_id = ?',
      whereArgs: [recordId],
    );
    return maps.isEmpty ? null : maps.first;
  }

  /// 사용자의 모든 기록을 조회합니다.
  static Future<List<Map<String, dynamic>>> getAllRecordsByUserId(int userId) async {
    final db = await database;
    return await db.query(
      _tableRecords,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'watch_date DESC, created_at DESC',
    );
  }

  /// 영화별 기록을 조회합니다.
  static Future<List<Map<String, dynamic>>> getRecordsByMovieId(String movieId) async {
    final db = await database;
    return await db.query(
      _tableRecords,
      where: 'movie_id = ?',
      whereArgs: [movieId],
      orderBy: 'watch_date DESC',
    );
  }

  /// 기간별 기록을 조회합니다.
  static Future<List<Map<String, dynamic>>> getRecordsByDateRange(
    int userId,
    String startDate, // YYYY-MM-DD
    String endDate, // YYYY-MM-DD
  ) async {
    final db = await database;
    return await db.query(
      _tableRecords,
      where: 'user_id = ? AND watch_date >= ? AND watch_date <= ?',
      whereArgs: [userId, startDate, endDate],
      orderBy: 'watch_date DESC',
    );
  }

  /// 기록을 검색합니다 (제목, 한줄평).
  static Future<List<Map<String, dynamic>>> searchRecords(
    int userId,
    String query,
  ) async {
    final db = await database;
    // Movies 테이블과 JOIN하여 제목 검색
    return await db.rawQuery('''
      SELECT r.* 
      FROM $_tableRecords r
      INNER JOIN $_tableMovies m ON r.movie_id = m.id
      WHERE r.user_id = ? 
        AND (m.title LIKE ? OR r.one_liner LIKE ?)
      ORDER BY r.watch_date DESC
    ''', [userId, '%$query%', '%$query%']);
  }

  /// 기록을 업데이트합니다.
  static Future<void> updateRecord({
    required int recordId,
    double? rating,
    String? watchDate,
    String? oneLiner,
    String? detailedReview,
    String? photoPath,
  }) async {
    final db = await database;
    final updateData = <String, dynamic>{};
    if (rating != null) updateData['rating'] = rating;
    if (watchDate != null) updateData['watch_date'] = watchDate;
    if (oneLiner != null) updateData['one_liner'] = oneLiner;
    if (detailedReview != null) updateData['detailed_review'] = detailedReview;
    if (photoPath != null) updateData['photo_path'] = photoPath;

    if (updateData.isEmpty) return;

    await db.update(
      _tableRecords,
      updateData,
      where: 'record_id = ?',
      whereArgs: [recordId],
    );
  }

  /// 기록을 삭제합니다.
  static Future<void> deleteRecord(int recordId) async {
    final db = await database;
    await db.delete(
      _tableRecords,
      where: 'record_id = ?',
      whereArgs: [recordId],
    );
  }

  // ========== Wishlist 테이블 관련 메서드 ==========

  /// 위시리스트에 영화를 추가합니다.
  static Future<void> insertWishlist({
    required int userId,
    required String movieId,
  }) async {
    final db = await database;
    await db.insert(
      _tableWishlist,
      {
        'user_id': userId,
        'movie_id': movieId,
        'saved_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace, // 중복 시 업데이트
    );
  }

  /// 위시리스트에서 영화를 제거합니다.
  static Future<void> deleteWishlist({
    required int userId,
    required String movieId,
  }) async {
    final db = await database;
    await db.delete(
      _tableWishlist,
      where: 'user_id = ? AND movie_id = ?',
      whereArgs: [userId, movieId],
    );
  }

  /// 사용자의 위시리스트를 조회합니다.
  static Future<List<Map<String, dynamic>>> getWishlistByUserId(int userId) async {
    final db = await database;
    return await db.query(
      _tableWishlist,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'saved_at DESC',
    );
  }

  /// 위시리스트에 포함되어 있는지 확인합니다.
  static Future<bool> isInWishlist({
    required int userId,
    required String movieId,
  }) async {
    final db = await database;
    final maps = await db.query(
      _tableWishlist,
      where: 'user_id = ? AND movie_id = ?',
      whereArgs: [userId, movieId],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  // ========== Tags 테이블 관련 메서드 ==========

  /// 태그를 추가합니다.
  /// Returns 생성된 tag_id
  static Future<int> insertTag(String name) async {
    final db = await database;
    try {
      return await db.insert(
        _tableTags,
        {'name': name},
        conflictAlgorithm: ConflictAlgorithm.ignore, // 중복 시 무시
      );
    } catch (e) {
      // 이미 존재하는 경우 조회하여 반환
      final existing = await getTagByName(name);
      if (existing != null) {
        return existing['tag_id'] as int;
      }
      rethrow;
    }
  }

  /// 이름으로 태그를 조회합니다.
  static Future<Map<String, dynamic>?> getTagByName(String name) async {
    final db = await database;
    final maps = await db.query(
      _tableTags,
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    return maps.isEmpty ? null : maps.first;
  }

  /// 태그를 조회하거나 생성합니다.
  static Future<int> getOrCreateTag(String name) async {
    final existing = await getTagByName(name);
    if (existing != null) {
      return existing['tag_id'] as int;
    }
    return await insertTag(name);
  }

  /// 모든 태그를 조회합니다.
  static Future<List<Map<String, dynamic>>> getAllTags() async {
    final db = await database;
    return await db.query(_tableTags, orderBy: 'name ASC');
  }

  // ========== Record_Tags 테이블 관련 메서드 ==========

  /// 기록에 태그를 연결합니다.
  static Future<void> insertRecordTag({
    required int recordId,
    required int tagId,
  }) async {
    final db = await database;
    await db.insert(
      _tableRecordTags,
      {
        'record_id': recordId,
        'tag_id': tagId,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore, // 중복 시 무시
    );
  }

  /// 기록의 모든 태그를 조회합니다.
  static Future<List<Map<String, dynamic>>> getTagsByRecordId(int recordId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT t.*
      FROM $_tableTags t
      INNER JOIN $_tableRecordTags rt ON t.tag_id = rt.tag_id
      WHERE rt.record_id = ?
      ORDER BY t.name ASC
    ''', [recordId]);
  }

  /// 기록의 모든 태그를 삭제합니다.
  static Future<void> deleteRecordTags(int recordId) async {
    final db = await database;
    await db.delete(
      _tableRecordTags,
      where: 'record_id = ?',
      whereArgs: [recordId],
    );
  }
}
