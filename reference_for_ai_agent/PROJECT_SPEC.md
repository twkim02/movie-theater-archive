# 📚 무비어리 (Movie Diary) 프로젝트 상세 명세서

이 문서는 무비어리 프로젝트의 전체 구조, 기능, 데이터 모델, 의존성을 상세히 정리한 개발 문서입니다.

---

## 1. 프로젝트 구조

### 1.1. 디렉토리 트리

```
movie-theater-archive/
├── lib/                          # Flutter 애플리케이션 소스 코드
│   ├── main.dart                 # 앱 진입점
│   ├── app.dart                  # 앱 루트 위젯 (Provider 설정)
│   ├── models/                   # 데이터 모델 클래스
│   │   ├── movie.dart           # 영화 모델
│   │   ├── record.dart          # 관람 기록 모델
│   │   ├── wishlist.dart        # 위시리스트 모델
│   │   └── summary.dart         # 통계/취향 분석 모델
│   ├── screens/                  # 화면 위젯
│   │   ├── root_screen.dart     # 하단 네비게이션 바 포함 루트 화면
│   │   ├── explore_screen.dart  # 탐색 탭 (영화 검색 및 목록)
│   │   ├── diary_screen.dart    # 일기 탭 (관람 기록 목록)
│   │   ├── saved_screen.dart    # 저장 탭 (위시리스트)
│   │   └── taste_screen.dart    # 취향 탭 (통계 및 추천)
│   ├── widgets/                  # 재사용 가능한 위젯
│   │   └── add_record_sheet.dart # 기록 추가 바텀 시트
│   ├── data/                     # 더미 데이터 및 레거시 저장소
│   │   ├── dummy_movies.dart    # 더미 영화 데이터 (테스트용)
│   │   ├── dummy_record.dart    # 더미 기록 데이터 (테스트용)
│   │   ├── dummy_wishlist.dart # 더미 위시리스트 데이터 (테스트용)
│   │   ├── dummy_summary.dart  # 더미 통계 데이터
│   │   ├── record_store.dart   # 기록 저장소 (@Deprecated)
│   │   └── saved_store.dart    # 저장된 영화 ID 저장소 (@Deprecated)
│   ├── database/                 # 데이터베이스 레이어
│   │   └── movie_database.dart  # SQLite 데이터베이스 헬퍼 클래스
│   ├── repositories/             # Repository 패턴 구현
│   │   ├── movie_repository.dart      # 영화 데이터 Repository
│   │   ├── record_repository.dart     # 기록 데이터 Repository
│   │   ├── wishlist_repository.dart   # 위시리스트 데이터 Repository
│   │   └── tag_repository.dart        # 태그 데이터 Repository
│   ├── services/                 # 비즈니스 로직 서비스
│   │   ├── movie_initialization_service.dart  # 영화 초기화 서비스
│   │   ├── movie_update_service.dart          # 영화 갱신 서비스
│   │   ├── movie_db_initializer.dart          # 더미 데이터 초기화
│   │   └── user_initialization_service.dart   # 사용자 초기화 서비스
│   ├── api/                      # 외부 API 클라이언트
│   │   ├── tmdb_client.dart     # TMDb API 클라이언트
│   │   └── tmdb_mapper.dart     # TMDb API 응답 매퍼
│   ├── utils/                    # 유틸리티
│   │   └── env_loader.dart      # 환경 변수 로더
│   ├── state/                    # 전역 상태 관리
│   │   └── app_state.dart      # AppState (Provider 기반)
│   └── theme/                    # 테마 및 스타일
│       └── colors.dart         # 색상 상수 정의
├── test/                         # 단위 테스트 및 통합 테스트
│   ├── data/                    # 데이터 레이어 테스트
│   ├── models/                  # 모델 테스트
│   ├── state/                   # 상태 관리 테스트
│   ├── database/                # 데이터베이스 테스트
│   ├── repositories/            # Repository 테스트
│   ├── services/                # 서비스 테스트
│   └── integration/             # 통합 테스트
├── android/                      # Android 플랫폼 설정
├── ios/                          # iOS 플랫폼 설정
├── windows/                      # Windows 플랫폼 설정
├── macos/                        # macOS 플랫폼 설정
├── linux/                        # Linux 플랫폼 설정
├── web/                          # Web 플랫폼 설정
├── docs/                         # 프로젝트 문서
│   ├── api_contract.md         # API 계약 문서
│   ├── TESTING_GUIDE.md       # 테스트 가이드
│   └── [기타 테스트 요약 문서들]
├── reference_for_ai_agent/       # AI 에이전트 참조 문서
│   ├── API_GUIDE.md            # API 명세서
│   ├── DB_SCHEMA.md            # 데이터베이스 스키마
│   ├── FUNCTIONAL_SPEC.md      # 기능 명세서
│   ├── MOVIE_DB_MIGRATION_PLAN.md    # 영화 DB 마이그레이션 계획
│   ├── RECORD_WISHLIST_DB_MIGRATION_PLAN.md  # 기록/위시리스트 DB 마이그레이션 계획
│   └── PROJECT_SPEC.md        # 프로젝트 상세 명세서 (본 문서)
├── pubspec.yaml                  # Flutter 프로젝트 의존성 및 설정
├── analysis_options.yaml         # Dart 분석 옵션
└── README.md                     # 프로젝트 개요
```

