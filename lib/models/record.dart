import 'movie.dart';

class Record {
  final int id;
  final Movie movie;
  final double rating;
  final DateTime watchDate;
  final String oneLiner;
  final String detailedReview;
  final List<String> tags;
  final String? photoUrl;

  Record({
    required this.id,
    required this.movie,
    required this.rating,
    required this.watchDate,
    required this.oneLiner,
    required this.detailedReview,
    required this.tags,
    this.photoUrl,
  });
}
