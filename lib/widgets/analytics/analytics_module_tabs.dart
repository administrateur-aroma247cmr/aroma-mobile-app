import 'package:flutter/material.dart';

import '../../theme/aroma_theme.dart';

enum AnalyticsTab {
  controle,
  interventions,
  stock,
  comptabilite,
  facturation,
  recouvrement,
  commercial,
  taches,
}

class AnalyticsTabDef {
  const AnalyticsTabDef({
    required this.id,
    required this.label,
    required this.icon,
    required this.activeColor,
  });

  final AnalyticsTab id;
  final String label;
  final IconData icon;
  final Color activeColor;
}

const analyticsTabs = [
  AnalyticsTabDef(
    id: AnalyticsTab.controle,
    label: 'Contrôle',
    icon: Icons.fact_check_outlined,
    activeColor: Color(0xFF4F46E5),
  ),
  AnalyticsTabDef(
    id: AnalyticsTab.interventions,
    label: 'Interventions',
    icon: Icons.build_outlined,
    activeColor: Color(0xFF7C3AED),
  ),
  AnalyticsTabDef(
    id: AnalyticsTab.stock,
    label: 'Stock',
    icon: Icons.inventory_2_outlined,
    activeColor: Color(0xFF16A34A),
  ),
  AnalyticsTabDef(
    id: AnalyticsTab.comptabilite,
    label: 'Compta',
    icon: Icons.calculate_outlined,
    activeColor: Color(0xFF059669),
  ),
  AnalyticsTabDef(
    id: AnalyticsTab.facturation,
    label: 'Facturation',
    icon: Icons.receipt_long_outlined,
    activeColor: Color(0xFFD97706),
  ),
  AnalyticsTabDef(
    id: AnalyticsTab.recouvrement,
    label: 'Recouvrement',
    icon: Icons.balance_outlined,
    activeColor: Color(0xFFE11D48),
  ),
  AnalyticsTabDef(
    id: AnalyticsTab.commercial,
    label: 'Commercial',
    icon: Icons.storefront_outlined,
    activeColor: Color(0xFF9333EA),
  ),
  AnalyticsTabDef(
    id: AnalyticsTab.taches,
    label: 'Tâches',
    icon: Icons.task_alt_outlined,
    activeColor: Color(0xFF475569),
  ),
];

class AnalyticsModuleTabs extends StatelessWidget {
  const AnalyticsModuleTabs({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
    required this.child,
  });

  final AnalyticsTab activeTab;
  final ValueChanged<AnalyticsTab> onTabChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              for (final tab in analyticsTabs) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _TabChip(
                    tab: tab,
                    selected: activeTab == tab.id,
                    onTap: () => onTabChanged(tab.id),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final AnalyticsTabDef tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? tab.activeColor : AromaColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? tab.activeColor : AromaColors.zinc200,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tab.icon,
                size: 16,
                color: selected ? Colors.white : AromaColors.zinc500,
              ),
              const SizedBox(width: 6),
              Text(
                tab.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AromaColors.zinc800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
