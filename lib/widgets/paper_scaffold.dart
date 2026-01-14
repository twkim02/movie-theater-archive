import 'package:flutter/material.dart';
import '../theme/app_assets.dart';

class PaperScaffold extends StatelessWidget {
  final Widget child;

  const PaperScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppAssets.bgPaper),
          fit: BoxFit.cover, // ✅ 왜곡 최소
        ),
      ),
      child: SafeArea(child: child),
    );
  }
}
