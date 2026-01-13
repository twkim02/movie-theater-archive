import 'package:flutter/material.dart';

class StickerButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool filled; // true=보라 채움, false=테두리
  final IconData? icon;

  const StickerButton({
    super.key,
    required this.text,
    required this.onTap,
    this.filled = true,
    this.icon,
  });

  static const _purple = Color(0xFFB9A7E8);
  static const _cream = Color(0xFFFFF7EE);

  @override
  Widget build(BuildContext context) {
    final bg = filled ? _purple : _cream;
    final fg = filled ? Colors.white : _purple;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _purple.withOpacity(filled ? 0.0 : 0.9),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
            ],
            Text(
              text,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