### 1.2. 주요 디렉토리 역할

| 디렉토리 | 역할 | 주요 파일/기능 |
|---------|------|---------------|
| `lib/models/` | 데이터 모델 정의 | 영화, 기록, 위시리스트, 통계 모델 클래스 및 JSON 직렬화/역직렬화 |
| `lib/screens/` | 화면 위젯 | 4개 탭 화면 (탐색, 일기, 저장, 취향) 및 루트 화면 |
| `lib/widgets/` | 재사용 위젯 | 기록 추가 바텀 시트 등 공통 UI 컴포넌트 |
| `lib/data/` | 더미 데이터 및 레거시 | 더미 데이터 제공 (테스트용), 레거시 저장소 (@Deprecated) |
| `lib/database/` | 데이터베이스 레이어 | SQLite 데이터베이스 헬퍼 클래스 (MovieDatabase) |
| `lib/repositories/` | Repository 패턴 | 데이터 접근 로직 추상화 (Movie, Record, Wishlist, Tag) |
| `lib/services/` | 비즈니스 로직 | 초기화, 갱신, 데이터 마이그레이션 서비스 |
| `lib/api/` | 외부 API 클라이언트 | TMDb API 연동 및 데이터 변환 |
| `lib/state/` | 상태 관리 | Provider 기반 전역 상태 관리 (AppState) |
| `lib/theme/` | 테마 설정 | 색상, 폰트 등 UI 테마 상수 |
| `test/` | 테스트 코드 | 단위 테스트, 통합 테스트, 영속성 테스트 |
| `reference_for_ai_agent/` | 참조 문서 | API 명세, DB 스키마, 기능 명세 등 개발 가이드 |

---

## 2. 기능 명세

### 2.1. 탐색 탭 (Explore Screen)

**파일:** `lib/screens/explore_screen.dart`

#### 주요 기능
- **영화 목록 표시**
  - 최근 상영 중인 영화 섹션 (NEW 배지 표시)
  - 모든 영화 섹션
  - 각 영화 카드에 포스터, 제목, 장르, 연도, 러닝타임, 평점(5점 만점, 소수점 첫째 자리까지) 표시
- **영화 검색**
  - 제목 기반 실시간 검색
  - 검색 결과를 최근 상영/모든 영화 섹션에 반영
- **영화 액션**
  - **일기 쓰기 버튼**: 기록 추가 바텀 시트 열기
  - **영화관 보기 버튼**: 최근 상영 영화에만 표시 (현재 스낵바로 구현)
  - **북마크 토글**: 위시리스트 추가/제거 (DB에 저장)

