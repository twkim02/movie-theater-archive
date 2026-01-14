import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/megabox_data.dart';

/// 메가박스 API 클라이언트
/// 
/// 메가박스 웹사이트의 API를 호출하여 상영 시간표를 가져오는 클래스입니다.
/// 공식 API가 아니므로 안정성을 보장할 수 없습니다.
class MegaboxClient {
  // 메가박스 API 기본 URL
  static const String _baseUrl = 'https://www.megabox.co.kr/on/oh/ohb/SimpleBooking/selectBokdList.do';
  
  // User-Agent (브라우저처럼 보이기 위해)
  static const String _userAgent = 
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
  
  // Referer
  static const String _referer = 'https://www.megabox.co.kr/booking';
  
  // 요청 타임아웃 (5초)
  static const Duration _timeout = Duration(seconds: 5);

  MegaboxClient();

  /// 특정 영화관, 특정 영화의 상영 시간표를 가져옵니다.
  /// 
  /// [brchNo] 영화관 번호 (예: "3011")
  /// [movieNo] 영화 번호 (메가박스 내부 ID, 예: "25096900")
  /// [playDe] 상영일 (YYYYMMDD 형식, 예: "20260114")
  /// 
  /// Returns 상영 시간표 목록 (실패 시 빈 리스트)
  Future<List<MegaboxSchedule>> getMovieSchedule({
    required String brchNo,
    required String movieNo,
    required String playDe,
  }) async {
    try {
      // 요청 Payload 구성
      final payload = {
        'arrMovieNo': movieNo,
        'playDe': playDe,
        'brchNoListCnt': 1,
        'brchNo1': brchNo,
        'movieNo1': movieNo,
      };

      // 헤더 설정
      final headers = {
        'User-Agent': _userAgent,
        'Content-Type': 'application/json',
        'Referer': _referer,
        'X-Requested-With': 'XMLHttpRequest',
      };

      // POST 요청 (JSON)
      final uri = Uri.parse(_baseUrl);
      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(_timeout);

      // 응답 확인
      if (response.statusCode != 200) {
        debugPrint('❌ 메가박스 API 오류: ${response.statusCode}');
        return [];
      }

      // JSON 파싱
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      
      // movieFormList 추출
      final movieFormList = data['movieFormList'] as List<dynamic>?;
      if (movieFormList == null || movieFormList.isEmpty) {
        debugPrint('ℹ️ 상영 시간표가 없습니다. (brchNo: $brchNo, movieNo: $movieNo, playDe: $playDe)');
        return [];
      }

      // MegaboxSchedule 리스트로 변환
      final schedules = <MegaboxSchedule>[];
      for (final item in movieFormList) {
        try {
          final schedule = MegaboxSchedule.fromJson(
            item as Map<String, dynamic>,
          );
          schedules.add(schedule);
        } catch (e) {
          debugPrint('⚠️ 상영 시간표 파싱 오류: $e');
          // 계속 진행
        }
      }

      return schedules;
    } on TimeoutException {
      debugPrint('❌ 요청 타임아웃 (메가박스 API)');
      return [];
    } on SocketException {
      debugPrint('❌ 네트워크 연결 오류 (메가박스 API)');
      return [];
    } on HttpException {
      debugPrint('❌ HTTP 오류 (메가박스 API)');
      return [];
    } on FormatException {
      debugPrint('❌ JSON 파싱 오류 (메가박스 API)');
      return [];
    } catch (e) {
      debugPrint('❌ 메가박스 API 오류: $e');
      return [];
    }
  }
}

/// 메가박스 API 예외 클래스
class MegaboxException implements Exception {
  final String message;
  final int? statusCode;

  MegaboxException(this.message, [this.statusCode]);

  @override
  String toString() => 'MegaboxException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}
