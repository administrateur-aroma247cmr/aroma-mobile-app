import 'package:flutter/material.dart';

import '../theme/aroma_theme.dart';
import 'caisse/caisse_ui.dart';
import 'compta/compta_ui.dart';
import 'interventions/interventions_ui.dart';
import 'rh/rh_ui.dart';
import 'tasks/task_ui.dart';

/// Thème visuel d'une bottom sheet — une couleur d'accent par module.
class ModernSheetTheme {
  const ModernSheetTheme({
    required this.accent,
    required this.accentEnd,
    this.icon,
  });

  final Color accent;
  final Color accentEnd;
  final IconData? icon;

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [accent, accentEnd],
      );
}

abstract final class ModernSheetThemes {
  static const interventions = ModernSheetTheme(
    accent: InterventionsUi.gradientStart,
    accentEnd: InterventionsUi.gradientEnd,
    icon: Icons.build_outlined,
  );

  static const transport = ModernSheetTheme(
    accent: Color(0xFF0891B2),
    accentEnd: Color(0xFF06B6D4),
    icon: Icons.local_shipping_rounded,
  );

  static const compta = ModernSheetTheme(
    accent: ComptaUi.gradientStart,
    accentEnd: ComptaUi.gradientEnd,
    icon: Icons.account_balance_wallet_outlined,
  );

  static const caisse = ModernSheetTheme(
    accent: CaisseUi.gradientStart,
    accentEnd: CaisseUi.gradientEnd,
    icon: Icons.payments_outlined,
  );

  static const rh = ModernSheetTheme(
    accent: RhUi.gradientStart,
    accentEnd: RhUi.gradientEnd,
    icon: Icons.groups_outlined,
  );

  static const tasks = ModernSheetTheme(
    accent: TaskUi.gradientStart,
    accentEnd: TaskUi.gradientEnd,
    icon: Icons.task_alt_outlined,
  );

  static const galerie = ModernSheetTheme(
    accent: Color(0xFF6366F1),
    accentEnd: Color(0xFF818CF8),
    icon: Icons.photo_library_outlined,
  );

  static const validation = ModernSheetTheme(
    accent: Color(0xFF4F46E5),
    accentEnd: Color(0xFF6366F1),
    icon: Icons.fact_check_outlined,
  );

  static const neutral = ModernSheetTheme(
    accent: AromaColors.zinc800,
    accentEnd: AromaColors.zinc500,
    icon: Icons.info_outline_rounded,
  );
}

/// Poignée de drag standardisée.
Widget modernSheetDragHandle() {
  return Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AromaColors.zinc200,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

/// Conteneur flottant arrondi (style transport_detail_sheet).
class ModernBottomSheetShell extends StatelessWidget {
  const ModernBottomSheetShell({
    super.key,
    required this.child,
    this.initialChildSize = 0.55,
    this.minChildSize = 0.35,
    this.maxChildSize = 0.92,
    this.margin = const EdgeInsets.fromLTRB(12, 0, 12, 12),
    this.useDraggable = true,
  });

  final Widget child;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;
  final EdgeInsets margin;
  final bool useDraggable;

  @override
  Widget build(BuildContext context) {
    final shell = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AromaColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );

    if (!useDraggable) return shell;

    return shell;
  }
}

