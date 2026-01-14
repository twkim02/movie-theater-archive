import 'package:flutter/material.dart';

class StickerChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const StickerChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFFB7A6EA);
    const cream = Color(0xFFFFF6EC);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? purple : cream,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: purple.withOpacity(selected ? 0.0 : 0.7),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 12.5,
            color: selected ? Colors.white : purple,
          ),
        ),
      ),
    );
  }
}
