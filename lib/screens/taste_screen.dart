import 'dart:math';
import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../data/record_store.dart';
import '../data/saved_store.dart';
import '../models/record.dart';
import '../models/movie.dart';
import '../widgets/add_record_sheet.dart';

enum _RangeMode { all, oneYear, threeYear }
enum _TrendMode { monthly, yearly }

class TasteScreen extends StatefulWidget {
  const TasteScreen({super.key});

  @override
  State<TasteScreen> createState() => _TasteScreenState();
}

class _TasteScreenState extends State<TasteScreen> {
  _RangeMode _range = _RangeMode.all;
  _TrendMode _trend = _TrendMode.yearly;

  DateTime _rangeFrom(DateTime now) {
    switch (_range) {
      case _RangeMode.all:
        return DateTime(2000);
      case _RangeMode.oneYear:
        return DateTime(now.year - 1, now.month, now.day);
      case _RangeMode.threeYear:
        return DateTime(now.year - 3, now.month, now.day);
    }
  }

  String _primaryGenre(Movie m) => (m.genres.isEmpty) ? '기타' : m.genres.first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3F6),
      appBar: AppBar(
        title: const Text('무비어리', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ValueListenableBuilder<List<Record>>(
        valueListenable: RecordStore.records,
        builder: (context, records, _) {
          final now = DateTime.now();
          final from = _rangeFrom(now);
          final filtered = records.where((r) => !r.watchDate.isBefore(from)).toList();

          final totalCount = filtered.length;
          final avgRating = totalCount == 0
              ? 0.0
              : filtered.map((r) => r.rating).reduce((a, b) => a + b) / totalCount;

          // 장르 count + 장르별 평균
          final Map<String, int> genreCount = {};
          final Map<String, double> genreSum = {};
          final Map<String, int> genreN = {};
          for (final r in filtered) {
            final g = _primaryGenre(r.movie);
            genreCount[g] = (genreCount[g] ?? 0) + 1;
            genreSum[g] = (genreSum[g] ?? 0) + r.rating;
            genreN[g] = (genreN[g] ?? 0) + 1;
          }

          String favoriteGenre = '—';
          if (genreCount.isNotEmpty) {
            final entries = genreCount.entries.toList()
              ..sort((a, b) {
                final byCount = b.value.compareTo(a.value);
                if (byCount != 0) return byCount;
                final ar = (genreSum[a.key]! / genreN[a.key]!);
                final br = (genreSum[b.key]! / genreN[b.key]!);
                return br.compareTo(ar);
              });
            favoriteGenre = entries.first.key;
          }

          // 도넛 데이터: 상위 5개 + 기타
          final pieEntries = genreCount.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          List<MapEntry<String, int>> pie = pieEntries.take(5).toList();
          final rest = pieEntries.skip(5).fold<int>(0, (s, e) => s + e.value);
          if (rest > 0) pie = [...pie, MapEntry('기타', rest)];

          // 추이 데이터
          final trendPoints = _buildTrend(filtered, _trend);

          // 추천
          final watchedIds = records.map((r) => r.movie.id).toSet();
          final recs = _buildRecommendations(
            favoriteGenre: favoriteGenre,
            watchedIds: watchedIds,
            genreAvgRating: {for (final k in genreN.keys) k: genreSum[k]! / genreN[k]!},
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              // 상단 "내 취향 분석" + 리프레시
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '내 취향 분석',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFF4FA0),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh, color: Color(0xFF444444)),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              Text(
                '취향',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '기록이 만드는 나만의 추천',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: textSecondary,
                ),
              ),

              const SizedBox(height: 14),

              // 요약 카드 3개
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: '총 기록 수',
                      value: '$totalCount',
                      valueColor: const Color(0xFFFF4FA0),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      title: '평균 별점',
                      value: avgRating.toStringAsFixed(1),
                      valueColor: const Color(0xFFFFC107),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      title: '선호 장르',
                      value: favoriteGenre,
                      valueColor: const Color(0xFF2DBB7F),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 장르 분포 (도넛 + 범례)
              _Panel(
                title: '장르 분포',
                trailing: Row(
                  children: [
                    _ChipPill(
                      label: '전체',
                      selected: _range == _RangeMode.all,
                      onTap: () => setState(() => _range = _RangeMode.all),
                    ),
                    const SizedBox(width: 8),
                    _ChipPill(
                      label: '1년',
                      selected: _range == _RangeMode.oneYear,
                      onTap: () => setState(() => _range = _RangeMode.oneYear),
                    ),
                    const SizedBox(width: 8),
                    _ChipPill(
                      label: '3년',
                      selected: _range == _RangeMode.threeYear,
                      onTap: () => setState(() => _range = _RangeMode.threeYear),
                    ),
                  ],
                ),
                child: totalCount == 0
                    ? const _EmptySmall(text: '아직 기록이 없어요.')
                    : _GenreDonutLegendChart(data: pie),
              ),

              const SizedBox(height: 14),

              // 관람 추이 (포인트 1개면 요약 카드 / 2개 이상이면 그래프)
              _Panel(
                title: '관람 추이',
                trailing: Row(
                  children: [
                    _ChipPill(
                      label: '월별',
                      selected: _trend == _TrendMode.monthly,
                      onTap: () => setState(() => _trend = _TrendMode.monthly),
                    ),
                    const SizedBox(width: 8),
                    _ChipPill(
                      label: '연도별',
                      selected: _trend == _TrendMode.yearly,
                      onTap: () => setState(() => _trend = _TrendMode.yearly),
                    ),
                  ],
                ),
                child: totalCount == 0
                    ? const _EmptySmall(text: '기록이 쌓이면 추이가 보여요.')
                    : (trendPoints.length <= 1
                        ? _SinglePointTrendSummary(points: trendPoints)
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12), // ✅ 핵심: 좌우 여백
                            child: Center(
                              child: _LineTrendChart(points: trendPoints),
                            ),
                          )),
              ),

              const SizedBox(height: 16),

              Text(
                '추천 영화',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 10),

              if (recs.isEmpty)
                const _EmptySmall(text: '추천할 영화가 아직 없어요.')
              else
                ...recs.map((m) {
                  final g = _primaryGenre(m);
                  final reason = (favoriteGenre != '—' && favoriteGenre == g)
                      ? '$g에서 높은 평점을 자주 줬어요'
                      : '$g 취향도 좋아하실 것 같아요';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RecommendCard(
                      movie: m,
                      reason: reason,
                      onAdd: () => openAddRecordSheet(context, m),
                    ),
                  );
                }),

              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black12),
                ),
                child: Text(
                  '💡 내가 높은 평점을 준 장르와 키워드를 기반으로 추천합니다',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<_TrendPoint> _buildTrend(List<Record> records, _TrendMode mode) {
    final Map<String, int> cnt = {};
    String keyOf(DateTime d) {
      if (mode == _TrendMode.yearly) return '${d.year}';
      final mm = d.month.toString().padLeft(2, '0');
      return '${d.year}-$mm';
    }

    for (final r in records) {
      final k = keyOf(r.watchDate);
      cnt[k] = (cnt[k] ?? 0) + 1;
    }

    final keys = cnt.keys.toList()..sort();
    return keys.map((k) => _TrendPoint(label: k, value: cnt[k]!.toDouble())).toList();
  }

  List<Movie> _buildRecommendations({
    required String favoriteGenre,
    required Set<String> watchedIds,
    required Map<String, double> genreAvgRating,
  }) {
    final candidates = dummyMovies.where((m) => !watchedIds.contains(m.id)).toList();

    if (favoriteGenre != '—') {
      final fav = candidates
          .where((m) => (m.genres.isNotEmpty && m.genres.first == favoriteGenre))
          .toList()
        ..sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
      if (fav.isNotEmpty) return fav.take(2).toList();
    }

    if (genreAvgRating.isNotEmpty) {
      final best = genreAvgRating.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final g = best.first.key;

      final byG = candidates.where((m) => (m.genres.isNotEmpty && m.genres.first == g)).toList()
        ..sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
      if (byG.isNotEmpty) return byG.take(2).toList();
    }

    candidates.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
    return candidates.take(2).toList();
  }
}

