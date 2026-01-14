# 🎬 메가박스 상영 정보 통합 작업 계획서

이 문서는 무비어리 앱에 메가박스 상영 정보를 통합하는 작업 순서를 정리합니다.
롯데시네마 통합 작업을 기반으로 메가박스도 동일한 방식으로 통합합니다.

---

## 📋 작업 개요

### 목표
1. 탐색 탭의 '영화관 보기' 버튼 클릭 시, 메가박스 영화관에 한해 실제 상영 시간표를 표시
2. TMDb에서 상영 중이 아니지만 메가박스(또는 롯데시네마)에서는 상영 중인 영화를 `isRecent = true`로 설정
3. 메가박스가 아닌 영화관은 기존처럼 안내 메시지 제공
4. 롯데시네마와 메가박스 모두 지원

### 주요 고려사항
- **안드로이드 앱 환경**: HTTP 요청이 제한될 수 있음
- **과도한 호출 방지**: 캐싱, 딜레이, 요청 제한 등 필요 (롯데시네마와 동일한 캐시 전략 사용)
- **영화 제목 매칭**: TMDb 제목과 메가박스 제목이 다를 수 있음 (롯데시네마와 동일한 매칭 전략 사용)
- **CSV 파일 관리**: 앱에 포함하여 사용 (assets 폴더)
- **롯데시네마와의 통합**: 기존 롯데시네마 코드를 확장하여 메가박스도 지원

### 메가박스와 롯데시네마의 차이점
| 항목 | 롯데시네마 | 메가박스 |
|------|-----------|---------|
| 영화 CSV | movie_now.csv, movie_upcoming.csv (분리) | movie.csv (단일) |
| 영화관 CSV | divisionCode, detailDivisionCode, cinemaID | brchNo, brchNm |
| 영화관 ID 형식 | "divisionCode\|detailDivisionCode\|cinemaID" | brchNo (단일 값) |
| 날짜 형식 | YYYY-MM-DD | YYYYMMDD |
| API 엔드포인트 | /LCWS/Ticketing/TicketingData.aspx | /on/oh/ohb/SimpleBooking/selectBokdList.do |
| 응답 구조 | PlaySeqs.Items | movieFormList |
| 필드명 | MovieNameKR, StartTime, EndTime, ScreenNameKR | movieNm, playStartTime, playEndTime, theabExpoNm |

---

## 📝 작업 단계

### 1단계: 데이터 모델 및 CSV 파싱 준비

#### 1.1. CSV 파일을 assets에 추가
- `megabox_movie.csv` → `assets/megabox/movie.csv`
- `megabox_theater.csv` → `assets/megabox/theater.csv`
- `pubspec.yaml`에 assets 경로 추가 (`assets/megabox/`)

#### 1.2. 메가박스 데이터 모델 생성
**파일**: `lib/models/megabox_data.dart` (새로 생성)

**모델 구조**:
- `MegaboxMovie`: movieNo, movieNm
- `MegaboxTheater`: brchNo, brchNm
- `MegaboxSchedule`: 상영 시간표 정보 (playStartTime, playEndTime, theabExpoNm, restSeatCnt, totSeatCnt)

**참고**: 롯데시네마 모델(`lottecinema_data.dart`)과 유사한 구조이지만 필드명이 다름

#### 1.3. CSV 파서 확장
**파일**: `lib/utils/csv_parser.dart` (기존 파일 확장)

**추가 기능**:
- `getMegaboxMovies()`: 메가박스 영화 목록 가져오기
- `getMegaboxTheaters()`: 메가박스 영화관 목록 가져오기
- `findMegaboxTheaterByName(String name)`: 영화관 이름으로 검색
- `findMegaboxMovieByName(String name)`: 영화명으로 검색

**캐싱**: 롯데시네마와 동일하게 메모리 캐싱 사용

**테스트 포인트**: CSV 파일이 제대로 파싱되는지 확인

---

### 2단계: 메가박스 API 클라이언트 구현

#### 2.1. 메가박스 API 클라이언트 생성
**파일**: `lib/api/megabox_client.dart` (새로 생성)

**주요 기능**:
- `getMovieSchedule()`: 특정 영화관, 특정 영화의 상영 시간표 가져오기
- API 엔드포인트: `https://www.megabox.co.kr/on/oh/ohb/SimpleBooking/selectBokdList.do`
- POST 요청 (JSON payload)
- 필요한 파라미터:
  - `arrMovieNo`: 영화 번호
  - `playDe`: YYYYMMDD 형식
  - `brchNoListCnt`: 1
  - `brchNo1`: 영화관 번호
  - `movieNo1`: 영화 번호

**주의사항**:
- User-Agent, Referer, X-Requested-With 헤더 필수
- 네트워크 에러 처리
- 타임아웃 설정 (5초)
- 요청 실패 시 빈 리스트 반환 (앱이 멈추지 않도록)
- 롯데시네마 클라이언트와 유사한 구조

