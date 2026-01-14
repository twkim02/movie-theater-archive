import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../theme/app_assets.dart';
import 'note_card.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;

  final VoidCallback? onPressDiary;
  final VoidCallback? onPressTheater;
  final VoidCallback? onToggleSave;
  final bool isSaved;
  final bool showTheaterButton;

  const MovieCard({
    super.key,
    required this.movie,
    this.onPressDiary,
    this.onPressTheater,
    this.onToggleSave,
    this.isSaved = false,
    this.showTheaterButton = true,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ 삐뚤삐뚤 제거: Transform.rotate 없음
    return NoteCard(
      child: _MovieCardContent(
        movie: movie,
        isSaved: isSaved,
        showTheaterButton: showTheaterButton,
        onPressDiary: onPressDiary,
        onPressTheater: onPressTheater,
        onToggleSave: onToggleSave,
      ),
    );
  }
}

/// 🔒 내부 전용 위젯
class _MovieCardContent extends StatelessWidget {
  final Movie movie;
  final bool isSaved;
  final bool showTheaterButton;
  final VoidCallback? onPressDiary;
  final VoidCallback? onPressTheater;
  final VoidCallback? onToggleSave;

  const _MovieCardContent({
    required this.movie,
    required this.isSaved,
    required this.showTheaterButton,
    this.onPressDiary,
    this.onPressTheater,
    this.onToggleSave,
  });

  String get year =>
      movie.releaseDate.length >= 4 ? movie.releaseDate.substring(0, 4) : "";

  // ✅ 영화마다 테이프 색 "고정 랜덤"
  String _pickTape(String id, String title) {
    final k = (id + title).hashCode.abs() % 4;
    switch (k) {
      case 0:
        return AppAssets.tapePink;
      case 1:
        return AppAssets.tapeYellow;
      case 2:
        return AppAssets.tapePurpleShort;
      default:
        return AppAssets.tapeCheck;
    }
  }

  @override
  Widget build(BuildContext context) {
    final genreText = movie.genres.take(2).join('·');
    final metaText = '$genreText · $year · ${movie.runtime}분';
    final tape = _pickTape(movie.id, movie.title);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ 포스터 + 포스터 위 대각선 테이프
        Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                movie.posterUrl,
                width: 78,
                height: 110,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 78,
                  height: 110,
                  color: Colors.black12,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined, size: 22),
                ),
              ),
            ),
            Positioned(
              left: -6,
              top: -10,
              child: Transform.rotate(
                angle: -0.35,
                child: Image.asset(
                  tape,
                  width: 48,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목 + 북마크
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      movie.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: Color(0xFF3A2E2E),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onToggleSave,
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        size: 22,
                        color: isSaved ? const Color(0xFFB7A6EA) : Colors.black45,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              Text(
                metaText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF8E847C),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: Color(0xFFFFC107)),
                  const SizedBox(width: 4),
                  Text(
                    '사람들 평점 ${movie.displayVoteAverage.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF6F5FA6),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 버튼
              if (showTheaterButton)
                Row(
                  children: [
                    Expanded(
                      child: _StickerButton(
                        filled: true,
                        text: '✍️ 일기 쓰기',
                        onTap: onPressDiary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StickerButton(
                        filled: false,
                        text: '영화관 보기',
                        onTap: onPressTheater,
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: _StickerButton(
                    filled: true,
                    text: '✍️ 일기 쓰기',
                    onTap: onPressDiary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// ✅ 버튼 색감/폰트 (1번 적용)
class _StickerButton extends StatelessWidget {
  final bool filled;
  final String text;
  final VoidCallback? onTap;

  const _StickerButton({
    required this.filled,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFFB7A6EA);
    const cream = Color(0xFFFFF6EC);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? purple : cream,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: purple.withOpacity(filled ? 0.0 : 0.8),
            width: 1.4,
          ),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    offset: const Offset(0, 3),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14.5,
            color: filled ? Colors.white : purple,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}
