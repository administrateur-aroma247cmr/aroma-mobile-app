import 'package:flutter/material.dart';

import '../../../models/analytics.dart';
import '../kpi_bar_chart.dart';
import '../kpi_chart_card.dart';
import '../kpi_format.dart';
import '../kpi_metric_card.dart';
import '../kpi_progress_ring.dart';

class AnalyticsTachesView extends StatelessWidget {
  const AnalyticsTachesView({super.key, required this.data});

  final AnalyticsTachesKpi data;

  @override
  Widget build(BuildContext context) {
    final obsSeries = data.observationsParSource.isNotEmpty
        ? data.observationsParSource
        : [
            KpiSeriesPoint(
              label: 'Avec action',
              value: data.observationsAvecAction.toDouble(),
            ),
            KpiSeriesPoint(
              label: 'Sans action',
              value: (data.observationsPeriode - data.observationsAvecAction)
                  .clamp(0, data.observationsPeriode)
                  .toDouble(),
            ),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KpiMetricGrid(
          children: [
            KpiMetricCard(
              label: 'Tâches période',
              value: formatKpiNumber(data.totalPeriode),
              sublabel: '${formatKpiNumber(data.tachesOuvertes)} ouvertes',
              icon: Icons.assignment_outlined,
              accent: KpiAccent.slate,
            ),
            KpiMetricCard(
              label: 'En retard',
              value: formatKpiNumber(data.tachesEnRetard),
              icon: Icons.pending_actions_outlined,
              accent: KpiAccent.amber,
            ),
            KpiMetricCard(
              label: 'Observations',
              value: formatKpiNumber(data.observationsPeriode),
              icon: Icons.visibility_outlined,
              accent: KpiAccent.cyan,
            ),
            KpiMetricCard(
              label: 'Obs. avec action',
              value: formatKpiNumber(data.observationsAvecAction),
              icon: Icons.task_alt_outlined,
              accent: KpiAccent.emerald,
            ),
            if (data.pctDansDelais != null)
              KpiMetricCard(
                label: 'Dans les délais',
                value: formatPct(data.pctDansDelais!),
                sublabel: 'Tâches terminées',
                icon: Icons.check_circle_outline,
                accent: KpiAccent.violet,
              ),
            if ((data.prioriteHauteRetard ?? 0) > 0)
              KpiMetricCard(
                label: 'Priorité haute + retard',
                value: formatKpiNumber(data.prioriteHauteRetard!),
                icon: Icons.priority_high,
                accent: KpiAccent.rose,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE4E4E7)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                KpiProgressRing(
                  value: data.pctTerminees,
                  label: 'tâches terminées',
                  color: const Color(0xFF475569),
                ),
                const SizedBox(height: 8),
                Text(
                  formatPct(data.pctTerminees),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const Text(
                  'Sur la période sélectionnée',
                  style: TextStyle(fontSize: 12, color: Color(0xFF71717A)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        KpiChartCard(
          title: 'Observations',
          description: 'Avec ou sans action planifiée',
          child: data.observationsPeriode > 0
              ? KpiBarChart(
                  data: obsSeries,
                  color: const Color(0xFF0891B2),
                )
              : const KpiEmptyChart(
                  message: 'Aucune observation sur la période',
                ),
        ),
      ],
    );
  }
}
