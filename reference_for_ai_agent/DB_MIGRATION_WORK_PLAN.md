# 🗄️ DB 마이그레이션 작업 계획서

이 문서는 메모리 기반 데이터 저장소를 SQLite 데이터베이스로 마이그레이션하는 작업 순서를 정리합니다.

---

## 📋 현재 상태 분석

### ✅ 이미 DB에 저장되는 데이터
- **Movies**: `MovieDatabase` 클래스로 SQLite에 저장됨

### ❌ 메모리 기반으로 동작하는 데이터
- **Records**: `RecordStore` (ValueNotifier) - 앱 종료 시 사라짐
- **Wishlist**: `SavedStore` (ValueNotifier) + `AppState._customWishlistItems` - 앱 종료 시 사라짐
- **북마크 상태**: `AppState._bookmarkedMovieIds` - 앱 종료 시 사라짐

### 📊 DB 스키마에 정의되어 있지만 미구현 테이블
- `users` - 사용자 정보
- `records` - 관람 기록
- `wishlist` - 찜한 영화
- `tags` - 태그 마스터
- `record_tags` - 기록-태그 매핑
- `genres` - 장르 마스터 (현재는 JSON으로 저장)
- `movie_genres` - 영화-장르 매핑 (현재는 JSON으로 저장)

---

## 🎯 작업 순서

### **1단계: DB 스키마 확장 및 초기화**

#### 1.1. `MovieDatabase` 클래스 확장
**파일:** `lib/database/movie_database.dart`

**작업 내용:**
- 기존 `movies` 테이블은 유지
- 새로운 테이블 추가:
  - `users` 테이블 생성
  - `records` 테이블 생성
  - `wishlist` 테이블 생성
  - `tags` 테이블 생성
  - `record_tags` 테이블 생성
  - `genres` 테이블 생성 (선택사항, 현재는 JSON으로 저장 중)
  - `movie_genres` 테이블 생성 (선택사항)

**주의사항:**
- DB 버전을 1에서 2로 증가
- `_onUpgrade` 메서드에 마이그레이션 로직 추가
- 기존 `movies` 테이블 데이터는 유지

**예상 작업 시간:** 2-3시간

---

### **2단계: Repository 패턴 구현**

#### 2.1. RecordRepository 생성
**파일:** `lib/repositories/record_repository.dart` (신규 생성)

**주요 메서드:**
- `addRecord(Record)`: 기록 추가
- `getAllRecords()`: 모든 기록 조회
- `getRecordById(int)`: ID로 기록 조회
- `updateRecord(Record)`: 기록 수정
- `deleteRecord(int)`: 기록 삭제
- `getRecordsByMovieId(String)`: 영화별 기록 조회
- `getRecordsByDateRange(DateTime, DateTime)`: 기간별 기록 조회
- `searchRecords(String)`: 검색 (제목, 한줄평)

**작업 내용:**
- `MovieDatabase`에 Records 관련 CRUD 메서드 추가
- `RecordRepository` 클래스 생성하여 DB 접근 추상화

**예상 작업 시간:** 3-4시간

#### 2.2. WishlistRepository 생성
**파일:** `lib/repositories/wishlist_repository.dart` (신규 생성)

**주요 메서드:**
- `addToWishlist(String movieId, int userId)`: 위시리스트 추가
- `removeFromWishlist(String movieId, int userId)`: 위시리스트 제거
- `getWishlist(int userId)`: 사용자의 위시리스트 조회
- `isInWishlist(String movieId, int userId)`: 위시리스트 포함 여부 확인

**작업 내용:**
- `MovieDatabase`에 Wishlist 관련 CRUD 메서드 추가
- `WishlistRepository` 클래스 생성

**예상 작업 시간:** 2-3시간

#### 2.3. UserRepository 생성 (선택사항)
**파일:** `lib/repositories/user_repository.dart` (신규 생성)

**주요 메서드:**
- `getDefaultUser()`: 기본 사용자(Guest) 조회 또는 생성
- `createUser(String nickname)`: 사용자 생성

**작업 내용:**
- 기본 사용자(Guest) 자동 생성 로직
- 사용자 ID 관리

**예상 작업 시간:** 1-2시간

#### 2.4. TagRepository 생성
**파일:** `lib/repositories/tag_repository.dart` (신규 생성)

**주요 메서드:**
- `getOrCreateTag(String name)`: 태그 조회 또는 생성
- `getAllTags()`: 모든 태그 조회
- `getTagsByRecordId(int)`: 기록별 태그 조회

