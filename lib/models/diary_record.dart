class DiaryRecord {
  final DateTime date;
  final String movieTitle;
  final String posterUrl;
  final double rating;
  final String oneLine;
  final List<String> tags;
  final List<String> genres;
  final List<String> photos;
  final String detail;

  DiaryRecord({
    required this.date,
    required this.movieTitle,
    required this.posterUrl,
    required this.rating,
    required this.oneLine,
    required this.tags,
    required this.genres,
    required this.photos,
    required this.detail,
  });
}
