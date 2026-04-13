import 'package:flutter/material.dart';

import '../theme/aroma_theme.dart';
import 'aroma_logo.dart';

/// En-tête commun des écrans auth (fond blanc, pas de « modal »).
class AuthPageLayout extends StatelessWidget {
  const AuthPageLayout({
    super.key,
    required this.title,
    this.description,
    required this.child,
  });

  final String title;
  final String? description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: AromaColors.zinc900,
        );
    final descStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AromaColors.zinc500,
          height: 1.35,
        );
    final brandStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: AromaColors.zinc900,
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        const padV = 32.0;
        final minContentHeight = constraints.hasBoundedHeight
            ? (constraints.maxHeight - padV * 2).clamp(0.0, double.infinity)
            : 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: padV),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minContentHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AromaLogo(height: 48),
                        const SizedBox(height: 14),
                        Text(
                          'Aroma JPC',
                          textAlign: TextAlign.center,
                          style: brandStyle,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: titleStyle,
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        description!,
                        textAlign: TextAlign.center,
                        style: descStyle,
                      ),
                    ],
                    const SizedBox(height: 28),
                    child,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
