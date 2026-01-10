import '../models/movie.dart';

/// 더미 영화 데이터를 제공하는 클래스
/// TEAMWORK.md에 명시된 데이터 구조를 따릅니다.
class DummyMovies {
  /// 더미 영화 목록을 반환합니다.
  /// 더미데이터 예시.txt 파일의 영화 정보를 기반으로 합니다.
  static List<Movie> getMovies() {
    return [
      Movie.fromJson({
        "id": "496243",
        "title": "기생충",
        "posterUrl": "https://image.tmdb.org/t/p/w500/mSi0gskYpmf1FbXngM37s2HppXh.jpg",
        "genres": ["코미디", "스릴러", "드라마"],
        "releaseDate": "2019-05-30",
        "runtime": 131,
        "voteAverage": 4.3,
        "isRecent": false,
      }),
      Movie.fromJson({
        "id": "639988",
        "title": "어쩔수가없다",
        "posterUrl": "https://image.tmdb.org/t/p/w500/9w7WGjQes0Cs0s4U3Qr09Tg1Sra.jpg",
        "genres": ["범죄", "스릴러", "코미디"],
        "releaseDate": "2025-09-24",
        "runtime": 139,
        "voteAverage": 3.9,
        "isRecent": true,
      }),
      Movie.fromJson({
        "id": "83533",
        "title": "아바타: 불과 재",
        "posterUrl": "https://image.tmdb.org/t/p/w500/l18o0AK18KS118tWeROOKYkF0ng.jpg",
        "genres": ["SF", "모험", "판타지"],
        "releaseDate": "2025-12-17",
        "runtime": 195,
        "voteAverage": 3.7,
        "isRecent": true,
      }),
      Movie.fromJson({
        "id": "1311031",
        "title": "극장판 귀멸의 칼날: 무한성편",
        "posterUrl": "https://image.tmdb.org/t/p/w500/m6Dho6hDCcL5KI8mOQNemZAedFI.jpg",
        "genres": ["애니메이션", "액션", "판타지"],
        "releaseDate": "2025-08-22",
        "runtime": 155,
        "voteAverage": 3.8,
        "isRecent": false,
      }),
      Movie.fromJson({
        "id": "361743",
        "title": "탑건: 매버릭",
        "posterUrl": "https://image.tmdb.org/t/p/w500/jeqXUwNilvNqNXqAHsdwm5pEfae.jpg",
        "genres": ["액션", "드라마"],
        "releaseDate": "2022-06-22",
        "runtime": 131,
        "voteAverage": 4.1,
        "isRecent": false,
      }),
      Movie.fromJson({
        "id": "696506",
        "title": "미키 17",
        "posterUrl": "https://image.tmdb.org/t/p/w500/mH7QnJDxQibVZw0M66IBZbsw2O6.jpg",
        "genres": ["SF", "코미디", "모험"],
        "releaseDate": "2025-02-28",
        "runtime": 137,
        "voteAverage": 3.4,
        "isRecent": false,
      }),
      Movie.fromJson({
        "id": "133200",
        "title": "광해, 왕이 된 남자",
        "posterUrl": "https://image.tmdb.org/t/p/w500/6Pg5AwsJUqeGanGOWcaljQXGe5g.jpg",
        "genres": ["드라마", "역사"],
        "releaseDate": "2012-09-13",
        "runtime": 131,
        "voteAverage": 3.7,
        "isRecent": false,
      }),
    ];
  }
}
