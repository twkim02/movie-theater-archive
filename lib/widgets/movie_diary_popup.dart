import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/diary_record.dart';

/// ✅ 팝업 열기 함수
void openDiaryPopup(BuildContext context, DiaryRecord record) {
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
  final DiaryRecord record;
  const MovieDiaryPopup({super.key, required this.record});

  String _fmtDate(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}";

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

    // ✅ Typo 크레파스 폰트 패밀리 (pubspec family와 동일해야 함)
    const f = 'TypoCrayon';

    // ✅ 스타일 세트 (크레파스 느낌: 굵기+행간)
    const titleStyle = TextStyle(
      fontFamily: f,
      fontSize: 26,
      fontWeight: FontWeight.w800,
      height: 1.05,
      color: ink,
    );

    const dateStyle = TextStyle(
      fontFamily: f,
      fontSize: 13,
      fontWeight: FontWeight.w800,
      height: 1.1,
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

    const detailStyle = TextStyle(
      fontFamily: f,
      fontSize: 15.5,
      fontWeight: FontWeight.w600,
      height: 1.55,
      color: ink,
    );

    const closeStyle = TextStyle(
      fontFamily: f,
      fontSize: 16,
      fontWeight: FontWeight.w800,
      height: 1.1,
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
                      // 상단: 날짜 pill + X
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
                        child: Row(
                          children: [
                            const SizedBox(width: 40),
                            Expanded(
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: pencil.withOpacity(0.7)),
                                  ),
                                  child: Text(_fmtDate(record.date), style: dateStyle),
                                ),
                              ),
                            ),
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
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _Poster(
                                    url: record.posterUrl,
                                    borderColor: pencil.withOpacity(0.75),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(record.movieTitle, style: titleStyle),
                                        const SizedBox(height: 8),
                                        _StarRow(
                                          rating: record.rating,
                                          color: starColor,
                                          emptyColor: pencil.withOpacity(0.45),
                                        ),
                                        const SizedBox(height: 10),

                                        Text(record.oneLine, style: oneLineStyle),
                                        const SizedBox(height: 12),

                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            ...record.tags.map(
                                              (t) => _Chip(
                                                text: "#$t",
                                                bg: tagBg,
                                                border: pencil.withOpacity(0.7),
                                                fg: ink,
                                                fontFamily: f,
                                              ),
                                            ),
                                            ...record.genres.map(
                                              (g) => _Chip(
                                                text: g,
                                                bg: Colors.white,
                                                border: pencil.withOpacity(0.7),
                                                fg: ink.withOpacity(0.9),
                                                fontFamily: f,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: highlight.withOpacity(0.75),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text("오늘의 기록", style: sectionStyle),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.menu_book_outlined, size: 18, color: ink.withOpacity(0.85)),
                                ],
                              ),

                              const SizedBox(height: 16),

                              if (record.photos.isNotEmpty) ...[
                                _PhotoGrid(
                                  photos: record.photos,
                                  borderColor: pencil.withOpacity(0.55),
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
                                child: Text(record.detail, style: detailStyle),
                              ),

                              const SizedBox(height: 18),

                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: ink,
                                    side: BorderSide(color: pencil.withOpacity(0.75)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text("닫기", style: closeStyle),
                                ),
                              ),
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
  const _Poster({required this.url, required this.borderColor});

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
      child: Image.network(
        url,
        fit: BoxFit.cover,
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
        errorBuilder: (_, __, ___) => Container(
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
        for (int i = 0; i < full; i++)
          Icon(Icons.star_rounded, size: 22, color: color),
        if (half) Icon(Icons.star_half_rounded, size: 22, color: color),
        for (int i = 0; i < empty; i++)
          Icon(Icons.star_outline_rounded, size: 22, color: emptyColor),
      ],
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  final List<String> photos;
  final Color borderColor;

  const _PhotoGrid({
    required this.photos,
    required this.borderColor,
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
        final url = photos[index];
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.0),
            color: Colors.white,
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.network(
            url,
            fit: BoxFit.cover,
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
            errorBuilder: (_, __, ___) => Container(
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
