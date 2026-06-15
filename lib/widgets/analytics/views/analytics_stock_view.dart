import 'package:flutter/material.dart';

import '../../../models/analytics.dart';
import '../kpi_area_chart.dart';
import '../kpi_bar_chart.dart';
import '../kpi_chart_card.dart';
import '../kpi_donut_chart.dart';
import '../kpi_format.dart';
import '../kpi_metric_card.dart';

class AnalyticsStockView extends StatelessWidget {
  const AnalyticsStockView({super.key, required this.data});

  final AnalyticsStockKpi data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KpiMetricGrid(
          children: [
            KpiMetricCard(
              label: 'Huile sortie',
              value: formatVolumeMl(data.sortiesHuileMl),
              sublabel: data.retoursMl > 0
                  ? 'Retours ${formatVolumeMl(data.retoursMl)}'
                  : 'Quantités en ml',
              icon: Icons.water_drop_outlined,
              accent: KpiAccent.lime,
              highlight: true,
            ),
            if (data.valeurStockFcfa > 0)
              KpiMetricCard(
                label: 'Valeur stock',
                value: formatFcfa(data.valeurStockFcfa),
                sublabel: 'Quantité × prix achat FCFA',
                icon: Icons.inventory_2_outlined,
                accent: KpiAccent.emerald,
              ),
            KpiMetricCard(
              label: 'Alertes conso',
              value: formatKpiNumber(data.alertesConso),
              sublabel: 'Sous seuil d\'alerte',
              icon: Icons.warning_amber_outlined,
              accent: KpiAccent.amber,
            ),
            KpiMetricCard(
              label: 'BC internes ouverts',
              value: formatKpiNumber(data.bonsCommandeOuverts),
              sublabel: data.bcFournisseurOuverts != null
                  ? '${formatKpiNumber(data.bcFournisseurOuverts!)} BC fournisseur'
                  : null,
              icon: Icons.assignment_outlined,
              accent: KpiAccent.cyan,
            ),
            if ((data.sortiesEnAttente ?? 0) > 0)
              KpiMetricCard(
                label: 'Sorties en attente',
                value: formatKpiNumber(data.sortiesEnAttente!),
                icon: Icons.schedule_outlined,
                accent: KpiAccent.amber,
              ),
            if (data.productionLots != null)
              KpiMetricCard(
                label: 'Lots production',
                value: formatKpiNumber(data.productionLots!),
                sublabel: data.productionVolumeMl != null
                    ? formatVolumeMl(data.productionVolumeMl!, compact: true)
                    : null,
                icon: Icons.factory_outlined,
                accent: KpiAccent.violet,
              ),
            if (data.rotationJours > 0)
              KpiMetricCard(
                label: 'Rotation stock',
                value: '${formatKpiNumber(data.rotationJours)} j',
                icon: Icons.autorenew_outlined,
                accent: KpiAccent.slate,
              ),
          ],
        ),
        if (data.rupturesEntrepot > 0) ...[
          const SizedBox(height: 12),
          KpiAlertBanner(
            icon: Icons.warehouse_outlined,
            message:
                '${data.rupturesEntrepot} référence${data.rupturesEntrepot > 1 ? 's' : ''} en rupture — à traiter en priorité.',
            color: const Color(0xFFFFFBEB),
            borderColor: const Color(0xFFFDE68A),
            textColor: const Color(0xFF92400E),
            iconColor: const Color(0xFFD97706),
          ),
        ],
        const SizedBox(height: 12),
        if (data.productionTopProduits.isNotEmpty)
          KpiChartCard(
            title: 'Top produits produits',
            description: 'Lots atelier par senteur / huile',
            child: KpiBarChart(
              data: data.productionTopProduits,
              layout: KpiBarLayout.vertical,
            ),
          ),
        const SizedBox(height: 12),
        if (data.topMateriauxSortie.isNotEmpty)
          KpiChartCard(
            title: 'Top matériels sortis',
            description: 'Volume sortie (ml) par article',
            child: KpiBarChart(
              data: data.topMateriauxSortie,
              layout: KpiBarLayout.vertical,
              color: const Color(0xFF84CC16),
              valueFormatter: (v) => formatVolumeMl(v),
            ),
          ),
        const SizedBox(height: 12),
        if (data.parEntrepot.isNotEmpty)
          KpiChartCard(
            title: 'Sorties par entrepôt',
            description: 'Volume sortie (ml)',
            child: KpiBarChart(
              data: data.parEntrepot,
              layout: KpiBarLayout.vertical,
              color: const Color(0xFF84CC16),
              valueFormatter: (v) => formatVolumeMl(v),
            ),
          ),
        const SizedBox(height: 12),
        if (data.consoParClientTop.isNotEmpty)
          KpiChartCard(
            title: 'Top consommation clients',
            description: 'Huile sortie via interventions',
            child: KpiBarChart(
              data: data.consoParClientTop,
              color: const Color(0xFF10B981),
              valueFormatter: (v) => formatVolumeMl(v),
            ),
          ),
        const SizedBox(height: 12),
        if (data.topClientsTransport.isNotEmpty)
          KpiChartCard(
            title: 'Top clients — transport',
            description: 'Coût transport terrain (FCFA)',
            child: KpiBarChart(
              data: data.topClientsTransport,
              layout: KpiBarLayout.vertical,
              color: const Color(0xFF0891B2),
              valueFormatter: (v) => formatFcfa(v),
            ),
          ),
        const SizedBox(height: 12),
        if (data.tendanceSorties.isNotEmpty)
          KpiChartCard(
            title: 'Tendance sorties',
            description: 'Évolution sur 6 mois (ml)',
            child: KpiAreaChart(
              data: data.tendanceSorties,
              color: const Color(0xFF84CC16),
              valueFormatter: (v) => formatVolumeMl(v, compact: true),
            ),
          ),
        const SizedBox(height: 12),
        if (data.parEntrepot.isNotEmpty)
          KpiChartCard(
            title: 'Répartition entrepôts',
            child: KpiDonutChart(data: data.parEntrepot, centerLabel: 'ml'),
          ),
        const SizedBox(height: 12),
        if (data.bcFournisseurParStatut.isNotEmpty)
          KpiChartCard(
            title: 'BC fournisseur',
            description: 'Par statut workflow',
            child: KpiBarChart(
              data: data.bcFournisseurParStatut,
              layout: KpiBarLayout.vertical,
              color: const Color(0xFF0891B2),
            ),
          ),
        if (data.productionParStatut.isNotEmpty) ...[
          const SizedBox(height: 12),
          KpiChartCard(
            title: 'Production — statuts',
            child: KpiDonutChart(data: data.productionParStatut, centerLabel: 'lots'),
          ),
        ],
      ],
    );
  }
}
