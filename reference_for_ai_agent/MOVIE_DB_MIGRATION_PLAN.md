# 🎬 영화 정보 DB 마이그레이션 작업 계획서

이 문서는 더미 데이터에서 실제 DB 저장 및 TMDb API 연동으로 전환하는 작업 순서를 정리합니다.

---

## 📋 작업 순서 개요

```
1단계: 환경 설정 및 DB 구조 설계
   ↓
2단계: TMDb API 클라이언트 구현
   ↓
3단계: DB 저장 로직 구현 및 테스트
   ↓
4단계: 초기 데이터 저장 (현재 상영 중, 과거 명작)
   ↓
5단계: 자동 갱신 시스템
```

---

## 1단계: 환경 설정 및 DB 구조 설계

### 1.1. 필요한 패키지 추가

**`pubspec.yaml`에 추가할 의존성:**

```yaml
dependencies:
  # SQLite 데이터베이스
  sqflite: ^2.3.0
  path: ^1.8.3
  
  # HTTP 통신 (TMDb API)
  http: ^1.1.0
  
  # JSON 직렬화
  json_annotation: ^4.8.1
  
  # 환경 변수 관리 (API 키)
  flutter_dotenv: ^5.1.0

dev_dependencies:
  json_serializable: ^6.7.1
  build_runner: ^2.4.7
```

### 1.2. DB 스키마 설계

**영화 정보 저장을 위한 테이블 구조:**

| 컬럼명 | 타입 | 설명 |
|--------|------|------|
| `id` | `TEXT PRIMARY KEY` | TMDb 영화 ID (movie_id) |
| `title` | `TEXT NOT NULL` | 영화 제목 |
| `poster_url` | `TEXT` | 포스터 이미지 URL |
| `release_date` | `TEXT` | 개봉일 (YYYY-MM-DD) |
| `runtime` | `INTEGER` | 러닝타임 (분) |
| `vote_average` | `REAL` | 대중 평점 |
| `is_recent` | `INTEGER` | 최근 상영 여부 (0 or 1) |
| `last_updated` | `INTEGER` | 마지막 업데이트 시간 (timestamp) |

**장르 정보 (별도 테이블 또는 JSON 저장):**
- 옵션 1: 별도 `genres` 테이블 + `movie_genres` 매핑 테이블
- 옵션 2: `genres` 컬럼에 JSON 배열로 저장 (간단한 경우)

**초기 구현 시 간단하게 시작:**
- `genres` 컬럼을 `TEXT`로 두고 JSON 배열 저장

### 1.3. DB 헬퍼 클래스 생성

**생성할 파일:** `lib/database/movie_database.dart`

**주요 기능:**
- DB 초기화 (`initDatabase()`)
- 테이블 생성 (`CREATE TABLE`)
- CRUD 메서드 (insert, update, get, getAll, delete)
- 검색 메서드

### 1.4. 환경 변수 설정

**`.env` 파일 생성:**
```
TMDB_API_KEY=your_api_key_here
TMDB_BASE_URL=https://api.themoviedb.org/3
```

**`.gitignore`에 추가:**
```
.env
```

---

## 2단계: TMDb API 클라이언트 구현

### 2.1. TMDb API 이해

**필요한 API 엔드포인트:**

1. **현재 상영 중인 영화**
   - `GET /movie/now_playing`
   - Query params: `api_key`, `language=ko-KR`, `region=KR`

2. **인기 영화 (과거 명작 포함)**
   - `GET /movie/popular`
   - Query params: `api_key`, `language=ko-KR`, `page=1`

3. **영화 상세 정보**
   - `GET /movie/{movie_id}`
   - Query params: `api_key`, `language=ko-KR`

4. **영화 검색**
   - `GET /search/movie`
   - Query params: `api_key`, `query={검색어}`, `language=ko-KR`

**API 응답 구조:**
```json
{
  "results": [
    {
      "id": 496243,
      "title": "기생충",
      "poster_path": "/mSi0gskYpmf1FbXngM37s2HppXh.jpg",
      "release_date": "2019-05-30",
      "vote_average": 8.5,
      "genre_ids": [35, 53, 18],
      // ... 기타 필드
    }
  ],
  "page": 1,
  "total_pages": 500
}
```

### 2.2. API 클라이언트 클래스 생성

