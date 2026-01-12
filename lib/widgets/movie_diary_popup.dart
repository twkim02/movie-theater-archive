import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../data/record_store.dart';
import '../models/record.dart';
import '../widgets/add_record_sheet.dart';

/// ✅ 팝업 열기 함수 (Record를 받음)
void openDiaryPopup(BuildContext context, Record record) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "diary",
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (context, anim, __, ___) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.98, end: 1.0).animate(curved),
          child: MovieDiaryPopup(record: record),
        ),
      );
    },
  );
}

class MovieDiaryPopup extends StatelessWidget {
  final Record record;
  const MovieDiaryPopup({super.key, required this.record});

  String _fmtDate(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}";

  // ✅ 네트워크 URL이면 Image.network, 로컬 파일 경로면 Image.file
  Widget _smartImage(
    String pathOrUrl, {
    BoxFit fit = BoxFit.cover,
    Widget? error,
  }) {
    final isNetwork = pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://');

    if (isNetwork) {
      return Image.network(
        pathOrUrl,
        fit: fit,
        loadingBuilder: (c, child, progress) {
          if (progress == null) return child;
          return Container(
            color: Colors.black.withOpacity(0.04),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (_, __, ___) =>
            error ??
            Container(
              color: Colors.black.withOpacity(0.04),
              alignment: Alignment.center,
              child: const Icon(Icons.photo_outlined),
            ),
      );
    }

    return Image.file(
      File(pathOrUrl),
      fit: fit,
      errorBuilder: (_, __, ___) =>
          error ??
          Container(
            color: Colors.black.withOpacity(0.04),
            alignment: Alignment.center,
            child: const Icon(Icons.photo_outlined),
          ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return AlertDialog(
          title: const Text("정말 삭제할까요?", style: TextStyle(fontWeight: FontWeight.w900)),
          content: const Text("이 기록은 삭제하면 복구할 수 없어요."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("아니오"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("예"),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await RecordStore.delete(record.id);
      Navigator.of(context).pop(); // 팝업 닫기
    }
  }

  void _edit(BuildContext context) {
    Navigator.of(context).pop();
    Future.microtask(() {
      openAddRecordSheet(context, record.movie, initialRecord: record);
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ “일기장” 톤
    const paper = Color(0xFFFAFAFA);
    const ink = Color(0xFF1E1E1E);
    const pencil = Color(0xFF8E8E8E);
    const highlight = Color(0xFFFFF3CD);
    const tagBg = Color(0xFFF1EFFF);
    const starColor = Color(0xFFFFD54F);

    final maxH = MediaQuery.of(context).size.height * 0.82;

    // ✅ Typo 크레파스 폰트 패밀리
    const f = 'TypoCrayon';

    const titleStyle = TextStyle(
      fontFamily: f,
      fontSize: 26,
      fontWeight: FontWeight.w800,
      height: 1.05,
      color: ink,
    );

    const oneLineStyle = TextStyle(
      fontFamily: f,
      fontSize: 15.5,
      fontWeight: FontWeight.w700,
      height: 1.35,
      color: ink,
    );

    const sectionStyle = TextStyle(
      fontFamily: f,
      fontSize: 18,
      fontWeight: FontWeight.w800,
      height: 1.1,
      color: ink,
    );

    const dateSmallStyle = TextStyle(
      fontFamily: f,
      fontSize: 13,
      fontWeight: FontWeight.w800,
      height: 1.1,
      color: pencil,
    );

    const detailStyle = TextStyle(
      fontFamily: f,
      fontSize: 15.5,
      fontWeight: FontWeight.w600,
      height: 1.55,
      color: ink,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 배경 블러
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
              child: Container(color: Colors.black.withOpacity(0.25)),
            ),
          ),

          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 380, maxHeight: maxH),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: paper,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: pencil.withOpacity(0.75), width: 1.3),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 26,
                      offset: const Offset(0, 14),
                      color: Colors.black.withOpacity(0.18),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Column(
                    children: [
                      // ✅ 상단: (왼쪽) 수정/삭제 + (오른쪽) X
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                        child: Row(
                          children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              tooltip: "수정",
                              onPressed: () => _edit(context),
                              icon: const Icon(Icons.edit_outlined, color: ink),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              tooltip: "삭제",
                              onPressed: () => _confirmDelete(context),
                              icon: const Icon(Icons.delete_outline, color: ink),
                            ),
                            const Spacer(),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close, color: ink),
                            ),
                          ],
                        ),
                      ),

                      // 얇은 연필선
                      Container(height: 1, color: pencil.withOpacity(0.25)),

                      // 본문 스크롤
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 상단 정보 영역
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _Poster(
                                    url: record.movie.posterUrl,
                                    borderColor: pencil.withOpacity(0.75),
                                    smartImage: _smartImage,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(record.movie.title, style: titleStyle),
                                        const SizedBox(height: 8),
                                        _StarRow(
                                          rating: record.rating,
                                          color: starColor,
                                          emptyColor: pencil.withOpacity(0.45),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          (record.oneLiner ?? '').trim().isEmpty
                                              ? '(한줄평 없음)'
                                              : (record.oneLiner ?? '').trim(),
                                          style: oneLineStyle,
                                        ),
                                        const SizedBox(height: 12),

                                        // ✅ 태그만 (장르 없음)
                                        if (record.tags.isNotEmpty)
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: record.tags.map((t) {
                                              final text = t.startsWith('#') ? t : "#$t";
                                              return _Chip(
                                                text: text,
                                                bg: tagBg,
                                                border: pencil.withOpacity(0.7),
                                                fg: ink,
                                                fontFamily: f,
                                              );
                                            }).toList(),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // ✅ 오늘의 기록 + 날짜(옆에)
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: highlight.withOpacity(0.75),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text("오늘의 기록", style: sectionStyle),
                                        const SizedBox(width: 10),
                                        Text("· ${_fmtDate(record.watchDate)}", style: dateSmallStyle),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.menu_book_outlined, size: 18, color: ink.withOpacity(0.85)),
                                ],
                              ),

                              const SizedBox(height: 16),

                              if (record.photoPaths.isNotEmpty) ...[
                                _PhotoGrid(
                                  photos: record.photoPaths,
                                  borderColor: pencil.withOpacity(0.55),
                                  smartImage: _smartImage,
                                ),
                                const SizedBox(height: 14),
                              ],

                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: pencil.withOpacity(0.55)),
                                ),
                                child: Text(
                                  (record.detailedReview ?? '').trim().isEmpty
                                      ? '(상세 후기 없음)'
                                      : (record.detailedReview ?? '').trim(),
                                  style: detailStyle,
                                ),
                              ),

                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  final String url;
  final Color borderColor;
  final Widget Function(String, {BoxFit fit, Widget? error}) smartImage;

  const _Poster({
    required this.url,
    required this.borderColor,
    required this.smartImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 118,
      height: 148,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.1),
      ),
      clipBehavior: Clip.antiAlias,
      child: smartImage(
        url,
        fit: BoxFit.cover,
        error: Container(
          color: Colors.black.withOpacity(0.04),
          alignment: Alignment.center,
          child: const Icon(Icons.photo_outlined),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color bg;
  final Color border;
  final Color fg;
  final String fontFamily;

  const _Chip({
    required this.text,
    required this.bg,
    required this.border,
    required this.fg,
    required this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          height: 1.05,
          color: fg,
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final double rating;
  final Color color;
  final Color emptyColor;

  const _StarRow({
    required this.rating,
    required this.color,
    required this.emptyColor,
  });

  @override
  Widget build(BuildContext context) {
    final full = rating.floor();
    final half = (rating - full) >= 0.5;
    final empty = 5 - full - (half ? 1 : 0);

    return Row(
      children: [
        for (int i = 0; i < full; i++) Icon(Icons.star_rounded, size: 22, color: color),
        if (half) Icon(Icons.star_half_rounded, size: 22, color: color),
        for (int i = 0; i < empty; i++) Icon(Icons.star_outline_rounded, size: 22, color: emptyColor),
      ],
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  final List<String> photos;
  final Color borderColor;
  final Widget Function(String, {BoxFit fit, Widget? error}) smartImage;

  const _PhotoGrid({
    required this.photos,
    required this.borderColor,
    required this.smartImage,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: photos.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.75,
      ),
      itemBuilder: (context, index) {
        final pathOrUrl = photos[index];
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.0),
            color: Colors.white,
          ),
          clipBehavior: Clip.antiAlias,
          child: smartImage(
            pathOrUrl,
            fit: BoxFit.cover,
            error: Container(
              color: Colors.black.withOpacity(0.04),
              alignment: Alignment.center,
              child: const Icon(Icons.photo_outlined),
            ),
          ),
        );
      },
    );
  }
}
