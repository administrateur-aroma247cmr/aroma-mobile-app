import 'package:flutter/material.dart';

import '../../../models/analytics.dart';
import '../kpi_area_chart.dart';
import '../kpi_bar_chart.dart';
import '../kpi_chart_card.dart';
import '../kpi_donut_chart.dart';
import '../kpi_format.dart';
import '../kpi_metric_card.dart';
import '../kpi_progress_ring.dart';

class AnalyticsFacturationView extends StatelessWidget {
  const AnalyticsFacturationView({super.key, required this.data});

  final AnalyticsFacturationKpi data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KpiMetricGrid(
          children: [
            KpiMetricCard(
              label: 'CA facturé',
              value: formatFcfa(data.caFacture),
              icon: Icons.receipt_long_outlined,
              accent: KpiAccent.amber,
              highlight: true,
            ),
            KpiMetricCard(
              label: 'Dette client',
              value: formatFcfa(data.detteTotale),
              icon: Icons.account_balance_wallet_outlined,
              accent: KpiAccent.rose,
            ),
            KpiMetricCard(
              label: 'Factures en retard',
              value: formatKpiNumber(data.facturesRetard),
              sublabel: 'Échéance dépassée',
              icon: Icons.schedule_outlined,
              accent: KpiAccent.amber,
            ),
            KpiMetricCard(
              label: 'Relances',
              value: formatKpiNumber(data.nbRelances),
              sublabel:
                  'Délai moy. paiement ${data.delaiPaiementMoyenJours.toStringAsFixed(0)} j',
              icon: Icons.notifications_active_outlined,
              accent: KpiAccent.slate,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (data.parStatut.isNotEmpty)
          KpiChartCard(
            title: 'Factures par statut',
            description: 'À facturer, envoyée, payée, retard',
            child: Column(
              children: [
                KpiDonutChart(data: data.parStatut, centerLabel: 'factures'),
                const SizedBox(height: 16),
                KpiBarChart(
                  data: data.parStatut,
                  color: const Color(0xFFF59E0B),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        KpiProgressRingCard(
          title: 'Taux de recouvrement',
          description: 'Encaissé / dû — objectif 85 %',
          pct: data.tauxRecouvrementPct,
          sublabel: 'recouvré',
          color: const Color(0xFFD97706),
        ),
        const SizedBox(height: 12),
        if (data.tendanceCa.isNotEmpty)
          KpiChartCard(
            title: 'Évolution CA facturé',
            description: '6 derniers mois',
            child: KpiAreaChart(
              data: data.tendanceCa,
              color: const Color(0xFFF59E0B),
              valueFormatter: (v) => formatFcfa(v),
            ),
          ),
        if (data.parCanalEnvoi.isNotEmpty) ...[
          const SizedBox(height: 12),
          KpiChartCard(
            title: 'Par canal d\'envoi',
            child: KpiBarChart(
              data: data.parCanalEnvoi,
              layout: KpiBarLayout.vertical,
              color: const Color(0xFF6366F1),
            ),
          ),
        ],
      ],
    );
  }
}