**작업 내용:**
- 태그 마스터 데이터 관리
- 기록-태그 매핑 관리

**예상 작업 시간:** 2-3시간

---

### **3단계: 초기화 서비스 구현**

#### 3.1. 기본 사용자 초기화
**파일:** `lib/services/user_initializer.dart` (신규 생성)

**작업 내용:**
- 앱 최초 실행 시 기본 사용자(Guest) 생성
- 사용자 ID를 SharedPreferences에 저장하여 재사용

**예상 작업 시간:** 1시간

#### 3.2. 기본 태그 초기화
**파일:** `lib/services/tag_initializer.dart` (신규 생성)

**작업 내용:**
- 앱 최초 실행 시 기본 태그 생성: "혼자", "친구", "가족", "극장", "OTT"
- 중복 생성 방지

**예상 작업 시간:** 1시간

---

### **4단계: AppState 마이그레이션**

#### 4.1. Records 관련 마이그레이션
**파일:** `lib/state/app_state.dart`

**작업 내용:**
- `RecordStore` 대신 `RecordRepository` 사용
- `records` getter를 DB에서 조회하도록 변경
- `addRecord()` 메서드에서 DB에 저장
- 앱 시작 시 DB에서 기록 로드
- 정렬/필터 기능은 메모리에서 처리하거나 DB 쿼리로 처리

**주의사항:**
- 기존 `RecordStore` 사용 코드를 모두 찾아서 수정
- `RecordStore.add()` 호출 부분을 `RecordRepository.addRecord()`로 변경

**예상 작업 시간:** 3-4시간

#### 4.2. Wishlist 관련 마이그레이션
**파일:** `lib/state/app_state.dart`

**작업 내용:**
- `SavedStore` 대신 `WishlistRepository` 사용
- `wishlist` getter를 DB에서 조회하도록 변경
- `addToWishlist()`, `removeFromWishlist()` 메서드에서 DB에 저장/삭제
- 앱 시작 시 DB에서 위시리스트 로드
- 북마크 상태도 위시리스트와 동기화

**주의사항:**
- `SavedStore.toggle()` 호출 부분을 찾아서 수정
- `AppState._customWishlistItems` 제거

**예상 작업 시간:** 2-3시간

---

### **5단계: UI 레이어 수정**

#### 5.1. 기록 추가 기능 수정
**파일:** `lib/widgets/add_record_sheet.dart`

**작업 내용:**
- 기록 저장 시 `RecordRepository.addRecord()` 호출
- 태그 저장 시 `TagRepository.getOrCreateTag()` 사용
- 저장 후 `AppState` 새로고침

**예상 작업 시간:** 1-2시간

#### 5.2. 일기 탭 수정
**파일:** `lib/screens/diary_screen.dart`

**작업 내용:**
- `AppState.records` 사용 (이미 DB에서 로드됨)
- 정렬/필터 기능 확인 및 수정

**예상 작업 시간:** 1시간

#### 5.3. 저장 탭 수정
**파일:** `lib/screens/saved_screen.dart`

**작업 내용:**
- `AppState.wishlist` 사용 (이미 DB에서 로드됨)
- 북마크 토글 시 DB에 저장

**예상 작업 시간:** 1시간

#### 5.4. 탐색 탭 수정
**파일:** `lib/screens/explore_screen.dart`

**작업 내용:**
- 북마크 토글 시 `WishlistRepository` 사용
- `SavedStore` 사용 부분 제거

**예상 작업 시간:** 1시간

---

### **6단계: 앱 시작 시 초기화**

#### 6.1. 앱 시작 로직 수정
**파일:** `lib/app.dart`

**작업 내용:**
- 기본 사용자 초기화
- 기본 태그 초기화
- DB에서 Records 로드
- DB에서 Wishlist 로드
- `AppState` 초기화 순서 조정

**예상 작업 시간:** 1-2시간

---

### **7단계: 테스트 및 검증**

#### 7.1. 기능 테스트
- 기록 추가/수정/삭제 테스트
- 위시리스트 추가/제거 테스트
- 앱 종료 후 재시작 시 데이터 유지 확인
- 정렬/필터 기능 테스트

#### 7.2. 데이터 마이그레이션 테스트
- 기존 더미 데이터가 있는 경우 마이그레이션 로직 테스트
- DB 버전 업그레이드 테스트

**예상 작업 시간:** 2-3시간

---

