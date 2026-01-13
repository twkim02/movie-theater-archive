import 'package:flutter/material.dart';

class Taped extends StatelessWidget {
  final Widget child;
  final String tapeAsset;
  final double tapeWidth;
  final double left;
  final double top;

  const Taped({
    super.key,
    required this.child,
    required this.tapeAsset,
    this.tapeWidth = 110,
    this.left = 10,
    this.top = -18,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          left: left,
          top: top,
          child: Image.asset(
            tapeAsset,
            width: tapeWidth,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}
