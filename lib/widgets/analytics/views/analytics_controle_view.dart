import 'package:flutter/material.dart';

import '../../../models/analytics.dart';
import '../../../theme/aroma_theme.dart';
import '../kpi_bar_chart.dart';
import '../kpi_chart_card.dart';
import '../kpi_format.dart';

class AnalyticsControleView extends StatelessWidget {
  const AnalyticsControleView({super.key, required this.data});

  final AnalyticsControleKpi data;

  @override
  Widget build(BuildContext context) {
    final sections = [
      data.comptabiliteRecouvrement,
      data.interventions,
      data.stockLogistique,
      data.rh,
    ];
    final totalEcarts = sections.fold<int>(
      0,
      (acc, s) =>
          acc +
          s.metrics
              .where(
                (m) =>
                    (m.enRetard ?? 0) > 0 ||
                    (m.cible != null && m.realise < m.cible!),
              )
              .length,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFC7D2FE)),
          ),
          child: Row(
            children: [
              const Icon(Icons.fact_check, color: Color(0xFF4F46E5), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  totalEcarts > 0
                      ? 'Suivi réalisé / attendu — $totalEcarts indicateur${totalEcarts > 1 ? 's' : ''} en écart.'
                      : 'Tous les indicateurs sont au vert sur la période.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF312E81),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final section in sections) ...[
          _ControleSection(section: section),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

class _ControleSection extends StatelessWidget {
  const _ControleSection({required this.section});

  final AnalyticsControleSection section;

  @override
  Widget build(BuildContext context) {
    final alertCount = section.metrics
        .where(
          (m) =>
              (m.enRetard ?? 0) > 0 ||
              (m.cible != null && m.realise < m.cible!),
        )
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              section.titre,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AromaColors.zinc900,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: alertCount > 0
                    ? const Color(0xFFFEF3C7)
                    : const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                alertCount > 0 ? '$alertCount écart${alertCount > 1 ? 's' : ''}' : 'OK',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: alertCount > 0
                      ? const Color(0xFF92400E)
                      : const Color(0xFF065F46),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ControleMetricsGrid(metrics: section.metrics),
        if (section.parMarque.isNotEmpty) ...[
          const SizedBox(height: 8),
          KpiChartCard(
            title: 'Répartition par marque',
            description: 'Ruptures stock abonnement',
            child: KpiBarChart(
              data: section.parMarque,
              layout: KpiBarLayout.vertical,
              color: const Color(0xFF84CC16),
            ),
          ),
        ],
      ],
    );
  }
}

class _ControleMetricsGrid extends StatelessWidget {
  const _ControleMetricsGrid({required this.metrics});

  final List<AnalyticsControleMetric> metrics;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (var i = 0; i < metrics.length; i += 2)
          Padding(
            padding: EdgeInsets.only(bottom: i + 2 < metrics.length ? 8 : 0),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _ControleMetricCard(metric: metrics[i])),
                  const SizedBox(width: 8),
                  Expanded(
                    child: i + 1 < metrics.length
                        ? _ControleMetricCard(metric: metrics[i + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ControleMetricCard extends StatelessWidget {
  const _ControleMetricCard({required this.metric});

  final AnalyticsControleMetric metric;

  @override
  Widget build(BuildContext context) {
    final pct = metric.cible != null && metric.cible! > 0
        ? (metric.realise / metric.cible! * 100).clamp(0, 100).round()
        : null;
    final hasRetard = (metric.enRetard ?? 0) > 0;
    final hasGap = metric.cible != null && metric.realise < metric.cible!;
    final isOk =
        metric.cible != null && metric.realise >= metric.cible! && !hasRetard;

    Color borderColor = AromaColors.zinc200;
    Color bgColor = AromaColors.surface;
    if (hasRetard) {
      borderColor = const Color(0xFFFECDD3);
      bgColor = const Color(0xFFFFF1F2);
    } else if (hasGap) {
      borderColor = const Color(0xFFFDE68A);
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  metric.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: AromaColors.zinc900,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              if (hasRetard || hasGap)
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 14,
                  color: Color(0xFFD97706),
                )
              else if (isOk)
                const Icon(
                  Icons.check_circle,
                  size: 14,
                  color: Color(0xFF22C55E),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 4,
            runSpacing: 2,
            children: [
              Text(
                formatControleValue(metric.realise, metric.unite),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AromaColors.zinc900,
                  height: 1.1,
                ),
              ),
              if (metric.cible != null)
                Text(
                  '/ ${formatControleValue(metric.cible!, metric.unite)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AromaColors.zinc500,
                    height: 1.1,
                  ),
                ),
            ],
          ),
          if (hasRetard) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFECDD3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${formatKpiNumber(metric.enRetard!)} retard',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9F1239),
                ),
              ),
            ),
          ],
          if (pct != null) ...[
            const Spacer(),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Avancement',
                  style: TextStyle(fontSize: 9, color: AromaColors.zinc500),
                ),
                Text(
                  '$pct %',
                  style: const TextStyle(fontSize: 9, color: AromaColors.zinc500),
                ),
              ],
            ),
            const SizedBox(height: 3),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct / 100,
                minHeight: 5,
                backgroundColor: AromaColors.zinc100,
                color: pct >= 100
                    ? const Color(0xFF22C55E)
                    : pct >= 70
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFFEF4444),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
