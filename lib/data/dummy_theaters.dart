import 'dart:math';
import '../models/theater.dart';
import '../api/kakao_local_client.dart';
import '../utils/env_loader.dart';
import '../services/theater_schedule_service.dart';


double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLon = (lon2 - lon1) * pi / 180;
  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}




String _dateYmd(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _naverSearchUrl(String q) =>
    'https://search.naver.com/search.naver?query=${Uri.encodeComponent(q)}';

/// ✅ 실제: 카카오 로컬 API로 주변 영화관 가져오기
Future<List<Theater>> fetchNearbyTheatersReal({
  required double lat,
  required double lng,
  required DateTime date,
  required String movieTitle,
  int radiusM = 5000,
}) async {
  final key = EnvLoader.kakaoRestApiKey;

  // 키가 없으면 더미로 fallback
  if (key == null || key.isEmpty) {
    return fetchNearbyTheatersDummy(
      lat: lat,
      lng: lng,
      date: date,
      movieTitle: movieTitle,
    );
  }

  final client = KakaoLocalClient(restApiKey: key);

  // "영화관" 키워드로 주변 검색
  final docs = await client.searchKeyword(
    query: '영화관',
    lat: lat,
    lng: lng,
    radius: radiusM,
    size: 15,
  );

  // 만료된 캐시 정리 (메모리 관리)
  TheaterScheduleService.cleanExpiredCache();

  final theaters = await Future.wait(docs.map((d) async {
    final name = (d['place_name'] ?? '').toString();
    final address = (d['road_address_name'] ?? d['address_name'] ?? '').toString();
    final x = double.tryParse((d['x'] ?? '').toString()) ?? 0; // lng
    final y = double.tryParse((d['y'] ?? '').toString()) ?? 0; // lat
    final id = (d['id'] ?? name).toString();

    // 카카오 응답 distance는 "미터 문자열"

    final distMeters = double.tryParse((d['distance'] ?? '0').toString()) ?? 0;
    final distKmFromApi = distMeters / 1000.0;

    final distKm = (distKmFromApi > 0)
        ? distKmFromApi
        : _haversineKm(lat, lng, y, x); // ✅ 0이면 직접 계산

    // 예매/시간표는 네이버 검색으로 안전하게 연결
    final bookingQuery = '$name $movieTitle 상영시간표 ${_dateYmd(date)}';

    // 롯데시네마 영화관인 경우 실제 상영 시간표 가져오기
    List<Showtime> showtimes = [];
    if (name.contains('롯데시네마') || name.contains('롯데')) {
      try {
        showtimes = await TheaterScheduleService.getLotteCinemaSchedule(
          theaterName: name,
          movieTitle: movieTitle,
          date: date,
        );
      } catch (e) {
        // 에러 발생 시 빈 리스트 유지 (조용히 처리)
        // 네트워크 오류나 API 오류 시에도 앱이 멈추지 않도록 함
        showtimes = [];
      }
    }

    return Theater(
      id: id,
      name: name,
      address: address,
      lat: y,
      lng: x,
      distanceKm: distKm,
      showtimes: showtimes, // ✅ 롯데시네마면 실제 시간표, 아니면 빈 리스트
      bookingUrl: _naverSearchUrl(bookingQuery),
    );
  }));

  theaters.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  return theaters;
}

/// ✅ 더미 fallback (개발용)
Future<List<Theater>> fetchNearbyTheatersDummy({
  required double lat,
  required double lng,
  required DateTime date,
  required String movieTitle,
}) async {
  await Future.delayed(const Duration(milliseconds: 500));

  final r = Random(42);
  double dist() => (r.nextDouble() * 4.5) + 0.3;

  return [
    Theater(
      id: 'dummy_megabox',
      name: '메가박스 (더미)',
      address: '대전 어딘가...',
      lat: lat + 0.01,
      lng: lng + 0.01,
      distanceKm: dist(),
      showtimes: const [
        Showtime(start: '17:30', end: '19:34', screen: '5관'),
        Showtime(start: '18:40', end: '20:44', screen: '3관'),
        Showtime(start: '19:50', end: '21:54', screen: '5관'),
      ],
      bookingUrl: _naverSearchUrl('메가박스 $movieTitle 상영시간표 ${_dateYmd(date)}'),
    ),
    Theater(
      id: 'dummy_cgv',
      name: 'CGV (더미)',
      address: '대전 어딘가...',
      lat: lat + 0.015,
      lng: lng - 0.006,
      distanceKm: dist(),
      showtimes: const [],
      bookingUrl: _naverSearchUrl('CGV $movieTitle 상영시간표 ${_dateYmd(date)}'),
    ),
    Theater(
      id: 'dummy_lotte',
      name: '롯데시네마 (더미)',
      address: '대전 어딘가...',
      lat: lat - 0.012,
      lng: lng + 0.004,
      distanceKm: dist(),
      showtimes: const [],
      bookingUrl: _naverSearchUrl('롯데시네마 $movieTitle 상영시간표 ${_dateYmd(date)}'),
    ),
  ]..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
}
