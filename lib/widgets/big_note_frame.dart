import 'package:flutter/material.dart';

class BigNoteFrame extends StatelessWidget {
  final Widget child;

  const BigNoteFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 18),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7EE).withOpacity(0.75),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE6DCD2), width: 1.6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        // ✅ 안쪽 라인(노트 프레임 느낌)
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF9).withOpacity(0.92),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black.withOpacity(0.06), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          child: child,
        ),
      ),
    );
  }
}
