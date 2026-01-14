class Movie {
  final String id;
  final String title;
  final String posterUrl;
  final List<String> genres;
  final String releaseDate;   // 개봉일
  final int runtime;          // 러닝타임(분)
  final double voteAverage;
  final bool isRecent;

  /// 화면에 표시할 평점을 반환합니다.
  /// 
  /// DB에 저장된 평점이 0.0인 경우 (신규 영화) 3.0을 반환합니다.
  /// 그 외의 경우에는 DB에 저장된 값을 그대로 반환합니다.
  double get displayVoteAverage {
    return voteAverage == 0.0 ? 3.0 : voteAverage;
  }

  Movie({
    required this.id,
    required this.title,
    required this.posterUrl,
    required this.genres,
    required this.releaseDate,
    required this.runtime,
    required this.voteAverage,
    required this.isRecent,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'].toString(),
      title: json['title'] as String,
      posterUrl: json['posterUrl'] as String? ?? '',
      genres: List<String>.from(json['genres'] ?? []),
      releaseDate: json['releaseDate'] as String? ?? '',
      runtime: (json['runtime'] as num?)?.toInt() ?? 0,
      voteAverage: (json['voteAverage'] as num?)?.toDouble() ?? 0.0,
      isRecent: json['isRecent'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'posterUrl': posterUrl,
      'genres': genres,
      'releaseDate': releaseDate, // YYYY-MM-DD 형식의 문자열
      'runtime': runtime,
      'voteAverage': voteAverage,
      'isRecent': isRecent,
    };
  }

  Movie copyWith({
    String? id,
    String? title,
    String? posterUrl,
    List<String>? genres,
    String? releaseDate,
    int? runtime,
    double? voteAverage,
    bool? isRecent,
  }) {
    return Movie(
      id: id ?? this.id,
      title: title ?? this.title,
      posterUrl: posterUrl ?? this.posterUrl,
      genres: genres ?? this.genres,
      releaseDate: releaseDate ?? this.releaseDate,
      runtime: runtime ?? this.runtime,
      voteAverage: voteAverage ?? this.voteAverage,
      isRecent: isRecent ?? this.isRecent,
    );
  }

  @override
  String toString() {
    return 'Movie(id: $id, title: $title, genres: ${genres.join(", ")}, releaseDate: $releaseDate, rating: $voteAverage)';
  }
}