**생성할 파일:** `lib/api/tmdb_client.dart`

**주요 메서드:**
- `getNowPlayingMovies()`: 현재 상영 중인 영화 가져오기
- `getPopularMovies(page)`: 인기 영화 가져오기
- `getMovieDetails(movieId)`: 영화 상세 정보 가져오기
- `searchMovies(query)`: 영화 검색
- `_buildImageUrl(path)`: 포스터 URL 생성

**장르 ID → 이름 매핑:**
- TMDb 장르 API: `GET /genre/movie/list`
- 장르 ID를 한국어 이름으로 변환하는 로직 필요

### 2.3. 데이터 변환 로직

**생성할 파일:** `lib/api/tmdb_mapper.dart`

**기능:**
- TMDb API 응답을 앱의 `Movie` 모델로 변환
- 장르 ID 배열을 장르 이름 배열로 변환
- `poster_path`를 전체 URL로 변환

---

## 3단계: DB 저장 로직 구현 및 테스트

### 3.1. DB 저장소 클래스 생성

**생성할 파일:** `lib/repositories/movie_repository.dart`

**주요 메서드:**
- `insertMovie(Movie)`: 영화 추가
- `insertMovies(List<Movie>)`: 여러 영화 일괄 추가
- `getMovieById(String id)`: ID로 조회
- `getAllMovies()`: 전체 조회
- `getRecentMovies()`: 최근 상영 영화 조회
- `searchMovies(String query)`: 제목으로 검색
- `updateMovie(Movie)`: 영화 정보 업데이트
- `deleteMovie(String id)`: 영화 삭제

### 3.2. 더미 데이터로 테스트

**작업 내용:**
1. `DummyMovies.getMovies()`의 데이터를 DB에 저장
2. DB에서 데이터를 읽어서 UI에 표시되는지 확인
3. `AppState`나 기존 코드에서 `DummyMovies` 대신 `MovieRepository` 사용하도록 수정

### 3.3. 기존 코드 통합

**수정할 파일들:**
- `lib/state/app_state.dart`: `movies` getter를 DB에서 가져오도록 변경
- `lib/screens/explore_screen.dart`: DB 조회 로직 적용
- 기타 영화 목록을 사용하는 모든 화면

**주의사항:**
- 초기에는 DB가 비어있을 수 있으므로, 빈 리스트 반환 처리
- 에러 발생 시 fallback 로직 (더미 데이터 또는 빈 리스트)

---

## 4단계: 초기 데이터 저장 (현재 상영 중, 과거 명작)

### 4.1. 초기화 서비스 생성

**생성할 파일:** `lib/services/movie_initialization_service.dart`

**주요 기능:**
- `initializeMovies()`: 앱 최초 실행 시 호출
- 현재 상영 중인 영화 가져오기 및 저장
- 인기 영화 가져오기 및 저장 (페이지네이션)
- 중복 체크 (이미 DB에 있으면 스킵)

### 4.2. 초기화 로직 구현

**작업 순서:**
1. TMDb API로 현재 상영 중인 영화 가져오기
2. `is_recent = 1`로 설정하여 DB에 저장
3. 인기 영화를 여러 페이지에 걸쳐 가져오기 (예: 1~3페이지)
4. `is_recent = 0`으로 설정하여 DB에 저장
5. 장르 정보도 함께 저장

**주의사항:**
- API 호출 실패 시 에러 처리
- 네트워크가 없을 때 처리
- 진행 상황 표시 (선택사항)

### 4.3. 앱 시작 시 초기화

**수정할 파일:** `lib/main.dart` 또는 `lib/app.dart`

