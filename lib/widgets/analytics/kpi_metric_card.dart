import 'package:flutter/material.dart';

import '../../theme/aroma_theme.dart';

enum KpiAccent { violet, emerald, amber, slate, rose, cyan, lime }

class KpiAccentStyle {
  const KpiAccentStyle({
    required this.iconBg,
    required this.iconColor,
    required this.gradientStart,
    required this.gradientEnd,
    required this.ring,
  });

  final Color iconBg;
  final Color iconColor;
  final Color gradientStart;
  final Color gradientEnd;
  final Color ring;

  static KpiAccentStyle of(KpiAccent accent) {
    return switch (accent) {
      KpiAccent.violet => const KpiAccentStyle(
          iconBg: Color(0xFFF5F3FF),
          iconColor: Color(0xFF7C3AED),
          gradientStart: Color(0x337C3AED),
          gradientEnd: Color(0x056366F1),
          ring: Color(0x337C3AED),
        ),
      KpiAccent.emerald => const KpiAccentStyle(
          iconBg: Color(0xFFECFDF5),
          iconColor: Color(0xFF059669),
          gradientStart: Color(0x3310B981),
          gradientEnd: Color(0x0514B8A6),
          ring: Color(0x3310B981),
        ),
      KpiAccent.amber => const KpiAccentStyle(
          iconBg: Color(0xFFFFFBEB),
          iconColor: Color(0xFFD97706),
          gradientStart: Color(0x33F59E0B),
          gradientEnd: Color(0x05F97316),
          ring: Color(0x33F59E0B),
        ),
      KpiAccent.slate => const KpiAccentStyle(
          iconBg: Color(0xFFF8FAFC),
          iconColor: Color(0xFF475569),
          gradientStart: Color(0x3364748B),
          gradientEnd: Color(0x0571717A),
          ring: Color(0x3364748B),
        ),
      KpiAccent.rose => const KpiAccentStyle(
          iconBg: Color(0xFFFFF1F2),
          iconColor: Color(0xFFE11D48),
          gradientStart: Color(0x33F43F5E),
          gradientEnd: Color(0x05EC4899),
          ring: Color(0x33F43F5E),
        ),
      KpiAccent.cyan => const KpiAccentStyle(
          iconBg: Color(0xFFECFEFF),
          iconColor: Color(0xFF0891B2),
          gradientStart: Color(0x3306B6D4),
          gradientEnd: Color(0x050EA5E9),
          ring: Color(0x3306B6D4),
        ),
      KpiAccent.lime => const KpiAccentStyle(
          iconBg: Color(0xFFF7FEE7),
          iconColor: Color(0xFF65A30D),
          gradientStart: Color(0x3384CC16),
          gradientEnd: Color(0x0522C55E),
          ring: Color(0x3384CC16),
        ),
    };
  }
}

class KpiMetricCard extends StatelessWidget {
  const KpiMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.sublabel,
    this.accent = KpiAccent.violet,
    this.highlight = false,
    this.compact = true,
  });

  final String label;
  final String value;
  final String? sublabel;
  final IconData icon;
  final KpiAccent accent;
  final bool highlight;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final styles = KpiAccentStyle.of(accent);
    final padding = compact ? 10.0 : 16.0;
    final iconSize = compact ? 30.0 : 44.0;
    final iconGlyph = compact ? 15.0 : 22.0;
    final valueSize = compact ? 15.0 : 20.0;
    final labelSize = compact ? 9.5 : 11.0;
    final sublabelSize = compact ? 10.0 : 12.0;
    final radius = compact ? 12.0 : 16.0;

    return Container(
      decoration: BoxDecoration(
        color: AromaColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: highlight ? styles.ring : AromaColors.zinc200,
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [styles.gradientStart, styles.gradientEnd],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(padding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: styles.iconBg,
                      borderRadius: BorderRadius.circular(compact ? 8 : 12),
                    ),
                    child: Icon(icon, size: iconGlyph, color: styles.iconColor),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: labelSize,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                            color: AromaColors.zinc500,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: valueSize,
                            color: AromaColors.zinc900,
                            height: 1.1,
                          ),
                        ),
                        if (sublabel != null) ...[
                          const SizedBox(height: 1),
                          Text(
                            sublabel!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: sublabelSize,
                              color: AromaColors.zinc500,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class KpiMetricGrid extends StatelessWidget {
  const KpiMetricGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= 900 ? 4 : width >= 600 ? 3 : 2;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: crossAxisCount >= 4 ? 2.6 : crossAxisCount == 3 ? 2.4 : 2.15,
      children: children,
    );
  }
}
