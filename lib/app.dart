import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 누락된 import 추가
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
        _initializeDatabase(appState);
        return appState;
      },
      child: MaterialApp(
        title: '무비어리',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'TypoCrayon', // 팀원의 폰트 설정 유지
        ),
        home: const RootScreen(),
      ),
    );
  }

  Future<void> _initializeDatabase(AppState appState) async {
    try {
      await MovieDatabase.database;
      await UserInitializationService.initializeAll();

      final prefs = await SharedPreferences.getInstance();
      final isInitialized = prefs.getBool('movies_initialized_from_tmdb') ?? false;

      if (!isInitialized) {
        try {
          await MovieInitializationService.initializeMovies();
          await prefs.setBool('movies_initialized_from_tmdb', true);
        } catch (e) {
          await MovieDbInitializer.initializeWithDummyData();
        }
      } else {
        final hasMovies = await MovieDbInitializer.hasMovies();
        if (!hasMovies) {
          await MovieDbInitializer.initializeWithDummyData();
        }
      }

      await appState.loadMoviesFromDatabase();
      await appState.loadRecordsFromDatabase();
      await appState.loadWishlistFromDatabase();
      await MovieUpdateService.checkAndUpdateIfNeeded();
      await appState.refreshMovies();
    } catch (e) {
      debugPrint('DB 초기화 실패: $e');
    }
  }
}