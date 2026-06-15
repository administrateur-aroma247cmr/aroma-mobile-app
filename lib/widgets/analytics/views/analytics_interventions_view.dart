import 'package:flutter/material.dart';

import '../../../models/analytics.dart';
import '../kpi_area_chart.dart';
import '../kpi_bar_chart.dart';
import '../kpi_chart_card.dart';
import '../kpi_donut_chart.dart';
import '../kpi_format.dart';
import '../kpi_metric_card.dart';
import '../kpi_progress_ring.dart';

class AnalyticsInterventionsView extends StatelessWidget {
  const AnalyticsInterventionsView({super.key, required this.data});

  final AnalyticsInterventionsKpi data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KpiMetricGrid(
          children: [
            KpiMetricCard(
              label: 'Interventions période',
              value: formatKpiNumber(data.periode),
              sublabel: '${formatKpiNumber(data.total)} cumulées',
              icon: Icons.build_outlined,
              accent: KpiAccent.slate,
            ),
            KpiMetricCard(
              label: 'Taux de clôture',
              value: formatPct(data.tauxCloturePct),
              sublabel: 'Planifiées → clôturées',
              icon: Icons.check_circle_outline,
              accent: KpiAccent.violet,
              highlight: true,
            ),
            KpiMetricCard(
              label: 'Délai moyen',
              value: '${data.delaiMoyenJours.toStringAsFixed(0)} j',
              sublabel: 'Création → intervention',
              icon: Icons.schedule_outlined,
              accent: KpiAccent.cyan,
            ),
            KpiMetricCard(
              label: 'Réparations ouvertes',
              value: formatKpiNumber(data.reparationsOuvertes),
              sublabel: data.reparationsPeriode != null
                  ? '${formatKpiNumber(data.reparationsPeriode!)} sur la période'
                  : null,
              icon: Icons.warning_amber_outlined,
              accent: KpiAccent.amber,
            ),
            KpiMetricCard(
              label: 'Refill 1',
              value: formatKpiNumber(data.refill1),
              icon: Icons.water_drop_outlined,
              accent: KpiAccent.cyan,
            ),
            KpiMetricCard(
              label: 'Refill 2',
              value: formatKpiNumber(data.refill2),
              icon: Icons.water_drop_outlined,
              accent: KpiAccent.cyan,
            ),
            KpiMetricCard(
              label: 'ADC réalisés',
              value: formatKpiNumber(data.adcRealises),
              icon: Icons.phone_in_talk_outlined,
              accent: KpiAccent.rose,
            ),
            KpiMetricCard(
              label: 'VDC',
              value: formatKpiNumber(data.vdcTotal),
              icon: Icons.place_outlined,
              accent: KpiAccent.rose,
            ),
            if (data.mesuresPeriode != null)
              KpiMetricCard(
                label: 'Mesures client',
                value: formatKpiNumber(data.mesuresPeriode!),
                icon: Icons.straighten_outlined,
                accent: KpiAccent.emerald,
              ),
            if ((data.mesuresEnRetard ?? 0) > 0)
              KpiMetricCard(
                label: 'Mesures en retard',
                value: formatKpiNumber(data.mesuresEnRetard!),
                icon: Icons.warning_amber_outlined,
                accent: KpiAccent.amber,
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (data.parType.isNotEmpty)
          KpiChartCard(
            title: 'Répartition par type',
            description: 'RF, MT, VT, RI, QC, installation…',
            child: KpiBarChart(
              data: data.parType,
              layout: KpiBarLayout.vertical,
              color: const Color(0xFF64748B),
            ),
          ),
        const SizedBox(height: 12),
        KpiProgressRingCard(
          title: 'Taux de clôture',
          description: 'Objectif CDC ≥ 85 %',
          pct: data.tauxCloturePct,
          sublabel: 'clôturées',
        ),
        const SizedBox(height: 12),
        if (data.tendanceMensuelle.isNotEmpty)
          KpiChartCard(
            title: 'Évolution mensuelle',
            description: 'Volume d\'interventions',
            child: KpiAreaChart(
              data: data.tendanceMensuelle,
              color: const Color(0xFF64748B),
            ),
          ),
        const SizedBox(height: 12),
        if (data.parEtat.isNotEmpty)
          KpiChartCard(
            title: 'Par état',
            description: 'Planifiées, en cours, clôturées',
            child: KpiDonutChart(data: data.parEtat, centerLabel: 'total'),
          ),
        const SizedBox(height: 12),
        if (data.parTechnicien.isNotEmpty)
          KpiChartCard(
            title: 'Par technicien',
            description: 'Interventions de la période',
            child: KpiBarChart(
              data: data.parTechnicien,
              layout: KpiBarLayout.vertical,
              color: const Color(0xFF64748B),
            ),
          ),
        const SizedBox(height: 12),
        if (data.parSite.isNotEmpty)
          KpiChartCard(
            title: 'Par site',
            description: 'Répartition terrain',
            child: KpiBarChart(
              data: data.parSite,
              color: const Color(0xFF0891B2),
            ),
          ),
        const SizedBox(height: 12),
        if (data.adcParStatut.isNotEmpty)
          KpiChartCard(
            title: 'ADC par statut',
            description: 'Expérience client',
            child: KpiDonutChart(data: data.adcParStatut, centerLabel: 'ADC'),
          ),
        const SizedBox(height: 12),
        if (data.adcParRessenti.isNotEmpty)
          KpiChartCard(
            title: 'Ressenti ADC',
            description: 'Retours clients',
            child: KpiBarChart(
              data: data.adcParRessenti,
              layout: KpiBarLayout.vertical,
              color: const Color(0xFFE11D48),
            ),
          ),
        const SizedBox(height: 12),
        if (data.reparationsParStatut.isNotEmpty)
          KpiChartCard(
            title: 'Réparations par statut',
            child: KpiBarChart(
              data: data.reparationsParStatut,
              layout: KpiBarLayout.vertical,
              color: const Color(0xFFF59E0B),
            ),
          ),
        const SizedBox(height: 12),
        if (data.reparationsParPanne.isNotEmpty)
          KpiChartCard(
            title: 'Réparations par panne',
            child: KpiBarChart(
              data: data.reparationsParPanne,
              layout: KpiBarLayout.vertical,
              color: const Color(0xFFF97316),
            ),
          ),
        if (data.rapportTechnicien != null) ...[
          const SizedBox(height: 12),
          _RapportTechnicienSection(data: data.rapportTechnicien!),
        ],
      ],
    );
  }
}

class _RapportTechnicienSection extends StatelessWidget {
  const _RapportTechnicienSection({required this.data});

  final AnalyticsRapportTechnicienKpi data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Rapport technicien',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        KpiMetricGrid(
          children: [
            KpiMetricCard(
              label: 'Évaluations réalisées',
              value: formatKpiNumber(data.evaluationsRealisees),
              icon: Icons.assignment_outlined,
              accent: KpiAccent.violet,
            ),
            KpiMetricCard(
              label: 'Score moyen',
              value: formatPct(data.scoreMoyenPct),
              icon: Icons.star_outline,
              accent: KpiAccent.amber,
            ),
            KpiMetricCard(
              label: 'En attente',
              value: formatKpiNumber(data.evaluationsEnAttente),
              icon: Icons.hourglass_empty_outlined,
              accent: KpiAccent.slate,
            ),
          ],
        ),
        if (data.parTechnicien.isNotEmpty) ...[
          const SizedBox(height: 12),
          KpiChartCard(
            title: 'Score par technicien',
            child: KpiBarChart(
              data: data.parTechnicien,
              layout: KpiBarLayout.vertical,
              color: const Color(0xFF7C3AED),
            ),
          ),
        ],
      ],
    );
  }
}