## 📝 상세 작업 체크리스트

### 1단계: DB 스키마 확장
- [ ] `MovieDatabase`에 `users` 테이블 생성 로직 추가
- [ ] `MovieDatabase`에 `records` 테이블 생성 로직 추가
- [ ] `MovieDatabase`에 `wishlist` 테이블 생성 로직 추가
- [ ] `MovieDatabase`에 `tags` 테이블 생성 로직 추가
- [ ] `MovieDatabase`에 `record_tags` 테이블 생성 로직 추가
- [ ] DB 버전을 2로 증가
- [ ] `_onUpgrade` 메서드에 마이그레이션 로직 추가
- [ ] 인덱스 생성 (성능 최적화)

### 2단계: Repository 구현
- [ ] `RecordRepository` 클래스 생성
- [ ] `WishlistRepository` 클래스 생성
- [ ] `UserRepository` 클래스 생성
- [ ] `TagRepository` 클래스 생성
- [ ] 각 Repository의 CRUD 메서드 구현
- [ ] 트랜잭션 처리 (필요한 경우)

### 3단계: 초기화 서비스
- [ ] `UserInitializer` 클래스 생성
- [ ] `TagInitializer` 클래스 생성
- [ ] 기본 사용자 생성 로직
- [ ] 기본 태그 생성 로직

### 4단계: AppState 마이그레이션
- [ ] `RecordStore` 사용 부분 찾기
- [ ] `SavedStore` 사용 부분 찾기
- [ ] `AppState.records`를 DB에서 로드하도록 수정
- [ ] `AppState.wishlist`를 DB에서 로드하도록 수정
- [ ] 기록 추가/수정/삭제 메서드 수정
- [ ] 위시리스트 추가/제거 메서드 수정

### 5단계: UI 레이어 수정
- [ ] `add_record_sheet.dart` 수정
- [ ] `diary_screen.dart` 수정
- [ ] `saved_screen.dart` 수정
- [ ] `explore_screen.dart` 수정
- [ ] 기타 `RecordStore`/`SavedStore` 사용 부분 수정

### 6단계: 앱 시작 초기화
- [ ] `app.dart`에 초기화 로직 추가
- [ ] 초기화 순서 확인
- [ ] 에러 처리 추가

### 7단계: 테스트
- [ ] 기록 CRUD 테스트
- [ ] 위시리스트 CRUD 테스트
- [ ] 앱 재시작 후 데이터 유지 테스트
- [ ] 정렬/필터 기능 테스트

---

## ⚠️ 주의사항

### 1. 데이터 마이그레이션
- 기존 더미 데이터가 있는 경우, 앱 업데이트 시 마이그레이션 로직 필요
- DB 버전 업그레이드 시 기존 데이터 보존

### 2. 성능 최적화
- 대량 데이터 조회 시 인덱스 활용
- 트랜잭션 사용으로 성능 최적화
- 필요시 페이지네이션 구현

### 3. 에러 처리
- DB 초기화 실패 시 처리
- 데이터 저장 실패 시 사용자에게 알림
- 네트워크 오류와 DB 오류 구분

### 4. 백업 및 복구
- 향후 데이터 백업 기능 고려
- DB 손상 시 복구 로직

---

## 📊 예상 작업 시간

| 단계 | 작업 내용 | 예상 시간 |
|------|----------|----------|
| 1단계 | DB 스키마 확장 | 2-3시간 |
| 2단계 | Repository 구현 | 8-12시간 |
| 3단계 | 초기화 서비스 | 2시간 |
| 4단계 | AppState 마이그레이션 | 5-7시간 |
| 5단계 | UI 레이어 수정 | 4-5시간 |
| 6단계 | 앱 시작 초기화 | 1-2시간 |
| 7단계 | 테스트 및 검증 | 2-3시간 |
| **총계** | | **24-34시간** |

---

## 🚀 권장 작업 순서

1. **1단계 → 2단계 → 3단계**: 인프라 구축 (DB, Repository, 초기화)
2. **4단계**: 핵심 로직 마이그레이션 (AppState)
3. **5단계**: UI 레이어 수정
4. **6단계**: 앱 시작 로직 통합
5. **7단계**: 테스트 및 버그 수정

각 단계를 완료한 후 테스트를 진행하고, 문제가 없으면 다음 단계로 진행하는 것을 권장합니다.

---

**문서 작성일**: 2026년 1월  
**작업 예상 기간**: 1-2주 (단계별로 나눠서 진행)
