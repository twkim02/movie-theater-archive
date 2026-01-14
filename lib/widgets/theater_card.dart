import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/theater.dart';

class TheaterCard extends StatelessWidget {
  final Theater t;
  const TheaterCard({super.key, required this.t});

  /// ✅ URL을 외부 앱(브라우저/카카오맵)으로 여는 함수
  Future<void> _openExternal(BuildContext context, String url) async {
    final uri = Uri.parse(url);

    // 외부로 열기 시도
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    // 실패하면 스낵바로 알림
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('링크를 열 수 없어요: $url')),
      );
    }
  }

  /// ✅ 카카오맵 길찾기 링크(목적지)
  String get kakaoMapToUrl {
    final name = Uri.encodeComponent(t.name);
    return 'https://map.kakao.com/link/to/$name,${t.lat},${t.lng}';
  }

  /// 지원되는 영화관인지 확인합니다 (롯데시네마 또는 메가박스).
  bool _isSupportedTheater(String theaterName) {
    final normalized = theaterName.toLowerCase();
    return normalized.contains('롯데시네마') || 
           normalized.contains('롯데') ||
           normalized.contains('메가박스') || 
           normalized.contains('메가');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 영화관 이름 + 거리
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${t.distanceKm.toStringAsFixed(1)}km',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // 주소
            Text(
              t.address,
              style: TextStyle(color: Colors.black.withOpacity(0.55)),
            ),

            const SizedBox(height: 10),

            // 상영시간표 칩(있으면 보여주기)
            if (t.showtimes.isNotEmpty) ...[
              // 롯데시네마 또는 메가박스인 경우 실제 상영 시간표 표시
              if (_isSupportedTheater(t.name))
                Container(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, size: 14, color: Colors.blue.shade700),
                      const SizedBox(width: 4),
                      Text(
                        '실시간 상영 시간표',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: t.showtimes.map((s) {
                  return Chip(
                    label: Text('${s.start}~${s.end} · ${s.screen}'),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: _isSupportedTheater(t.name)
                        ? Colors.blue.shade50
                        : null,
                  );
                }).toList(),
              ),
            ]
            else
              Text(
                '시간표는 예매/시간표에서 확인할 수 있어요.',
                style: TextStyle(color: Colors.black.withOpacity(0.6)),
              ),

            const SizedBox(height: 12),

            // ✅ 버튼 2개
            Row(
              children: [
                // 1) 길찾기
                OutlinedButton.icon(
                  onPressed: () {
                    _openExternal(context, kakaoMapToUrl);
                  },
                  icon: const Icon(Icons.directions, size: 18),
                  label: const Text('길찾기'),
                ),

                const SizedBox(width: 10),

                // 2) 예매/시간표
                ElevatedButton.icon(
                  onPressed: () {
                    _openExternal(context, t.bookingUrl);
                  },
                  icon: const Icon(Icons.confirmation_number, size: 18),
                  label: const Text('예매/시간표'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
