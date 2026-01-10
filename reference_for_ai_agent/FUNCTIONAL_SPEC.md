# 🎬 무비어리 (Movie Diary) 기능 명세서

## 1. 프로젝트 개요
- **프로젝트명:** 무비어리 (Movie Diary)
- **플랫폼:** Android Native App
- **개발 언어:** Kotlin
- **주요 기술:** Jetpack Compose, Room Database, Retrofit, **Firebase**
- **목표:** 영화 관람 기록을 로컬에 저장하고, 데이터를 바탕으로 개인의 취향을 분석해주는 다이어리 앱

---

## 2. 주요 기능 (Tab 구성)

### 2.1. 탭 1: 탐색 (Explore)
**담당:** 팀원 (Frontend/API Focus)

- **영화 검색 및 조회**
  - 외부 API(TMDB 등)를 연동하여 영화 제목, 장르 등으로 검색.
  - 최신 상영작 및 인기 영화 목록을 가로 스크롤/그리드 형태로 제공.
- **영화 상세 정보**
  - 포스터, 제목, 개봉일, 장르, 평점, 러닝타임 표시.
  - **액션:** '기록하기' 버튼(기록 탭 연동), '찜하기' 버튼(저장 탭 연동).
- **상영관 정보 (Optional)**
  - 현재 위치 기반 주변 상영관 정보 및 상영 시간표 확인 (초기엔 Mock Data 활용 가능).

### 2.2. 탭 2: 기록 (Records)
**담당:** 본인 (Backend Logic/DB Focus)

- **관람 기록 작성 (Create)**
  - **필수 정보:** 영화 선택, 별점(0.5~5.0), 관람일.
  - **선택 정보:** 한줄평, 상세 리뷰, 태그(혼자, 친구, 극장 등), 인증샷(갤러리 이미지).
- **기록 목록 조회 (Read)**
  - 카드 리스트 형태로 작성한 리뷰 표시.
  - **정렬:** 최신순, 별점순, 많이 본 순.
  - **필터:** 기간 설정(Date Range), 검색어(제목/태그) 필터링.
- **기록 관리 (Update/Delete)**
  - 작성된 기록 수정 및 삭제 기능.

### 2.3. 탭 3: 저장 (Saved)
**담당:** 팀원 (Frontend/API Focus)

- **위시리스트 (Wishlist)**
  - '보고 싶은 영화'로 찜한 영화들을 3열 그리드 뷰로 표시.
- **상세 및 관리**
  - 포스터 클릭 시 하단 시트(Bottom Sheet)로 상세 정보 표시.
  - '저장 해제' 버튼을 통해 목록에서 제거.

### 2.4. 탭 4: 취향 (Taste)
**담당:** 본인 (Backend Logic/DB Focus)

- **취향 분석 대시보드**
  - **KPI 카드:** 총 기록 수, 평균 별점, 최다 선호 장르(Top Genre).
- **데이터 시각화 (Charts)**
  - **장르 분포:** 전체/최근 1년/최근 3년 기간별 선호 장르 비율 (Pie Chart).
  - **관람 추이:** 월별/연도별 영화 관람 횟수 변화 그래프 (Line Chart).
- **개인화 추천**
  - 사용자가 고평점(4.0 이상)을 준 장르를 분석하여, 아직 보지 않은 해당 장르 영화 추천.

---

## 3. 데이터 및 아키텍처 전략

### 3.1. 데이터베이스 및 백엔드 (Room + Firebase)
로컬 데이터베이스와 Firebase를 연동하여 데이터 동기화 및 백업을 지원합니다.
- **User:** Firebase Auth를 통한 사용자 인증 (Google, Email) 및 게스트 모드 지원.
- **Database:** 
  - **Local:** Room Database (오프라인 지원, 빠른 로딩).
  - **Remote:** Cloud Firestore (데이터 백업, 기기 간 동기화).
- **Movie:** API 호출 횟수 절감을 위해 조회한 영화 정보 로컬 캐싱.

### 3.2. 이미지 및 스토리지 전략
- **포스터:** 
  - API에서 받은 이미지 URL을 `Coil` 라이브러리를 통해 로드.
  - 최초 로드 시 내부 저장소에 파일로 저장하고, 이후엔 로컬 파일 경로를 우선 사용 (네트워크 비용 절감).
- **사용자 업로드 사진:**
  - **Local:** 갤러리 URI 임시 사용.
  - **Remote:** Firebase Storage에 업로드하여 영구 보관 및 URL 공유.

### 3.3. 기술 스택 상세
- **UI:** Jetpack Compose (Material3 Design System 적용).
- **Architecture:** MVVM (Model-View-ViewModel) 패턴.
- **Network:** Retrofit2 (TMDB API), Firebase SDK (Backend).
- **Async:** Kotlin Coroutines + Flow.
- **Chart:** Vico 또는 MPAndroidChart (취향 분석용).
