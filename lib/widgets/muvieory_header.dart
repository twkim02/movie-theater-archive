import 'package:flutter/material.dart';
import '../theme/app_assets.dart';

class MuvieoryHeader extends StatelessWidget {
  final bool big; // true: characterlogo / false: logo
  final VoidCallback? onTapSetting;

  const MuvieoryHeader({
    super.key,
    this.big = true,
    this.onTapSetting,
  });

  @override
  Widget build(BuildContext context) {
    final asset = big ? AppAssets.characterLogo : AppAssets.logo;
    final height = big ? 140.0 : 56.0;

    return Stack(
      children: [
        Center(
          child: Image.asset(
            asset,
            height: height,
            fit: BoxFit.contain,
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: IconButton(
            onPressed: onTapSetting,
            icon: const Icon(Icons.settings, color: Colors.black54),
          ),
        ),
      ],
    );
  }
}
