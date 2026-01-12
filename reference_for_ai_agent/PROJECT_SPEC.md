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
│   ├── data/                     # 데이터 관리 및 저장소
│   │   ├── dummy_movies.dart    # 더미 영화 데이터
│   │   ├── dummy_record.dart    # 더미 기록 데이터
│   │   ├── dummy_wishlist.dart # 더미 위시리스트 데이터
│   │   ├── dummy_summary.dart  # 더미 통계 데이터
│   │   ├── record_store.dart   # 기록 저장소 (ValueNotifier)
│   │   └── saved_store.dart    # 저장된 영화 ID 저장소
│   ├── state/                    # 전역 상태 관리
│   │   └── app_state.dart      # AppState (Provider 기반)
│   └── theme/                    # 테마 및 스타일
│       └── colors.dart         # 색상 상수 정의
├── test/                         # 단위 테스트 및 통합 테스트
│   ├── data/                    # 데이터 레이어 테스트
│   ├── models/                  # 모델 테스트
│   └── state/                   # 상태 관리 테스트
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
| `lib/data/` | 데이터 레이어 | 더미 데이터 제공 및 메모리 기반 저장소 (RecordStore, SavedStore) |
| `lib/state/` | 상태 관리 | Provider 기반 전역 상태 관리 (AppState) |
| `lib/theme/` | 테마 설정 | 색상, 폰트 등 UI 테마 상수 |
| `test/` | 테스트 코드 | 단위 테스트 및 통합 테스트 |
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
  - **북마크 토글**: 위시리스트 추가/제거 (SavedStore 사용)

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
  - **검색**: 제목, 한줄평으로 검색
- **기록 추가**
  - 탐색 탭의 "일기 쓰기" 버튼 또는 취향 탭의 추천 영화에서 기록 추가 가능

### 2.3. 저장 탭 (Saved Screen)

**파일:** `lib/screens/saved_screen.dart`

#### 주요 기능
- **위시리스트 표시**
  - 3열 그리드 뷰로 저장된 영화 목록 표시
  - 각 카드에 포스터, 제목, 평점 표시
  - 북마크 아이콘으로 저장 해제 가능
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
- **태그** (선택): "혼자", "친구", "가족", "극장", "OTT" 중 다중 선택
- **한줄평** (선택): 최대 20자 한 줄 입력
- **사진** (선택): 업로드 기능 (현재 스낵바로 구현)
- **후기** (선택): 여러 줄 상세 리뷰 입력

#### 저장 로직
- 별점이 0.0 이하일 경우 에러 메시지 표시
- RecordStore에 기록 추가 (메모리 기반)
- 저장 후 바텀 시트 닫기

---

## 3. 데이터 모델 및 데이터베이스

### 3.1. Flutter 앱 내 데이터 모델

#### 3.1.1. Movie (영화)

**파일:** `lib/models/movie.dart`

| 필드명 | 타입 | 설명 | 필수 |
|--------|------|------|------|
| `id` | `String` | 영화 고유 ID (API 기준) | ✅ |
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

### 3.2. 데이터베이스 스키마 (참조)

**참조 문서:** `reference_for_ai_agent/DB_SCHEMA.md`

프로젝트는 향후 Android Room Database로 마이그레이션을 고려한 스키마를 설계했습니다. 현재는 Flutter 앱에서 메모리 기반 저장소를 사용하고 있으며, DB 스키마는 백엔드 연동 시 참조용으로 정의되어 있습니다.

#### 주요 테이블 구조

| 테이블명 | 주요 컬럼 | 설명 |
|---------|----------|------|
| `Users` | `user_id`, `nickname`, `email`, `created_at` | 사용자 정보 |
| `Movies` | `movie_id`, `title`, `poster_url`, `release_date`, `runtime`, `vote_average` | 영화 정보 (API 캐싱) |
| `Records` | `record_id`, `user_id`, `movie_id`, `rating`, `watch_date`, `one_liner`, `detailed_review`, `photo_path`, `created_at` | 관람 기록 |
| `Wishlist` | `id`, `user_id`, `movie_id`, `saved_at` | 위시리스트 |
| `Genres` | `genre_id`, `name` | 장르 마스터 |
| `Movie_Genres` | `id`, `movie_id`, `genre_id` | 영화-장르 매핑 (N:M) |
| `Tags` | `tag_id`, `name` | 태그 마스터 |
| `Record_Tags` | `id`, `record_id`, `tag_id` | 기록-태그 매핑 (N:M) |

### 3.3. 현재 데이터 저장 방식

#### 3.3.1. RecordStore

**파일:** `lib/data/record_store.dart`

