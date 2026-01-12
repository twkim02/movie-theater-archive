import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/root_screen.dart';
import 'state/app_state.dart';
import 'database/movie_database.dart';
import 'services/movie_db_initializer.dart';
import 'services/movie_initialization_service.dart';
import 'services/movie_update_service.dart';
import 'services/user_initialization_service.dart';

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

      // 기본 사용자 및 태그 초기화
      await UserInitializationService.initializeAll();

      // 초기화 완료 플래그 확인
      final prefs = await SharedPreferences.getInstance();
      final isInitialized = prefs.getBool('movies_initialized_from_tmdb') ?? false;

      if (!isInitialized) {
        // 최초 실행: TMDb API로 영화 데이터 초기화
        debugPrint('TMDb API로 영화 데이터 초기화 시작...');
        try {
          final savedCount = await MovieInitializationService.initializeMovies();
          debugPrint('TMDb API 초기화 완료: $savedCount개 영화 저장됨');
          
          // 초기화 완료 플래그 저장
          await prefs.setBool('movies_initialized_from_tmdb', true);
        } catch (e) {
          debugPrint('TMDb API 초기화 실패: $e');
          // TMDb API 실패 시 더미 데이터로 폴백
          await MovieDbInitializer.initializeWithDummyData();
        }
      } else {
        // 이미 초기화됨: DB가 비어있을 경우에만 더미 데이터 사용
        final hasMovies = await MovieDbInitializer.hasMovies();
        if (!hasMovies) {
          debugPrint('DB가 비어있어서 더미 데이터로 초기화...');
          await MovieDbInitializer.initializeWithDummyData();
        }
      }

      // DB에서 영화 로드
      await appState.loadMoviesFromDatabase();

      // DB에서 기록 및 위시리스트 로드
      await appState.loadRecordsFromDatabase();
      await appState.loadWishlistFromDatabase();

      // 24시간 경과 확인 및 자동 갱신
      await MovieUpdateService.checkAndUpdateIfNeeded();
      
      // 갱신 후 영화 리스트 다시 로드
      await appState.refreshMovies();
    } catch (e) {
      debugPrint('DB 초기화 실패: $e');
      // 에러 발생 시에도 앱은 계속 실행
    }
  }
}