// ---------------- UI Components ----------------

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color valueColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget trailing;
  final Widget child;

  const _Panel({
    required this.title,
    required this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18), // ✅ 카드 밖으로 나가는 느낌 방지
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                    ),
                  ),
                ),
                trailing,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ChipPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChipPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFFFF7CB8) : Colors.white;
    final border = selected ? const Color(0xFFFF7CB8) : const Color(0xFFE6E6E6);
    final fg = selected ? Colors.white : const Color(0xFF666666);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: fg,
          ),
        ),
      ),
    );
  }
}

class _EmptySmall extends StatelessWidget {
  final String text;
  const _EmptySmall({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          color: textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ---------------- Donut + Legend ----------------

class _GenreDonutLegendChart extends StatelessWidget {
  final List<MapEntry<String, int>> data;
  const _GenreDonutLegendChart({required this.data});

  static const _palette = [
    Color(0xFF8E7BFF),
    Color(0xFFFF5C9A),
    Color(0xFF5CA6FF),
    Color(0xFFFFC83D),
    Color(0xFF2ED2A0),
    Color(0xFFBDBDBD),
  ];

  @override
  Widget build(BuildContext context) {
    final total = data.fold<int>(0, (s, e) => s + e.value);
    final colors = List<Color>.generate(data.length, (i) => _palette[i % _palette.length]);

    return SizedBox(
      height: 200,
      child: Row(
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(160, 160),
                  painter: _DonutPainter(
                    values: data.map((e) => e.value.toDouble()).toList(),
                    colors: colors,
                  ),
                ),
                Text(
                  '총 $total회',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(data.length, (i) {
                final e = data[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colors[i],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${e.value}회',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: colors[i],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  _DonutPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (s, v) => s + v);
    if (total <= 0) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    double start = -pi / 2;

    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 2 * pi;
      paint.color = colors[i];
      canvas.drawArc(rect, start, sweep, true, paint);
      start += sweep;
    }

    final center = Offset(size.width / 2, size.height / 2);
    final hole = Paint()..color = Colors.white;
    canvas.drawCircle(center, size.width * 0.24, hole);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.colors != colors;
}

// ---------------- Trend Points ----------------

class _TrendPoint {
  final String label;
  final double value;
  _TrendPoint({required this.label, required this.value});
}

class _SinglePointTrendSummary extends StatelessWidget {
  final List<_TrendPoint> points;
  const _SinglePointTrendSummary({required this.points});

  @override
  Widget build(BuildContext context) {
    final p = points.isEmpty ? _TrendPoint(label: '-', value: 0) : points.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          const Icon(Icons.show_chart, color: Color(0xFFFF5C9A)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${p.label} 기준 관람 ${p.value.toStringAsFixed(0)}회',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- Line Trend ----------------

class _LineTrendChart extends StatelessWidget {
  final List<_TrendPoint> points;
  const _LineTrendChart({required this.points});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, // ✅ 폭을 확실히
      height: 170,
      child: CustomPaint(
        painter: _LinePainter(points),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<_TrendPoint> points;
  _LinePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // 바깥 padding
    const padL = 46.0;
    const padT = 14.0;
    const padR = 18.0;
    const padB = 30.0;

    // 내부 여백
    const innerX = 12.0;
    const innerY = 8.0;

    final chart = Rect.fromLTWH(
      padL,
      padT,
      size.width - padL - padR,
      size.height - padT - padB,
    );

    final plot = Rect.fromLTWH(
      chart.left + innerX,
      chart.top + innerY,
      chart.width - innerX * 2,
      chart.height - innerY * 2,
    );

    final maxV = max<double>(1.0, points.map((p) => p.value).reduce(max));
    const minV = 0.0;

    final gridPaint = Paint()
      ..color = Colors.black.withOpacity(0.12)
      ..strokeWidth = 1;

    // y grid
    for (int i = 0; i <= 2; i++) {
      final y = plot.top + plot.height * i / 2;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
    }

    // x axis
    canvas.drawLine(Offset(plot.left, plot.bottom), Offset(plot.right, plot.bottom), gridPaint);

    double xForIndex(int i) {
      if (points.length == 1) return plot.left + plot.width / 2;
      if (points.length == 2) {
        final cx = plot.left + plot.width / 2;
        final spread = min(70.0, plot.width * 0.25);
        return i == 0 ? (cx - spread) : (cx + spread);
      }
      return plot.left + plot.width * i / (points.length - 1);
    }

    double yForValue(double v) {
      final norm = (v - minV) / (maxV - minV);
      return plot.bottom - plot.height * norm;
    }

    Offset pt(int i) => Offset(xForIndex(i), yForValue(points[i].value));

    final linePaint = Paint()
      ..color = const Color(0xFFFF5C9A)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()..color = const Color(0xFFFF5C9A);

    // 클립
    canvas.save();
    canvas.clipRect(plot);

    final path = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(pt(i).dx, pt(i).dy);
    }
    canvas.drawPath(path, linePaint);

    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(pt(i), 4.5, dotPaint);
    }

    canvas.restore();

    // 라벨
    final tp = TextPainter(textDirection: TextDirection.ltr);
    final labelStyle = TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w800,
      color: Colors.black.withOpacity(0.45),
    );

    for (int i = 0; i < points.length; i++) {
      tp.text = TextSpan(text: points[i].label, style: labelStyle);
      tp.layout();
      final x = (pt(i).dx - tp.width / 2).clamp(plot.left, plot.right - tp.width);
      tp.paint(canvas, Offset(x, plot.bottom + 6));
    }

    tp.text = TextSpan(text: '0', style: labelStyle);
    tp.layout();
    tp.paint(canvas, Offset(10, plot.bottom - 6));

    tp.text = TextSpan(text: maxV.toStringAsFixed(0), style: labelStyle);
    tp.layout();
    tp.paint(canvas, Offset(10, plot.top - 6));
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) => oldDelegate.points != points;
}

// ---------------- Recommend Card ----------------

class _RecommendCard extends StatelessWidget {
  final Movie movie;
  final String reason;
  final VoidCallback onAdd;

  const _RecommendCard({
    required this.movie,
    required this.reason,
    required this.onAdd,
  });

  String get year => movie.releaseDate.length >= 4 ? movie.releaseDate.substring(0, 4) : '';

  @override
  Widget build(BuildContext context) {
    final meta = '${movie.genres.take(2).join('·')} · $year';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              movie.posterUrl,
              width: 56,
              height: 78,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 56,
                height: 78,
                color: Colors.black12,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  meta,
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w700,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '사람들 평점 ',
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                      ),
                    ),
                    const Icon(Icons.star, size: 14, color: Color(0xFFFFC107)),
                    const SizedBox(width: 2),
                    Text(
                      movie.voteAverage.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w900,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  reason,
                  style: const TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFF5C9A),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF5C9A), Color(0xFF9A7BFF)],
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: onAdd,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: const Text(
                            '기록 추가',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ValueListenableBuilder<Set<String>>(
                      valueListenable: SavedStore.savedIds,
                      builder: (context, ids, _) {
                        final saved = ids.contains(movie.id);
                        return InkWell(
                          onTap: () => SavedStore.toggle(movie.id),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Colors.black12),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              saved ? Icons.favorite : Icons.favorite_border,
                              color: saved ? const Color(0xFFFF4FA0) : Colors.black38,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
