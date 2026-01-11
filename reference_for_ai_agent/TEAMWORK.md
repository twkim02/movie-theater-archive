# ✅ 역할 분담 정답 (지금 상태 기준)

## 🔵 팀원 (프론트 / UI 담당)

**“피그마 → Flutter 화면 구현”만 집중**

- MovieCard UI (포스터 / 제목 / 장르 / 연도 / 평점)
- 탐색 화면 레이아웃 (리스트/그리드)
- 북마크 아이콘 UI (on/off 모양만)
- “기록 추가” 버튼 UI (바텀시트 열기까지만)
- **데이터는 ‘이미 있다’고 가정하고 사용**

👉 절대:

- 더미 데이터 구조 만들지 않기
- JSON 직접 손대지 않기

---

## 🟢 나 (데이터 / 상태 담당)

**“데이터를 Flutter가 쓰기 좋게 만들어주는 역할”**

- 더미 영화 JSON 관리 (네가 보낸 구조 유지)
- Movie 모델 클래스 정의
- dummy_movies.dart 생성
- Provider(AppState)에서
    - 영화 리스트 제공
    - 북마크 상태 관리
- (나중에) Firebase/로컬저장 붙이기

👉 절대:

- UI 위젯 건드리지 않기
- 피그마 레이아웃 수정하지 않기

---

# 🔑 핵심: “데이터 계약서”가 이미 생긴 상태

아까 내가 팀원에게 보낸 이 JSON 👇

이게 **너희 둘 사이의 공식 계약**이야.

```json
{
"id":"496243",
"title":"기생충",
"posterUrl":"https://image.tmdb.org/t/p/w500/...",
"genres":["드라마"],
"releaseDate":"2019-05-30",
"runtime":131,
"voteAverage":8.5,
"isRecent":false
}

```

👉 **이 필드 이름/형식은 절대 바꾸지 않기**

(바꾸면 UI 다 깨짐)

---

# 📁 추천 파일 분리 (충돌 방지)

## 내가 만드는 파일들

```
lib/
 ├─ models/
 │   └─ movie.dart
 ├─data/
 │   └─ dummy_movies.dart
 ├─ state/
 │   └─ app_state.dart

```

### movie.dart (내 담당)

```dart
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
      id: json['id'],
      title: json['title'],
      posterUrl: json['posterUrl'],
      genres: List<String>.from(json['genres']),
      releaseDate: DateTime.parse(json['releaseDate']),
      runtime: json['runtime'],
      voteAverage: (json['voteAverage'] as num).toDouble(),
      isRecent: json['isRecent'],
    );
  }
}

```

---

## 팀원이 만드는 파일들

```
lib/
 ├─ widgets/
 │   └─ movie_card.dart
 ├─ screens/
 │   └─ explore_screen.dart

```

### movie_card.dart (팀원 담당)

```dart
class MovieCard extends StatelessWidget {
  final Movie movie;

  const MovieCard({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.network(movie.posterUrl),
        Text(movie.title),
        Text(movie.genres.join(' · ')),
        Text('${movie.releaseDate.year} · ⭐ ${movie.voteAverage}'),
      ],
    );
  }
}

```

👉 **팀원은 `Movie`가 어디서 오는지 신경 안 써도 됨**

“이미 movie가 들어온다”는 가정만 하면 됨.

---

# 🔌 연결 지점은 딱 하나

`ExploreScreen`에서만 만난다.

```dart
final movies = context.watch<AppState>().movies;

ListView.builder(
  itemCount: movies.length,
  itemBuilder: (context, index) {
    return MovieCard(movie: movies[index]);
  },
);

```

- AppState 내부 구현은 내 책임
- UI가 깨지면 → UI 문제
- 데이터 안 뜨면 → 내 쪽 데이터 문제

👉 디버깅도 명확해짐

---

# 🎯 지금 당장 할 일 (각자)

### 팀원

- 피그마 MovieCard **1개 완벽히 구현**
- 하드코딩 데이터로라도 레이아웃 먼저 맞추기

### 나

- 위 JSON → Movie.fromJson
- dummy_movies.dart에서 List<Movie> 제공