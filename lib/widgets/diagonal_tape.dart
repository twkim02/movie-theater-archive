import 'package:flutter/material.dart';

class DiagonalTape extends StatelessWidget {
  final String asset;
  final double angle;
  final double width;

  const DiagonalTape({
    super.key,
    required this.asset,
    this.angle = -0.25,
    this.width = 62,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Image.asset(asset, width: width, fit: BoxFit.contain),
    );
  }
}
