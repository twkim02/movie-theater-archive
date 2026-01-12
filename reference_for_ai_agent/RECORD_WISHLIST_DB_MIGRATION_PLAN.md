# 📝 기록 및 위시리스트 DB 마이그레이션 작업 계획서

이 문서는 관람 기록(Records), 위시리스트(Wishlist), 태그(Tags), 사용자(Users) 등의 DB 마이그레이션 작업 순서를 정리합니다.

---

## 📋 작업 순서 개요

```
1단계: DB 스키마 확장 (Users, Records, Tags, Wishlist 테이블 추가)
   ↓
2단계: Record 관련 DB 클래스 구현
   ↓
3단계: Wishlist 관련 DB 클래스 구현
   ↓
4단계: Tag 관련 DB 클래스 구현
   ↓
5단계: User 기본 데이터 초기화
   ↓
6단계: AppState에서 DB 사용하도록 변경
   ↓
7단계: 기존 메모리 저장소 제거 및 테스트
```

---

## 1단계: DB 스키마 확장

### 1.1. 현재 상태
- `MovieDatabase` 클래스에 `movies` 테이블만 존재
- DB 버전: 1

### 1.2. 추가할 테이블
1. **users** - 사용자 정보
2. **records** - 관람 기록
3. **tags** - 태그 마스터
4. **record_tags** - 기록-태그 매핑 (N:M)
5. **wishlist** - 위시리스트

### 1.3. 작업 내용
- `MovieDatabase` 클래스를 `AppDatabase`로 리네이밍하거나, 별도 클래스로 분리
- DB 버전을 2로 증가
- `_onUpgrade` 메서드에 마이그레이션 로직 추가
- 새 테이블 생성 SQL 작성

### 1.4. 테이블 스키마

#### users 테이블
```sql
CREATE TABLE users (
  user_id INTEGER PRIMARY KEY AUTOINCREMENT,
  nickname TEXT NOT NULL,
  email TEXT,
  created_at INTEGER NOT NULL
)
```

#### records 테이블
```sql
CREATE TABLE records (
  record_id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  movie_id TEXT NOT NULL,
  rating REAL NOT NULL,
  watch_date TEXT NOT NULL,
  one_liner TEXT,
  detailed_review TEXT,
  photo_path TEXT,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (movie_id) REFERENCES movies(id) ON DELETE CASCADE
)
```

#### tags 테이블
```sql
CREATE TABLE tags (
  tag_id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE
)
```

#### record_tags 테이블
```sql
CREATE TABLE record_tags (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  record_id INTEGER NOT NULL,
  tag_id INTEGER NOT NULL,
  FOREIGN KEY (record_id) REFERENCES records(record_id) ON DELETE CASCADE,
  FOREIGN KEY (tag_id) REFERENCES tags(tag_id) ON DELETE CASCADE,
  UNIQUE(record_id, tag_id)
)
```

#### wishlist 테이블
```sql
CREATE TABLE wishlist (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  movie_id TEXT NOT NULL,
  saved_at INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (movie_id) REFERENCES movies(id) ON DELETE CASCADE,
  UNIQUE(user_id, movie_id)
)
```

### 1.5. 인덱스 추가
```sql
-- records 테이블 인덱스
CREATE INDEX idx_records_user_id ON records(user_id);
CREATE INDEX idx_records_movie_id ON records(movie_id);
CREATE INDEX idx_records_watch_date ON records(watch_date);

-- wishlist 테이블 인덱스
CREATE INDEX idx_wishlist_user_id ON wishlist(user_id);
CREATE INDEX idx_wishlist_movie_id ON wishlist(movie_id);

-- record_tags 테이블 인덱스
CREATE INDEX idx_record_tags_record_id ON record_tags(record_id);
CREATE INDEX idx_record_tags_tag_id ON record_tags(tag_id);
```

---

## 2단계: Record 관련 DB 클래스 구현

### 2.1. 생성할 파일
- `lib/database/record_database.dart` (또는 `AppDatabase`에 통합)
- `lib/repositories/record_repository.dart`

### 2.2. 주요 메서드

#### RecordDatabase
- `insertRecord(Record)`: 기록 추가
- `getRecordById(int)`: ID로 조회
- `getAllRecords()`: 전체 조회
- `getRecordsByUserId(int)`: 사용자별 조회
- `getRecordsByMovieId(String)`: 영화별 조회
- `updateRecord(Record)`: 기록 수정
- `deleteRecord(int)`: 기록 삭제
- `searchRecords(String query)`: 제목/한줄평 검색
- `getRecordsByDateRange(DateTime?, DateTime?)`: 기간 필터
- `getRecordsByTag(String tag)`: 태그별 조회

