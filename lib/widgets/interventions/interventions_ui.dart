import 'package:flutter/material.dart';

import '../../models/intervention.dart';
import '../../theme/aroma_theme.dart';
import '../../utils/format_utils.dart';
import '../../utils/intervention_status_colors.dart';
import '../modern_bottom_sheet.dart';

/// Palette module Interventions — bleu terrain doux (aligné CRM web).
abstract final class InterventionsUi {
  static const gradientStart = Color(0xFF0EA5E9);
  static const gradientEnd = Color(0xFF38BDF8);
  static const accent = Color(0xFF0284C7);
  static const accentSoft = Color(0xFFE0F2FE);
  static const accentMuted = Color(0xFFF0F9FF);
  static const canvasSoft = Color(0xFFF8FAFC);

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0EA5E9), Color(0xFF7DD3FC)],
  );

  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0284C7), Color(0xFF38BDF8), Color(0xFFBAE6FD)],
    stops: [0.0, 0.55, 1.0],
  );

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: accent.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static BoxDecoration softCardDecoration({Color? borderColor}) {
    return BoxDecoration(
      color: AromaColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: borderColor ?? accentSoft.withValues(alpha: 0.9),
      ),
      boxShadow: softShadow,
    );
  }

  static InputDecoration softSearchDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: AromaColors.zinc500.withValues(alpha: 0.85)),
      prefixIcon: Icon(
        Icons.search_rounded,
        color: AromaColors.zinc500.withValues(alpha: 0.75),
      ),
      filled: true,
      fillColor: AromaColors.surface.withValues(alpha: 0.92),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: accent.withValues(alpha: 0.35), width: 1.5),
      ),
    );
  }

  /// Bouton d'action dans une [Row] (évite minWidth infinity des FilledButton).
  static ButtonStyle compactActionStyle({Color? backgroundColor}) {
    return FilledButton.styleFrom(
      backgroundColor: backgroundColor ?? accent,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      elevation: 0,
      shadowColor: accent.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  static ButtonStyle technicianActionStyle({required bool isReportAction}) {
    return FilledButton.styleFrom(
      backgroundColor: isReportAction ? accent : const Color(0xFF18181B),
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(48),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}

class InterventionsTabConfig {
  const InterventionsTabConfig(this.id, this.label, this.icon);

  final String id;
  final String label;
  final IconData icon;
}

class InterventionsTabPills extends StatefulWidget {
  const InterventionsTabPills({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelected,
  });

  final List<InterventionsTabConfig> tabs;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  State<InterventionsTabPills> createState() => _InterventionsTabPillsState();
}

class _InterventionsTabPillsState extends State<InterventionsTabPills> {
  final _keys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _ensureKeys();
    _scrollToSelected();
  }

  @override
  void didUpdateWidget(InterventionsTabPills oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureKeys();
    if (oldWidget.selected != widget.selected ||
        oldWidget.tabs.length != widget.tabs.length) {
      _scrollToSelected();
    }
  }

  void _ensureKeys() {
    for (final tab in widget.tabs) {
      _keys.putIfAbsent(tab.id, GlobalKey.new);
    }
  }

  void _scrollToSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = _keys[widget.selected];
      final ctx = key?.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        alignment: 0.5,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: AromaColors.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
          boxShadow: InterventionsUi.softShadow,
        ),
        child: SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            itemCount: widget.tabs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, i) {
              final tab = widget.tabs[i];
              final isSelected = widget.selected == tab.id;
              return KeyedSubtree(
                key: _keys[tab.id],
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => widget.onSelected(tab.id),
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected ? InterventionsUi.gradient : null,
                        color: isSelected
                            ? null
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: InterventionsUi.accent
                                      .withValues(alpha: 0.22),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tab.icon,
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : AromaColors.zinc500,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tab.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.1,
                              color: isSelected
                                  ? Colors.white
                                  : AromaColors.zinc800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class InterventionsSectionHeader extends StatelessWidget {
  const InterventionsSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.light = false,
  });

  final String title;
  final String? subtitle;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: light ? Colors.white : AromaColors.zinc900,
              ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: light
                  ? Colors.white.withValues(alpha: 0.82)
                  : AromaColors.zinc500,
            ),
          ),
        ],
      ],
    );
  }
}

class InterventionsMonthNavigator extends StatelessWidget {
  const InterventionsMonthNavigator({
    super.key,
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: InterventionsUi.softCardDecoration(),
      child: Row(
        children: [
          _NavButton(icon: Icons.chevron_left_rounded, onTap: onPrevious),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: -0.2,
                color: AromaColors.zinc900,
              ),
            ),
          ),
          _NavButton(icon: Icons.chevron_right_rounded, onTap: onNext),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: InterventionsUi.accentMuted,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: InterventionsUi.accent, size: 22),
        ),
      ),
    );
  }
}

class InterventionsSearchField extends StatelessWidget {
  const InterventionsSearchField({
    super.key,
    required this.hintText,
    required this.onChanged,
  });

  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InterventionsUi.softSearchDecoration(hintText: hintText),
      onChanged: onChanged,
    );
  }
}

