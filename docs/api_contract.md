# 🎬 Movie Diary App – API Contract

이 문서는 **Frontend ↔ Backend 간 데이터 계약서**입니다.  
모든 개발은 이 문서를 기준으로 진행합니다.

---

## 📌 Common Rules
- id: string
- 날짜: `YYYY-MM-DD`
- 시간: ISO 8601 (`2026-01-09T13:40:00Z`)
- 평점: 0.5 단위 (double)
- null 허용 ❌ (필요 시 빈 값으로 처리)

---

## 🎥 Movie
```json
{
  "id": "movie_001",
  "title": "듄: 파트2",
  "genres": ["SF", "액션"],
  "year": 2024,
  "posterUrl": "https://image.tmdb.org/...",
  "averageRating": 4.6
}


##📝 Record (관람 기록)
{
  "id": "record_101",
  "movie": {
    "id": "movie_001",
    "title": "듄: 파트2",
    "posterUrl": "https://image.tmdb.org/..."
  },
  "watchedAt": "2026-01-09",
  "rating": 4.5,
  "oneLineReview": "영상미가 압도적",
  "review": "극장에서 꼭 봐야 할 영화",
  "tags": ["극장", "혼자"],
  "createdAt": "2026-01-09T13:40:00Z"
}


##📊 Stats (취향 분석)
{
  "totalRecords": 3,
  "averageRating": 4.0,
  "favoriteGenre": "액션",
  "genreCount": {
    "액션": 2,
    "SF": 1,
    "드라마": 1
  },
  "yearlyWatchCount": [
    { "year": 2025, "count": 1 },
    { "year": 2026, "count": 2 }
  ]
}


##❤️ Saved Movie
{
  "id": "movie_003",
  "title": "인터스텔라",
  "posterUrl": "https://...",
  "year": 2014
}

