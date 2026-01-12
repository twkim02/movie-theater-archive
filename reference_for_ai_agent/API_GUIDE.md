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
        "id": "496243",
        "title": "기생충",
        "posterUrl": "https://image.tmdb.org/t/p/w500/mSi0gskYpmf1FbXngM37s2HppXh.jpg", 
        "genres": ["코미디","스릴러","드라마"],
        "releaseDate": "2019-05-30",
        "runtime": 131,
        "voteAverage": 4.3,
        "isRecent": false
      },
      ... 
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
        "userId": 1,
        "rating": 4.5,
        "watchDate": "2026-01-02",
        "oneLiner": "압도적인 영상미, 역시 아바타 시리즈네요.",
        "detailedReview": "극장에서 보지 않으면 후회할 뻔했습니다. 전작보다 훨씬 화려해진 불의 부족 묘사가 인상적이었고, 3시간 넘는 러닝타임이 전혀 지루하지 않았습니다. 가족들과 함께 보기 정말 좋은 영화입니다.",
        "tags": ["가족", "극장"],
        "photoPaths:": "https://my-bucket.s3.amazonaws.com/review_img_101.jpg",
        "movie": {
          "id": "83533",
          "title": "아바타: 불과 재",
          "posterUrl": "https://image.tmdb.org/t/p/w500/l18o0AK18KS118tWeROOKYkF0ng.jpg"
        }
      },
      ...
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
  "photoPaths:": "https://..." // 파일 업로드 API 호출 후 받은 URL
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
        "id": "696506",
        "title": "미키 17",
        "posterUrl": "https://image.tmdb.org/t/p/w500/mH7QnJDxQibVZw0M66IBZbsw2O6.jpg", 
        "genres": ["SF","코미디","모험"],
        "rating": 3.4,
        "savedAt": "2026-01-05T10:00:00Z"
      },
      ...
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
      "totalRecords": 7,
      "averageRating": 4.1,
      "topGenre": "판타지"
    },
    "genreDistribution": {
      "all": [
        { "name": "판타지", "count": 4 },
        { "name": "액션", "count": 3 },
        { "name": "SF", "count": 2 },
        { "name": "모험", "count": 2 },
        { "name": "코미디", "count": 2 },
        { "name": "스릴러", "count": 2 },
        { "name": "드라마", "count": 2 },
        { "name": "애니메이션", "count": 2 },
        { "name": "범죄", "count": 1 }
      ],
      "recent1Year": [
        { "name": "판타지", "count": 4 },
        { "name": "액션", "count": 3 },
        { "name": "SF", "count": 2 },
        { "name": "모험", "count": 2 },
        { "name": "코미디", "count": 2 }
      ],
      "recent3Years": [
        { "name": "판타지", "count": 4 },
        { "name": "액션", "count": 3 },
        { "name": "SF", "count": 2 },
        { "name": "모험", "count": 2 },
        { "name": "코미디", "count": 2 }
      ]
    },
    "viewingTrend": {
      "yearly": [
        { "date": "2025", "count": 3 },
        { "date": "2026", "count": 4 }
      ],
      "monthly": [
        { "date": "2025-10", "count": 1 },
        { "date": "2025-11", "count": 1 },
        { "date": "2025-12", "count": 1 },
        { "date": "2026-01", "count": 4 }
      ]
    }
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