- **타입**: `ValueNotifier<List<Record>>`
- **용도**: 관람 기록을 메모리에 저장
- **메서드**:
  - `add(Record)`: 기록 추가 (최신이 위로)
  - `nextId()`: 다음 ID 생성

#### 3.3.2. SavedStore

**파일:** `lib/data/saved_store.dart`

- **타입**: `ValueNotifier<Set<String>>`
- **용도**: 저장된 영화 ID만 저장 (가벼운 구조)
- **메서드**:
  - `isSaved(String movieId)`: 저장 여부 확인
  - `toggle(String movieId)`: 저장 상태 토글
  - `remove(String movieId)`: 저장 해제
  - `clear()`: 전체 초기화

#### 3.3.3. AppState

**파일:** `lib/state/app_state.dart`

- **타입**: `ChangeNotifier` (Provider 패턴)
- **용도**: 전역 상태 관리
- **주요 상태**:
  - 북마크된 영화 ID 목록
  - 기록 정렬/필터 옵션
  - 위시리스트 아이템 목록
  - 통계 데이터

---

## 4. 의존성 및 패키지

### 4.1. 주요 의존성

**파일:** `pubspec.yaml`

| 패키지명 | 버전 | 용도 |
|---------|------|------|
| `flutter` | SDK | Flutter 프레임워크 |
| `cupertino_icons` | ^1.0.8 | iOS 스타일 아이콘 |
| `provider` | ^6.1.5+1 | 상태 관리 (Provider 패턴) |

### 4.2. 개발 의존성

| 패키지명 | 버전 | 용도 |
|---------|------|------|
| `flutter_test` | SDK | Flutter 테스트 프레임워크 |
| `flutter_lints` | ^6.0.0 | Dart/Flutter 린트 규칙 |

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

#### 4.3.2. flutter_lints (^6.0.0)

**용도:**
- Dart/Flutter 코드 품질 검사
- `analysis_options.yaml`에서 활성화된 린트 규칙에 따라 코드 스타일 및 잠재적 오류 검사

---

## 5. 아키텍처 및 상태 관리

### 5.1. 아키텍처 패턴

프로젝트는 **Provider 패턴**을 기반으로 한 상태 관리를 사용합니다.

- **전역 상태**: `AppState` (Provider)
- **로컬 상태**: 각 화면의 `StatefulWidget` 내부 상태
- **데이터 저장소**: `RecordStore`, `SavedStore` (ValueNotifier)

### 5.2. 데이터 흐름

```
UI (Screens/Widgets)
    ↓ (구독)
AppState (Provider)
    ↓ (참조)
Dummy Data / RecordStore / SavedStore
```

### 5.3. 주요 상태 관리 클래스

#### AppState (`lib/state/app_state.dart`)

**주요 기능:**
- 영화 목록 관리 (더미 데이터)
- 북마크 관리
- 기록 목록 관리 (필터, 정렬, 검색)
- 위시리스트 관리
- 통계 데이터 제공

**주요 메서드:**
- `toggleBookmark(String movieId)`: 북마크 토글
- `setRecordSortOption(RecordSortOption)`: 기록 정렬 옵션 설정
- `setRecordDateFilter(DateTime?, DateTime?)`: 기록 기간 필터 설정
- `setRecordSearchQuery(String)`: 기록 검색어 설정
- `addToWishlist(Movie)`: 위시리스트 추가
- `removeFromWishlist(String movieId)`: 위시리스트 제거

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

## 7. 향후 확장 계획

### 7.1. 데이터베이스 연동

- 현재 메모리 기반 저장소를 Android Room Database로 마이그레이션
- 로컬 데이터 영구 저장 및 오프라인 지원

### 7.2. 백엔드 API 연동

- REST API를 통한 서버 연동 (참조: `reference_for_ai_agent/API_GUIDE.md`)
- Firebase 또는 자체 백엔드 서버 연동

### 7.3. 이미지 처리

- 포스터 이미지 로컬 캐싱
- 사용자 업로드 사진 처리 (갤러리 접근, Firebase Storage 업로드)

### 7.4. 기능 확장

- 기록 수정/삭제 기능
- 상영관 정보 연동
- 소셜 기능 (기록 공유 등)

---

## 8. 참고 문서

- **API 명세서**: `reference_for_ai_agent/API_GUIDE.md`
- **DB 스키마**: `reference_for_ai_agent/DB_SCHEMA.md`
- **기능 명세서**: `reference_for_ai_agent/FUNCTIONAL_SPEC.md`
- **테스트 가이드**: `docs/TESTING_GUIDE.md`

---

**문서 작성일**: 2026년 1월  
**프로젝트 버전**: 1.0.0+1  
**Flutter SDK**: ^3.10.7