#### RecordRepository
- `addRecord(Record)`: 기록 추가 (태그도 함께 저장)
- `getAllRecords()`: 전체 조회 (태그 포함)
- `getRecordById(int)`: ID로 조회 (태그 포함)
- `updateRecord(Record)`: 기록 수정
- `deleteRecord(int)`: 기록 삭제
- `searchRecords(String)`: 검색
- `getRecordsByDateRange(DateTime?, DateTime?)`: 기간 필터

### 2.3. 태그 처리
- 기록 추가 시 태그가 DB에 없으면 자동 생성
- `record_tags` 테이블에 매핑 저장
- 조회 시 JOIN으로 태그 목록 가져오기

### 2.4. 데이터 변환
- `Record` 모델의 `tags` (List<String>) ↔ DB의 `tags` 테이블 + `record_tags` 매핑
- `DateTime` ↔ `TEXT` (YYYY-MM-DD 형식)
- `created_at`은 timestamp (milliseconds)

---

## 3단계: Wishlist 관련 DB 클래스 구현

### 3.1. 생성할 파일
- `lib/repositories/wishlist_repository.dart`

### 3.2. 주요 메서드

#### WishlistRepository
- `addToWishlist(int userId, String movieId)`: 위시리스트 추가
- `removeFromWishlist(int userId, String movieId)`: 위시리스트 제거
- `isInWishlist(int userId, String movieId)`: 위시리스트 여부 확인
- `getWishlist(int userId)`: 사용자의 위시리스트 조회 (Movie 객체 포함)
- `getWishlistCount(int userId)`: 위시리스트 개수

### 3.3. 데이터 변환
- `WishlistItem` 모델 생성 시 `Movie` 객체는 `MovieRepository`에서 조회
- `saved_at`은 timestamp (milliseconds)

---

## 4단계: Tag 관련 DB 클래스 구현

### 4.1. 생성할 파일
- `lib/repositories/tag_repository.dart`

### 4.2. 주요 메서드

#### TagRepository
- `getOrCreateTag(String name)`: 태그 조회 또는 생성
- `getAllTags()`: 전체 태그 조회
- `getTagsByRecordId(int recordId)`: 기록의 태그 조회
- `addTagToRecord(int recordId, String tagName)`: 기록에 태그 추가
- `removeTagFromRecord(int recordId, String tagName)`: 기록에서 태그 제거

### 4.3. 초기 태그 데이터
- 기본 태그: "혼자", "친구", "가족", "극장", "OTT"
- 앱 초기화 시 자동 생성

---

## 5단계: User 기본 데이터 초기화

### 5.1. 기본 사용자 생성
- 앱 최초 실행 시 기본 사용자(Guest) 1명 자동 생성
- `user_id = 1`, `nickname = "Guest"`, `email = null`

### 5.2. 초기화 로직
- `lib/services/user_initialization_service.dart` 생성
- `initializeDefaultUser()`: 기본 사용자 생성
- `getDefaultUserId()`: 기본 사용자 ID 반환 (항상 1)

### 5.3. 앱 시작 시 호출
- `main.dart` 또는 `app.dart`에서 초기화
- DB 초기화 후 사용자 초기화

---

## 6단계: AppState에서 DB 사용하도록 변경

### 6.1. 수정할 파일
- `lib/state/app_state.dart`

### 6.2. 변경 사항

#### Records 관련
- `allRecords` getter: `DummyRecords.getRecords()` → `RecordRepository.getAllRecords()`
- `addRecord(Record)` 메서드 추가: DB에 저장
- `updateRecord(Record)` 메서드 추가: DB 업데이트
- `deleteRecord(int)` 메서드 추가: DB 삭제
- `records` getter: DB에서 조회 후 필터/정렬 적용

#### Wishlist 관련
- `wishlist` getter: `DummyWishlist` + `_customWishlistItems` → `WishlistRepository.getWishlist()`
- `addToWishlist(Movie)`: DB에 저장
- `removeFromWishlist(String)`: DB에서 삭제
- `_customWishlistItems` 제거

#### 북마크 관련
- `_bookmarkedMovieIds`: `WishlistRepository.isInWishlist()` 사용
- `toggleBookmark(String)`: `WishlistRepository` 사용

### 6.3. 비동기 처리
- 모든 DB 조회는 `Future` 반환
- `AppState`에 로딩 상태 추가
- UI에서 `FutureBuilder` 또는 상태 관리로 처리

---

## 7단계: 기존 메모리 저장소 제거 및 테스트

### 7.1. 제거할 파일
- `lib/data/record_store.dart` (선택사항: 호환성을 위해 유지 가능)
- `lib/data/saved_store.dart` (선택사항: 호환성을 위해 유지 가능)

### 7.2. 더미 데이터 처리
- `DummyRecords`, `DummyWishlist`는 테스트용으로 유지 가능
- 또는 초기 데이터 마이그레이션 스크립트로 DB에 저장

