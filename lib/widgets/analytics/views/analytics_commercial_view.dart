import 'package:flutter/material.dart';

import '../../../models/analytics.dart';
import '../kpi_area_chart.dart';
import '../kpi_bar_chart.dart';
import '../kpi_chart_card.dart';
import '../kpi_donut_chart.dart';
import '../kpi_format.dart';
import '../kpi_metric_card.dart';

class AnalyticsCommercialView extends StatelessWidget {
  const AnalyticsCommercialView({super.key, required this.data});

  final AnalyticsCommercialKpi data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KpiMetricGrid(
          children: [
            KpiMetricCard(
              label: 'CA boutique',
              value: formatFcfa(data.caBoutique),
              sublabel: '${formatKpiNumber(data.nbVentes)} ventes',
              icon: Icons.shopping_bag_outlined,
              accent: KpiAccent.violet,
              highlight: true,
            ),
            KpiMetricCard(
              label: 'Panier moyen',
              value: formatFcfa(data.panierMoyen),
              icon: Icons.shopping_cart_outlined,
              accent: KpiAccent.violet,
            ),
            KpiMetricCard(
              label: 'Offres période',
              value: formatKpiNumber(data.nbOffres),
              sublabel: data.montantOffres != null
                  ? '${formatFcfa(data.montantOffres!)} pipeline'
                  : null,
              icon: Icons.work_outline,
              accent: KpiAccent.cyan,
            ),
            KpiMetricCard(
              label: 'Prospects actifs',
              value: formatKpiNumber(data.prospectsActifs),
              icon: Icons.people_outline,
              accent: KpiAccent.rose,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (data.topProduitsBoutique.isNotEmpty)
          KpiChartCard(
            title: 'Top produits boutique',
            description: 'CA par article (période)',
            child: KpiBarChart(
              data: data.topProduitsBoutique,
              layout: KpiBarLayout.vertical,
              valueFormatter: (v) => formatFcfa(v),
            ),
          ),
        const SizedBox(height: 12),
        if (data.ventesParVille.isNotEmpty)
          KpiChartCard(
            title: 'Ventes par ville',
            description: 'CA boutique agrégé',
            child: KpiBarChart(
              data: data.ventesParVille,
              color: const Color(0xFF10B981),
              valueFormatter: (v) => formatFcfa(v),
            ),
          ),
        const SizedBox(height: 12),
        if (data.topClientsAchats.isNotEmpty)
          KpiChartCard(
            title: 'Top clients — achats boutique',
            child: KpiBarChart(
              data: data.topClientsAchats,
              layout: KpiBarLayout.vertical,
              color: const Color(0xFFF59E0B),
              valueFormatter: (v) => formatFcfa(v),
            ),
          ),
        const SizedBox(height: 12),
        if (data.prospectsParStatut.isNotEmpty)
          KpiChartCard(
            title: 'Prospects par statut',
            child: KpiBarChart(
              data: data.prospectsParStatut,
              layout: KpiBarLayout.vertical,
              color: const Color(0xFFE11D48),
            ),
          ),
        const SizedBox(height: 12),
        if (data.offresParStatut.isNotEmpty)
          KpiChartCard(
            title: 'Offres par statut',
            child: KpiDonutChart(data: data.offresParStatut, centerLabel: 'offres'),
          ),
        const SizedBox(height: 12),
        if (data.parTemperature.isNotEmpty)
          KpiChartCard(
            title: 'Par température',
            child: Column(
              children: [
                KpiDonutChart(data: data.parTemperature, centerLabel: 'prospects'),
                const SizedBox(height: 16),
                KpiBarChart(
                  data: data.parTemperature,
                  layout: KpiBarLayout.vertical,
                  color: const Color(0xFFEC4899),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        if (data.ventesParModePaiement.isNotEmpty)
          KpiChartCard(
            title: 'Ventes par mode de paiement',
            child: KpiBarChart(
              data: data.ventesParModePaiement,
              layout: KpiBarLayout.vertical,
              color: const Color(0xFF0891B2),
              valueFormatter: (v) => formatFcfa(v),
            ),
          ),
        if (data.tendanceVentes.isNotEmpty) ...[
          const SizedBox(height: 12),
          KpiChartCard(
            title: 'Tendance ventes',
            child: KpiAreaChart(
              data: data.tendanceVentes,
              color: const Color(0xFF9333EA),
              valueFormatter: (v) => formatFcfa(v),
            ),
          ),
        ],
      ],
    );
  }
}
