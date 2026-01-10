# 🧪 코드 검증 가이드

이 문서는 작성한 코드가 제대로 작동하는지 확인하는 방법을 설명합니다.

## 📋 목차

1. [자동화된 테스트 실행](#1-자동화된-테스트-실행)
2. [시각적 테스트 화면](#2-시각적-테스트-화면)
3. [각 테스트의 의미](#3-각-테스트의-의미)
4. [테스트 결과 해석](#4-테스트-결과-해석)

---

## 1. 자동화된 테스트 실행

### 전체 테스트 실행

터미널에서 다음 명령어를 실행하세요:

```bash
flutter test
```

이 명령어는 모든 테스트 파일을 실행하고 결과를 보여줍니다.

### 특정 테스트만 실행

```bash
# Movie 모델 테스트만 실행
flutter test test/models/movie_test.dart

# AppState 테스트만 실행
flutter test test/state/app_state_test.dart

# 더미데이터 테스트만 실행
flutter test test/data/dummy_movies_test.dart
```

### 예상되는 결과

모든 테스트가 통과하면 다음과 같은 메시지가 표시됩니다:

```
00:00 +7: All tests passed!
```

---

## 2. 시각적 테스트 화면

### 테스트 화면 접근 방법

#### 방법 1: RootScreen 임시 수정 (개발 중에만)

`lib/screens/root_screen.dart` 파일을 임시로 수정:

```dart
import 'test_screen.dart'; // 추가

// screens 리스트에 추가
final screens = [
  const TestScreen(),  // 테스트 화면을 첫 번째로 추가
  const ExploreScreen(),
  const DiaryScreen(),
  const SavedScreen(),
  const TasteScreen(),
];
```

#### 방법 2: 직접 네비게이션 추가

`RootScreen`에 FloatingActionButton으로 테스트 화면 접근:

```dart
floatingActionButton: FloatingActionButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TestScreen()),
    );
  },
  child: const Icon(Icons.bug_report),
),
```

### 테스트 화면 기능

테스트 화면에서는 다음을 확인할 수 있습니다:

1. ✅ **테스트 요약**: 모든 기능이 정상 작동하는지 요약
2. 📝 **Movie 모델 테스트**: JSON 변환, copyWith 등
3. 🔄 **AppState 테스트**: 북마크 기능 등
4. 📚 **북마크된 영화 목록**: 실제 북마크 상태 확인

---

## 3. 각 테스트의 의미

### Movie 모델 테스트 (`test/models/movie_test.dart`)

#### `fromJson` 테스트
- **목적**: JSON 데이터를 Movie 객체로 변환하는지 확인
- **검증**: 모든 필드가 올바르게 파싱되는지
- **중요성**: API나 더미데이터에서 받은 JSON을 사용할 수 있는지 확인

#### `toJson` 테스트
- **목적**: Movie 객체를 JSON으로 변환하는지 확인
- **검증**: 나중에 로컬 저장이나 API 전송 시 사용 가능한지

#### `Round-trip` 테스트
- **목적**: JSON → Movie → JSON 변환이 손실 없이 되는지 확인
- **검증**: 데이터 일관성 보장

#### `copyWith` 테스트
- **목적**: 불변 객체의 일부 필드만 변경하는 기능 확인
- **검증**: 상태 관리 시 유용한 기능이 작동하는지

### DummyMovies 테스트 (`test/data/dummy_movies_test.dart`)

#### 데이터 로드 테스트
- **목적**: 더미 데이터가 올바르게 로드되는지 확인
- **검증**: 7개의 영화가 모두 로드되는지

#### 필수 필드 검증
- **목적**: 모든 영화의 필수 데이터가 채워져 있는지 확인
- **검증**: UI에서 사용할 때 오류가 발생하지 않는지

#### 특정 영화 존재 확인
- **목적**: 더미데이터 예시.txt에 명시된 영화들이 모두 있는지 확인
- **검증**: 데이터 계약서 준수

### AppState 테스트 (`test/state/app_state_test.dart`)

#### 초기 상태 테스트
- **목적**: 앱 시작 시 올바른 초기 상태인지 확인
- **검증**: 영화 리스트는 있지만 북마크는 비어있어야 함

#### 북마크 기능 테스트
- **목적**: 북마크 추가/제거/토글이 정상 작동하는지 확인
- **검증**: 상태 변경 시 UI 업데이트가 가능한지

#### 불변성 테스트
- **목적**: 내부 상태가 직접 수정되지 않도록 보호되는지 확인
- **검증**: 안전한 상태 관리

---

## 4. 테스트 결과 해석

### ✅ 모든 테스트 통과

```
00:00 +7: All tests passed!
```

**의미**: 
- 모든 코드가 정상 작동함
- 팀원과 코드를 합쳐도 안전함
- 데이터 구조가 올바르게 구현됨

**다음 단계**: 팀원과 코드 합치기 가능

---

### ❌ 일부 테스트 실패

```
00:00 +5 -2: Some tests failed.
  Failed tests:
  - test/models/movie_test.dart: fromJson 테스트
  - test/state/app_state_test.dart: 북마크 토글 테스트
```

**의미**: 
- 문제가 있는 부분이 있음
- 수정이 필요함

**조치 방법**:
1. 실패한 테스트 이름 확인
2. 에러 메시지 확인
3. 해당 부분의 코드 수정
4. 다시 테스트 실행

---

## 🔍 문제 해결

### 테스트 실행 시 "package not found" 오류

```bash
flutter pub get
```

### 특정 테스트만 계속 실패하는 경우

1. 해당 테스트 파일의 `expect` 부분 확인
2. 실제 데이터와 예상 값 비교
3. 디버깅용 print 문 추가:

```dart
test('문제가 있는 테스트', () {
  final result = someFunction();
  print('실제 결과: $result'); // 디버깅
  expect(result, expectedValue);
});
```

---

## 📝 체크리스트

코드를 팀원과 합치기 전에 확인:

- [ ] `flutter test` 명령어로 모든 테스트 통과
- [ ] 테스트 화면에서 모든 기능이 정상 작동
- [ ] 린터 오류 없음 (`flutter analyze`)
- [ ] 앱이 정상적으로 실행됨 (`flutter run`)
- [ ] 코드 주석과 문서가 명확함

---

## 🚀 최종 확인

모든 테스트를 통과했다면:

1. ✅ **Movie 모델**: JSON 변환, copyWith 등 모든 기능 작동
2. ✅ **DummyMovies**: 7개 영화 데이터 정상 로드
3. ✅ **AppState**: 북마크 기능, 상태 관리 정상 작동
4. ✅ **Provider 연결**: 앱 전반에서 상태 접근 가능

**이제 팀원과 안심하고 코드를 합칠 수 있습니다!** 🎉

---

## 📌 참고사항

- 테스트 화면(`test_screen.dart`)은 개발 중에만 사용
- 최종 제출 전이나 팀원과 합칠 때는 제거 가능
- 테스트 파일(`test/` 폴더)은 그대로 유지 (CI/CD에서 사용 가능)
