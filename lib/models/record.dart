import 'movie.dart';

/// 관람 기록(리뷰)을 나타내는 모델 클래스
/// 더미데이터 예시.txt와 API_GUIDE.md의 구조를 따릅니다.
class Record {
  final int id;
  final int userId;
  final double rating; // 0.0 ~ 5.0
  final DateTime watchDate; // 관람일
  final String? oneLiner; // 한줄평 (선택)
  final String? detailedReview; // 상세 리뷰 (선택)
  final List<String> tags; // 태그 목록 (✅ 최대 2개 제한은 UI에서 처리)
  final List<String> photoPaths; // ✅ 첨부 사진(선택) - 로컬 파일 경로 리스트
  final Movie movie; // 영화 정보

  Record({
    required this.id,
    required this.userId,
    required this.rating,
    required this.watchDate,
    this.oneLiner,
    this.detailedReview,
    required this.tags,
    this.photoPaths = const [],
    required this.movie,
  });

  factory Record.fromJson(Map<String, dynamic> json, {Movie? movie}) {
    // movie 파라미터가 제공되면 사용하고, 없으면 json에서 생성
    Movie movieObj;
    if (movie != null) {
      movieObj = movie;
    } else {
      // API 응답에서는 movie에 id, title, posterUrl만 포함될 수 있음
      final movieJson = json['movie'] as Map<String, dynamic>? ?? {};
      movieObj = Movie.fromJson({
        'id': movieJson['id'] ?? '',
        'title': movieJson['title'] ?? '알 수 없는 영화',
        'posterUrl': movieJson['posterUrl'] ?? '',
        'genres': [], // API 응답에 genres가 없을 수 있음
        'releaseDate': DateTime.now().toIso8601String().split('T')[0], // 기본값
        'runtime': 0, // 기본값
        'voteAverage': 0.0, // 기본값
        'isRecent': false, // 기본값
      });
    }

    // ✅ photoPaths 우선 지원
    final pathsFromJson = (json['photoPaths'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    // ✅ (과거 호환) 기존 photoPaths(단일)이 남아있으면 photoPaths로 변환
    final legacyphotoPaths = json['photoPaths'] as String?;
    final finalPhotoPaths = pathsFromJson.isNotEmpty
        ? pathsFromJson
        : (legacyphotoPaths == null || legacyphotoPaths.isEmpty
            ? <String>[]
            : <String>[legacyphotoPaths]);

    return Record(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      rating: (json['rating'] as num).toDouble(),
      watchDate: DateTime.parse(json['watchDate'] as String),
      oneLiner: json['oneLiner'] as String?,
      detailedReview: json['detailedReview'] as String?,
      tags: List<String>.from(json['tags'] ?? []),
      photoPaths: finalPhotoPaths,
      movie: movieObj,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'rating': rating,
      'watchDate': watchDate.toIso8601String().split('T')[0], // YYYY-MM-DD 형식
      'oneLiner': oneLiner,
      'detailedReview': detailedReview,
      'tags': tags,
      'photoPaths': photoPaths, // ✅ 변경된 필드
      'movie': {
        'id': movie.id,
        'title': movie.title,
        'posterUrl': movie.posterUrl,
      },
    };
  }

  Record copyWith({
    int? id,
    int? userId,
    double? rating,
    DateTime? watchDate,
    String? oneLiner,
    String? detailedReview,
    List<String>? tags,
    List<String>? photoPaths,
    Movie? movie,
  }) {
    return Record(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      rating: rating ?? this.rating,
      watchDate: watchDate ?? this.watchDate,
      oneLiner: oneLiner ?? this.oneLiner,
      detailedReview: detailedReview ?? this.detailedReview,
      tags: tags ?? this.tags,
      photoPaths: photoPaths ?? this.photoPaths,
      movie: movie ?? this.movie,
    );
  }

  @override
  String toString() {
    return 'Record(id: $id, movie: ${movie.title}, rating: $rating, watchDate: ${watchDate.toIso8601String().split("T")[0]})';
  }
}
