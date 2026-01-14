import 'package:flutter/material.dart';

class NoteCard extends StatelessWidget {
  final Widget child;

  const NoteCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6DCD2), width: 1.6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 6),
            blurRadius: 14,
          ),
        ],
      ),
      child: Container(
        // ✅ 안쪽 테두리 라인
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.75), width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}
