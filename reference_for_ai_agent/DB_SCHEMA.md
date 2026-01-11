# 🗄️ 무비어리(Movie Diary) DB Schema

이 문서는 Android Room Database(SQLite)를 기준으로 설계된 데이터베이스 스키마 명세서입니다.

## 1. ER Diagram (Conceptual)

- **User** (1) : (N) **Record**
- **User** (1) : (N) **Wishlist**
- **Movie** (1) : (N) **Record**
- **Movie** (1) : (N) **Wishlist**
- **Movie** (N) : (M) **Genre** (via `Movie_Genre`)
- **Record** (N) : (M) **Tag** (via `Record_Tag`)

---

## 2. Tables (Entities)

### 2.1. Users (사용자)
로컬 전용 앱이므로 초기에는 기본 사용자(Guest) 1명만 존재합니다. 향후 서버 연동 시 확장을 고려한 구조입니다.

| Column Name | Type | Key | Nullable | Description |
|---|---|---|---|---|
| `user_id` | Long | PK | No | 사용자 고유 ID (Auto Increment) |
| `nickname` | String | | No | 닉네임 |
| `email` | String | | Yes | 이메일 (로그인용, 로컬 모드 시 null) |
| `created_at` | Long | | No | 가입일 (Timestamp) |

### 2.2. Movies (영화)
API에서 가져온 영화 정보를 로컬에 캐싱하여 사용합니다.

| Column Name | Type | Key | Nullable | Description |
|---|---|---|---|---|
| `movie_id` | String | PK | No | 영화 고유 ID (API 기준) |
| `title` | String | | No | 영화 제목 |
| `poster_url` | String | | Yes | 포스터 이미지 URL |
| `release_date` | String | | Yes | 개봉일 (YYYY-MM-DD) |
| `runtime` | Integer | | Yes | 상영 시간 (분) |
| `vote_average` | Float | | Yes | 대중 평점 |

### 2.3. Genres (장르)

| Column Name | Type | Key | Nullable | Description |
|---|---|---|---|---|
| `genre_id` | Integer | PK | No | 장르 ID |
| `name` | String | | No | 장르명 (예: 액션, 로맨스) |

### 2.4. Movie_Genres (영화-장르 매핑)
N:M 관계 해소를 위한 중간 테이블입니다.

| Column Name | Type | Key | Nullable | Description |
|---|---|---|---|---|
| `id` | Long | PK | No | 고유 ID (Auto Increment) |
| `movie_id` | String | FK | No | Movies 테이블 참조 |
| `genre_id` | Integer | FK | No | Genres 테이블 참조 |

### 2.5. Records (관람 기록)
사용자가 작성한 리뷰 데이터입니다.

| Column Name | Type | Key | Nullable | Description |
|---|---|---|---|---|
| `record_id` | Long | PK | No | 기록 고유 ID (Auto Increment) |
| `user_id` | Long | FK | No | 작성자 (Users 참조) |
| `movie_id` | String | FK | No | 영화 (Movies 참조) |
| `rating` | Float | | No | 내 별점 (0.0 ~ 5.0) |
| `watch_date` | String | | No | 관람일 (YYYY-MM-DD) |
| `one_liner` | String | | Yes | 한줄평 |
| `detailed_review` | String | | Yes | 상세 리뷰 |
| `photo_path` | String | | Yes | 업로드한 사진의 로컬 경로 (URI) |
| `created_at` | Long | | No | 작성일시 (Timestamp) |

### 2.6. Tags (태그)
관람 상황 태그 (예: '혼자', '친구', '극장' 등)

| Column Name | Type | Key | Nullable | Description |
|---|---|---|---|---|
| `tag_id` | Integer | PK | No | 태그 ID (Auto Increment) |
| `name` | String | | No | 태그 이름 |

### 2.7. Record_Tags (기록-태그 매핑)
하나의 리뷰에 여러 태그를 달 수 있습니다.

| Column Name | Type | Key | Nullable | Description |
|---|---|---|---|---|
| `id` | Long | PK | No | 고유 ID (Auto Increment) |
| `record_id` | Long | FK | No | Records 테이블 참조 |
| `tag_id` | Integer | FK | No | Tags 테이블 참조 |

### 2.8. Wishlist (찜한 영화)
나중에 볼 영화 목록입니다.

| Column Name | Type | Key | Nullable | Description |
|---|---|---|---|---|
| `id` | Long | PK | No | 고유 ID (Auto Increment) |
| `user_id` | Long | FK | No | 사용자 (Users 참조) |
| `movie_id` | String | FK | No | 영화 (Movies 참조) |
| `saved_at` | Long | | No | 찜한 날짜 (Timestamp) |

---

## 3. Room Implementation Notes

### 3.1. Type Converters
Room은 기본 타입만 저장 가능하므로, 복잡한 타입은 변환이 필요합니다.
- **Date/Timestamp**: `Long` (milliseconds)으로 변환하여 저장

### 3.2. Foreign Keys
- `onDelete = CASCADE`: 부모 데이터(예: 영화, 사용자)가 삭제되면 관련 기록도 함께 삭제되도록 설정합니다.