### 2.2. 일기 탭 (Diary Screen)

**파일:** `lib/screens/diary_screen.dart`

#### 주요 기능
- **기록 목록 표시**
  - 3열 그리드 뷰로 기록 카드 표시
  - 각 카드에 포스터, 제목, 별점, 한줄평, 관람일 표시
  - 재관람 기록은 빨간 "재관람" 리본 표시
- **정렬 옵션**
  - **최신 관람일**: 관람일 기준 내림차순
  - **평점 순**: 별점 기준 내림차순 (동점 시 관람일 내림차순)
  - **많이 본 순**: 같은 영화를 여러 번 본 경우 그룹화하여 표시 (평균 별점, 관람 횟수 표시)
- **필터링**
  - **기간 설정**: YYYYMMDD 형식으로 시작일/종료일 입력
  - **검색**: 제목, 한줄평, 태그로 검색
- **기록 추가**
  - 탐색 탭의 "일기 쓰기" 버튼 또는 취향 탭의 추천 영화에서 기록 추가 가능
  - DB에 저장되어 앱 종료 후에도 유지

### 2.3. 저장 탭 (Saved Screen)

**파일:** `lib/screens/saved_screen.dart`

#### 주요 기능
- **위시리스트 표시**
  - 3열 그리드 뷰로 저장된 영화 목록 표시
  - 각 카드에 포스터, 제목, 평점 표시
  - 북마크 아이콘으로 저장 해제 가능
  - DB에 저장되어 앱 종료 후에도 유지
- **검색**
  - 저장된 영화 제목으로 검색

### 2.4. 취향 탭 (Taste Screen)

**파일:** `lib/screens/taste_screen.dart`

#### 주요 기능
- **통계 카드**
  - 총 기록 수
  - 평균 별점
  - 선호 장르 (가장 많이 본 장르, 동점 시 평균 별점 높은 순)
- **관람 추이 그래프**
  - 월별/연도별 토글
  - 라인 차트로 관람 횟수 추이 시각화
  - 데이터가 1개 이하일 경우 요약 텍스트 표시
- **추천 영화**
  - 선호 장르 기반 추천 (아직 보지 않은 영화)
  - 평균 별점이 높은 장르 기반 추천
  - 각 추천 영화에 추천 이유 표시
  - 일기 쓰기 및 북마크 추가 버튼 제공

### 2.5. 기록 추가 기능

**파일:** `lib/widgets/add_record_sheet.dart`

#### 입력 필드
- **관람일** (필수): 날짜 선택기로 선택
- **별점** (필수): 0.5 단위로 0.5~5.0점 입력 (별 5개 터치 입력)
- **태그** (선택): "혼자", "친구", "가족", "극장", "OTT" 중 다중 선택 (기본 태그 자동 생성)
- **한줄평** (선택): 최대 20자 한 줄 입력
- **사진** (선택): 업로드 기능 (현재 스낵바로 구현)
- **후기** (선택): 여러 줄 상세 리뷰 입력

#### 저장 로직
- 별점이 0.0 이하일 경우 에러 메시지 표시
- `AppState.addRecord()`를 통해 DB에 저장
- 태그는 자동으로 DB에 생성 및 매핑
- 저장 후 바텀 시트 닫기 및 UI 자동 업데이트

---

## 3. 데이터 모델 및 데이터베이스

### 3.1. Flutter 앱 내 데이터 모델

#### 3.1.1. Movie (영화)

**파일:** `lib/models/movie.dart`

