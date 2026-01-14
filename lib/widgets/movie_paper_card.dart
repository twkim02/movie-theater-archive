import 'package:flutter/material.dart';
import 'sticker_button.dart';

class MoviePaperCard extends StatelessWidget {
  final String title;
  final String subtitle; // "로맨스·드라마 · 2025 · 115분"
  final double rating;   // 0.0 ~ 5.0
  final String posterUrl; // 네트워크 or 파일 경로로 바꿔도 됨

  final bool isSaved;
  final VoidCallback onToggleSaved;

  final VoidCallback onWriteDiary;
  final VoidCallback onViewTheaters;

  const MoviePaperCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.rating,
    required this.posterUrl,
    required this.isSaved,
    required this.onToggleSaved,
    required this.onWriteDiary,
    required this.onViewTheaters,
  });

  static const _cream = Color(0xFFFFF7EE);
  static const _ink = Color(0xFF4A4A4A);
  static const _purple = Color(0xFFB9A7E8);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cream.withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.08), width: 1),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Poster(url: posterUrl),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목 + 저장 아이콘 (오른쪽)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: _ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _SaveIconButton(
                          isSaved: isSaved,
                          onTap: onToggleSaved,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    Text(
                      subtitle,
                      style: TextStyle(
                        color: _ink.withOpacity(0.75),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 18, color: Color(0xFFFFC107)),
                        const SizedBox(width: 4),
                        Text(
                          '사람들 평점 ${rating.toStringAsFixed(1)}',
                          style: TextStyle(
                            color: _ink.withOpacity(0.85),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 버튼 2개
          Row(
            children: [
              Expanded(
                child: StickerButton(
                  text: '일기 쓰기',
                  icon: Icons.edit_rounded,
                  filled: true,
                  onTap: onWriteDiary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StickerButton(
                  text: '영화관 보기',
                  icon: Icons.location_on_rounded,
                  filled: false,
                  onTap: onViewTheaters,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  final String url;
  const _Poster({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 84,
        height: 110,
        color: Colors.black.withOpacity(0.06),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.movie_rounded, size: 26, color: Colors.black26),
          ),
        ),
      ),
    );
  }
}

class _SaveIconButton extends StatelessWidget {
  final bool isSaved;
  final VoidCallback onTap;

  const _SaveIconButton({required this.isSaved, required this.onTap});

  static const _purple = Color(0xFFB9A7E8);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _purple.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(color: _purple.withOpacity(0.25), width: 1),
        ),
        child: Icon(
          isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          size: 22,
          color: _purple,
        ),
      ),
    );
  }
}