**응답 파싱**:
- `movieFormList` 배열에서 각 항목 추출
- 필드 매핑:
  - `playStartTime` → startTime
  - `playEndTime` → endTime
  - `theabExpoNm` → screenName
  - `restSeatCnt` → availableSeatCount
  - `totSeatCnt` → totalSeatCount

#### 2.2. 영화 제목 매칭 로직 확장
**파일**: `lib/services/movie_title_matcher.dart` (기존 파일 확장)

**추가 기능**:
- `findMegaboxMovie(String tmdbTitle)`: TMDb 제목으로 메가박스 영화 찾기
- `isPlayingInMegabox(String tmdbTitle)`: 메가박스에서 상영 중인지 확인

**매칭 전략**: 롯데시네마와 동일
1. 정확한 제목 매칭 (대소문자 무시, 공백 정규화)
2. 부분 매칭 (한쪽이 다른 쪽을 포함)
3. 특수문자 제거 후 매칭

**테스트 포인트**: 
- CSV의 영화명과 TMDb 제목이 매칭되는지 확인
- 매칭 실패 시 빈 결과 반환하는지 확인

---

### 3단계: 영화관 정보와 상영 시간표 통합

#### 3.1. TheaterScheduleService 확장
**파일**: `lib/services/theater_schedule_service.dart` (기존 파일 확장)

**추가 기능**:
- `getMegaboxSchedule()`: 메가박스 영화관의 상영 시간표 가져오기
- `getSchedule()`: 통합 메서드 (롯데시네마 또는 메가박스 자동 감지)
  - 영화관 이름에 "롯데시네마" 또는 "롯데" 포함 → `getLotteCinemaSchedule()` 호출
  - 영화관 이름에 "메가박스" 또는 "메가" 포함 → `getMegaboxSchedule()` 호출
  - 그 외 → 빈 리스트 반환

**캐싱**: 롯데시네마와 동일한 캐시 전략 사용 (5분 캐시, 같은 키 형식)

**에러 처리**: 롯데시네마와 동일하게 조용히 처리 (빈 리스트 반환)

#### 3.2. dummy_theaters.dart 수정
**파일**: `lib/data/dummy_theaters.dart` (기존 파일 수정)

**수정 내용**:
- `fetchNearbyTheatersReal()`에서 메가박스 영화관도 처리
- 영화관 이름에 "메가박스" 또는 "메가" 포함 시 `TheaterScheduleService.getMegaboxSchedule()` 호출
- 기존 롯데시네마 로직과 병행

**테스트 포인트**: 
- 롯데시네마와 메가박스 영화관 모두 상영 시간표를 가져오는지 확인
- 다른 영화관은 빈 리스트를 반환하는지 확인

---

### 4단계: TMDb 초기화 시 메가박스 상영 여부 확인

#### 4.1. 메가박스 영화 확인 서비스 생성
**파일**: `lib/services/megabox_movie_checker.dart` (새로 생성)

**기능**:
- `isPlayingInMegabox(String movieTitle)`: 메가박스에서 상영 중인지 확인
- `MovieTitleMatcher.isPlayingInMegabox()` 사용

#### 4.2. MovieInitializationService 수정
**파일**: `lib/services/movie_initialization_service.dart` (기존 파일 수정)

**수정 내용**:
- `_saveNowPlayingMovies()`와 `_savePopularMovies()`에서:
  - `LotteCinemaMovieChecker.isPlayingInLotteCinema()` 확인
  - `MegaboxMovieChecker.isPlayingInMegabox()` 확인
  - 둘 중 하나라도 true이면 `isRecent = true` 설정

**로직**:
```dart
final isPlayingInLotte = await LotteCinemaMovieChecker.isPlayingInLotteCinema(movie.title);
final isPlayingInMegabox = await MegaboxMovieChecker.isPlayingInMegabox(movie.title);
if (isPlayingInLotte || isPlayingInMegabox) {
  movie = movie.copyWith(isRecent: true);
}
```

**테스트 포인트**: 
- TMDb에서 상영 중이 아니지만 메가박스에서 상영 중인 영화가 `isRecent = true`로 설정되는지 확인
- 롯데시네마와 메가박스 모두 확인하는지 확인
- 둘 중 하나라도 상영 중이면 `isRecent = true`로 설정되는지 확인

**완료 상태**: ✅ 완료
- `MegaboxMovieChecker` 서비스 생성 완료
- `MovieInitializationService` 수정 완료 (현재 상영 중인 영화 + 인기 영화 모두 처리)
- 단위 테스트 작성 및 통과 (4개 테스트 모두 통과)
- TestScreen에 테스트 섹션 추가 완료

---

### 5단계: UI 통합 및 최적화

#### 5.1. TheaterCard 위젯 확인
**파일**: `lib/widgets/theater_card.dart` (기존 파일 확인)

**확인 사항**:
- 현재 로직: `t.name.contains('롯데시네마') || t.name.contains('롯데')`로 롯데시네마 감지
- 메가박스도 동일하게 처리: `t.name.contains('메가박스') || t.name.contains('메가')` 추가
- "실시간 상영 시간표" 라벨과 파란색 Chip이 메가박스에도 표시되는지 확인

