import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../data/record_store.dart';
import '../models/record.dart';

enum RecordSort { latest, rating, mostWatched }

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

/// ✅ "많이 본 순"에서만 쓰는 영화별 묶음 아이템
class _MovieDiaryItem {
  final String movieId;
  final String title;
  final String posterUrl;

  final int watchCount; // N회 관람
  final double avgRating; // 평균 별점
  final DateTime latestWatchDate; // tie-breaker

  _MovieDiaryItem({
    required this.movieId,
    required this.title,
    required this.posterUrl,
    required this.watchCount,
    required this.avgRating,
    required this.latestWatchDate,
  });
}

class _DiaryScreenState extends State<DiaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = "";

  RecordSort _sort = RecordSort.latest;

  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  // ✅ YYYYMMDD 숫자 입력을 DateTime으로 파싱
  DateTime? _parseYYYYMMDD(String raw) {
    final s = raw.trim();
    if (s.length != 8) return null;

    final y = int.tryParse(s.substring(0, 4));
    final m = int.tryParse(s.substring(4, 6));
    final d = int.tryParse(s.substring(6, 8));
    if (y == null || m == null || d == null) return null;
    if (m < 1 || m > 12) return null;
    if (d < 1 || d > 31) return null;

    final dt = DateTime(y, m, d);
    // DateTime 자동 보정 방지(예: 20250230)
    if (dt.year != y || dt.month != m || dt.day != d) return null;

    return dt;
  }

  // ✅ 달력 대신 숫자로 기간 입력 다이얼로그
  Future<void> _openRangeInputDialog() async {
    final fromCtrl = TextEditingController(
      text: _fromDate == null
          ? ''
          : '${_fromDate!.year.toString().padLeft(4, '0')}${_fromDate!.month.toString().padLeft(2, '0')}${_fromDate!.day.toString().padLeft(2, '0')}',
    );
    final toCtrl = TextEditingController(
      text: _toDate == null
          ? ''
          : '${_toDate!.year.toString().padLeft(4, '0')}${_toDate!.month.toString().padLeft(2, '0')}${_toDate!.day.toString().padLeft(2, '0')}',
    );

    String? errorText;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('기간 설정', style: TextStyle(fontWeight: FontWeight.w900)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RangeInputField(
                    controller: fromCtrl,
                    label: '시작 날짜 (YYYYMMDD)',
                    hintText: '예) 20260110',
                  ),
                  const SizedBox(height: 10),
                  _RangeInputField(
                    controller: toCtrl,
                    label: '끝 날짜 (YYYYMMDD)',
                    hintText: '예) 20260131',
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        errorText!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _fromDate = null;
                      _toDate = null;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('해제'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final from = _parseYYYYMMDD(fromCtrl.text);
                    final to = _parseYYYYMMDD(toCtrl.text);

                    if (from == null || to == null) {
                      setLocal(() => errorText = '날짜는 YYYYMMDD 8자리 숫자로 입력해줘!');
                      return;
                    }
                    if (to.isBefore(from)) {
                      setLocal(() => errorText = '끝 날짜는 시작 날짜보다 같거나 이후여야 해!');
                      return;
                    }

                    setState(() {
                      _fromDate = from;
                      _toDate = to;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('적용'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ✅ 검색(제목/한줄평)
  bool _matchesQuery(Record r) {
    if (_query.trim().isEmpty) return true;
    final q = _query.trim();
    final titleMatch = r.movie.title.toLowerCase().contains(q.toLowerCase());
    final oneLinerMatch = r.oneLiner?.toLowerCase().contains(q.toLowerCase()) ?? false;
    return titleMatch || oneLinerMatch;
  }

  // ✅ 기간 필터(Record 단위)
  bool _matchesRange(Record r) {
    if (_fromDate == null || _toDate == null) return true;

    final d = DateTime(r.watchDate.year, r.watchDate.month, r.watchDate.day);
    final from = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
    final to = DateTime(_toDate!.year, _toDate!.month, _toDate!.day);

    return !d.isBefore(from) && !d.isAfter(to);
  }

  /// ✅ movieId -> 최초 관람 record.id
  Map<String, int> _earliestRecordIdByMovie(List<Record> records) {
    final Map<String, Record> earliest = {};

    for (final r in records) {
      final movieId = r.movie.id;
      final cur = earliest[movieId];

      if (cur == null) {
        earliest[movieId] = r;
        continue;
      }

      if (r.watchDate.isBefore(cur.watchDate)) {
        earliest[movieId] = r;
        continue;
      }

      if (r.watchDate.isAtSameMomentAs(cur.watchDate) && r.id < cur.id) {
        earliest[movieId] = r;
      }
    }

    return earliest.map((k, v) => MapEntry(k, v.id));
  }

  bool _isAutoRewatch(Record r, Map<String, int> earliestIdMap) {
    final earliestId = earliestIdMap[r.movie.id];
    if (earliestId == null) return false;
    return r.id != earliestId; // 최초 기록이 아니면 재관람
  }

  /// ✅ 최신/평점 순(Record 단위로 그대로)
  List<Record> _applyFilterAndSortRecords(List<Record> records) {
    final filtered = records.where((r) => _matchesQuery(r) && _matchesRange(r)).toList();

    filtered.sort((a, b) {
      switch (_sort) {
        case RecordSort.latest:
          return b.watchDate.compareTo(a.watchDate);

        case RecordSort.rating:
          final byRating = b.rating.compareTo(a.rating);
          if (byRating != 0) return byRating;
          return b.watchDate.compareTo(a.watchDate);

        case RecordSort.mostWatched:
          // 여기서는 안 씀(많이 본 순은 그룹 뷰)
          return b.watchDate.compareTo(a.watchDate);
      }
    });

    return filtered;
  }

  /// ✅ 많이 본 순: 필터 적용된 records를 영화별로 묶기
  List<_MovieDiaryItem> _groupForMostWatched(List<Record> filteredRecords) {
    final Map<String, List<Record>> byMovie = {};
    for (final r in filteredRecords) {
      (byMovie[r.movie.id] ??= []).add(r);
    }

    final List<_MovieDiaryItem> items = [];
    for (final entry in byMovie.entries) {
      final list = entry.value;
      final any = list.first;

      final int watchCount = list.length;

      double sum = 0.0;
      for (final r in list) {
        sum += r.rating;
      }
      final double avgRating = watchCount == 0 ? 0.0 : (sum / watchCount);

      DateTime latest = list.first.watchDate;
      for (final r in list) {
        if (r.watchDate.isAfter(latest)) latest = r.watchDate;
      }

      items.add(
        _MovieDiaryItem(
          movieId: any.movie.id,
          title: any.movie.title,
          posterUrl: any.movie.posterUrl,
          watchCount: watchCount,
          avgRating: avgRating,
          latestWatchDate: latest,
        ),
      );
    }

    items.sort((a, b) {
      final byCount = b.watchCount.compareTo(a.watchCount);
      if (byCount != 0) return byCount;

      final byRating = b.avgRating.compareTo(a.avgRating);
      if (byRating != 0) return byRating;

      return b.latestWatchDate.compareTo(a.latestWatchDate);
    });

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          '무비어리',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ValueListenableBuilder<List<Record>>(
          valueListenable: RecordStore.records,
          builder: (context, records, _) {
            final earliestIdMap = _earliestRecordIdByMovie(records);

            final filtered = records.where((r) => _matchesQuery(r) && _matchesRange(r)).toList();
            final bool isMostWatchedView = _sort == RecordSort.mostWatched;

            final List<Record> shownRecords =
                isMostWatchedView ? const [] : _applyFilterAndSortRecords(records);

            final List<_MovieDiaryItem> shownMovies =
                isMostWatchedView ? _groupForMostWatched(filtered) : const [];

            final bool isEmpty = isMostWatchedView ? shownMovies.isEmpty : shownRecords.isEmpty;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ 탐색 탭 스타일: 큰 타이틀 + 작은 부제
                      Text(
                        "기록",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "일기장",
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 검색창
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _query = v),
                          decoration: const InputDecoration(
                            isDense: true,
                            icon: Icon(Icons.search, size: 20),
                            hintText: "내 일기 검색 (제목/한줄평)",
                            border: InputBorder.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 정렬 칩 + 기간설정
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _SortChip(
                            label: "최신 관람일",
                            selected: _sort == RecordSort.latest,
                            onTap: () => setState(() => _sort = RecordSort.latest),
                          ),
                          _SortChip(
                            label: "평점 순",
                            selected: _sort == RecordSort.rating,
                            onTap: () => setState(() => _sort = RecordSort.rating),
                          ),
                          _SortChip(
                            label: "많이 본 순",
                            selected: _sort == RecordSort.mostWatched,
                            onTap: () => setState(() => _sort = RecordSort.mostWatched),
                          ),
                          _SortChip(
                            label: _fromDate == null
                                ? "기간 설정"
                                : "${_formatDate(_fromDate!)} ~ ${_formatDate(_toDate!)}",
                            selected: _fromDate != null,
                            onTap: _openRangeInputDialog,
                            leadingIcon: Icons.filter_alt_outlined,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: isEmpty
                      ? Center(
                          child: Text(
                            records.isEmpty
                                ? "아직 기록이 없어요.\n탐색에서 기록 추가를 눌러 추가해보세요!"
                                : "검색/필터 결과가 없어요.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
                          itemCount: isMostWatchedView ? shownMovies.length : shownRecords.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.74,
                          ),
                          itemBuilder: (context, index) {
                            // ✅ 많이 본 순: 영화 묶음 카드(평균별점 + N회 관람)
                            if (isMostWatchedView) {
                              final it = shownMovies[index];
                              return _DiaryGridCardMostWatched(
                                title: it.title,
                                posterUrl: it.posterUrl,
                                rating: it.avgRating,
                                watchCount: it.watchCount,
                              );
                            }

                            // ✅ 최신/평점 순: record 카드(한줄평 + 날짜 + 재관람 리본)
                            final r = shownRecords[index];
                            final isRewatch = _isAutoRewatch(r, earliestIdMap);

                            return _DiaryGridCardRecord(
                              title: r.movie.title,
                              posterUrl: r.movie.posterUrl,
                              rating: r.rating,
                              oneLiner: r.oneLiner ?? '',
                              dateText: _formatDate(r.watchDate),
                              isRewatch: isRewatch,
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? leadingIcon;

  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFFFFE2F0) : Colors.white;
    final border = selected ? const Color(0xFFFF8FBF) : const Color(0xFFE6E6E6);
    const textColor = Color(0xFF444444);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 14, color: textColor),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ✅ 최신/평점 순에서 사용하는 카드(한줄평+날짜+재관람 리본)
class _DiaryGridCardRecord extends StatelessWidget {
  final String title;
  final String posterUrl;
  final double rating;
  final String oneLiner;
  final String dateText;
  final bool isRewatch;

  const _DiaryGridCardRecord({
    required this.title,
    required this.posterUrl,
    required this.rating,
    required this.oneLiner,
    required this.dateText,
    required this.isRewatch,
  });

  @override
  Widget build(BuildContext context) {
    const radius = 8.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFEDEDED)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _StarsDisplay(value: rating),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        posterUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: Colors.black12,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    oneLiner.isEmpty ? '(한줄평 없음)' : oneLiner,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // ✅ 재관람 빨간 리본
            if (isRewatch)
              Positioned(
                left: -26,
                top: 10,
                child: Transform.rotate(
                  angle: -0.785398,
                  child: Container(
                    width: 90,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    color: Colors.red,
                    alignment: Alignment.center,
                    child: const Text(
                      '재관람',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// ✅ 많이 본 순에서 사용하는 카드(평균별점 + N회 관람)
class _DiaryGridCardMostWatched extends StatelessWidget {
  final String title;
  final String posterUrl;
  final double rating;
  final int watchCount;

  const _DiaryGridCardMostWatched({
    required this.title,
    required this.posterUrl,
    required this.rating,
    required this.watchCount,
  });

  @override
  Widget build(BuildContext context) {
    const radius = 8.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFEDEDED)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _StarsDisplay(value: rating),
              const SizedBox(height: 4),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    posterUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: Colors.black12,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "$watchCount회 관람", 
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StarsDisplay extends StatelessWidget {
  final double value;
  const _StarsDisplay({required this.value});

  IconData _iconFor(int idx) {
    final full = idx.toDouble();
    final half = idx - 0.5;
    if (value >= full) return Icons.star;
    if (value >= half) return Icons.star_half;
    return Icons.star_border;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final idx = i + 1;
        final icon = _iconFor(idx);
        final filled = icon != Icons.star_border;

        return Icon(
          icon,
          size: 14,
          color: filled ? const Color(0xFFFFC107) : Colors.black26,
        );
      }),
    );
  }
}

class _RangeInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;

  const _RangeInputField({
    required this.controller,
    required this.label,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hintText,
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }
}
