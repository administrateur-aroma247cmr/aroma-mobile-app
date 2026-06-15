import 'package:flutter/material.dart';

import '../../theme/aroma_theme.dart';

/// Palette module RH — alignée sur le dégradé ambre/orange du CRM web.
abstract final class RhUi {
  static const gradientStart = Color(0xFFF59E0B);
  static const gradientEnd = Color(0xFFEA580C);
  static const accent = Color(0xFFF97316);

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientEnd],
  );

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static ({Color bg, Color fg}) statutColors(String? statut) => switch (statut) {
        'en_attente' => (
            bg: const Color(0xFFFEF3C7),
            fg: const Color(0xFFB45309),
          ),
        'approuve' || 'approuve_paye' || 'approuve_non_paye' => (
            bg: const Color(0xFFD1FAE5),
            fg: const Color(0xFF047857),
          ),
        'rejete' || 'refuse' => (
            bg: const Color(0xFFFEE2E2),
            fg: const Color(0xFFB91C1C),
          ),
        _ => (bg: AromaColors.zinc100, fg: AromaColors.zinc500),
      };

  static ({Color bg, Color fg, IconData icon}) presenceStyle({
    required bool absence,
    required bool retard,
  }) {
    if (absence) {
      return (
        bg: const Color(0xFFFEE2E2),
        fg: const Color(0xFFB91C1C),
        icon: Icons.event_busy_rounded,
      );
    }
    if (retard) {
      return (
        bg: const Color(0xFFFEF3C7),
        fg: const Color(0xFFB45309),
        icon: Icons.schedule_rounded,
      );
    }
    return (
      bg: const Color(0xFFD1FAE5),
      fg: const Color(0xFF047857),
      icon: Icons.check_circle_outline_rounded,
    );
  }

  static IconData typeDemandeIcon(String type) => switch (type) {
        'Absence' => Icons.event_busy_outlined,
        'Maladie' => Icons.medical_services_outlined,
        'Congé' => Icons.beach_access_outlined,
        'Avance de Paiement' => Icons.payments_outlined,
        _ => Icons.description_outlined,
      };

  static IconData typeDisciplineIcon(String type) => switch (type) {
        'avertissement' => Icons.warning_amber_rounded,
        'blame' => Icons.gavel_rounded,
        'mise_a_pied' => Icons.pause_circle_outline_rounded,
        'licenciement' => Icons.person_off_outlined,
        'demande_explication' => Icons.help_outline_rounded,
        _ => Icons.rule_folder_outlined,
      };

  static ({Color bg, Color fg}) statutDisciplineColors(String? statut) =>
      switch (statut) {
        'valide' => (
            bg: const Color(0xFFD1FAE5),
            fg: const Color(0xFF047857),
          ),
        'rejete' => (
            bg: const Color(0xFFFEE2E2),
            fg: const Color(0xFFB91C1C),
          ),
        'en_cours' => (
            bg: const Color(0xFFFEF3C7),
            fg: const Color(0xFFB45309),
          ),
        _ => (bg: AromaColors.zinc100, fg: AromaColors.zinc500),
      };
}

class RhTabConfig {
  const RhTabConfig(this.id, this.label, this.icon, {this.count});

  final String id;
  final String label;
  final IconData icon;
  final int? count;
}

class RhTabPills extends StatefulWidget {
  const RhTabPills({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelected,
  });

  final List<RhTabConfig> tabs;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  State<RhTabPills> createState() => _RhTabPillsState();
}

class _RhTabPillsState extends State<RhTabPills> {
  final _keys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _ensureKeys();
    _scrollToSelected();
  }

  @override
  void didUpdateWidget(RhTabPills oldWidget) {
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
    return SizedBox(
      height: 44,
      child: Stack(
        children: [
          ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.tabs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final tab = widget.tabs[i];
              final isSelected = widget.selected == tab.id;
              return KeyedSubtree(
                key: _keys[tab.id],
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => widget.onSelected(tab.id),
                    borderRadius: BorderRadius.circular(22),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected ? RhUi.gradient : null,
                        color: isSelected ? null : AromaColors.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : const Color(0xFFE4E4E7),
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: RhUi.accent.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
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
                              color: isSelected
                                  ? Colors.white
                                  : AromaColors.zinc800,
                            ),
                          ),
                          if (tab.count != null && tab.count! > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : RhUi.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${tab.count}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      isSelected ? Colors.white : RhUi.accent,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (widget.tabs.length > 4)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  width: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AromaColors.canvas.withValues(alpha: 0),
                        AromaColors.canvas,
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class RhStatPill extends StatelessWidget {
  const RhStatPill({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AromaColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE4E4E7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AromaColors.zinc500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RhStatusBadge extends StatelessWidget {
  const RhStatusBadge({super.key, required this.label, required this.statut});

  final String label;
  final String? statut;

  @override
  Widget build(BuildContext context) {
    final colors = RhUi.statutColors(statut);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.fg,
        ),
      ),
    );
  }
}

class RhEmptyState extends StatelessWidget {
  const RhEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.groups_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: RhUi.gradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AromaColors.zinc500),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class RhSectionHeader extends StatelessWidget {
  const RhSectionHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AromaColors.zinc900,
              ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 13, color: AromaColors.zinc500),
          ),
        ],
      ],
    );
  }
}

class RhProfileHero extends StatelessWidget {
  const RhProfileHero({
    super.key,
    required this.name,
    this.poste,
    this.subtitle,
  });

  final String name;
  final String? poste;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        gradient: RhUi.gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: RhUi.accent.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              RhUi.initials(name),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          if (poste != null && poste!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              poste!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class RhInfoSection extends StatelessWidget {
  const RhInfoSection({
    super.key,
    required this.title,
    required this.icon,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final List<({String label, String? value})> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AromaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: RhUi.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: RhUi.accent),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AromaColors.zinc900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...rows.map(
            (r) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      r.label,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AromaColors.zinc500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      (r.value == null || r.value!.isEmpty) ? '—' : r.value!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AromaColors.zinc900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
