import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/lottecinema_data.dart';

/// 롯데시네마 API 클라이언트
/// 
/// 롯데시네마 웹사이트의 API를 호출하여 상영 시간표를 가져오는 클래스입니다.
/// 공식 API가 아니므로 안정성을 보장할 수 없습니다.
class LotteCinemaClient {
  // 롯데시네마 API 기본 URL
  static const String _baseUrl = 'https://www.lottecinema.co.kr/LCWS/Ticketing/TicketingData.aspx';
  
  // User-Agent (브라우저처럼 보이기 위해)
  static const String _userAgent = 
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36';
  
  // Referer
  static const String _referer = 'https://www.lottecinema.co.kr/NLCHS/Ticketing';
  
  // Origin
  static const String _origin = 'https://www.lottecinema.co.kr';
  
  // 요청 타임아웃 (5초)
  static const Duration _timeout = Duration(seconds: 5);

  LotteCinemaClient();

  /// 특정 영화관, 특정 영화의 상영 시간표를 가져옵니다.
  /// 
  /// [cinemaId] 영화관 ID (예: "1|0003|4008")
  /// [movieNo] 영화 번호 (롯데시네마 내부 ID, 예: "23663")
  /// [playDate] 상영일 (YYYY-MM-DD 형식, 예: "2026-01-13")
  /// 
  /// Returns 상영 시간표 목록 (실패 시 빈 리스트)
  Future<List<LotteCinemaSchedule>> getMovieSchedule({
    required String cinemaId,
    required String movieNo,
    required String playDate,
  }) async {
    try {
      // 요청 파라미터 구성
      final dicParam = {
        'MethodName': 'GetPlaySequence',
        'channelType': 'HO',
        'osType': 'W',
        'osVersion': _userAgent,
        'playDate': playDate,
        'cinemaID': cinemaId,
        'representationMovieCode': movieNo,
      };

      // POST 요청 body
      final payload = {
        'paramList': jsonEncode(dicParam),
      };

      // 헤더 설정
      final headers = {
        'User-Agent': _userAgent,
        'Referer': _referer,
        'Origin': _origin,
        'Content-Type': 'application/x-www-form-urlencoded',
      };

      // POST 요청
      final uri = Uri.parse(_baseUrl);
      final response = await http
          .post(uri, body: payload, headers: headers)
          .timeout(_timeout);

      // 응답 확인
      if (response.statusCode != 200) {
        debugPrint('❌ 롯데시네마 API 오류: ${response.statusCode}');
        return [];
      }

      // JSON 파싱
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      
      // PlaySeqs.Items 추출
      final playSeqs = data['PlaySeqs'] as Map<String, dynamic>?;
      if (playSeqs == null) {
        debugPrint('⚠️ 롯데시네마 API 응답에 PlaySeqs가 없습니다.');
        return [];
      }

      final items = playSeqs['Items'] as List<dynamic>?;
      if (items == null || items.isEmpty) {
        debugPrint('ℹ️ 상영 시간표가 없습니다. (cinemaId: $cinemaId, movieNo: $movieNo, playDate: $playDate)');
        return [];
      }

      // LotteCinemaSchedule 리스트로 변환
      final schedules = <LotteCinemaSchedule>[];
      for (final item in items) {
        try {
          final schedule = LotteCinemaSchedule.fromJson(
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
      debugPrint('❌ 요청 타임아웃 (롯데시네마 API)');
      return [];
    } on SocketException {
      debugPrint('❌ 네트워크 연결 오류 (롯데시네마 API)');
      return [];
    } on HttpException {
      debugPrint('❌ HTTP 오류 (롯데시네마 API)');
      return [];
    } on FormatException {
      debugPrint('❌ JSON 파싱 오류 (롯데시네마 API)');
      return [];
    } catch (e) {
      debugPrint('❌ 롯데시네마 API 오류: $e');
      return [];
    }
  }
}

/// 롯데시네마 API 예외 클래스
class LotteCinemaException implements Exception {
  final String message;
  final int? statusCode;

  LotteCinemaException(this.message, [this.statusCode]);

  @override
  String toString() => 'LotteCinemaException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}
