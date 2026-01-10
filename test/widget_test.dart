import 'package:flutter_test/flutter_test.dart';
import 'package:movie_diary_app/app.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('탐색'), findsOneWidget); // RootScreen의 첫 탭 appBar
  });
}
