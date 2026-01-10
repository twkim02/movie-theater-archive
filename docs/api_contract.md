# 🎬 무비어리(Movie Diary) API 명세서

## 1. 개요
이 문서는 무비어리 앱의 프론트엔드(Flutter)와 백엔드 간의 데이터 통신을 위한 REST API 명세서입니다.

### ⚠️ 중요: 이미지 캐싱 전략 (포스터)
외부 이미지(영화 포스터)를 반복적으로 로딩하는 트래픽을 줄이기 위해 다음과 같은 전략을 사용합니다.
1. **백엔드**: 영화 정보 조회 시 `posterUrl`을 제공합니다.
2. **프론트엔드**: 
   - 최초 로딩 시 `posterUrl`의 이미지를 다운로드하여 **로컬 디바이스(내부 저장소)**에 저장합니다.
   - 이후 해당 영화를 표시할 때는 로컬에 저장된 이미지 경로를 우선적으로 사용합니다.
   - `movieId`를 파일명으로 활용하여 매핑하는 것을 권장합니다. (예: `movie_12345.jpg`)

---

## 2. 공통 응답 구조
모든 API 응답은 아래와 같은 JSON 형식을 따릅니다.

```json
{
  "status": "success", // "success" | "error"
  "message": "요청이 성공했습니다.", // 성공 시 생략 가능, 에러 시 필수
  "data": { ... } // 실제 데이터 페이로드
}
```

---

## 3. API 상세

### 3.1. 영화 검색 및 탐색

#### 영화 목록 조회 (검색 포함)
- **URL**: `GET /api/movies`
- **Query Parameters**:
  - `query` (선택): 검색어 (제목 또는 장르). 없을 경우 최신/인기 영화 목록 반환.

**Response Example:**
```json
{
  "status": "success",
  "data": {
    "movies": [
      {
        "id": "movie_12345",
        "title": "인사이드 아웃 2",
        "posterUrl": "https://image.tmdb.org/t/p/w500/...", 
        "genres": ["애니메이션", "가족"],
        "releaseDate": "2024-06-12",
        "runtime": 96,
        "voteAverage": 8.5,
        "isRecent": true // 최신 상영작 여부
      }
    ]
  }
}
```

---

### 3.2. 관람 기록 (Records)

#### 기록 목록 조회
- **URL**: `GET /api/records`
- **Description**: 사용자의 모든 관람 기록을 가져옵니다.

**Response Example:**
```json
{
  "status": "success",
  "data": {
    "records": [
      {
        "id": 101,
        "rating": 4.5,
        "watchDate": "2026-01-09",
        "oneLiner": "오랜만에 펑펑 울었다.",
        "tags": ["혼자", "극장"],
        "photoUrl": "https://my-bucket.s3.../review_img_1.jpg", // 사용자가 업로드한 직찍
        "movie": {
          "id": "movie_12345",
          "title": "인사이드 아웃 2",
          "posterUrl": "https://image.tmdb.org/..." // 프론트에서 로컬 캐싱 확인 후 사용
        }
      }
    ]
  }
}
```

#### 기록 생성
- **URL**: `POST /api/records`
- **Content-Type**: `application/json`

**Request Body:**
```json
{
  "movieId": "movie_12345",
  "rating": 4.5,
  "watchDate": "2026-01-09",
  "oneLiner": "감동적이었다.",
  "detailedReview": "상세 리뷰 내용...",
  "tags": ["혼자", "극장"],
  "photoUrl": "https://..." // 파일 업로드 API 호출 후 받은 URL
}
```

#### 기록 삭제
- **URL**: `DELETE /api/records/{recordId}`

---

### 3.3. 위시리스트 (Saved)

#### 위시리스트 조회
- **URL**: `GET /api/wishlist`

**Response Example:**
```json
{
  "status": "success",
  "data": {
    "movies": [
      {
        "id": "movie_98765",
        "title": "듄: 파트 2",
        "posterUrl": "https://...",
        "genres": ["SF", "액션"],
        "rating": 8.8, // 대중 평점
        "savedAt": "2026-01-05T10:00:00Z"
      }
    ]
  }
}
```

#### 위시리스트 추가/제거 (Toggle)
- **URL**: `POST /api/wishlist`
- **Body**: `{ "movieId": "movie_98765" }`

---

### 3.4. 취향 분석 (Statistics)

#### 통계 데이터 조회
- **URL**: `GET /api/statistics`
- **Description**: 대시보드에 필요한 모든 통계 데이터를 한 번에 반환합니다.

**Response Example:**
```json
{
  "status": "success",
  "data": {
    "summary": {
      "totalRecords": 42,
      "averageRating": 4.2,
      "topGenre": "SF"
    },
    // 기간별 장르 분포 (Pie Chart용)
    "genreDistribution": {
      "all": [
        { "name": "SF", "count": 15 },
        { "name": "로맨스", "count": 10 }
      ],
      "recent1Year": [
        { "name": "SF", "count": 8 },
        { "name": "액션", "count": 5 }
      ],
      "recent3Years": [
        { "name": "SF", "count": 12 },
        { "name": "로맨스", "count": 8 }
      ]
    },
    // 관람 추이 (Line Chart용)
    "viewingTrend": {
      "yearly": [
        { "date": "2024", "count": 12 },
        { "date": "2025", "count": 20 },
        { "date": "2026", "count": 2 }
      ],
      "monthly": [
        { "date": "2025-11", "count": 3 },
        { "date": "2025-12", "count": 5 },
        { "date": "2026-01", "count": 2 }
      ]
    },
    // 취향 기반 추천 영화
    "recommendations": [
      {
        "id": "movie_55555",
        "title": "인터스텔라",
        "posterUrl": "https://...",
        "genres": ["SF", "드라마"],
        "reason": "SF 장르를 선호하시네요!"
      }
    ]
  }
}
```

---

### 3.5. 파일 업로드

#### 이미지 업로드
- **URL**: `POST /api/upload`
- **Content-Type**: `multipart/form-data`
- **Body**: `file` (Binary)

**Response Example:**
```json
{
  "status": "success",
  "data": {
    "url": "https://your-storage.com/images/uploaded_file.jpg"
  }
}
```

---

## 4. 데이터 모델 (참고용)

### Movie Object
| Field | Type | Description |
|---|---|---|
| id | String | 영화 고유 ID |
| title | String | 영화 제목 |
| posterUrl | String | 포스터 이미지 URL (로컬 저장 권장) |
| genres | List<String> | 장르 목록 |
| releaseDate | String | 개봉일 (YYYY-MM-DD) |
| voteAverage | Double | 대중 평점 |

### Record Object
| Field | Type | Description |
|---|---|---|
| id | Long | 기록 고유 ID |
| movieId | String | 영화 ID |
| rating | Double | 내 별점 (0.0 ~ 5.0) |
| watchDate | String | 관람일 (YYYY-MM-DD) |
| oneLiner | String | 한줄평 |
| detailedReview | String | 상세 리뷰 (Optional) |
| tags | List<String> | 태그 목록 |
| photoUrl | String | 직찍 사진 URL (Optional) |
```