class InterventionsEmptyState extends StatelessWidget {
  const InterventionsEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.build_outlined,
  });

  final String title;
  final String? subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: InterventionsUi.accentMuted,
              borderRadius: BorderRadius.circular(24),
              boxShadow: InterventionsUi.softShadow,
            ),
            child: Icon(
              icon,
              color: InterventionsUi.accent,
              size: 36,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AromaColors.zinc500,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class InterventionsListCard extends StatelessWidget {
  const InterventionsListCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.trailingWidget,
    required this.onTap,
    this.icon = Icons.chevron_right_rounded,
  });

  final String title;
  final String subtitle;
  final String? trailing;
  final Widget? trailingWidget;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: InterventionsUi.softCardDecoration(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: InterventionsUi.accentMuted,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.build_outlined,
                    color: InterventionsUi.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: -0.2,
                          color: AromaColors.zinc900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: AromaColors.zinc500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailingWidget != null) ...[
                  const SizedBox(width: 10),
                  trailingWidget!,
                ] else if (trailing != null) ...[
                  const SizedBox(width: 10),
                  Text(
                    trailing!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AromaColors.zinc800,
                    ),
                  ),
                ],
                const SizedBox(width: 6),
                Icon(
                  icon,
                  color: AromaColors.zinc400,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

List<Widget> interventionDetailRows(Intervention i) {
  return [
    if ((i.ref ?? '').isNotEmpty) InterventionsDetailRow('Référence', i.ref!),
    InterventionsDetailRow('Type', i.typeIntervention ?? '—'),
    InterventionsDetailRow('Client', i.clientNom ?? '—'),
    InterventionsDetailRow(
      'Site',
      i.siteAffiche.isEmpty ? '—' : i.siteAffiche,
    ),
    InterventionsDetailRow('Ville', i.ville ?? '—'),
    InterventionsDetailRow('Date', formatDateFr(i.dateIntervention)),
    InterventionsDetailRow(
      'État',
      i.etat ?? '—',
      valueWidget: InterventionEtatBadge(etat: i.etat),
    ),
    InterventionsDetailRow('Technicien', i.technicienNom ?? '—'),
    InterventionsDetailRow('Auteur', i.auteur ?? '—'),
    if ((i.description ?? '').trim().isNotEmpty)
      InterventionsDetailRow('Description', i.description!.trim()),
  ];
}

class InterventionEtatBadge extends StatelessWidget {
  const InterventionEtatBadge({super.key, required this.etat});

  final String? etat;

  @override
  Widget build(BuildContext context) {
    final label = (etat ?? '').trim().isEmpty ? '—' : etat!.trim();
    final colors = InterventionStatusColors.forEtat(etat);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border.withValues(alpha: 0.7)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: colors.foreground,
        ),
      ),
    );
  }
}

class AdcStatutBadge extends StatelessWidget {
  const AdcStatutBadge({super.key, required this.statut});

  final String? statut;

  @override
  Widget build(BuildContext context) {
    final colors = AdcStatutColors.forStatut(statut);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        AdcStatutColors.label(statut),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colors.foreground,
        ),
      ),
    );
  }
}

class AdcListCard extends StatelessWidget {
  const AdcListCard({
    super.key,
    required this.clientName,
    required this.siteName,
    required this.datePlanifiee,
    required this.statut,
    this.exchangeCount,
    required this.onTap,
  });

  final String clientName;
  final String siteName;
  final String datePlanifiee;
  final String? statut;
  final int? exchangeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: InterventionsUi.softCardDecoration(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: InterventionsUi.accentMuted,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.phone_in_talk_outlined,
                    color: InterventionsUi.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clientName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: -0.2,
                          color: AromaColors.zinc900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _metaLine('Site', siteName),
                      const SizedBox(height: 2),
                      _metaLine('Date planifiée', datePlanifiee),
                      if (exchangeCount != null && exchangeCount! > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          '$exchangeCount échange${exchangeCount! > 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AromaColors.zinc500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AdcStatutBadge(statut: statut),
                    const SizedBox(height: 8),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AromaColors.zinc400,
                      size: 22,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metaLine(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label · ',
          style: const TextStyle(fontSize: 12, color: AromaColors.zinc500),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: AromaColors.zinc800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class InterventionsDetailRow extends StatelessWidget {
  const InterventionsDetailRow(
    this.label,
    this.value, {
    super.key,
    this.valueWidget,
  });

  final String label;
  final String value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: AromaColors.zinc500, fontSize: 13),
            ),
          ),
          Expanded(
            child: valueWidget ??
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AromaColors.zinc900,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

void showInterventionsDetailSheet({
  required BuildContext context,
  required String title,
  required List<Widget> children,
  String? subtitle,
}) {
  showModernDetailSheet(
    context: context,
    title: title,
    subtitle: subtitle,
    theme: ModernSheetThemes.interventions,
    children: children,
  );
}

Widget interventionsErrorState({
  required String message,
  required VoidCallback onRetry,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    ),
  );
}

class InterventionsToggleKpiCard extends StatelessWidget {
  const InterventionsToggleKpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accent.withValues(alpha: 0.08) : AromaColors.surface,
      elevation: selected ? 2 : 0,
      shadowColor: accent.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? accent : AromaColors.zinc200,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: accent, size: 22),
                  const Spacer(),
                  if (selected)
                    Icon(Icons.check_circle_rounded, color: accent, size: 18),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: selected ? accent : AromaColors.zinc500,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selected ? accent : null,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
