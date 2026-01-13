import 'package:flutter/material.dart';

class TapedSectionTitle extends StatelessWidget {
  final String title;

  const TapedSectionTitle({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: Color(0xFF3A2E2E),
      ),
    );
  }
}
