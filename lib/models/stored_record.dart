import 'package:hive/hive.dart';

part 'stored_record.g.dart';

@HiveType(typeId: 1)
class StoredRecord extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final int userId;

  @HiveField(2)
  final double rating;

  @HiveField(3)
  final DateTime watchDate;

  @HiveField(4)
  final String? oneLiner;

  @HiveField(5)
  final String? detailedReview;

  @HiveField(6)
  final List<String> tags;

  @HiveField(7)
  final List<String> photoPaths;

  // ---- Movie 정보 ----
  @HiveField(8)
  final String movieId;

  @HiveField(9)
  final String movieTitle;

  @HiveField(10)
  final String moviePosterUrl;

  @HiveField(11)
  final List<String> movieGenres;

  @HiveField(12)
  final String movieReleaseDate;

  @HiveField(13)
  final int movieRuntime;

  @HiveField(14)
  final double movieVoteAverage;

  @HiveField(15)
  final bool movieIsRecent;

  StoredRecord({
    required this.id,
    required this.userId,
    required this.rating,
    required this.watchDate,
    this.oneLiner,
    this.detailedReview,
    required this.tags,
    required this.photoPaths,

    required this.movieId,
    required this.movieTitle,
    required this.moviePosterUrl,
    required this.movieGenres,
    required this.movieReleaseDate,
    required this.movieRuntime,
    required this.movieVoteAverage,
    required this.movieIsRecent,
  });
}
