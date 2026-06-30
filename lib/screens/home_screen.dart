import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../navigation/app_modules.dart';
import '../providers/auth_provider.dart';
import '../theme/aroma_theme.dart';
import '../widgets/aroma_logo.dart';

/// Accueil type grille de modules (même esprit que le CRM web).
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onOpenModule,
  });

  final ValueChanged<AppModuleId> onOpenModule;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: AromaColors.zinc800,
      letterSpacing: -0.5,
    );
    final subtitleStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: AromaColors.zinc500);

    final modules = visibleAppModules(auth)
        .where((m) => m.id != AppModuleId.home)
        .toList();

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
          LayoutBuilder(
            builder: (context, constraints) {
              const columns = 3;
              const spacing = 12.0;
              final itemWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: modules
                    .map(
                      (m) => SizedBox(
                        width: itemWidth,
                        child: _ModuleCard(
                          title: m.title,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: m.gradientColors,
                          ),
                          icon: m.icon,
                          onTap: () => onOpenModule(m.id),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
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
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: widget.gradient,
                      ),
                      child: Icon(
                        widget.icon,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      softWrap: true,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AromaColors.zinc900,
                        letterSpacing: -0.1,
                        height: 1.2,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