| 필드명 | 타입 | 설명 | 필수 |
|--------|------|------|------|
| `id` | `String` | 영화 고유 ID (TMDb API 기준) | ✅ |
| `title` | `String` | 영화 제목 | ✅ |
| `posterUrl` | `String` | 포스터 이미지 URL | ✅ |
| `genres` | `List<String>` | 장르 목록 | ✅ |
| `releaseDate` | `String` | 개봉일 (YYYY-MM-DD) | ✅ |
| `runtime` | `int` | 러닝타임 (분) | ✅ |
| `voteAverage` | `double` | 대중 평점 | ✅ |
| `isRecent` | `bool` | 최근 상영 여부 | ✅ |

**주요 메서드:**
- `fromJson()`: JSON에서 Movie 객체 생성
- `toJson()`: Movie 객체를 JSON으로 변환
- `copyWith()`: 불변 객체 복사 및 수정

#### 3.1.2. Record (관람 기록)

**파일:** `lib/models/record.dart`

| 필드명 | 타입 | 설명 | 필수 |
|--------|------|------|------|
| `id` | `int` | 기록 고유 ID | ✅ |
| `userId` | `int` | 사용자 ID | ✅ |
| `rating` | `double` | 내 별점 (0.0 ~ 5.0) | ✅ |
| `watchDate` | `DateTime` | 관람일 | ✅ |
| `oneLiner` | `String?` | 한줄평 | ❌ |
| `detailedReview` | `String?` | 상세 리뷰 | ❌ |
| `tags` | `List<String>` | 태그 목록 | ✅ |
| `photoUrl` | `String?` | 업로드한 사진 URL | ❌ |
| `movie` | `Movie` | 영화 정보 (중첩 객체) | ✅ |

**주요 메서드:**
- `fromJson()`: JSON에서 Record 객체 생성 (Movie 객체 병합 가능)
- `toJson()`: Record 객체를 JSON으로 변환
- `copyWith()`: 불변 객체 복사 및 수정

#### 3.1.3. WishlistItem (위시리스트 아이템)

**파일:** `lib/models/wishlist.dart`

| 필드명 | 타입 | 설명 | 필수 |
|--------|------|------|------|
| `movie` | `Movie` | 영화 정보 | ✅ |
| `savedAt` | `DateTime` | 찜한 날짜 및 시간 | ✅ |

**주요 메서드:**
- `fromJson()`: JSON에서 WishlistItem 객체 생성
- `toJson()`: WishlistItem 객체를 JSON으로 변환
- `copyWith()`: 불변 객체 복사 및 수정

#### 3.1.4. Statistics (취향 분석 통계)

**파일:** `lib/models/summary.dart`

**Statistics 클래스 구조:**

| 필드명 | 타입 | 설명 |
|--------|------|------|
| `summary` | `StatisticsSummary` | 요약 통계 정보 |
| `genreDistribution` | `GenreDistribution` | 장르 분포 데이터 |
| `viewingTrend` | `ViewingTrend` | 관람 추이 데이터 |

**StatisticsSummary:**

| 필드명 | 타입 | 설명 |
|--------|------|------|
| `totalRecords` | `int` | 총 기록 수 |
| `averageRating` | `double` | 평균 별점 |
| `topGenre` | `String` | 최다 선호 장르 |

**GenreDistribution:**

| 필드명 | 타입 | 설명 |
|--------|------|------|
| `all` | `List<GenreDistributionItem>` | 전체 기간 장르 분포 |
| `recent1Year` | `List<GenreDistributionItem>` | 최근 1년 장르 분포 |
| `recent3Years` | `List<GenreDistributionItem>` | 최근 3년 장르 분포 |

**GenreDistributionItem:**

| 필드명 | 타입 | 설명 |
|--------|------|------|
| `name` | `String` | 장르 이름 |
| `count` | `int` | 해당 장르를 본 횟수 |

**ViewingTrend:**

| 필드명 | 타입 | 설명 |
|--------|------|------|
| `yearly` | `List<ViewingTrendItem>` | 연도별 관람 횟수 |
| `monthly` | `List<ViewingTrendItem>` | 월별 관람 횟수 |

**ViewingTrendItem:**

