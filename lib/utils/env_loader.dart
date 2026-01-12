import 'dart:convert';
import 'package:flutter/services.dart';

/// 환경 변수를 로드하는 유틸리티 클래스
class EnvLoader {
  static Map<String, dynamic>? _env;

  /// 환경 변수를 로드합니다.
  /// 
  /// env.json 파일에서 API 키 등을 읽어옵니다.
  static Future<void> load() async {
    try {
      final String jsonString = await rootBundle.loadString('env.json');
      _env = jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('환경 변수 로드 실패: $e');
    }
  }

  /// 환경 변수 값을 가져옵니다.
  /// 
  /// [key] 환경 변수 키
  /// Returns 환경 변수 값 (없으면 null)
  static String? get(String key) {
    return _env?[key] as String?;
  }

  /// TMDb API 키를 가져옵니다.
  static String? get tmdbApiKey => get('TMDB_API_KEY');
}