### 7.3. 테스트
- 기록 추가/수정/삭제 테스트
- 위시리스트 추가/제거 테스트
- 태그 추가/제거 테스트
- 검색 및 필터 테스트
- 앱 재시작 후 데이터 유지 확인

---

## 📝 작업 체크리스트

### 1단계 체크리스트
- [ ] DB 버전을 2로 증가
- [ ] `users` 테이블 생성 SQL 작성 및 실행
- [ ] `records` 테이블 생성 SQL 작성 및 실행
- [ ] `tags` 테이블 생성 SQL 작성 및 실행
- [ ] `record_tags` 테이블 생성 SQL 작성 및 실행
- [ ] `wishlist` 테이블 생성 SQL 작성 및 실행
- [ ] 인덱스 생성 SQL 작성 및 실행
- [ ] `_onUpgrade` 메서드에 마이그레이션 로직 추가
- [ ] DB 초기화 테스트

### 2단계 체크리스트
- [ ] `RecordDatabase` 클래스 생성
- [ ] CRUD 메서드 구현
- [ ] 태그 매핑 로직 구현
- [ ] `RecordRepository` 클래스 생성
- [ ] Repository 메서드 구현
- [ ] 더미 데이터로 테스트

### 3단계 체크리스트
- [ ] `WishlistRepository` 클래스 생성
- [ ] 위시리스트 CRUD 메서드 구현
- [ ] Movie 객체 조회 로직 구현
- [ ] 테스트

### 4단계 체크리스트
- [ ] `TagRepository` 클래스 생성
- [ ] 태그 CRUD 메서드 구현
- [ ] 기본 태그 초기화 로직 구현
- [ ] 테스트

### 5단계 체크리스트
- [ ] `UserInitializationService` 클래스 생성
- [ ] 기본 사용자 생성 로직 구현
- [ ] 앱 시작 시 초기화 호출
- [ ] 테스트

### 6단계 체크리스트
- [ ] `AppState.allRecords` 수정
- [ ] `AppState.addRecord()` 구현
- [ ] `AppState.updateRecord()` 구현
- [ ] `AppState.deleteRecord()` 구현
- [ ] `AppState.wishlist` 수정
- [ ] `AppState.addToWishlist()` 수정
- [ ] `AppState.removeFromWishlist()` 수정
- [ ] `AppState.toggleBookmark()` 수정
- [ ] UI에서 비동기 처리 확인

### 7단계 체크리스트
- [ ] 기존 메모리 저장소 제거 또는 주석 처리
- [ ] 더미 데이터 마이그레이션 (선택사항)
- [ ] 전체 기능 테스트
- [ ] 앱 재시작 후 데이터 유지 확인

---

## 🔄 마이그레이션 전략

### 단계별 전환
1. **DB 구조만 먼저 구현**
   - 테이블 생성
   - 더미 데이터를 DB에 저장하는 스크립트 작성
   - 기존 코드는 그대로 사용

2. **Repository 구현**
   - DB 접근 로직 구현
   - 더미 데이터로 테스트

3. **AppState 점진적 교체**
   - 한 기능씩 DB로 전환
   - 각 단계마다 테스트

4. **메모리 저장소 제거**
   - 모든 기능이 DB로 전환된 후 제거

### 롤백 계획
- 각 단계마다 커밋
- 문제 발생 시 이전 단계로 롤백 가능하도록 구성

---

## ⚠️ 주의사항

1. **외래 키 제약**
   - `records.movie_id`는 `movies.id` 참조
   - `records.user_id`는 `users.user_id` 참조
   - 영화나 사용자 삭제 시 CASCADE 처리 확인

2. **데이터 무결성**
   - 기록 추가 시 영화가 DB에 있는지 확인
   - 기록 추가 시 사용자가 DB에 있는지 확인
   - 위시리스트 추가 시 중복 방지 (UNIQUE 제약)

3. **성능**
   - 대량 데이터 조회 시 인덱스 활용
   - 태그 조회 시 JOIN 최적화
   - 페이지네이션 고려 (필요 시)

4. **에러 처리**
   - DB 에러 처리
   - 외래 키 제약 위반 처리
   - 트랜잭션 실패 처리

5. **기존 데이터 마이그레이션**
   - 더미 데이터를 DB로 마이그레이션하는 스크립트 작성 (선택사항)
   - 사용자가 이미 추가한 기록/위시리스트가 있다면 마이그레이션 필요

---

## 📚 참고 자료

- **DB 스키마**: `reference_for_ai_agent/DB_SCHEMA.md`
- **영화 DB 마이그레이션**: `reference_for_ai_agent/MOVIE_DB_MIGRATION_PLAN.md`
- **프로젝트 명세**: `reference_for_ai_agent/PROJECT_SPEC.md`
- **sqflite 패키지**: https://pub.dev/packages/sqflite

---

**문서 작성일**: 2026년 1월  
**작업 예상 기간**: 1-2주 (단계별로 나눠서 진행)