**로직:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // DB 초기화
  await MovieDatabase.init();
  
  // 최초 실행 시에만 초기화
  final prefs = await SharedPreferences.getInstance();
  final isInitialized = prefs.getBool('movies_initialized') ?? false;
  
  if (!isInitialized) {
    await MovieInitializationService.initializeMovies();
    await prefs.setBool('movies_initialized', true);
  }
  
  runApp(const MyApp());
}
```

**또는 앱 내에서 수동 초기화:**
- 설정 화면에 "영화 데이터 초기화" 버튼 추가

---

## 5단계: 자동 갱신 시스템 (백그라운드 작업)

### 5.1. 갱신 서비스 생성

**생성할 파일:** `lib/services/movie_update_service.dart`

**주요 기능:**
- `updateNowPlayingMovies()`: 현재 상영 중인 영화 갱신
  - TMDb API로 최신 데이터 가져오기
  - 기존 `is_recent = 1`인 영화는 `is_recent = 0`으로 변경
  - 새로 상영 중인 영화 추가 및 `is_recent = 1`로 설정
- `checkNewReleases()`: 새로 개봉한 영화 확인
  - 날짜 기반으로 필터링 (예: 최근 7일)
  - DB에 없으면 추가

### 5.2. 갱신 전략

**스마트 업데이트 (권장)**
- 새로 상영 중인 영화만 추가
- 더 이상 상영 중이 아닌 영화는 `is_recent = 0`으로 변경
- `is_recent` 플래그를 업데이트만 하고 영화 데이터는 삭제하지 않음
- 사용자가 북마크하거나 기록한 영화는 항상 유지
- 장점: 데이터 손실 없음
- 단점: 로직이 복잡함

---

## 📝 작업 체크리스트

### 1단계 체크리스트
- [ ] `pubspec.yaml`에 필요한 패키지 추가
- [ ] `flutter pub get` 실행
- [ ] `.env` 파일 생성 및 API 키 설정
- [ ] `MovieDatabase` 클래스 생성
- [ ] DB 테이블 생성 로직 구현

### 2단계 체크리스트
- [ ] TMDb API 키 발급
- [ ] `TmdbClient` 클래스 생성
- [ ] API 엔드포인트 메서드 구현
- [ ] `TmdbMapper` 클래스 생성
- [ ] API 응답 → Movie 모델 변환 테스트

### 3단계 체크리스트
- [ ] `MovieRepository` 클래스 생성
- [ ] CRUD 메서드 구현
- [ ] 더미 데이터로 DB 저장 테스트
- [ ] `AppState`에서 DB 사용하도록 수정
- [ ] UI에서 DB 데이터 표시 확인

### 4단계 체크리스트
- [ ] `MovieInitializationService` 클래스 생성
- [ ] 현재 상영 중인 영화 가져오기 및 저장
- [ ] 인기 영화 가져오기 및 저장
- [ ] 앱 시작 시 초기화 로직 추가
- [ ] 초기화 완료 플래그 저장

### 5단계 체크리스트
- [ ] `MovieUpdateService` 클래스 생성
- [ ] 갱신 로직 구현
- [ ] 갱신 테스트 (수동 및 자동)

---

## 🔄 마이그레이션 전략

### 단계별 전환

1. **DB 구조만 먼저 구현**
   - 더미 데이터를 DB에 저장
   - 기존 코드는 그대로 사용

2. **TMDb API 연동 추가**
   - API 클라이언트 구현
   - 수동으로 데이터 가져와서 저장하는 기능 추가

3. **기존 코드 점진적 교체**
   - `DummyMovies` → `MovieRepository` 사용하도록 변경
   - 각 화면별로 순차적으로 수정

4. **자동화 추가**
   - 초기화 서비스
   - 자동 갱신 서비스

### 롤백 계획

- 각 단계마다 커밋
- 문제 발생 시 이전 단계로 롤백 가능하도록 구성

---

## 📚 참고 자료

- **TMDb API 문서**: https://developers.themoviedb.org/3
- **sqflite 패키지**: https://pub.dev/packages/sqflite
- **http 패키지**: https://pub.dev/packages/http

---

## ⚠️ 주의사항

1. **API 키 보안**
   - `.env` 파일은 절대 커밋하지 않기
   - 프로덕션에서는 환경 변수나 안전한 저장소 사용

2. **API 호출 제한**
   - TMDb API는 무료 플랜에 호출 제한이 있음
   - 불필요한 중복 호출 방지
   - 캐싱 전략 활용

3. **에러 처리**
   - 네트워크 에러 처리
   - API 응답 에러 처리
   - DB 에러 처리

4. **성능**
   - 대량 데이터 삽입 시 트랜잭션 사용
   - 인덱스 추가 (제목 검색 최적화)
   - 페이지네이션 구현

---

**문서 작성일**: 2026년 1월  
**작업 예상 기간**: 1-2주 (단계별로 나눠서 진행)
