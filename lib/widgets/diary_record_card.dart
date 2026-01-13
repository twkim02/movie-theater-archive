import 'package:flutter/material.dart';
import '../theme/colors.dart';

class DiaryRecordCard extends StatelessWidget {
  final String title;
  final String posterUrl;
  final double rating;

  /// 오른쪽 텍스트 2줄
  final String subtitleTop;
  final String subtitleBottom;

  /// 우상단 pill (선택)
  final String? pillText;
  final Color? pillColor;

  final VoidCallback onTap;

  const DiaryRecordCard({
    super.key,
    required this.title,
    required this.posterUrl,
    required this.rating,
    required this.subtitleTop,
    required this.subtitleBottom,
    this.pillText,
    this.pillColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF0F0F0)),
          boxShadow: const [
            BoxShadow(
              blurRadius: 10,
              offset: Offset(0, 4),
              color: Color(0x0E000000),
            ),
          ],
        ),
        child: Row(
          children: [
            // 포스터
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                posterUrl,
                width: 60,
                height: 84,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 60,
                  height: 84,
                  color: Colors.black12,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 텍스트
            Expanded(
              child: SizedBox(
                height: 84,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목 + pill
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (pillText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: pillColor ?? const Color(0xFFFFE2F0),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: const Color(0x1A000000)),
                            ),
                            child: Text(
                              pillText!,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 6),

                    _StarsDisplay(value: rating),

                    const Spacer(),

                    Text(
                      subtitleTop,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitleBottom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
      children: List.generate(5, (i) {
        final idx = i + 1;
        final icon = _iconFor(idx);
        final filled = icon != Icons.star_border;

        return Icon(
          icon,
          size: 16,
          color: filled ? const Color(0xFFFFC107) : Colors.black26,
        );
      }),
    );
  }
}
