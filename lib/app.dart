import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/root_screen.dart';
import 'state/app_state.dart';
import 'database/movie_database.dart';
import 'services/movie_db_initializer.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final appState = AppState();
        // 비동기로 DB 초기화 및 영화 로드
        _initializeDatabase(appState);
        return appState;
      },
      child: MaterialApp(
        title: 'movie_diary_app',
        debugShowCheckedModeBanner: false,
        home: const RootScreen(),
      ),
    );
  }

  /// 데이터베이스를 초기화하고 영화 데이터를 로드합니다.
  Future<void> _initializeDatabase(AppState appState) async {
    try {
      // DB 초기화 (테이블 생성)
      await MovieDatabase.database;

      // 더미 데이터로 초기화 (DB가 비어있을 경우)
      await MovieDbInitializer.initializeWithDummyData();

      // DB에서 영화 로드
      await appState.loadMoviesFromDatabase();
    } catch (e) {
      debugPrint('DB 초기화 실패: $e');
      // 에러 발생 시에도 앱은 계속 실행 (더미 데이터 사용)
    }
  }
}
