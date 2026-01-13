import 'dart:convert';
import 'package:flutter/services.dart';

/// 환경 변수를 로드하는 유틸리티 클래스
class EnvLoader {
  static Map<String, dynamic>? _env;

  /// env.json 파일에서 환경 변수 로드
  static Future<void> load() async {
    try {
      final String jsonString = await rootBundle.loadString('env.json');
      _env = jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('환경 변수 로드 실패: $e');
    }
  }

  /// key로 환경 변수 가져오기
  static String? get(String key) {
    return _env?[key] as String?;
  }

  /// TMDb API 키
  static String? get tmdbApiKey => get('TMDB_API_KEY');

  /// ✅ Kakao REST API 키 (추가!)
  static String? get kakaoRestApiKey => get('KAKAO_REST_API_KEY');
}