/// En-tête gradient optionnel pour les fiches détail.
class ModernSheetHeader extends StatelessWidget {
  const ModernSheetHeader({
    super.key,
    required this.title,
    required this.theme,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final ModernSheetTheme theme;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: theme.gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.accent.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (theme.icon != null)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(theme.icon, color: Colors.white, size: 24),
            ),
          if (theme.icon != null) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                if ((subtitle ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!.trim(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

Future<T?> showModernBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext context) builder,
  bool isScrollControlled = true,
  bool useRootNavigator = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    backgroundColor: Colors.transparent,
    builder: builder,
  );
}

/// Fiche détail scrollable — remplace les anciennes bottom sheets « plates ».
Future<void> showModernDetailSheet({
  required BuildContext context,
  required String title,
  required List<Widget> children,
  ModernSheetTheme theme = ModernSheetThemes.neutral,
  String? subtitle,
  Widget? titleTrailing,
  Widget? footer,
  double initialChildSize = 0.55,
  double minChildSize = 0.35,
  double maxChildSize = 0.9,
}) {
  return showModernBottomSheet<void>(
    context: context,
    builder: (ctx) {
      final bottom = MediaQuery.paddingOf(ctx).bottom;
      final insetBottom = MediaQuery.viewInsetsOf(ctx).bottom;

      return ModernBottomSheetShell(
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: initialChildSize,
          minChildSize: minChildSize,
          maxChildSize: maxChildSize,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(
                0,
                0,
                0,
                16 + bottom + insetBottom,
              ),
              children: [
                const SizedBox(height: 10),
                modernSheetDragHandle(),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ModernSheetHeader(
                    title: title,
                    subtitle: subtitle,
                    theme: theme,
                    trailing: titleTrailing,
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: children,
                  ),
                ),
                if (footer != null) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: footer,
                  ),
                ],
              ],
            );
          },
        ),
      );
    },
  );
}

/// Menu d'actions (approuver, rejeter, ajouter…).
Future<void> showModernActionSheet({
  required BuildContext context,
  required String title,
  required List<Widget> actions,
  ModernSheetTheme theme = ModernSheetThemes.neutral,
  String? subtitle,
}) {
  return showModernBottomSheet<void>(
    context: context,
    builder: (ctx) {
      final bottom = MediaQuery.paddingOf(ctx).bottom;
      return ModernBottomSheetShell(
        useDraggable: false,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 16 + bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                modernSheetDragHandle(),
                const SizedBox(height: 16),
                ModernSheetHeader(
                  title: title,
                  subtitle: subtitle,
                  theme: theme,
                ),
                const SizedBox(height: 16),
                ...actions,
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Liste de sélection (pays, dossiers, options…).
Future<T?> showModernListSheet<T>({
  required BuildContext context,
  required String title,
  required List<Widget> children,
  ModernSheetTheme theme = ModernSheetThemes.neutral,
  String? subtitle,
  double initialChildSize = 0.5,
}) {
  return showModernBottomSheet<T>(
    context: context,
    builder: (ctx) {
      final bottom = MediaQuery.paddingOf(ctx).bottom;
      return ModernBottomSheetShell(
        initialChildSize: initialChildSize,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: initialChildSize,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(0, 0, 0, 12 + bottom),
              children: [
                const SizedBox(height: 10),
                modernSheetDragHandle(),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ModernSheetHeader(
                    title: title,
                    subtitle: subtitle,
                    theme: theme,
                  ),
                ),
                const SizedBox(height: 12),
                ...children,
              ],
            );
          },
        ),
      );
    },
  );
}

/// Tuile d'action pour les menus (galerie, etc.).
class ModernSheetActionTile extends StatelessWidget {
  const ModernSheetActionTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.theme = ModernSheetThemes.neutral,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final ModernSheetTheme theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AromaColors.zinc100,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AromaColors.zinc200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: theme.gradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AromaColors.zinc900,
                          ),
                        ),
                        if ((subtitle ?? '').isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AromaColors.zinc500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AromaColors.zinc500,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Option de liste sélectionnable.
class ModernSheetListTile extends StatelessWidget {
  const ModernSheetListTile({
    super.key,
    required this.title,
    this.leading,
    this.selected = false,
    required this.onTap,
    this.theme = ModernSheetThemes.neutral,
  });

  final String title;
  final Widget? leading;
  final bool selected;
  final VoidCallback onTap;
  final ModernSheetTheme theme;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: leading,
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: theme.accent)
          : null,
      onTap: onTap,
    );
  }
}
