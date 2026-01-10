class Movie {
  final String id;
  final String title;
  final String posterUrl;
  final List<String> genres;
  final String releaseDate;   // 개봉일
  final int runtime;          // 러닝타임(분)
  final double voteAverage;
  final bool isRecent;

  Movie({
    required this.id,
    required this.title,
    required this.posterUrl,
    required this.genres,
    required this.releaseDate,   // ✅ 생성자에 추가
    required this.runtime,        // ✅ 생성자에 추가
    required this.voteAverage,
    required this.isRecent,
  });
}

final List<Movie> dummyMovies = [
  Movie(
    id: "496243",
    title: "기생충",
    posterUrl: "https://image.tmdb.org/t/p/w500/mSi0gskYpmf1FbXngM37s2HppXh.jpg",
    genres: ["코미디", "스릴러", "드라마"],
    releaseDate: "2019-05-30",
    runtime: 131,
    voteAverage: 4.3,
    isRecent: false,
  ),
  Movie(
    id: "639988",
    title: "어쩔수가없다",
    posterUrl: "https://image.tmdb.org/t/p/w500/9w7WGjQes0Cs0s4U3Qr09Tg1Sra.jpg",
    genres: ["범죄", "스릴러", "코미디"],
    releaseDate: "2025-09-24",
    runtime: 139,
    voteAverage: 3.9,
    isRecent: true,
  ),
  Movie(
    id: "83533",
    title: "아바타: 불과 재",
    posterUrl: "https://image.tmdb.org/t/p/w500/l18o0AK18KS118tWeROOKYkF0ng.jpg",
    genres: ["SF", "모험", "판타지"],
    releaseDate: "2025-12-17",
    runtime: 195,
    voteAverage: 3.7,
    isRecent: true,
  ),
  Movie(
    id: "1311031",
    title: "극장판 귀멸의 칼날: 무한성편",
    posterUrl: "https://image.tmdb.org/t/p/w500/m6Dho6hDCcL5KI8mOQNemZAedFI.jpg",
    genres: ["애니메이션", "액션", "판타지"],
    releaseDate: "2025-08-22",
    runtime: 155,
    voteAverage: 3.8,
    isRecent: false,
  ),
  Movie(
    id: "361743",
    title: "탑건: 매버릭",
    posterUrl: "https://image.tmdb.org/t/p/w500/jeqXUwNilvNqNXqAHsdwm5pEfae.jpg",
    genres: ["액션", "드라마"],
    releaseDate: "2022-06-22",
    runtime: 131,
    voteAverage: 4.1,
    isRecent: false,
  ),
  Movie(
    id: "696506",
    title: "미키 17",
    posterUrl: "https://image.tmdb.org/t/p/w500/mH7QnJDxQibVZw0M66IBZbsw2O6.jpg",
    genres: ["SF", "코미디", "모험"],
    releaseDate: "2025-02-28",
    runtime: 137,
    voteAverage: 3.4,
    isRecent: false,
  ),
  Movie(
    id: "133200",
    title: "광해, 왕이 된 남자",
    posterUrl: "https://image.tmdb.org/t/p/w500/6Pg5AwsJUqeGanGOWcaljQXGe5g.jpg",
    genres: ["드라마", "역사"],
    releaseDate: "2012-09-13",
    runtime: 131,
    voteAverage: 3.7,
    isRecent: false,
  ),
];
