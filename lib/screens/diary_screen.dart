import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/colors.dart';
import '../models/record.dart';
import '../state/app_state.dart';
import '../widgets/movie_diary_popup.dart';

enum RecordSort { latest, rating, mostWatched }

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _MovieDiaryItem {
  final String movieId;
  final String title;
  final String posterUrl;

  final int watchCount;
  final double avgRating;
  final DateTime latestWatchDate;

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
    if (dt.year != y || dt.month != m || dt.day != d) return null;

    return dt;
  }

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

  bool _matchesQuery(Record r) {
    if (_query.trim().isEmpty) return true;
    final q = _query.trim().toLowerCase();
    final titleMatch = r.movie.title.toLowerCase().contains(q);
    final oneLinerMatch = r.oneLiner?.toLowerCase().contains(q) ?? false;
    return titleMatch || oneLinerMatch;
  }

  bool _matchesRange(Record r) {
    if (_fromDate == null || _toDate == null) return true;

    final d = DateTime(r.watchDate.year, r.watchDate.month, r.watchDate.day);
    final from = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
    final to = DateTime(_toDate!.year, _toDate!.month, _toDate!.day);

    return !d.isBefore(from) && !d.isAfter(to);
  }

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
    return r.id != earliestId;
  }

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
          return b.watchDate.compareTo(a.watchDate);
      }
    });

    return filtered;
  }

  List<_MovieDiaryItem> _groupForMostWatched(List<Record> filteredRecords) {
    final Map<String, List<Record>> byMovie = {};
    for (final r in filteredRecords) {
      (byMovie[r.movie.id] ??= []).add(r);
    }

    final List<_MovieDiaryItem> items = [];
    for (final entry in byMovie.entries) {
      final list = entry.value;
      final any = list.first;

      final watchCount = list.length;

      double sum = 0.0;
      for (final r in list) sum += r.rating;
      final avgRating = watchCount == 0 ? 0.0 : (sum / watchCount);

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

  String _sortLabel() {
    switch (_sort) {
      case RecordSort.latest:
        return "최신 관람순";
      case RecordSort.rating:
        return "평점 순";
      case RecordSort.mostWatched:
        return "많이 본 순";
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ SavedScreen과 동일한 기준
    const double contentShiftRight = 20;
    const double innerWidthRatio = 0.90;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/notebook_page.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Consumer<AppState>(
              builder: (context, appState, _) {
                final records = appState.records;
                final earliestIdMap = _earliestRecordIdByMovie(records);

                final filtered = records.where((r) => _matchesQuery(r) && _matchesRange(r)).toList();
                final isMostWatchedView = _sort == RecordSort.mostWatched;

                final shownRecords = isMostWatchedView
                    ? const <Record>[]
                    : _applyFilterAndSortRecords(records);

                final shownMovies = isMostWatchedView
                    ? _groupForMostWatched(filtered)
                    : const <_MovieDiaryItem>[];

                final isEmpty = isMostWatchedView ? shownMovies.isEmpty : shownRecords.isEmpty;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 92,
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Transform.rotate(
                                angle: -0.06,
                                child: Image.asset(
                                  'assets/character.png',
                                  width: 86,
                                ),
                              ),
                            ),
                            const Align(
                              alignment: Alignment.center,
                              child: Padding(
                                padding: EdgeInsets.only(bottom: 18),
                                child: Text(
                                  '내 일기장',
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF7E74C9),
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: EdgeInsets.only(top: 18),
                                child: _SortDropdown(
                                  label: _sortLabel(),
                                  onSelected: (value) {
                                    if (value == 'range') {
                                      _openRangeInputDialog();
                                    } else if (value is RecordSort) {
                                      setState(() {
                                        _sort = value;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 0),

                      Expanded(
                        child: Center(
                          child: Container(
                            width: MediaQuery.of(context).size.width * innerWidthRatio,
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: contentShiftRight),
                                  child: _SearchBar(
                                    controller: _searchController,
                                    hintText: "일기 검색 (제목/한줄평)",
                                    onChanged: (v) => setState(() => _query = v),
                                  ),
                                ),
                                const SizedBox(height: 10),
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
                                      : Padding(
                                          padding: const EdgeInsets.only(left: contentShiftRight),
                                          child: GridView.builder(
                                            itemCount: isMostWatchedView ? shownMovies.length : shownRecords.length,
                                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 3,
                                              crossAxisSpacing: 10,
                                              mainAxisSpacing: 12,
                                              childAspectRatio: 0.74,
                                            ),
                                            itemBuilder: (context, index) {
                                              if (isMostWatchedView) {
                                                final it = shownMovies[index];
                                                return _DiaryGridCardMostWatched(
                                                  title: it.title,
                                                  posterUrl: it.posterUrl,
                                                  rating: it.avgRating,
                                                  watchCount: it.watchCount,
                                                  onTap: () {
                                                    final candidates =
                                                        filtered.where((r) => r.movie.id == it.movieId).toList();
                                                    if (candidates.isEmpty) return;
                                                    candidates.sort((a, b) => b.watchDate.compareTo(a.watchDate));
                                                    openDiaryPopup(context, candidates.first);
                                                  },
                                                );
                                              }

                                              final r = shownRecords[index];
                                              final isRewatch = _isAutoRewatch(r, earliestIdMap);

                                              return _DiaryGridCardRecord(
                                                title: r.movie.title,
                                                posterUrl: r.movie.posterUrl,
                                                rating: r.rating,
                                                oneLiner: r.oneLiner ?? '',
                                                dateText: _formatDate(r.watchDate),
                                                isRewatch: isRewatch,
                                                onTap: () => openDiaryPopup(context, r),
                                              );
                                            },
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final String label;
  final ValueChanged<dynamic>? onSelected;

  const _SortDropdown({
    required this.label,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<dynamic>(
      onSelected: onSelected,
      itemBuilder: (context) => const [
        PopupMenuItem(value: RecordSort.latest, child: Text("최신 관람순")),
        PopupMenuItem(value: RecordSort.rating, child: Text("평점 순")),
        PopupMenuItem(value: RecordSort.mostWatched, child: Text("많이 본 순")),
        PopupMenuItem(value: 'range', child: Text("기간 설정")),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: Color(0xFF3A2E2E),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.expand_more, size: 18, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7EE).withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: Colors.black54),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                isDense: true,
                hintText: hintText,
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
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



class _DiaryGridCardRecord extends StatelessWidget {
  final String title;
  final String posterUrl;
  final double rating;
  final String oneLiner;
  final String dateText;
  final bool isRewatch;
  final VoidCallback onTap;

  const _DiaryGridCardRecord({
    required this.title,
    required this.posterUrl,
    required this.rating,
    required this.oneLiner,
    required this.dateText,
    required this.isRewatch,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const radius = 14.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: const Color(0xFFEDEDED)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            children: [
              Padding(
                // ✅ 예전처럼 촘촘하게
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _StarsDisplay(value: rating),
                    const SizedBox(height: 2),

                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // ✅ 포스터를 "작게" (잘려도 OK)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        posterUrl,
                        width: double.infinity,
                        height: 75, // ⭐ 핵심: 더 작게 → 카드가 납작해짐
                        fit: BoxFit.cover, // ✅ 잘려도 OK (예전 느낌)
                        errorBuilder: (_, __, ___) => Container(
                          height: 66,
                          color: Colors.black12,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // ✅ 한줄평/날짜 영역이 더 빨리 보이게
                    Text(
                      oneLiner.isEmpty ? '(한줄평 없음)' : oneLiner,
                      maxLines: 1, // ⭐ 예전 느낌: 1줄
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dateText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              // ✅ 재관람 리본 유지
              if (isRewatch)
                Positioned(
                  left: -26,
                  top: 10,
                  child: Transform.rotate(
                    angle: -0.785398,
                    child: Container(
                      width: 85,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.red,
                      alignment: Alignment.center,
                      child: const Text(
                        '재관람',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

















class _DiaryGridCardMostWatched extends StatelessWidget {
  final String title;
  final String posterUrl;
  final double rating;
  final int watchCount;
  final VoidCallback onTap;

  const _DiaryGridCardMostWatched({
    required this.title,
    required this.posterUrl,
    required this.rating,
    required this.watchCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const radius = 14.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: const Color(0xFFEDEDED)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
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
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      posterUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
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
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
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
