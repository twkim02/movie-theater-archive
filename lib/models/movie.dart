class Movie {
  final String id;
  final String title;
  final String posterUrl;
  final List<String> genres;
  final DateTime releaseDate;
  final int runtime;
  final double voteAverage;
  final bool isRecent;

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
      releaseDate: DateTime.parse(json['releaseDate'] as String),
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
      'releaseDate': releaseDate.toIso8601String().split('T')[0], // YYYY-MM-DD 형식
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
    DateTime? releaseDate,
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
    return 'Movie(id: $id, title: $title, genres: ${genres.join(", ")}, releaseDate: ${releaseDate.toIso8601String().split("T")[0]}, rating: $voteAverage)';
  }
}