| 필드명 | 타입 | 설명 |
|--------|------|------|
| `date` | `String` | 날짜 (YYYY 또는 YYYY-MM) |
| `count` | `int` | 해당 기간에 본 영화 수 |

### 3.2. 데이터베이스 스키마

**참조 문서:** `reference_for_ai_agent/DB_SCHEMA.md`

프로젝트는 **SQLite 데이터베이스**를 사용하여 로컬 데이터를 영구 저장합니다. 모든 데이터는 앱 종료 후에도 유지됩니다.

#### 주요 테이블 구조

| 테이블명 | 주요 컬럼 | 설명 |
|---------|----------|------|
| `users` | `user_id`, `nickname`, `email`, `created_at` | 사용자 정보 |
| `movies` | `id`, `title`, `poster_url`, `release_date`, `runtime`, `vote_average`, `is_recent`, `genres`, `last_updated` | 영화 정보 (TMDb API 캐싱) |
| `records` | `record_id`, `user_id`, `movie_id`, `rating`, `watch_date`, `one_liner`, `detailed_review`, `photo_path`, `created_at` | 관람 기록 |
| `wishlist` | `id`, `user_id`, `movie_id`, `saved_at` | 위시리스트 |
| `tags` | `tag_id`, `name` | 태그 마스터 |
| `record_tags` | `id`, `record_id`, `tag_id` | 기록-태그 매핑 (N:M) |

#### 데이터베이스 버전 관리
- **현재 버전**: 2
- **버전 1**: `movies` 테이블만 존재
- **버전 2**: `users`, `records`, `tags`, `record_tags`, `wishlist` 테이블 추가

#### 외래 키 제약
- `records.user_id` → `users.user_id` (ON DELETE CASCADE)
- `records.movie_id` → `movies.id` (ON DELETE CASCADE)
- `wishlist.user_id` → `users.user_id` (ON DELETE CASCADE)
- `wishlist.movie_id` → `movies.id` (ON DELETE CASCADE)
- `record_tags.record_id` → `records.record_id` (ON DELETE CASCADE)
- `record_tags.tag_id` → `tags.tag_id` (ON DELETE CASCADE)

### 3.3. 현재 데이터 저장 방식

#### 3.3.1. MovieDatabase (`lib/database/movie_database.dart`)

**역할**: SQLite 데이터베이스 헬퍼 클래스

**주요 기능:**
- DB 초기화 및 버전 관리
- 테이블 생성 및 마이그레이션
- CRUD 메서드 (영화, 기록, 위시리스트, 태그, 사용자)
- 데이터 변환 (Dart 모델 ↔ DB Map)
- 검색 및 필터링

**주요 메서드:**
- `database`: 싱글톤 DB 인스턴스 접근
- `insertMovie()`, `updateMovie()`, `getMovieById()`, `getAllMovies()`
- `insertRecord()`, `updateRecord()`, `getRecordById()`, `getRecordsByUserId()`
- `insertWishlist()`, `deleteWishlist()`, `getWishlist()`
- `insertTag()`, `getTagsByRecordId()`, `setTagsForRecord()`
- `insertUser()`, `getUserById()`, `createDefaultUser()`

#### 3.3.2. Repository 패턴

**역할**: 데이터 접근 로직을 비즈니스 로직에서 분리

**Repository 클래스:**

1. **MovieRepository** (`lib/repositories/movie_repository.dart`)
   - 영화 데이터 CRUD
   - 검색 및 필터링
   - TMDb API 연동 지원

2. **RecordRepository** (`lib/repositories/record_repository.dart`)
   - 기록 데이터 CRUD
   - 태그 매핑 처리
   - 검색 및 필터링

3. **WishlistRepository** (`lib/repositories/wishlist_repository.dart`)
   - 위시리스트 추가/제거
   - 정렬 및 필터링
   - Movie 객체 조회

4. **TagRepository** (`lib/repositories/tag_repository.dart`)
   - 태그 생성 및 조회
   - 기록-태그 매핑 관리
   - 기본 태그 초기화

