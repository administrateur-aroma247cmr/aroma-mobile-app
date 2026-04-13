import 'package:flutter/material.dart';

class AromaLogo extends StatelessWidget {
  const AromaLogo({
    super.key,
    this.height = 40,
    this.fit = BoxFit.contain,
  });

  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/branding/aroma-logo.png',
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.spa_outlined,
        size: height,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
