import 'package:flutter/material.dart';

import '../providers/auth_provider.dart';
import '../theme/aroma_theme.dart';

enum AppModuleId {
  home,
  analytics,
  tasks,
  interventions,
  rh,
  compta,
  caisse,
  validation,
  galerie,
}

class AppModuleEntry {
  const AppModuleEntry({
    required this.id,
    required this.title,
    required this.icon,
    required this.gradientColors,
    this.permissionKey,
  });

  final AppModuleId id;
  final String title;
  final IconData icon;
  final List<Color> gradientColors;
  final String? permissionKey;
}

const appModuleCatalog = <AppModuleEntry>[
  AppModuleEntry(
    id: AppModuleId.home,
    title: 'Mon accueil',
    icon: Icons.home_rounded,
    gradientColors: [AromaColors.inputFill, AromaColors.zinc100],
  ),
  AppModuleEntry(
    id: AppModuleId.analytics,
    title: 'Analytics KPI',
    icon: Icons.bar_chart_rounded,
    gradientColors: [Color(0xFF7C3AED), Color(0xFFC026D3)],
    permissionKey: 'analytics',
  ),
  AppModuleEntry(
    id: AppModuleId.tasks,
    title: 'Mes tâches',
    icon: Icons.check_box_outlined,
    gradientColors: [Color(0xFF8B5CF6), Color(0xFF4F46E5)],
    permissionKey: 'tasks',
  ),
  AppModuleEntry(
    id: AppModuleId.interventions,
    title: 'Mes interventions',
    icon: Icons.build_circle_outlined,
    gradientColors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
    permissionKey: 'interventions',
  ),
  AppModuleEntry(
    id: AppModuleId.rh,
    title: 'Mon espace RH',
    icon: Icons.groups_outlined,
    gradientColors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
    permissionKey: 'rh',
  ),
  AppModuleEntry(
    id: AppModuleId.compta,
    title: 'Ma comptabilité',
    icon: Icons.calculate_outlined,
    gradientColors: [Color(0xFF059669), Color(0xFF0D9488)],
    permissionKey: 'compta',
  ),
  AppModuleEntry(
    id: AppModuleId.caisse,
    title: 'Ma caisse',
    icon: Icons.account_balance_wallet_outlined,
    gradientColors: [Color(0xFFF97316), Color(0xFFD97706)],
    permissionKey: 'caisse',
  ),
  AppModuleEntry(
    id: AppModuleId.validation,
    title: 'Ma validation',
    icon: Icons.verified_rounded,
    gradientColors: [Color(0xFF22C55E), Color(0xFF16A34A)],
    permissionKey: 'validation',
  ),
  AppModuleEntry(
    id: AppModuleId.galerie,
    title: 'Ma galerie',
    icon: Icons.image_outlined,
    gradientColors: [
      AromaColors.galerieGradientStart,
      AromaColors.galerieGradientEnd,
    ],
    permissionKey: 'galerie',
  ),
];

List<AppModuleEntry> visibleAppModules(AuthProvider auth) {
  return appModuleCatalog.where((module) {
    if (module.id == AppModuleId.home) return true;
    final key = module.permissionKey;
    if (key == null) return false;
    return auth.canShowHomeModule(key);
  }).toList();
}

AppModuleEntry? appModuleById(AppModuleId id) {
  for (final module in appModuleCatalog) {
    if (module.id == id) return module;
  }
  return null;
}

Widget appModuleDrawerIcon(AppModuleEntry module, {required bool selected}) {
  if (module.id == AppModuleId.home) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: selected ? AromaColors.zinc100 : AromaColors.inputFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? AromaColors.zinc200 : const Color(0x14000000),
        ),
      ),
      child: Icon(
        module.icon,
        size: 22,
        color: selected ? AromaColors.primary : AromaColors.zinc500,
      ),
    );
  }

  final colors = selected
      ? module.gradientColors
      : module.gradientColors
          .map((c) => c.withValues(alpha: 0.85))
          .toList(growable: false);

  return Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ),
      boxShadow: selected
          ? [
              BoxShadow(
                color: module.gradientColors.last.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    ),
    child: Icon(module.icon, size: 22, color: Colors.white),
  );
}