#### 3.3.3. 서비스 레이어

**역할**: 비즈니스 로직 및 초기화 처리

**서비스 클래스:**

1. **MovieInitializationService** (`lib/services/movie_initialization_service.dart`)
   - TMDb API로 영화 데이터 초기화
   - 현재 상영 중인 영화 및 인기 영화 가져오기

2. **MovieUpdateService** (`lib/services/movie_update_service.dart`)
   - 현재 상영 중인 영화 자동 갱신
   - 24시간 주기 갱신 체크

3. **UserInitializationService** (`lib/services/user_initialization_service.dart`)
   - 기본 사용자(Guest) 생성
   - 기본 태그 초기화

4. **MovieDbInitializer** (`lib/services/movie_db_initializer.dart`)
   - 더미 데이터를 DB에 저장
   - 테스트 및 개발용

#### 3.3.4. AppState (`lib/state/app_state.dart`)

**타입**: `ChangeNotifier` (Provider 패턴)

**역할**: 전역 상태 관리 및 UI와 Repository 간 브릿지

**주요 상태:**
- 영화 리스트 캐시 (DB에서 로드)
- 기록 리스트 캐시 (DB에서 로드)
- 위시리스트 캐시 (DB에서 로드)
- 북마크 상태 캐시 (위시리스트 기반)
- 기록 정렬/필터 옵션
- 로딩 상태

**주요 메서드:**
- `loadMoviesFromDatabase()`: DB에서 영화 로드
- `loadRecordsFromDatabase()`: DB에서 기록 로드
- `loadWishlistFromDatabase()`: DB에서 위시리스트 로드
- `addRecord(Record)`: 기록 추가 (DB 저장)
- `updateRecord(Record)`: 기록 수정 (DB 업데이트)
- `deleteRecord(int)`: 기록 삭제 (DB 삭제)
- `addToWishlist(Movie)`: 위시리스트 추가 (DB 저장)
- `removeFromWishlist(String)`: 위시리스트 제거 (DB 삭제)
- `toggleBookmark(String)`: 북마크 토글 (DB 저장)
- `setRecordSortOption()`, `setRecordDateFilter()`, `setRecordSearchQuery()`: 필터/정렬 설정

#### 3.3.5. 레거시 저장소 (@Deprecated)

**RecordStore** (`lib/data/record_store.dart`)
- **상태**: `@Deprecated` - 더 이상 사용하지 않음
- **대체**: `AppState.addRecord()` 및 `RecordRepository` 사용

**SavedStore** (`lib/data/saved_store.dart`)
- **상태**: `@Deprecated` - 더 이상 사용하지 않음
- **대체**: `AppState.toggleBookmark()` 및 `WishlistRepository` 사용

---

## 4. 의존성 및 패키지

### 4.1. 주요 의존성

**파일:** `pubspec.yaml`

| 패키지명 | 버전 | 용도 |
|---------|------|------|
| `flutter` | SDK | Flutter 프레임워크 |
| `cupertino_icons` | ^1.0.8 | iOS 스타일 아이콘 |
| `provider` | ^6.1.5+1 | 상태 관리 (Provider 패턴) |
| `sqflite` | ^2.3.0 | SQLite 데이터베이스 |
| `path` | ^1.8.3 | 파일 경로 처리 |
| `http` | ^1.1.0 | HTTP 통신 (TMDb API) |
| `flutter_dotenv` | ^5.1.0 | 환경 변수 관리 (API 키) |
| `shared_preferences` | ^2.2.2 | 초기화 플래그 저장 |

### 4.2. 개발 의존성

| 패키지명 | 버전 | 용도 |
|---------|------|------|
| `flutter_test` | SDK | Flutter 테스트 프레임워크 |
| `flutter_lints` | ^6.0.0 | Dart/Flutter 린트 규칙 |
| `sqflite_common_ffi` | ^2.3.0 | 테스트용 SQLite (FFI) |

