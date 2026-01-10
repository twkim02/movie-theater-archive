import 'movie.dart';

/// 위시리스트 아이템을 나타내는 모델 클래스
/// 더미데이터 예시.txt와 API_GUIDE.md의 구조를 따릅니다.
/// 
/// 위시리스트는 찜한 영화와 찜한 날짜 정보를 포함합니다.
class WishlistItem {
  final Movie movie; // 영화 정보
  final DateTime savedAt; // 찜한 날짜 및 시간

  WishlistItem({
    required this.movie,
    required this.savedAt,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json, {Movie? movie}) {
    // movie 객체가 제공되면 사용하고, 없으면 json에서 생성
    Movie movieObj;
    if (movie != null) {
      movieObj = movie;
    } else {
      // API 응답에서는 위시리스트에 영화 정보가 직접 포함됨
      movieObj = Movie.fromJson({
        'id': json['id'] ?? '',
        'title': json['title'] ?? '알 수 없는 영화',
        'posterUrl': json['posterUrl'] ?? '',
        'genres': json['genres'] ?? [],
        'releaseDate': DateTime.now().toIso8601String().split('T')[0], // 기본값
        'runtime': 0, // 기본값
        'voteAverage': (json['rating'] as num?)?.toDouble() ?? 0.0,
        'isRecent': false, // 기본값
      });
    }

    // savedAt 파싱 (ISO 8601 형식: "2026-01-05T10:00:00Z")
    DateTime savedAtDate;
    if (json['savedAt'] != null) {
      savedAtDate = DateTime.parse(json['savedAt'] as String);
    } else {
      savedAtDate = DateTime.now();
    }

    return WishlistItem(
      movie: movieObj,
      savedAt: savedAtDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': movie.id,
      'title': movie.title,
      'posterUrl': movie.posterUrl,
      'genres': movie.genres,
      'rating': movie.voteAverage,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  WishlistItem copyWith({
    Movie? movie,
    DateTime? savedAt,
  }) {
    return WishlistItem(
      movie: movie ?? this.movie,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  @override
  String toString() {
    return 'WishlistItem(movie: ${movie.title}, savedAt: ${savedAt.toIso8601String()})';
  }
}
