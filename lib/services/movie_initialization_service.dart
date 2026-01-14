import 'package:flutter/foundation.dart';
import '../api/tmdb_client.dart';
import '../api/tmdb_mapper.dart';
import '../repositories/movie_repository.dart';
import '../utils/env_loader.dart';
import '../models/movie.dart';
import 'lottecinema_movie_checker.dart';
import 'megabox_movie_checker.dart';

/// 영화 데이터 초기화 서비스
/// 
/// TMDb API를 통해 현재 상영 중인 영화와 인기 영화를 가져와 DB에 저장합니다.
class MovieInitializationService {
  /// 영화 데이터를 초기화합니다.
  /// 
  /// 현재 상영 중인 영화와 인기 영화를 TMDb API에서 가져와 DB에 저장합니다.
  /// 이미 DB에 있는 영화는 스킵합니다.
  /// 
  /// Returns 저장된 영화 개수
  static Future<int> initializeMovies() async {
    final apiKey = EnvLoader.tmdbApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('TMDb API 키가 없습니다.');
    }

    final client = TmdbClient(apiKey: apiKey);
    int totalSaved = 0;

    try {
      // 1. 장르 맵 로드 (한 번만 로드)
      final genreMap = await client.getGenres();
      TmdbMapper.setGenreMap(genreMap);

      // 2. 현재 상영 중인 영화 가져오기 및 저장
      final nowPlayingSaved = await _saveNowPlayingMovies(client);
      totalSaved += nowPlayingSaved;

      // 3. 인기 영화 가져오기 및 저장 (여러 페이지)
      final popularSaved = await _savePopularMovies(client);
      totalSaved += popularSaved;

      return totalSaved;
    } catch (e) {
      throw Exception('영화 초기화 실패: $e');
    }
  }

  /// 현재 상영 중인 영화를 가져와서 DB에 저장합니다.
  /// 
  /// [client] TMDb 클라이언트
  /// Returns 저장된 영화 개수
  static Future<int> _saveNowPlayingMovies(TmdbClient client) async {
    try {
      // 현재 상영 중인 영화 가져오기 (1페이지)
      final response = await client.getNowPlayingMovies(page: 1);
      
      // 각 영화의 상세 정보를 가져와서 runtime 등 추가 정보 확보
      final moviesWithDetails = <Movie>[];
      
      for (final tmdbMovie in response.results) {
        try {
          // 상세 정보 가져오기 (runtime 등)
          final detail = await client.getMovieDetails(tmdbMovie.id);
          
          // TMDb에서는 현재 상영 중이므로 기본적으로 true
          // 하지만 롯데시네마나 메가박스에서도 상영 중인지 확인하여 보완
          var isRecent = true;
          
          // 롯데시네마와 메가박스에서 상영 중인지 확인 (에러 발생해도 계속 진행)
          try {
            final isPlayingInLotte = await LotteCinemaMovieChecker.isPlayingInLotteCinema(detail.title);
            final isPlayingInMegabox = await MegaboxMovieChecker.isPlayingInMegabox(detail.title);
            
            if (isPlayingInLotte || isPlayingInMegabox) {
              isRecent = true;
              if (isPlayingInLotte) {
                debugPrint('✅ 롯데시네마 상영 확인: "${detail.title}"');
              }
              if (isPlayingInMegabox) {
                debugPrint('✅ 메가박스 상영 확인: "${detail.title}"');
              }
            }
          } catch (e) {
            // 롯데시네마/메가박스 확인 실패해도 계속 진행 (TMDb 기준으로 true 유지)
            debugPrint('⚠️ 롯데시네마/메가박스 상영 여부 확인 실패 (${detail.title}): $e');
          }
          
          // 상세 정보를 Movie 모델로 변환
          final movie = TmdbMapper.toMovieFromDetail(
            detail,
            isRecent: isRecent,
          );
          
          moviesWithDetails.add(movie);
        } catch (e) {
          // 상세 정보 가져오기 실패 시 기본 정보만 사용
          debugPrint('영화 상세 정보 가져오기 실패 (${tmdbMovie.id}): $e');
          
          // 기본 정보로도 롯데시네마와 메가박스 확인 시도
          var isRecent = true;
          try {
            final isPlayingInLotte = await LotteCinemaMovieChecker.isPlayingInLotteCinema(tmdbMovie.title);
            final isPlayingInMegabox = await MegaboxMovieChecker.isPlayingInMegabox(tmdbMovie.title);
            
            if (isPlayingInLotte || isPlayingInMegabox) {
              isRecent = true;
              if (isPlayingInLotte) {
                debugPrint('✅ 롯데시네마 상영 확인 (기본 정보): "${tmdbMovie.title}"');
              }
              if (isPlayingInMegabox) {
                debugPrint('✅ 메가박스 상영 확인 (기본 정보): "${tmdbMovie.title}"');
              }
            }
          } catch (e) {
            // 롯데시네마/메가박스 확인 실패해도 계속 진행
            debugPrint('⚠️ 롯데시네마 상영 여부 확인 실패 (기본 정보, ${tmdbMovie.title}): $e');
          }
          
          final movie = TmdbMapper.toMovie(
            tmdbMovie,
            isRecent: isRecent,
          );
          moviesWithDetails.add(movie);
        }
        
        // API 호출 제한을 고려하여 약간의 딜레이 추가 (선택사항)
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // DB에 없는 영화만 필터링
      final newMovies = await MovieRepository.filterNewMovies(moviesWithDetails);

      // DB에 저장
      if (newMovies.isNotEmpty) {
        await MovieRepository.addMovies(newMovies);
      }

      return newMovies.length;
    } catch (e) {
      throw Exception('현재 상영 중인 영화 저장 실패: $e');
    }
  }

  /// 인기 영화를 가져와서 DB에 저장합니다.
  /// 
  /// 여러 페이지에 걸쳐 가져옵니다 (기본: 1~3페이지).
  /// 각 영화의 상세 정보를 가져와서 runtime 등 추가 정보를 포함합니다.
  /// 
  /// [client] TMDb 클라이언트
  /// [maxPages] 가져올 최대 페이지 수 (기본값: 3)
  /// Returns 저장된 영화 개수
  static Future<int> _savePopularMovies(
    TmdbClient client, {
    int maxPages = 7,
  }) async {
    int totalSaved = 0;

    try {
      // 여러 페이지에 걸쳐 인기 영화 가져오기
      for (int page = 1; page <= maxPages; page++) {
        final response = await client.getPopularMovies(page: page);

        // 각 영화의 상세 정보를 가져와서 runtime 등 추가 정보 확보
        final moviesWithDetails = <Movie>[];
        
        for (final tmdbMovie in response.results) {
          try {
            // 상세 정보 가져오기 (runtime 등)
            final detail = await client.getMovieDetails(tmdbMovie.id);
            
            // 인기 영화는 기본적으로 false이지만, 롯데시네마나 메가박스에서 상영 중인지 확인
            var isRecent = false;
            
            // 롯데시네마와 메가박스에서 상영 중인지 확인 (에러 발생해도 계속 진행)
            try {
              final isPlayingInLotte = await LotteCinemaMovieChecker.isPlayingInLotteCinema(detail.title);
              final isPlayingInMegabox = await MegaboxMovieChecker.isPlayingInMegabox(detail.title);
              
              if (isPlayingInLotte || isPlayingInMegabox) {
                isRecent = true;
                if (isPlayingInLotte) {
                  debugPrint('✅ 롯데시네마 상영 확인 (인기 영화): "${detail.title}" → isRecent = true');
                }
                if (isPlayingInMegabox) {
                  debugPrint('✅ 메가박스 상영 확인 (인기 영화): "${detail.title}" → isRecent = true');
                }
              }
            } catch (e) {
              // 롯데시네마/메가박스 확인 실패해도 계속 진행 (기본값 false 유지)
              debugPrint('⚠️ 롯데시네마/메가박스 상영 여부 확인 실패 (${detail.title}): $e');
            }
            
            // 상세 정보를 Movie 모델로 변환
            final movie = TmdbMapper.toMovieFromDetail(
              detail,
              isRecent: isRecent,
            );
            
            moviesWithDetails.add(movie);
          } catch (e) {
            // 상세 정보 가져오기 실패 시 기본 정보만 사용
            debugPrint('영화 상세 정보 가져오기 실패 (${tmdbMovie.id}): $e');
            
            // 기본 정보로도 롯데시네마와 메가박스 확인 시도
            var isRecent = false;
            try {
              final isPlayingInLotte = await LotteCinemaMovieChecker.isPlayingInLotteCinema(tmdbMovie.title);
              final isPlayingInMegabox = await MegaboxMovieChecker.isPlayingInMegabox(tmdbMovie.title);
              
              if (isPlayingInLotte || isPlayingInMegabox) {
                isRecent = true;
                if (isPlayingInLotte) {
                  debugPrint('✅ 롯데시네마 상영 확인 (기본 정보, 인기 영화): "${tmdbMovie.title}" → isRecent = true');
                }
                if (isPlayingInMegabox) {
                  debugPrint('✅ 메가박스 상영 확인 (기본 정보, 인기 영화): "${tmdbMovie.title}" → isRecent = true');
                }
              }
            } catch (e) {
              // 롯데시네마/메가박스 확인 실패해도 계속 진행
              debugPrint('⚠️ 롯데시네마/메가박스 상영 여부 확인 실패 (기본 정보, ${tmdbMovie.title}): $e');
            }
            
            final movie = TmdbMapper.toMovie(
              tmdbMovie,
              isRecent: isRecent,
            );
            moviesWithDetails.add(movie);
          }
          
          // API 호출 제한을 고려하여 약간의 딜레이 추가
          await Future.delayed(const Duration(milliseconds: 100));
        }

        // DB에 없는 영화만 필터링
        final newMovies = await MovieRepository.filterNewMovies(moviesWithDetails);

        // DB에 저장
        if (newMovies.isNotEmpty) {
          await MovieRepository.addMovies(newMovies);
          totalSaved += newMovies.length;
        }

        // 마지막 페이지에 도달했으면 중단
        if (page >= response.totalPages) {
          break;
        }
      }

      return totalSaved;
    } catch (e) {
      throw Exception('인기 영화 저장 실패: $e');
    }
  }

  /// 현재 상영 중인 영화만 업데이트합니다.
  /// 
  /// 기존의 is_recent 플래그를 업데이트하고, 새로운 상영 영화를 추가합니다.
  /// 
  /// Returns 새로 추가된 영화 개수
  static Future<int> updateNowPlayingMovies() async {
    final apiKey = EnvLoader.tmdbApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('TMDb API 키가 없습니다.');
    }

    final client = TmdbClient(apiKey: apiKey);

    try {
      // 장르 맵 로드
      final genreMap = await client.getGenres();
      TmdbMapper.setGenreMap(genreMap);

      // 현재 상영 중인 영화 가져오기
      final response = await client.getNowPlayingMovies(page: 1);
      final movies = TmdbMapper.toMovieList(response.results, isRecent: true);

      // 현재 상영 중인 영화 ID 목록
      final recentMovieIds = movies.map((m) => m.id).toList();

      // is_recent 플래그 업데이트
      await MovieRepository.updateRecentFlag(recentMovieIds);

      // 새로운 영화 추가
      final newMovies = await MovieRepository.filterNewMovies(movies);
      if (newMovies.isNotEmpty) {
        await MovieRepository.addMovies(newMovies);
      }

      return newMovies.length;
    } catch (e) {
      throw Exception('현재 상영 영화 업데이트 실패: $e');
    }
  }

  /// DB에 저장된 영화들의 러닝타임을 업데이트합니다.
  /// 
  /// runtime이 0인 영화들의 상세 정보를 TMDb API에서 가져와서 업데이트합니다.
  /// 
  /// Returns 업데이트된 영화 개수
  static Future<int> updateMovieRuntimes() async {
    final apiKey = EnvLoader.tmdbApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('TMDb API 키가 없습니다.');
    }

    final client = TmdbClient(apiKey: apiKey);
    int updatedCount = 0;

    try {
      // 장르 맵 로드
      final genreMap = await client.getGenres();
      TmdbMapper.setGenreMap(genreMap);

      // DB에서 모든 영화 가져오기
      final allMovies = await MovieRepository.getAllMovies();

      // runtime이 0인 영화만 필터링
      final moviesWithoutRuntime = allMovies.where((m) => m.runtime == 0).toList();

      debugPrint('러닝타임 업데이트 대상: ${moviesWithoutRuntime.length}개');

      // 각 영화의 상세 정보를 가져와서 runtime 업데이트
      for (final movie in moviesWithoutRuntime) {
        try {
          final movieId = int.tryParse(movie.id);
          if (movieId == null) continue;

          // 상세 정보 가져오기
          final detail = await client.getMovieDetails(movieId);

          // runtime이 있으면 업데이트
          if (detail.runtime != null && detail.runtime! > 0) {
            final updatedMovie = movie.copyWith(runtime: detail.runtime!);
            await MovieRepository.updateMovie(updatedMovie);
            updatedCount++;
          }

          // API 호출 제한을 고려하여 약간의 딜레이 추가
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          debugPrint('영화 러닝타임 업데이트 실패 (${movie.id}): $e');
          // 계속 진행
        }
      }

      return updatedCount;
    } catch (e) {
      throw Exception('러닝타임 업데이트 실패: $e');
    }
  }
}