### 4.3. 패키지 상세 설명

#### 4.3.1. provider (^6.1.5+1)

**용도:**
- 전역 상태 관리
- `AppState` 클래스를 `ChangeNotifierProvider`로 제공하여 앱 전체에서 접근 가능
- `context.watch<AppState>()` 또는 `context.read<AppState>()`로 상태 구독/접근

**사용 예시:**
```dart
// app.dart
ChangeNotifierProvider(
  create: (_) => AppState(),
  child: MaterialApp(...),
)

// 화면에서 사용
final appState = context.watch<AppState>();
final records = appState.records;
```

#### 4.3.2. sqflite (^2.3.0)

**용도:**
- SQLite 데이터베이스 연동
- 로컬 데이터 영구 저장
- 트랜잭션 및 외래 키 제약 지원

#### 4.3.3. http (^1.1.0)

**용도:**
- TMDb API와의 HTTP 통신
- 영화 데이터 가져오기 및 갱신

#### 4.3.4. flutter_dotenv (^5.1.0)

**용도:**
- 환경 변수 관리
- TMDb API 키 보안 저장
- `env.json` 파일에서 로드

#### 4.3.5. shared_preferences (^2.2.2)

**용도:**
- 초기화 완료 플래그 저장
- 앱 설정 저장

---

## 5. 아키텍처 및 상태 관리

### 5.1. 아키텍처 패턴

프로젝트는 **Repository 패턴**과 **Provider 패턴**을 결합한 아키텍처를 사용합니다.

- **전역 상태**: `AppState` (Provider)
- **로컬 상태**: 각 화면의 `StatefulWidget` 내부 상태
- **데이터 저장소**: SQLite 데이터베이스 (MovieDatabase)
- **데이터 접근**: Repository 패턴 (MovieRepository, RecordRepository, WishlistRepository, TagRepository)
- **비즈니스 로직**: Service 레이어 (Initialization, Update)

### 5.2. 데이터 흐름

```
UI (Screens/Widgets)
    ↓ (구독)
AppState (Provider)
    ↓ (호출)
Repository (MovieRepository, RecordRepository, etc.)
    ↓ (접근)
MovieDatabase (SQLite)
    ↓ (저장)
로컬 DB 파일
```

### 5.3. 주요 상태 관리 클래스

#### AppState (`lib/state/app_state.dart`)

**주요 기능:**
- 영화 목록 관리 (DB에서 로드)
- 북마크 관리 (위시리스트 기반)
- 기록 목록 관리 (DB에서 로드, 필터, 정렬, 검색)
- 위시리스트 관리 (DB에서 로드)
- 통계 데이터 제공
- 로딩 상태 관리

**주요 메서드:**
- `loadMoviesFromDatabase()`: DB에서 영화 로드
- `loadRecordsFromDatabase()`: DB에서 기록 로드
- `loadWishlistFromDatabase()`: DB에서 위시리스트 로드
- `addRecord(Record)`: 기록 추가 (DB 저장)
- `updateRecord(Record)`: 기록 수정 (DB 업데이트)
- `deleteRecord(int)`: 기록 삭제 (DB 삭제)
- `addToWishlist(Movie)`: 위시리스트 추가 (DB 저장)
- `removeFromWishlist(String)`: 위시리스트 제거 (DB 삭제)
- `toggleBookmark(String)`: 북마크 토글 (DB 저장)
- `setRecordSortOption(RecordSortOption)`: 기록 정렬 옵션 설정
- `setRecordDateFilter(DateTime?, DateTime?)`: 기록 기간 필터 설정
- `setRecordSearchQuery(String)`: 기록 검색어 설정

### 5.4. Repository 패턴

**장점:**
- 데이터 접근 로직과 비즈니스 로직 분리
- 테스트 용이성
- 데이터 소스 변경 시 유연성 (예: DB → API)
- 코드 재사용성

