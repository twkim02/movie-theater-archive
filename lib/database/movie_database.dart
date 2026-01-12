import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/movie.dart';
import 'dart:convert';

/// 영화 정보를 저장하는 SQLite 데이터베이스 헬퍼 클래스
class MovieDatabase {
  static Database? _database;
  static const String _databaseName = 'movie_diary.db';
  static const int _databaseVersion = 1;

  // 테이블 이름
  static const String _tableMovies = 'movies';

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

    // 제목 검색을 위한 인덱스 생성
    await db.execute('''
      CREATE INDEX idx_movies_title ON $_tableMovies(title)
    ''');

    // 최근 상영 영화 조회를 위한 인덱스
    await db.execute('''
      CREATE INDEX idx_movies_is_recent ON $_tableMovies(is_recent)
    ''');

    // 개봉일 기준 정렬을 위한 인덱스
    await db.execute('''
      CREATE INDEX idx_movies_release_date ON $_tableMovies(release_date)
    ''');
  }

  /// 데이터베이스 업그레이드 로직
  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // 향후 스키마 변경 시 마이그레이션 로직 추가
    if (oldVersion < newVersion) {
      // 예: 새로운 컬럼 추가 등
    }
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
}