**수정 필요 시**:
- 메가박스 영화관도 "실시간 상영 시간표" 라벨 표시
- 메가박스 상영 시간표도 파란색 Chip으로 표시

#### 5.2. 에러 처리 및 사용자 경험 개선
- 네트워크 에러 시 조용히 처리 (하이퍼링크로 fallback) - 이미 구현됨
- 메가박스 API 오류도 롯데시네마와 동일하게 처리
- 캐시 정리 기능은 롯데시네마와 메가박스 공통 사용

**완료 상태**: ✅ 완료
- TheaterCard 위젯 메가박스 지원 확인 완료
- 에러 처리 확인 완료
- 캐시 최적화 확인 완료
- 성능 최적화 확인 완료
- 통합 메서드 최적화 완료

**최적화 요약**: `OPTIMIZATION_SUMMARY.md` 참고

---

## 🔄 작업 순서 및 테스트 계획

### Phase 1: 기반 구조 (1단계 + 2단계)
**목표**: CSV 파싱 및 API 클라이언트 구현

**작업 내용**:
1. CSV 파일을 assets에 추가
2. 메가박스 데이터 모델 생성
3. CSV 파서 확장 (메가박스 추가)
4. 메가박스 API 클라이언트 구현
5. 영화 제목 매칭 로직 확장

**테스트**:
- TestScreen에 메가박스 테스트 섹션 추가
- CSV 파싱 테스트
- API 클라이언트 테스트 (실제 API 호출)
- 영화 제목 매칭 테스트

---

### Phase 2: 통합 (3단계)
**목표**: TheaterScheduleService 확장 및 dummy_theaters.dart 수정

**작업 내용**:
1. TheaterScheduleService에 메가박스 지원 추가
2. `getSchedule()` 통합 메서드 구현
3. dummy_theaters.dart에서 메가박스 영화관 처리

**테스트**:
- TestScreen에서 메가박스 상영 시간표 가져오기 테스트
- 롯데시네마와 메가박스 모두 작동하는지 확인
- 다른 영화관은 빈 리스트 반환하는지 확인

---

### Phase 3: TMDb 초기화 보완 (4단계)
**목표**: TMDb 초기화 시 메가박스 상영 여부 확인

**작업 내용**:
1. MegaboxMovieChecker 서비스 생성
2. MovieInitializationService 수정 (롯데시네마 + 메가박스)

**테스트**:
- TestScreen에서 메가박스 상영 여부 확인 테스트
- TMDb 초기화 후 "최근 상영 중인 영화" 섹션 확인
- 메가박스에서 상영 중인 영화가 포함되는지 확인

---

### Phase 4: UI 통합 및 최적화 (5단계)
**목표**: TheaterCard 위젯 확인 및 최종 테스트

**작업 내용**:
1. TheaterCard 위젯 확인 (메가박스 지원)
2. 최종 통합 테스트

**테스트**:
- TheaterCard에서 메가박스 영화관도 "실시간 상영 시간표" 표시되는지 확인
- 롯데시네마와 메가박스 모두 정상 작동하는지 확인

---

## 📌 주의사항

1. **롯데시네마 코드 재사용**: 가능한 한 기존 롯데시네마 코드를 확장하여 사용
2. **캐시 키 형식**: 메가박스도 동일한 캐시 키 형식 사용 (`theaterName_movieTitle_date`)
3. **에러 처리**: 롯데시네마와 동일하게 조용히 처리 (빈 리스트 반환)
4. **날짜 형식 변환**: 메가박스는 YYYYMMDD 형식이므로 변환 필요
5. **areaCd1 처리**: 메가박스 API의 areaCd1은 기본값 "45" 사용 (필요시 영화관별로 매핑 가능)

---

## ✅ 완료 체크리스트

### 1단계
- [ ] CSV 파일을 assets에 추가
- [ ] 메가박스 데이터 모델 생성
- [ ] CSV 파서 확장
- [ ] 테스트: CSV 파싱 확인

### 2단계
- [ ] 메가박스 API 클라이언트 구현
- [ ] 영화 제목 매칭 로직 확장
- [ ] 테스트: API 클라이언트 및 매칭 로직 확인

### 3단계
- [ ] TheaterScheduleService 확장
- [ ] dummy_theaters.dart 수정
- [ ] 테스트: 상영 시간표 가져오기 확인

### 4단계
- [ ] MegaboxMovieChecker 서비스 생성
- [ ] MovieInitializationService 수정
- [ ] 테스트: TMDb 초기화 시 메가박스 상영 여부 확인

### 5단계
- [ ] TheaterCard 위젯 확인
- [ ] 최종 통합 테스트

---

**문서 작성일**: 2026년 1월  
**참고**: 롯데시네마 통합 계획서 (`reference_for_lottecinema_data/LOTTECINEMA_INTEGRATION_PLAN.md`)