**Repository 구조:**
```
Repository (인터페이스 역할)
    ↓
MovieDatabase (구현)
    ↓
SQLite
```

---

## 6. 테마 및 스타일

### 6.1. 색상 정의

**파일:** `lib/theme/colors.dart`

| 상수명 | 색상 값 | 용도 |
|--------|---------|------|
| `backgroundColor` | `#FFFBFB` | 앱 배경색 |
| `primaryColor` | `#B48CFF` | 주요 액션 버튼 색상 |
| `textPrimary` | `#222222` | 주요 텍스트 색상 |
| `textSecondary` | `#777777` | 보조 텍스트 색상 |

### 6.2. UI 스타일 특징

- **카드 기반 디자인**: 둥근 모서리, 그림자 효과
- **그리드 레이아웃**: 3열 그리드로 영화/기록 표시
- **바텀 시트**: 기록 추가 시 모달 바텀 시트 사용
- **칩(Chip) UI**: 정렬 옵션, 태그 선택 등에 사용

---

## 7. 데이터 영속성

### 7.1. 현재 구현 상태

✅ **완료된 항목:**
- SQLite 데이터베이스 연동 완료
- 모든 데이터 (영화, 기록, 위시리스트, 태그, 사용자) DB 저장
- 앱 종료 후 재시작 시 데이터 유지 확인
- 외래 키 제약 및 CASCADE 삭제 구현
- 데이터 무결성 보장

### 7.2. 데이터 초기화

**앱 최초 실행 시:**
1. DB 초기화 (테이블 생성)
2. 기본 사용자(Guest) 생성
3. 기본 태그 초기화 ("혼자", "친구", "가족", "극장", "OTT")
4. TMDb API로 영화 데이터 초기화 (또는 더미 데이터)

**앱 재시작 시:**
1. DB에서 데이터 자동 로드
2. 24시간 경과 시 현재 상영 중인 영화 자동 갱신

### 7.3. 데이터 마이그레이션

- **DB 버전 관리**: `_databaseVersion`으로 관리
- **마이그레이션**: `_onUpgrade()` 메서드에서 처리
- **안전한 업그레이드**: 기존 데이터 보존하며 새 테이블 추가

---

## 8. 향후 확장 계획

### 8.1. 백엔드 API 연동

- REST API를 통한 서버 연동 (참조: `reference_for_ai_agent/API_GUIDE.md`)
- Firebase 또는 자체 백엔드 서버 연동
- 데이터 동기화 (클라우드 백업)

### 8.2. 이미지 처리

- 포스터 이미지 로컬 캐싱
- 사용자 업로드 사진 처리 (갤러리 접근, Firebase Storage 업로드)

### 8.3. 기능 확장

- 기록 수정/삭제 기능 (UI 구현)
- 상영관 정보 연동
- 소셜 기능 (기록 공유 등)
- 다중 사용자 지원

### 8.4. 성능 최적화

- 대량 데이터 조회 시 페이지네이션
- 이미지 로딩 최적화
- DB 쿼리 최적화

---

## 9. 참고 문서

- **API 명세서**: `reference_for_ai_agent/API_GUIDE.md`
- **DB 스키마**: `reference_for_ai_agent/DB_SCHEMA.md`
- **기능 명세서**: `reference_for_ai_agent/FUNCTIONAL_SPEC.md`
- **영화 DB 마이그레이션 계획**: `reference_for_ai_agent/MOVIE_DB_MIGRATION_PLAN.md`
- **기록/위시리스트 DB 마이그레이션 계획**: `reference_for_ai_agent/RECORD_WISHLIST_DB_MIGRATION_PLAN.md`
- **테스트 가이드**: `docs/TESTING_GUIDE.md`

---

**문서 작성일**: 2026년 1월  
**최종 업데이트**: 2026년 1월 (DB 마이그레이션 완료 반영)  
**프로젝트 버전**: 1.0.0+1  
**Flutter SDK**: ^3.10.7
