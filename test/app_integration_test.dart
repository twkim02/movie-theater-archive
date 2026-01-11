import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:movie_diary_app/app.dart';
import 'package:movie_diary_app/state/app_state.dart';

void main() {
  group('앱 통합 테스트', () {
    testWidgets('AppState가 Provider를 통해 제공되는지 확인', (WidgetTester tester) async {
      // When: 앱 빌드
      await tester.pumpWidget(const MyApp());

      // Then: AppState에 접근 가능해야 함
      final appState = tester.element(find.byType(MaterialApp)).read<AppState>();
      expect(appState, isNotNull);
      expect(appState.movies.isNotEmpty, true);
    });

    testWidgets('앱이 정상적으로 빌드되는지 확인', (WidgetTester tester) async {
      // When: 앱 빌드
      await tester.pumpWidget(const MyApp());

      // Then: 앱이 빌드되고 탐색 탭이 표시되어야 함 (AppBar와 NavigationBar에 둘 다 있을 수 있음)
      expect(find.text('탐색'), findsWidgets); // findsWidgets로 변경
      expect(find.text('탐색'), findsAtLeastNWidgets(1)); // 최소 1개는 있어야 함
    });
  });
}
