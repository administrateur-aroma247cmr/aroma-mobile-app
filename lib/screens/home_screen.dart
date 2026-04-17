import 'package:flutter/material.dart';

import '../theme/aroma_theme.dart';
import '../widgets/aroma_logo.dart';

/// Accueil type grille de modules (même esprit que le CRM web).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenGalerie});

  final VoidCallback onOpenGalerie;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: AromaColors.zinc800,
      letterSpacing: -0.5,
    );
    final subtitleStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: AromaColors.zinc500);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        children: [
          const SizedBox(height: 8),
          const AromaLogo(height: 96),
          const SizedBox(height: 20),
          Text(
            'Mon tableau de bord',
            textAlign: TextAlign.center,
            style: titleStyle?.copyWith(fontSize: 26),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Choisissez un de mes modules pour commencer',
              style: subtitleStyle,
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 0.92,
            children: [
              _ModuleCard(
                title: 'Ma galerie',
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AromaColors.galerieGradientStart,
                    AromaColors.galerieGradientEnd,
                  ],
                ),
                icon: Icons.image_outlined,
                onTap: onOpenGalerie,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatefulWidget {
  const _ModuleCard({
    required this.title,
    required this.gradient,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final Gradient gradient;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hover = v),
      child: AnimatedScale(
        scale: _hover ? 1.02 : 1,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              decoration: BoxDecoration(
                color: AromaColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xCC_E4E4E7)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, c) {
                  final minSide = c.biggest.shortestSide;
                  final compact = minSide < 150;
                  final padding = compact ? 10.0 : 24.0;
                  final iconBox = compact ? 44.0 : 80.0;
                  final iconSize = compact ? 24.0 : 46.0;
                  final gap = compact ? 8.0 : 20.0;

                  return Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: iconBox,
                          height: iconBox,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: widget.gradient,
                          ),
                          child: Icon(
                            widget.icon,
                            size: iconSize,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: gap),
                        Flexible(
                          child: Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            maxLines: compact ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AromaColors.zinc900,
                                  letterSpacing: -0.2,
                                  fontSize: compact ? 12 : null,
                                ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
