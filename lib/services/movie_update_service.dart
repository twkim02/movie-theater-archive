import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/tmdb_client.dart';
import '../api/tmdb_mapper.dart';
import '../repositories/movie_repository.dart';
import '../utils/env_loader.dart';
import '../models/movie.dart';

/// 영화 데이터 갱신 서비스
/// 
/// 현재 상영 중인 영화 정보를 주기적으로 갱신합니다.
/// 스마트 업데이트 전략을 사용하여 데이터 손실 없이 갱신합니다.
class MovieUpdateService {
  /// 마지막 갱신 시간을 저장하는 키
  static const String _lastUpdateKey = 'movies_last_update_timestamp';

  /// 24시간을 밀리초로 변환
  static const int _updateIntervalMs = 24 * 60 * 60 * 1000; // 24시간

  /// 마지막 갱신 시간을 가져옵니다.
  /// 
  /// Returns 마지막 갱신 시간 (timestamp, 없으면 null)
  static Future<int?> getLastUpdateTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastUpdateKey);
    return timestamp;
  }

  /// 마지막 갱신 시간을 저장합니다.
  /// 
  /// [timestamp] 저장할 timestamp (현재 시간)
  static Future<void> setLastUpdateTime(int timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastUpdateKey, timestamp);
  }

  /// 24시간이 경과했는지 확인합니다.
  /// 
  /// Returns 24시간 경과 시 true, 아니면 false
  static Future<bool> shouldUpdate() async {
    final lastUpdate = await getLastUpdateTime();
    if (lastUpdate == null) {
      // 처음 실행이면 갱신 필요
      return true;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = now - lastUpdate;
    return elapsed >= _updateIntervalMs;
  }

  /// 현재 상영 중인 영화를 스마트 업데이트합니다.
  /// 
  /// 스마트 업데이트 전략:
  /// 1. TMDb API로 현재 상영 중인 영화 가져오기
  /// 2. 기존 DB의 모든 영화의 is_recent를 0으로 설정
  /// 3. 새로 가져온 영화 중 DB에 없는 것은 추가 (is_recent = 1)
  /// 4. 새로 가져온 영화 중 DB에 있는 것은 is_recent = 1로 업데이트
  /// 
  /// Returns 새로 추가된 영화 개수
  static Future<int> updateNowPlayingMovies() async {
    final apiKey = EnvLoader.tmdbApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('TMDb API 키가 없습니다.');
    }

    final client = TmdbClient(apiKey: apiKey);
    int newMoviesCount = 0;

    try {
      // 장르 맵 로드
      final genreMap = await client.getGenres();
      TmdbMapper.setGenreMap(genreMap);

      // 현재 상영 중인 영화 가져오기
      final response = await client.getNowPlayingMovies(page: 1);

      // 각 영화의 상세 정보를 가져와서 runtime 등 추가 정보 확보
      final moviesWithDetails = <Movie>[];

      for (final tmdbMovie in response.results) {
        try {
          // 상세 정보 가져오기 (runtime 등)
          final detail = await client.getMovieDetails(tmdbMovie.id);

          // 상세 정보를 Movie 모델로 변환
          final movie = TmdbMapper.toMovieFromDetail(
            detail,
            isRecent: true, // 현재 상영 중이므로 true
          );

          moviesWithDetails.add(movie);
        } catch (e) {
          // 상세 정보 가져오기 실패 시 기본 정보만 사용
          debugPrint('영화 상세 정보 가져오기 실패 (${tmdbMovie.id}): $e');
          final movie = TmdbMapper.toMovie(
            tmdbMovie,
            isRecent: true,
          );
          moviesWithDetails.add(movie);
        }

        // API 호출 제한을 고려하여 약간의 딜레이 추가
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // 현재 상영 중인 영화 ID 목록
      final recentMovieIds = moviesWithDetails.map((m) => m.id).toList();

      // 1. 기존 DB의 모든 영화의 is_recent를 0으로 설정
      // (updateRecentFlag 메서드가 이 작업을 수행합니다)
      await MovieRepository.updateRecentFlag(recentMovieIds);

      // 2. 새로 가져온 영화 중 DB에 없는 것은 추가, 있는 것은 업데이트
      for (final movie in moviesWithDetails) {
        final existing = await MovieRepository.getMovieById(movie.id);
        if (existing == null) {
          // DB에 없으면 추가
          await MovieRepository.addMovie(movie);
          newMoviesCount++;
        } else {
          // DB에 있으면 is_recent만 업데이트 (다른 정보는 유지)
          final updatedMovie = existing.copyWith(isRecent: true);
          await MovieRepository.updateMovie(updatedMovie);
        }
      }

      // 마지막 갱신 시간 저장
      final now = DateTime.now().millisecondsSinceEpoch;
      await setLastUpdateTime(now);

      debugPrint('영화 갱신 완료: 새로 추가된 영화 $newMoviesCount개');

      return newMoviesCount;
    } catch (e) {
      throw Exception('영화 갱신 실패: $e');
    }
  }

  /// 앱 시작 시 자동 갱신을 수행합니다.
  /// 
  /// 24시간이 경과했으면 자동으로 갱신합니다.
  /// 
  /// Returns 갱신이 수행되었으면 true, 아니면 false
  static Future<bool> checkAndUpdateIfNeeded() async {
    try {
      final shouldUpdateNow = await shouldUpdate();
      if (!shouldUpdateNow) {
        debugPrint('영화 갱신 불필요 (24시간 미경과)');
        return false;
      }

      debugPrint('24시간 경과, 영화 갱신 시작...');
      await updateNowPlayingMovies();
      return true;
    } catch (e) {
      debugPrint('자동 갱신 실패: $e');
      // 에러가 발생해도 앱은 계속 실행
      return false;
    }
  }

  /// 마지막 갱신 시간을 포맷팅하여 반환합니다.
  /// 
  /// Returns 포맷팅된 문자열 (예: "2024-01-15 14:30")
  static Future<String> getLastUpdateTimeFormatted() async {
    final timestamp = await getLastUpdateTime();
    if (timestamp == null) {
      return '갱신 이력 없음';
    }

    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final year = dateTime.year;
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$year-$month-$day $hour:$minute';
  }
}
