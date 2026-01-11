import '../models/record.dart';
import '../models/movie.dart';
import 'dummy_movies.dart';

/// 더미 관람 기록(리뷰) 데이터를 제공하는 클래스
/// 더미데이터 예시.txt 파일의 리뷰 정보를 기반으로 합니다.
class DummyRecords {
  /// 더미 영화 데이터에서 영화를 찾아 Movie 객체를 반환합니다.
  /// 찾지 못하면 기본값으로 Movie 객체를 생성합니다.
  static Movie _findMovieById(String movieId) {
    final allMovies = DummyMovies.getMovies();
    final movie = allMovies.firstWhere(
      (m) => m.id == movieId,
      orElse: () => Movie(
        id: movieId,
        title: '알 수 없는 영화',
        posterUrl: '',
        genres: [],
        releaseDate: '',
        runtime: 0,
        voteAverage: 0.0,
        isRecent: false,
      ),
    );
    return movie;
  }

  /// 더미 관람 기록 목록을 반환합니다.
  /// 더미데이터 예시.txt 파일의 7개 리뷰 정보를 기반으로 합니다.
  static List<Record> getRecords() {
    return [
      Record.fromJson(
        {
          "id": 101,
          "userId": 1,
          "rating": 4.5,
          "watchDate": "2026-01-02",
          "oneLiner": "압도적인 영상미, 역시 아바타 시리즈네요.",
          "detailedReview": "극장에서 보지 않으면 후회할 뻔했습니다. 전작보다 훨씬 화려해진 불의 부족 묘사가 인상적이었고, 3시간 넘는 러닝타임이 전혀 지루하지 않았습니다. 가족들과 함께 보기 정말 좋은 영화입니다.",
          "tags": ["가족", "극장"],
          "photoUrl": "https://my-bucket.s3.amazonaws.com/review_img_101.jpg",
        },
        movie: _findMovieById("83533"), // 아바타: 불과 재
      ),
      Record.fromJson(
        {
          "id": 102,
          "userId": 1,
          "rating": 5.0,
          "watchDate": "2026-01-05",
          "oneLiner": "다시 봐도 완벽한 서사와 연출.",
          "detailedReview": "OTT로 다시 감상했는데, 세세한 복선들을 다시 찾아보는 재미가 있네요. 한국 영화 역사에 남을 걸작이라는 걸 새삼 느꼈습니다. 기택네 가족의 긴장감 넘치는 전개는 언제 봐도 최고입니다.",
          "tags": ["혼자", "OTT", "재관람"],
          "photoUrl": "https://my-bucket.s3.amazonaws.com/review_img_102.jpg",
        },
        movie: _findMovieById("496243"), // 기생충
      ),
      Record.fromJson(
        {
          "id": 103,
          "userId": 1,
          "rating": 4.0,
          "watchDate": "2025-12-25",
          "oneLiner": "작화 퀄리티가 미쳤습니다. 전율 그 자체!",
          "detailedReview": "무한성 편을 드디어 스크린으로 보다니 감격스럽습니다. 액션 신의 프레임 하나하나가 예술이네요. 친구와 함께 보면서 계속 감탄했습니다. 다음 편이 벌써 기다려집니다.",
          "tags": ["친구", "극장"],
          "photoUrl": "https://my-bucket.s3.amazonaws.com/review_img_103.jpg",
        },
        movie: _findMovieById("1311031"), // 극장판 귀멸의 칼날: 무한성편
      ),
      Record.fromJson(
        {
          "id": 104,
          "userId": 1,
          "rating": 3.5,
          "watchDate": "2025-10-10",
          "oneLiner": "긴장감 넘치는 한국형 스릴러의 진수.",
          "detailedReview": "박찬욱 감독님의 신작이라 기대를 많이 하고 갔습니다. 범죄와 코미디가 적절히 섞여 있어서 몰입감이 좋았어요. 배우들의 연기력이 탄탄해서 지루할 틈이 없었습니다.",
          "tags": ["친구", "극장"],
          "photoUrl": "https://my-bucket.s3.amazonaws.com/review_img_104.jpg",
        },
        movie: _findMovieById("639988"), // 어쩔수가없다
      ),
      Record.fromJson(
        {
          "id": 105,
          "userId": 1,
          "rating": 5.0,
          "watchDate": "2026-01-08",
          "oneLiner": "하늘을 가르는 전율, 내 인생 최고의 속편.",
          "detailedReview": "집에서 큰 화면으로 다시 봤는데도 가슴이 웅장해집니다. 매버릭의 고뇌와 성장이 액션과 완벽하게 조화를 이룹니다. 마지막 전투 신은 정말 몇 번을 봐도 질리지 않네요.",
          "tags": ["혼자", "OTT", "재관람"],
          "photoUrl": "https://my-bucket.s3.amazonaws.com/review_img_105.jpg",
        },
        movie: _findMovieById("361743"), // 탑건: 매버릭
      ),
      Record.fromJson(
        {
          "id": 106,
          "userId": 1,
          "rating": 4.0,
          "watchDate": "2026-01-10",
          "oneLiner": "나비족의 세계관 확장이 놀랍습니다.",
          "detailedReview": "개봉하고 벌써 두 번째 관람입니다. 처음 볼 때는 놓쳤던 배경의 디테일들을 보려고 노력했어요. 판타지 장르를 좋아한다면 무조건 극장에서 봐야 하는 영화라고 생각합니다.",
          "tags": ["혼자", "극장", "재관람"],
          "photoUrl": "https://my-bucket.s3.amazonaws.com/review_img_106.jpg",
        },
        movie: _findMovieById("83533"), // 아바타: 불과 재 (재관람)
      ),
      Record.fromJson(
        {
          "id": 107,
          "userId": 1,
          "rating": 3.0,
          "watchDate": "2025-11-20",
          "oneLiner": "스토리는 아쉽지만 액션만큼은 인정.",
          "detailedReview": "귀멸의 칼날 시리즈 팬이라서 극장을 찾았습니다. 작화는 정말 훌륭했지만 전개 속도가 생각보다 조금 느린 감이 있었어요. 그래도 큰 화면으로 보니 사운드와 연출이 주는 힘이 대단했습니다.",
          "tags": ["가족", "극장"],
          "photoUrl": "https://my-bucket.s3.amazonaws.com/review_img_107.jpg",
        },
        movie: _findMovieById("1311031"), // 극장판 귀멸의 칼날: 무한성편 (재관람)
      ),
    ];
  }
}
