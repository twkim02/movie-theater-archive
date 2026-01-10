import 'package:flutter_test/flutter_test.dart';
import 'package:movie_diary_app/app.dart';

void main() {
  testWidgets('앱이 정상적으로 빌드되고 Provider가 연결되어 있는지 확인', (WidgetTester tester) async {
    // When: 앱 빌드
    await tester.pumpWidget(const MyApp());
    
    // Then: RootScreen의 탐색 탭이 표시되어야 함 (AppBar와 NavigationBar에 둘 다 있을 수 있음)
    expect(find.text('탐색'), findsWidgets); // findsWidgets로 변경 (여러 개 있어도 OK)
    expect(find.text('탐색'), findsAtLeastNWidgets(1)); // 최소 1개는 있어야 함
  });
}
